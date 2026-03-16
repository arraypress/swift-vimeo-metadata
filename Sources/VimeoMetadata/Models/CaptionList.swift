//
//  CaptionList.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 3/16/26.
//

import Foundation

/// The result of listing available captions for a video.
public struct CaptionList: Sendable {
    
    /// All available caption tracks.
    public let tracks: [CaptionTrack]
    
    /// Language codes for all available tracks.
    public var availableLanguages: [String] {
        tracks.map(\.language)
    }
    
    /// Finds the best matching track for the given language preferences.
    ///
    /// - Parameter languages: Language codes in descending priority (e.g., `["en", "de"]`).
    /// - Returns: The best matching track, or `nil` if no match is found.
    public func findTrack(languages: [String] = ["en"]) -> CaptionTrack? {
        for lang in languages {
            // Exact match
            if let track = tracks.first(where: { $0.language == lang }) {
                return track
            }
            // Prefix match (e.g., "en" matches "en-US")
            if let track = tracks.first(where: { $0.language.hasPrefix(lang) }) {
                return track
            }
        }
        return nil
    }
    
}
