//
//  VimeoMetadata.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetch metadata, video URLs, and transcripts from Vimeo videos.
///
/// Uses Vimeo's OAuth API with the macOS client credentials (same approach as yt-dlp)
/// to fetch video metadata, progressive MP4 download URLs, and WebVTT caption tracks.
/// No user authentication, API key, or developer account required.
///
/// ## Quick Start
///
/// ```swift
/// import VimeoMetadata
///
/// let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")
///
/// print(video.title)
/// print(video.uploader ?? "Unknown")
/// print("Duration: \(video.formattedDuration)")
///
/// // Best quality MP4 download
/// if let url = video.bestDownloadUrl {
///     print("Download: \(url)")
/// }
///
/// // Transcript (if captions available)
/// if !video.transcript.isEmpty {
///     print(video.plainText)
/// }
///
/// // All quality variants
/// for variant in video.variants {
///     print("\(variant.quality ?? "?") — \(variant.width)x\(variant.height)")
/// }
/// ```
///
/// ## How It Works
///
/// 1. **Obtain OAuth token** — POST to `api.vimeo.com/oauth/authorize/client` with macOS
///    client credentials. Returns a bearer token. Token is cached for subsequent requests.
/// 2. **Fetch video data** — GET `api.vimeo.com/videos/{id}` with the bearer token.
///    Returns title, description, duration, uploader, thumbnails, engagement counts,
///    and `play.progressive` array with direct MP4 URLs at multiple qualities.
/// 3. **Fetch text tracks** — GET `api.vimeo.com/videos/{id}/texttracks` with
///    `include_transcript=true`. Returns VTT subtitle URLs by language.
/// 4. **Fetch and parse VTT** — Downloads the best matching caption file and parses
///    it into timed transcript segments.
public enum VimeoMetadata {
    
    // MARK: - Configuration
    
    /// macOS client Basic auth credentials (from yt-dlp).
    ///
    /// This is a public client credential embedded in Vimeo's macOS app,
    /// used by all major extraction tools. Not a personal or secret credential.
    private static let clientAuth = "NDc1N2JlN2Y5ZjZmMjU3NzE3NTRkZTg1NmY2YzU2MTI0OTFlNjJiYjpwVUNDWUlBZmZqSHhQcndBYWxGMzgyYys2NkN5d1JrREJZZXdPcEdsU05tdjFlVVo2aE1lYk9GcWE3ZW9KVldlYnFlOWh5Vno5UWtpUGJ5empYZFBpYkFwV0FFTnB5VWV4ZEh3aHZnRUNEL0VySnBzTmFraDdNbS9nMXhWanhIcw=="
    
    /// macOS client User-Agent string (from yt-dlp).
    private static let clientUserAgent = "Vimeo/1.6.3 (com.vimeo.mac; build:251121.142637.0; macOS 13.7.8) Alamofire/5.9.0 VimeoNetworking/5.0.0"
    
    /// API version headers required by Vimeo.
    private static let apiHeaders: [String: String] = [
        "Accept": "application/vnd.vimeo.*+json; version=3.4.10",
        "Accept-Language": "en",
    ]
    
    /// Fields to request from the videos API.
    ///
    /// Requesting specific fields reduces response size and avoids
    /// unnecessary data transfer.
    private static let videoFields = [
        "uri", "name", "description", "type", "link", "duration", "width", "height",
        "created_time", "modified_time", "release_time", "license", "language",
        "privacy", "pictures", "stats", "metadata", "user", "play", "download",
        "files", "is_playable", "has_audio"
    ].joined(separator: ",")
    
    /// Cached OAuth token to avoid fetching on every request.
    private static let tokenCache = TokenCache()
    
    // MARK: - Public API
    
