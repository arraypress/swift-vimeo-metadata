//
//  SupportTests.swift
//  VimeoMetadataTests
//
//  Created by David Sherlock on 2026.
//
//  The extracted rules pinned directly — no model constructed.
//

import XCTest
@testable import VimeoMetadata

final class SupportTests: XCTestCase {

    func testDurationFormatting() {
        XCTAssertEqual(Formatting.duration(seconds: 0), "0:00")
        XCTAssertEqual(Formatting.duration(seconds: 3599), "59:59")
        XCTAssertEqual(Formatting.duration(seconds: 3600), "1:00:00")
    }

    func testCountFormattingWithPinnedLocale() {
        XCTAssertEqual(Formatting.count(1234567, locale: Locale(identifier: "en_US")), "1,234,567")
    }

    func testVideoIDEdges() throws {
        XCTAssertEqual(try VideoID.extract(from: "https://vimeo.com/channels/staffpicks/123456789"), "123456789")
        XCTAssertEqual(VideoID.extractUnlistedHash(from: "https://vimeo.com/123456789/abcdef1234"), "abcdef1234")
    }

    func testCaptionLanguageMatching() {
        XCTAssertEqual(CaptionSelection.bestIndex(available: ["de", "en-US"], preferred: ["en"]), 1)
        XCTAssertEqual(CaptionSelection.bestIndex(available: ["en-US", "en"], preferred: ["en"]), 1,
                       "an exact code beats an earlier prefix match")
        XCTAssertNil(CaptionSelection.bestIndex(available: ["fr"], preferred: ["en", "de"]))
    }
}
