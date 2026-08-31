//
//  VideoVariant.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single video format variant at a specific resolution.
///
/// Vimeo serves progressive download MP4 files at multiple quality levels.
///
/// ```swift
/// for variant in video.variants {
///     print("\(variant.quality ?? "?") — \(variant.width)x\(variant.height)")
///     print("  URL: \(variant.url)")
/// }
/// ```
public struct VideoVariant: Codable, Equatable, Sendable {
    
    /// The direct MP4 download URL.
    public let url: String
    
    /// Video width in pixels.
    public let width: Int
    
    /// Video height in pixels.
    public let height: Int
    
    /// The quality label (e.g., `"360p"`, `"720p"`, `"1080p"`).
    public let quality: String?
    
    /// The video codec (e.g., `"H264"`, `"VP6F"`).
    public let codec: String?
    
    /// The file size in bytes, if known.
    public let filesize: Int?
    
    /// Frames per second, if known.
    public let fps: Int?
    
    /// The MIME type (e.g., `"video/mp4"`).
    public let mimeType: String?

}
