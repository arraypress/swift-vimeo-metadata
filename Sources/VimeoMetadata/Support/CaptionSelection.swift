//
//  CaptionSelection.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//
//  Which caption track satisfies a language preference list: an exact
//  code beats a prefix match, earlier preferences beat later ones. A
//  pure rule over language strings, so it is pinned without a track
//  in sight.
//

import Foundation

/// Matching caption languages against a preference list.
enum CaptionSelection {

    /// The index of the best available language, or `nil` for no match.
    ///
    /// For each preferred code in order: an exact match wins outright,
    /// then a prefix match (`"en"` accepts `"en-US"`).
    static func bestIndex(available: [String], preferred: [String]) -> Int? {
        for lang in preferred {
            if let exact = available.firstIndex(where: { $0 == lang }) { return exact }
            if let prefix = available.firstIndex(where: { $0.hasPrefix(lang) }) { return prefix }
        }
        return nil
    }
}