    /// Fetches metadata, video URLs, and optionally a transcript for a Vimeo video.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")
    ///
    /// print(video.title)
    /// print(video.formattedDuration)
    /// print(video.formattedViewCount ?? "N/A")
    ///
    /// // Direct MP4 download
    /// if let url = video.bestDownloadUrl {
    ///     print("Download: \(url)")
    /// }
    ///
    /// // Transcript
    /// print(video.plainText)
    ///
    /// // Password-protected video
    /// let course = try await VimeoMetadata.fetch("https://vimeo.com/68375962", password: "secret")
    /// ```
    ///
    /// - Parameters:
    ///   - input: A Vimeo video URL or numeric video ID.
    ///   - languages: Language codes for transcript preference. Defaults to `["en"]`.
    ///   - fetchTranscript: Whether to fetch and parse caption content. Defaults to `true`.
    ///   - password: Password for protected videos. Pass `nil` for public videos.
    /// - Throws: ``VimeoMetadataError`` if the metadata cannot be retrieved.
    /// - Returns: A ``VideoMetadata`` with all available fields populated.
    public static func fetch(
        _ input: String,
        languages: [String] = ["en"],
        fetchTranscript: Bool = true,
        password: String? = nil
    ) async throws -> VideoMetadata {
        let videoId = try VideoID.extract(from: input)
        let unlistedHash = VideoID.extractUnlistedHash(from: input)
        
        // Step 1: Get OAuth token
        let token = try await getToken()
        
        // Step 2: Fetch video data from API (with password retry if needed)
        let videoData: [String: Any]
        do {
            videoData = try await fetchVideoAPI(videoId: videoId, unlistedHash: unlistedHash, token: token)
        } catch VimeoMetadataError.passwordRequired {
            guard let password = password else {
                throw VimeoMetadataError.passwordRequired
            }
            // Submit password and retry
            try await submitVideoPassword(videoId: videoId, password: password, token: token)
            videoData = try await fetchVideoAPI(videoId: videoId, unlistedHash: unlistedHash, token: token)
        }
        
        // Step 3: Fetch text tracks
        let captionTracks = await fetchTextTracks(videoId: videoId, unlistedHash: unlistedHash, token: token)
        
        // Step 4: Optionally fetch and parse the best caption track
        var segments: [TranscriptSegment] = []
        var transcriptLanguage: String? = nil
        
        if fetchTranscript && !captionTracks.isEmpty {
            let captionList = CaptionList(tracks: captionTracks)
            if let track = captionList.findTrack(languages: languages) {
                if let vttContent = try? await fetchVTT(url: track.url) {
                    segments = VTTParser.parse(vttContent, language: track.language)
                    transcriptLanguage = track.language
                }
            }
        }
        
        // Parse the video data
        return parseVideoData(
            videoData,
            videoId: videoId,
            captionTracks: captionTracks,
            transcript: segments,
            transcriptLanguage: transcriptLanguage
        )
    }
    
    /// Lists available caption tracks for a Vimeo video without fetching content.
    ///
    /// ```swift
    /// let captions = try await VimeoMetadata.listCaptions("https://vimeo.com/123456789")
    /// print("Available: \(captions.availableLanguages)")
    /// ```
    ///
    /// - Parameter input: A Vimeo video URL or numeric video ID.
    /// - Throws: ``VimeoMetadataError`` if the video data cannot be accessed.
    /// - Returns: A ``CaptionList`` containing available tracks.
    public static func listCaptions(_ input: String) async throws -> CaptionList {
        let videoId = try VideoID.extract(from: input)
        let unlistedHash = VideoID.extractUnlistedHash(from: input)
        let token = try await getToken()
        let tracks = await fetchTextTracks(videoId: videoId, unlistedHash: unlistedHash, token: token)
        return CaptionList(tracks: tracks)
    }
    
    // MARK: - OAuth Token
    
    /// Obtains a cached or fresh OAuth token.
    private static func getToken() async throws -> String {
        if let cached = await tokenCache.get() {
            return cached
        }
        
        let token = try await fetchOAuthToken()
        await tokenCache.set(token)
        return token
    }
    
