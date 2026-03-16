//
//  ThumbnailInfo.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 3/16/26.
//

import Foundation

/// A thumbnail image at a specific size.
public struct ThumbnailInfo: Sendable {

    /// The thumbnail URL.
    public let url: String

    /// Width in pixels.
    public let width: Int

    /// Height in pixels.
    public let height: Int
}
