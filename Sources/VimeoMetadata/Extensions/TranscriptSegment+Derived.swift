//
//  TranscriptSegment+Derived.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//
//  The segment's derived times, delegating into Support. The internal
//  formatTimestamp shim stays so existing in-module callers keep
//  working; it carries no rule of its own.
//

import Foundation

extension TranscriptSegment {

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
        Formatting.duration(seconds: Int(seconds))
    }
}
