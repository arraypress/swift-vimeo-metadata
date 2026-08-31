//
//  CaptionList+Find.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//
//  Searching the list, delegating the matching rule into Support.
//

import Foundation

extension CaptionList {

    /// Language codes for all available tracks.
    public var availableLanguages: [String] {
        tracks.map(\.language)
    }

    /// Finds the best matching track for the given language preferences.
    ///
    /// - Parameter languages: Language codes in descending priority (e.g., `["en", "de"]`).
    /// - Returns: The best matching track, or `nil` if no match is found.
    public func findTrack(languages: [String] = ["en"]) -> CaptionTrack? {
        CaptionSelection.bestIndex(available: tracks.map(\.language), preferred: languages)
            .map { tracks[$0] }
    }
}
