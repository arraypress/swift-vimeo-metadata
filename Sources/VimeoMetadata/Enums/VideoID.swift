//
//  VideoID.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Utility for extracting Vimeo video IDs from various URL formats.
///
/// Supports `vimeo.com`, `player.vimeo.com`, and raw numeric IDs.
public enum VideoID {
    
    /// Regex patterns for extracting video IDs from Vimeo URLs.
    private static let patterns = [
        #"vimeo\.com/(?:video/)?(\d+)"#,
        #"player\.vimeo\.com/video/(\d+)"#,
        #"vimeo\.com/channels/[^/]+/(\d+)"#,
        #"vimeo\.com/groups/[^/]+/videos/(\d+)"#,
        #"vimeo\.com/album/\d+/video/(\d+)"#,
        #"vimeo\.com/showcase/\d+/video/(\d+)"#,
    ]
    
    /// Extracts a video ID from a URL string.
    ///
    /// Accepts:
    /// - `https://vimeo.com/123456789`
    /// - `https://vimeo.com/video/123456789`
    /// - `https://player.vimeo.com/video/123456789`
    /// - `https://vimeo.com/channels/staffpicks/123456789`
    /// - `https://vimeo.com/groups/name/videos/123456789`
    /// - Raw numeric video IDs
    ///
    /// Also extracts an optional unlisted hash if present (e.g., `vimeo.com/123456789/abcdef1234`).
    ///
    /// - Parameter input: A Vimeo URL or raw video ID.
    /// - Throws: ``VimeoMetadataError/invalidVideoId`` if no valid ID can be extracted.
    /// - Returns: The numeric video ID string.
    public static func extract(from input: String) throws -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Raw numeric ID
        if trimmed.allSatisfy(\.isNumber), trimmed.count >= 5 {
            return trimmed
        }
        
        // URL patterns
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(trimmed.startIndex..., in: trimmed)
                if let match = regex.firstMatch(in: trimmed, range: range),
                   let idRange = Range(match.range(at: 1), in: trimmed) {
                    return String(trimmed[idRange])
                }
            }
        }
        
        throw VimeoMetadataError.invalidVideoId
    }
    
    /// Extracts the unlisted hash from a Vimeo URL, if present.
    ///
    /// Unlisted videos have a hash appended: `vimeo.com/123456789/abcdef1234`
    ///
    /// - Parameter input: A Vimeo URL.
    /// - Returns: The unlisted hash, or `nil` if not found.
    public static func extractUnlistedHash(from input: String) -> String? {
        let pattern = #"vimeo\.com/(?:video/)?(\d+)/([0-9a-f]{10})"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(input.startIndex..., in: input)
        guard let match = regex.firstMatch(in: input, range: range),
              let hashRange = Range(match.range(at: 2), in: input) else { return nil }
        return String(input[hashRange])
    }
    
}
