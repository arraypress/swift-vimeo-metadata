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

}
