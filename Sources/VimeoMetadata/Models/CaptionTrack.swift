//
//  CaptionTrack.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Represents an available caption/subtitle track for a Vimeo video.
///
/// ```swift
/// let result = try await VimeoMetadata.fetch("https://vimeo.com/123456789")
/// for track in result.captionTracks {
///     print("\(track.displayLanguage ?? track.language) — \(track.type ?? "unknown")")
/// }
/// ```
public struct CaptionTrack: Equatable, Sendable {
    
    /// The language code (e.g., `"en"`, `"de"`, `"fr"`).
    public let language: String
    
    /// The human-readable language name (e.g., `"English"`, `"German"`).
    public let displayLanguage: String?
    
    /// The track type (e.g., `"captions"`, `"subtitles"`).
    public let type: String?
    
    /// The track name/label, if provided by the creator.
    public let name: String?
    
    /// The URL to the WebVTT caption file.
    internal let url: String
    
    /// Whether this track is currently active/default.
    public let isActive: Bool
}