    /// Fetches a fresh OAuth token from Vimeo's client credentials endpoint.
    ///
    /// Uses the macOS client's Basic auth credentials to obtain a bearer token
    /// via the `client_credentials` grant type. No user login required.
    private static func fetchOAuthToken() async throws -> String {
        guard let url = URL(string: "https://api.vimeo.com/oauth/authorize/client") else {
            throw VimeoMetadataError.tokenFailed
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic \(clientAuth)", forHTTPHeaderField: "Authorization")
        request.setValue(clientUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        for (key, value) in apiHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let body = "grant_type=client_credentials&scope=public"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 { throw VimeoMetadataError.rateLimited }
            if httpResponse.statusCode != 200 {
                throw VimeoMetadataError.tokenFailed
            }
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw VimeoMetadataError.tokenFailed
        }
        
        return accessToken
    }
    
    // MARK: - Videos API
    
    /// Fetches video data from the Vimeo API.
    private static func fetchVideoAPI(videoId: String, unlistedHash: String?, token: String) async throws -> [String: Any] {
        let videoPath = unlistedHash != nil ? "\(videoId):\(unlistedHash!)" : videoId
        guard let url = URL(string: "https://api.vimeo.com/videos/\(videoPath)?fields=\(videoFields)") else {
            throw VimeoMetadataError.parsingError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(clientUserAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in apiHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 404 { throw VimeoMetadataError.videoNotFound }
            if httpResponse.statusCode == 403 { throw VimeoMetadataError.videoNotFound }
            if httpResponse.statusCode == 429 { throw VimeoMetadataError.rateLimited }
            if httpResponse.statusCode == 400 {
                // Check if password is required
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let invalidParams = json["invalid_parameters"] as? [[String: Any]],
                   invalidParams.contains(where: { ($0["field"] as? String) == "password" }) {
                    throw VimeoMetadataError.passwordRequired
                }
            }
            if httpResponse.statusCode != 200 {
                throw VimeoMetadataError.networkError("API HTTP \(httpResponse.statusCode)")
            }
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw VimeoMetadataError.parsingError("Invalid API JSON")
        }
        
        return json
    }
    
    // MARK: - Password Submission
    
    /// Submits a password for a password-protected video.
    ///
    /// Vimeo's password flow requires fetching a viewer token first, then POSTing
    /// the password to `vimeo.com/{id}/password`. The response sets cookies that
    /// grant access, after which the API can be retried.
    ///
    /// Mirrors yt-dlp's `_verify_video_password` approach.
    ///
    /// - Parameters:
    ///   - videoId: The video ID.
    ///   - password: The video password.
    ///   - token: The OAuth bearer token.
    /// - Throws: ``VimeoMetadataError/wrongPassword`` if the password is incorrect,
    ///           or ``VimeoMetadataError/networkError(_:)`` on failure.
    private static func submitVideoPassword(videoId: String, password: String, token: String) async throws {
        // Step 1: Fetch viewer info to get the XSRF token
        guard let viewerUrl = URL(string: "https://vimeo.com/_next/viewer") else {
            throw VimeoMetadataError.parsingError("Invalid viewer URL")
        }
        
        var viewerRequest = URLRequest(url: viewerUrl)
        viewerRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        viewerRequest.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        
        let config = URLSessionConfiguration.default
        config.httpCookieAcceptPolicy = .always
        config.httpCookieStorage = HTTPCookieStorage.shared
        let session = URLSession(configuration: config)
        
        let (viewerData, _) = try await session.data(for: viewerRequest)
        
        guard let viewerJson = try? JSONSerialization.jsonObject(with: viewerData) as? [String: Any],
              let xsrfToken = viewerJson["xsrft"] as? String else {
            throw VimeoMetadataError.parsingError("Could not extract XSRF token for password submission")
        }
        
        // Step 2: POST the password
        let passwordUrl = URL(string: "https://vimeo.com/\(videoId)/password")!
        
        var passwordRequest = URLRequest(url: passwordUrl)
        passwordRequest.httpMethod = "POST"
        passwordRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        passwordRequest.setValue("*/*", forHTTPHeaderField: "Accept")
        passwordRequest.setValue("https://vimeo.com/\(videoId)", forHTTPHeaderField: "Referer")
        passwordRequest.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            forHTTPHeaderField: "User-Agent"
        )
        
        let body: [String: String] = [
            "password": password,
            "token": xsrfToken,
        ]
        passwordRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, passwordResponse) = try await session.data(for: passwordRequest)
        
        if let httpResponse = passwordResponse as? HTTPURLResponse {
            if httpResponse.statusCode == 418 {
                throw VimeoMetadataError.wrongPassword
            }
            if httpResponse.statusCode != 200 && httpResponse.statusCode != 204 {
                throw VimeoMetadataError.networkError("Password submission HTTP \(httpResponse.statusCode)")
            }
        }
    }
    
    // MARK: - Text Tracks API
    
    /// Fetches available text tracks (captions/subtitles) from the Vimeo API.
    private static func fetchTextTracks(videoId: String, unlistedHash: String?, token: String) async -> [CaptionTrack] {
        let videoPath = unlistedHash != nil ? "\(videoId):\(unlistedHash!)" : videoId
        let fields = "active,display_language,id,language,link,name,type,uri"
        guard let url = URL(string: "https://api.vimeo.com/videos/\(videoPath)/texttracks?include_transcript=true&fields=\(fields)") else {
            return []
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(clientUserAgent, forHTTPHeaderField: "User-Agent")
        for (key, value) in apiHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tracksData = json["data"] as? [[String: Any]] else {
            return []
        }
        
        return tracksData.compactMap { tt -> CaptionTrack? in
            guard let link = tt["link"] as? String, !link.isEmpty else { return nil }
            return CaptionTrack(
                language: tt["language"] as? String ?? "en",
                displayLanguage: tt["display_language"] as? String,
                type: tt["type"] as? String,
                name: tt["name"] as? String,
                url: link,
                isActive: tt["active"] as? Bool ?? false
            )
        }
    }
    
    // MARK: - VTT Fetching
    
    /// Fetches a WebVTT caption file.
    private static func fetchVTT(url: String) async throws -> String {
        guard let vttUrl = URL(string: url) else {
            throw VimeoMetadataError.parsingError("Invalid VTT URL")
        }
        
        let (data, response) = try await URLSession.shared.data(for: URLRequest(url: vttUrl))
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw VimeoMetadataError.networkError("VTT HTTP \(httpResponse.statusCode)")
        }
        
        guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
            throw VimeoMetadataError.parsingError("Empty VTT response")
        }
        
