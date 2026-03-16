//
//  TranscriptSegment.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single timed segment of a transcript.
///
/// Each segment represents a portion of spoken text during a specific
/// time window of the video, parsed from WebVTT captions.
public struct TranscriptSegment: Codable, Equatable, Sendable {

    /// The text content of this segment.
    public let text: String

    /// The start time in seconds from the beginning of the video.
    public let start: Double

    /// How long this segment is displayed in seconds.
    public let duration: Double

    /// The language code of this segment (e.g., `"en"`, `"de"`).
    public let language: String

    /// The end time in seconds (`start + duration`).
    public var end: Double {
        start + duration
    }

    /// The start time formatted as `"M:SS"` or `"H:MM:SS"`.
    public var formattedStart: String {
        Self.formatTimestamp(start)
    }

    /// Formats a time interval in seconds to `"M:SS"` or `"H:MM:SS"`.
    internal static func formatTimestamp(_ seconds: Double) -> String {
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
    }
    
}
