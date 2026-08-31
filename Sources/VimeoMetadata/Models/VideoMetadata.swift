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

}
