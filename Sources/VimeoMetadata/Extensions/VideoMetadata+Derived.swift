//
//  VideoMetadata+Derived.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//
//  The video's derived facts. Formatting delegates into Support; the
//  one-line derivations are stated here in full.
//

import Foundation

extension VideoMetadata {

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
        Formatting.duration(seconds: duration)
    }

    /// The view count formatted with locale-appropriate grouping separators.
    public var formattedViewCount: String? {
        viewCount.map { Formatting.count($0) }
    }

    /// The like count formatted with grouping separators.
    public var formattedLikeCount: String? {
        likeCount.map { Formatting.count($0) }
    }

    /// The comment count formatted with grouping separators.
    public var formattedCommentCount: String? {
        commentCount.map { Formatting.count($0) }
    }

    /// The creation date formatted as a readable string.
    public var formattedDate: String? {
        createdAt.map { Formatting.date($0) }
    }

    /// Available caption languages as a ``CaptionList`` for searching.
    public var captions: CaptionList {
        CaptionList(tracks: captionTracks)
    }
}
