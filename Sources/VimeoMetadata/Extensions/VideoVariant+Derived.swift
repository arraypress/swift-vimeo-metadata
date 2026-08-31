//
//  VideoVariant+Derived.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//
//  The variant's one derived fact.
//

import Foundation

extension VideoVariant {

    /// The typed download URL.
    public var downloadUrl: URL? {
        URL(string: url)
    }
}