        return content
    }
    
    // MARK: - Response Parsing
    
    /// Parses the API response into a ``VideoMetadata`` struct.
    private static func parseVideoData(
        _ video: [String: Any],
        videoId: String,
        captionTracks: [CaptionTrack],
        transcript: [TranscriptSegment],
        transcriptLanguage: String?
    ) -> VideoMetadata {
        // User/uploader
        let user = video["user"] as? [String: Any]
        let userLink = user?["link"] as? String
        let uploaderId = userLink?.components(separatedBy: "/").last
        
        // Thumbnails
        let pictures = video["pictures"] as? [String: Any]
        let sizes = pictures?["sizes"] as? [[String: Any]] ?? []
        let thumbnails: [ThumbnailInfo] = sizes.compactMap { size in
            guard let url = size["link"] as? String else { return nil }
            return ThumbnailInfo(
                url: url,
                width: size["width"] as? Int ?? 0,
                height: size["height"] as? Int ?? 0
            )
        }.sorted { ($0.width * $0.height) > ($1.width * $1.height) }
        
        // Progressive download variants
        var variants: [VideoVariant] = []
        let play = video["play"] as? [String: Any]
        let progressive = play?["progressive"] as? [[String: Any]] ?? []
        for file in progressive {
            guard let link = file["link"] as? String else { continue }
            variants.append(VideoVariant(
                url: link,
                width: file["width"] as? Int ?? 0,
                height: file["height"] as? Int ?? 0,
                quality: file["rendition"] as? String ?? file["public_name"] as? String,
                codec: file["codec"] as? String,
                filesize: file["size"] as? Int,
                fps: file["fps"] as? Int,
                mimeType: file["type"] as? String
            ))
        }
        
        // Also check download array and files array
        for key in ["download", "files"] {
            if let files = video[key] as? [[String: Any]] {
                for file in files {
                    guard let link = file["link"] as? String,
                          !variants.contains(where: { $0.url == link }) else { continue }
                    
                    // Skip HLS/DASH entries — they have no dimensions and are
                    // already available via play.hls and play.dash
                    let quality = file["quality"] as? String ?? ""
                    let rendition = file["rendition"] as? String ?? ""
                    if quality == "hls" || quality == "dash" || rendition == "adaptive" {
                        continue
                    }
                    
                    variants.append(VideoVariant(
                        url: link,
                        width: file["width"] as? Int ?? 0,
                        height: file["height"] as? Int ?? 0,
                        quality: file["rendition"] as? String ?? file["public_name"] as? String ?? file["quality"] as? String,
                        codec: file["codec"] as? String,
                        filesize: file["size"] as? Int,
                        fps: file["fps"] as? Int,
                        mimeType: file["type"] as? String
                    ))
                }
            }
        }
        
        // Sort variants by resolution, highest first
        variants.sort { ($0.width * $0.height) > ($1.width * $1.height) }
        
        // Engagement stats
        let stats = video["stats"] as? [String: Any]
        let viewCount = stats?["plays"] as? Int
        
        let connections = (video["metadata"] as? [String: Any])?["connections"] as? [String: Any]
        let likeCount = (connections?["likes"] as? [String: Any])?["total"] as? Int
        let commentCount = (connections?["comments"] as? [String: Any])?["total"] as? Int
        
        return VideoMetadata(
            videoId: videoId,
            title: video["name"] as? String ?? "",
            description: video["description"] as? String,
            uploader: user?["name"] as? String,
            uploaderId: uploaderId,
            uploaderUrl: userLink,
            duration: video["duration"] as? Int ?? 0,
            width: video["width"] as? Int,
            height: video["height"] as? Int,
            license: video["license"] as? String,
            language: video["language"] as? String,
            viewCount: viewCount,
            likeCount: likeCount,
            commentCount: commentCount,
            createdAt: parseDate(video["created_time"] as? String),
            releasedAt: parseDate(video["release_time"] as? String),
            thumbnails: thumbnails,
            variants: variants,
            captionTracks: captionTracks,
            transcript: transcript,
            transcriptLanguage: transcriptLanguage
        )
    }
    
    // MARK: - Helpers
    
    /// Parses an ISO 8601 date string.
    private static func parseDate(_ dateStr: String?) -> Date? {
        guard let dateStr = dateStr else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateStr) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateStr)
    }
    
}

// MARK: - Token Cache

/// Thread-safe cache for the OAuth token.
///
/// Tokens are cached in memory for the lifetime of the process.
/// Vimeo client credential tokens are long-lived (typically hours).
private actor TokenCache {
    private var token: String?
    
    func get() -> String? {
        token
    }
    
    func set(_ newToken: String) {
        token = newToken
    }
}
