//
//  VideoMetadata.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Metadata about a Vimeo video.
///
/// Fetched from Vimeo's API without user authentication. Includes video details,
/// uploader info, engagement counts, direct MP4 download URLs at multiple qualities,
/// transcript segments, and caption tracks.
///
/// ```swift
/// let result = try await VimeoMetadata.fetch("https://vimeo.com/123456789")
///
/// print(result.title)
/// print("\(result.uploader ?? "Unknown") — \(result.formattedDuration)")
/// print("Views: \(result.formattedViewCount ?? "N/A")")
///
/// // Best quality MP4
/// if let url = result.bestDownloadUrl {
///     print("Download: \(url)")
/// }
///
/// // Transcript
/// if !result.transcript.isEmpty {
///     print(result.plainText)
/// }
/// ```
public struct VideoMetadata: Sendable {
    
    /// The Vimeo video ID.
    public let videoId: String
    
    /// The video title.
    public let title: String
    
    /// The video description.
    public let description: String?
    
    // MARK: - Uploader
    
    /// The uploader/creator's display name.
    public let uploader: String?
    
    /// The uploader's Vimeo user ID (e.g., `"user12345678"`).
    public let uploaderId: String?
    
    /// The uploader's profile URL.
    public let uploaderUrl: String?
    
    // MARK: - Video Details
    
    /// Video duration in seconds.
    public let duration: Int
    
    /// Video width in pixels.
    public let width: Int?
    
    /// Video height in pixels.
    public let height: Int?
    
    /// The content license (e.g., `"by"`, `"by-sa"`, `"by-nc"`).
    public let license: String?
    
    /// The video language code.
    public let language: String?
    
    // MARK: - Engagement
    
    /// Number of plays/views.
    public let viewCount: Int?
    
    /// Number of likes.
    public let likeCount: Int?
    
    /// Number of comments.
    public let commentCount: Int?
    
    // MARK: - Timestamps
    
    /// When the video was created/uploaded.
    public let createdAt: Date?
    
    /// When the video was released (may differ from upload date).
    public let releasedAt: Date?
    
    // MARK: - Media
    
    /// Thumbnail URLs at various sizes, sorted largest first.
    public let thumbnails: [ThumbnailInfo]
    
    /// Available video download variants (progressive MP4s at different qualities).
    ///
    /// Sorted by resolution, highest first.
    public let variants: [VideoVariant]
    
    // MARK: - Captions
    
    /// Available caption/subtitle tracks.
    public let captionTracks: [CaptionTrack]
    
    /// Transcript segments parsed from the best available caption track.
    ///
    /// Empty if no captions are available. Populated when `fetchTranscript`
    /// is true (the default) in ``VimeoMetadata/fetch(_:languages:fetchTranscript:)``.
    public let transcript: [TranscriptSegment]
    
    /// The language of the fetched transcript.
    public let transcriptLanguage: String?
    
    // MARK: - Computed Properties
    
    /// The full Vimeo video URL.
    public var url: String {
        "https://vimeo.com/\(videoId)"
    }
    
    /// The highest-quality direct MP4 download URL.
    ///
    /// Returns the variant with the largest resolution.
    public var bestDownloadUrl: URL? {
        variants.first?.downloadUrl
    }
    
    /// The best thumbnail URL (largest available).
    public var thumbnailUrl: String? {
        thumbnails.first?.url
    }
    
    /// All transcript text joined into a single string.
    ///
    /// Empty string if no transcript is available.
    public var plainText: String {
        transcript.map(\.text).joined(separator: " ")
    }
    
    /// The transcript with timestamps, one segment per line.
    public var timestampedText: String {
        transcript.map { "[\($0.formattedStart)] \($0.text)" }.joined(separator: "\n")
    }
    
    /// The duration formatted as `"M:SS"` or `"H:MM:SS"`.
    public var formattedDuration: String {
        TranscriptSegment.formatTimestamp(Double(duration))
    }
    
    /// The view count formatted with locale-appropriate grouping separators.
    public var formattedViewCount: String? {
        guard let count = viewCount else { return nil }
        return Self.formatNumber(count)
    }
    
    /// The like count formatted with grouping separators.
    public var formattedLikeCount: String? {
        guard let count = likeCount else { return nil }
        return Self.formatNumber(count)
    }
    
    /// The comment count formatted with grouping separators.
    public var formattedCommentCount: String? {
        guard let count = commentCount else { return nil }
        return Self.formatNumber(count)
    }
    
    /// The creation date formatted as a readable string.
    public var formattedDate: String? {
        guard let date = createdAt else { return nil }
        return date.formatted(date: .abbreviated, time: .shortened)
    }
    
    /// Available caption languages as a ``CaptionList`` for searching.
    public var captions: CaptionList {
        CaptionList(tracks: captionTracks)
    }
    
    /// Formats a number with locale-appropriate grouping separators.
    private static func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
}
