//
//  VimeoMetadataTests.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import XCTest
@testable import VimeoMetadata

final class VimeoMetadataTests: XCTestCase {
    
    // MARK: - Video ID Extraction
    
    func testExtractFromStandardUrl() throws {
        let id = try VideoID.extract(from: "https://vimeo.com/54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractFromVideoPath() throws {
        let id = try VideoID.extract(from: "https://vimeo.com/video/54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractFromPlayerUrl() throws {
        let id = try VideoID.extract(from: "https://player.vimeo.com/video/54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractFromChannelUrl() throws {
        let id = try VideoID.extract(from: "https://vimeo.com/channels/staffpicks/54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractFromGroupUrl() throws {
        let id = try VideoID.extract(from: "https://vimeo.com/groups/mygroup/videos/54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractFromShowcaseUrl() throws {
        let id = try VideoID.extract(from: "https://vimeo.com/showcase/12345/video/54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractFromRawId() throws {
        let id = try VideoID.extract(from: "54469442")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractWithWhitespace() throws {
        let id = try VideoID.extract(from: "  54469442  ")
        XCTAssertEqual(id, "54469442")
    }
    
    func testExtractInvalidThrows() {
        XCTAssertThrowsError(try VideoID.extract(from: "not-a-url")) { error in
            XCTAssertEqual(error as? VimeoMetadataError, .invalidVideoId)
        }
    }
    
    func testExtractEmptyStringThrows() {
        XCTAssertThrowsError(try VideoID.extract(from: "")) { error in
            XCTAssertEqual(error as? VimeoMetadataError, .invalidVideoId)
        }
    }
    
    // MARK: - Unlisted Hash Extraction
    
    func testExtractUnlistedHash() {
        let hash = VideoID.extractUnlistedHash(from: "https://vimeo.com/123456789/abcdef1234")
        XCTAssertEqual(hash, "abcdef1234")
    }
    
    func testExtractUnlistedHashVideoPath() {
        let hash = VideoID.extractUnlistedHash(from: "https://vimeo.com/video/123456789/abcdef1234")
        XCTAssertEqual(hash, "abcdef1234")
    }
    
    func testExtractUnlistedHashNone() {
        let hash = VideoID.extractUnlistedHash(from: "https://vimeo.com/123456789")
        XCTAssertNil(hash)
    }
    
    // MARK: - VTT Parser
    
    func testParseSimpleVTT() {
        let vtt = """
        WEBVTT
        
        00:00:01.000 --> 00:00:03.000
        Hello everyone
        
        00:00:03.500 --> 00:00:05.000
        Welcome to my video
        """
        
        let segments = VTTParser.parse(vtt, language: "en")
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].text, "Hello everyone")
        XCTAssertEqual(segments[0].start, 1.0)
        XCTAssertEqual(segments[0].language, "en")
        XCTAssertEqual(segments[1].text, "Welcome to my video")
    }
    
    func testParseVTTWithTags() {
        let vtt = """
        WEBVTT
        
        00:00:00.000 --> 00:00:02.000
        <v Speaker>styled text</v>
        """
        
        let segments = VTTParser.parse(vtt, language: "en")
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].text, "styled text")
    }
    
    func testParseEmptyVTT() {
        let segments = VTTParser.parse("", language: "en")
        XCTAssertTrue(segments.isEmpty)
    }
    
    func testParseVTTHoursFormat() {
        let vtt = """
        WEBVTT
        
        01:30:05.500 --> 01:30:08.000
        Long video segment
        """
        
        let segments = VTTParser.parse(vtt, language: "en")
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].start, 5405.5, accuracy: 0.01)
    }
    
    // MARK: - TranscriptSegment
    
    func testFormattedStart() {
        let segment = TranscriptSegment(text: "test", start: 65.5, duration: 1, language: "en")
        XCTAssertEqual(segment.formattedStart, "1:05")
    }
    
    func testFormattedStartHours() {
        let segment = TranscriptSegment(text: "test", start: 3661, duration: 1, language: "en")
        XCTAssertEqual(segment.formattedStart, "1:01:01")
    }
    
    func testFormattedStartZero() {
        let segment = TranscriptSegment(text: "test", start: 0, duration: 1, language: "en")
        XCTAssertEqual(segment.formattedStart, "0:00")
    }
    
    func testSegmentEnd() {
        let segment = TranscriptSegment(text: "test", start: 10, duration: 2.5, language: "en")
        XCTAssertEqual(segment.end, 12.5)
    }
    
    // MARK: - CaptionList
    
    func testFindTrackExactMatch() {
        let tracks = [
            CaptionTrack(language: "en", displayLanguage: "English", type: "captions", name: nil, url: "url1", isActive: true),
            CaptionTrack(language: "de", displayLanguage: "German", type: "captions", name: nil, url: "url2", isActive: false),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.findTrack(languages: ["de"])?.language, "de")
    }
    
    func testFindTrackPrefixMatch() {
        let tracks = [
            CaptionTrack(language: "en-US", displayLanguage: "English", type: "captions", name: nil, url: "url1", isActive: true),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.findTrack(languages: ["en"])?.language, "en-US")
    }
    
    func testFindTrackFallback() {
        let tracks = [
            CaptionTrack(language: "en", displayLanguage: "English", type: "captions", name: nil, url: "url1", isActive: true),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.findTrack(languages: ["fr", "en"])?.language, "en")
    }
    
    func testFindTrackReturnsNil() {
        let tracks = [
            CaptionTrack(language: "en", displayLanguage: "English", type: "captions", name: nil, url: "url1", isActive: true),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertNil(list.findTrack(languages: ["fr", "de"]))
    }
    
    func testAvailableLanguages() {
        let tracks = [
            CaptionTrack(language: "en", displayLanguage: "English", type: "captions", name: nil, url: "url1", isActive: true),
            CaptionTrack(language: "de", displayLanguage: "German", type: "captions", name: nil, url: "url2", isActive: false),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.availableLanguages, ["en", "de"])
    }
    
    // MARK: - VideoMetadata Convenience
    
    func testBestDownloadUrl() {
        // Variants should be pre-sorted largest first (as parseVideoData does)
        let video = makeVideo(variants: [
            VideoVariant(url: "https://example.com/large.mp4", width: 1920, height: 1080, quality: "1080p", codec: nil, filesize: nil, fps: nil, mimeType: nil),
            VideoVariant(url: "https://example.com/small.mp4", width: 480, height: 270, quality: "360p", codec: nil, filesize: nil, fps: nil, mimeType: nil),
        ])
        XCTAssertEqual(video.bestDownloadUrl?.absoluteString, "https://example.com/large.mp4")
    }
    
    func testBestDownloadUrlNil() {
        let video = makeVideo(variants: [])
        XCTAssertNil(video.bestDownloadUrl)
    }
    
    func testPlainText() {
        let video = makeVideo(transcript: [
            TranscriptSegment(text: "Hello", start: 0, duration: 1, language: "en"),
            TranscriptSegment(text: "World", start: 1, duration: 1, language: "en"),
        ])
        XCTAssertEqual(video.plainText, "Hello World")
    }
    
    func testTimestampedText() {
        let video = makeVideo(transcript: [
            TranscriptSegment(text: "Hello", start: 0, duration: 1, language: "en"),
            TranscriptSegment(text: "World", start: 65, duration: 1, language: "en"),
        ])
        XCTAssertEqual(video.timestampedText, "[0:00] Hello\n[1:05] World")
    }
    
    func testEmptyTranscript() {
        let video = makeVideo(transcript: [])
        XCTAssertEqual(video.plainText, "")
        XCTAssertEqual(video.timestampedText, "")
    }
    
    func testFormattedDuration() {
        let video = makeVideo(duration: 3661)
        XCTAssertEqual(video.formattedDuration, "1:01:01")
    }
    
    func testFormattedViewCount() {
        let video = makeVideo(viewCount: 15420)
        XCTAssertNotNil(video.formattedViewCount)
        XCTAssertTrue(video.formattedViewCount!.contains("15"))
    }
    
    func testFormattedViewCountNil() {
        let video = makeVideo(viewCount: nil)
        XCTAssertNil(video.formattedViewCount)
    }
    
    func testFormattedLikeCount() {
        let video = makeVideo(likeCount: 250)
        XCTAssertNotNil(video.formattedLikeCount)
    }
    
    func testFormattedLikeCountNil() {
        let video = makeVideo(likeCount: nil)
        XCTAssertNil(video.formattedLikeCount)
    }
    
    func testFormattedCommentCount() {
        let video = makeVideo(commentCount: 42)
        XCTAssertNotNil(video.formattedCommentCount)
    }
    
    func testFormattedDate() {
        let video = makeVideo(createdAt: Date(timeIntervalSince1970: 1710412072))
        XCTAssertNotNil(video.formattedDate)
    }
    
    func testFormattedDateNil() {
        let video = makeVideo(createdAt: nil)
        XCTAssertNil(video.formattedDate)
    }
    
    func testUrl() {
        let video = makeVideo()
        XCTAssertEqual(video.url, "https://vimeo.com/123456")
    }
    
    func testThumbnailUrl() {
        let video = makeVideo()
        XCTAssertEqual(video.thumbnailUrl, "https://i.vimeocdn.com/video/large.jpg")
    }
    
    func testCaptionsList() {
        let tracks = [
            CaptionTrack(language: "en", displayLanguage: "English", type: "captions", name: nil, url: "url1", isActive: true),
        ]
        let video = makeVideo(captionTracks: tracks)
        XCTAssertEqual(video.captions.availableLanguages, ["en"])
    }
    
    // MARK: - VideoVariant
    
    func testVariantDownloadUrl() {
        let variant = VideoVariant(url: "https://example.com/video.mp4", width: 1920, height: 1080, quality: "1080p", codec: "H264", filesize: 50_000_000, fps: 30, mimeType: "video/mp4")
        XCTAssertNotNil(variant.downloadUrl)
        XCTAssertEqual(variant.downloadUrl?.absoluteString, "https://example.com/video.mp4")
    }
    
    // MARK: - Error Descriptions
    
    func testAllErrorsHaveDescriptions() {
        let errors: [VimeoMetadataError] = [
            .invalidUrl,
            .invalidVideoId,
            .videoNotFound,
            .passwordRequired,
            .wrongPassword,
            .rateLimited,
            .tokenFailed,
            .noCaptions,
            .noCaptionForLanguage(requested: ["en"], available: ["de"]),
            .networkError("timeout"),
            .parsingError("bad json"),
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testErrorEquatable() {
        XCTAssertEqual(VimeoMetadataError.invalidUrl, .invalidUrl)
        XCTAssertEqual(VimeoMetadataError.videoNotFound, .videoNotFound)
        XCTAssertNotEqual(VimeoMetadataError.invalidUrl, .videoNotFound)
    }
    
    // MARK: - Integration Tests (require network)
    
    func testFetchVideo() async throws {
        // Public Vimeo video (Kathy Sierra talk)
        let video = try await VimeoMetadata.fetch("https://vimeo.com/54469442", fetchTranscript: false)
        
        XCTAssertEqual(video.videoId, "54469442")
        XCTAssertFalse(video.title.isEmpty)
        XCTAssertGreaterThan(video.duration, 0)
        XCTAssertNotNil(video.uploader)
        XCTAssertFalse(video.uploader!.isEmpty)
    }
    
    func testFetchVideoVariants() async throws {
        let video = try await VimeoMetadata.fetch("https://vimeo.com/54469442", fetchTranscript: false)
        
        XCTAssertFalse(video.variants.isEmpty, "Should have video variants")
        XCTAssertNotNil(video.bestDownloadUrl, "Should have a best download URL")
        
        // All variants should have URLs
        for variant in video.variants {
            XCTAssertFalse(variant.url.isEmpty)
        }
        
        // Progressive MP4 variants should have dimensions
        // (HLS entries from the files array may have width/height = 0)
        let progressiveVariants = video.variants.filter { $0.url.contains("progressive") }
        XCTAssertFalse(progressiveVariants.isEmpty, "Should have progressive MP4 variants")
        for variant in progressiveVariants {
            XCTAssertGreaterThan(variant.width, 0, "Progressive variant should have width")
            XCTAssertGreaterThan(variant.height, 0, "Progressive variant should have height")
        }
    }
    
    func testFetchVideoThumbnails() async throws {
        let video = try await VimeoMetadata.fetch("https://vimeo.com/54469442", fetchTranscript: false)
        
        XCTAssertFalse(video.thumbnails.isEmpty, "Should have thumbnails")
        XCTAssertNotNil(video.thumbnailUrl)
    }
    
    func testFetchVideoMetadata() async throws {
        let video = try await VimeoMetadata.fetch("https://vimeo.com/54469442", fetchTranscript: false)
        
        XCTAssertNotNil(video.uploaderUrl)
        XCTAssertNotNil(video.uploaderId)
        XCTAssertNotNil(video.createdAt)
    }
    
    func testFetchFromRawId() async throws {
        let video = try await VimeoMetadata.fetch("54469442", fetchTranscript: false)
        XCTAssertEqual(video.videoId, "54469442")
        XCTAssertFalse(video.title.isEmpty)
    }
    
    func testListCaptions() async throws {
        // This particular video may or may not have captions —
        // just test that the API call succeeds without error
        let captions = try await VimeoMetadata.listCaptions("54469442")
        // Don't assert on content since not all videos have captions
        XCTAssertNotNil(captions)
    }
    
    // MARK: - Helpers
    
    private func makeVideo(
        duration: Int = 120,
        viewCount: Int? = 1000,
        likeCount: Int? = 50,
        commentCount: Int? = 10,
        createdAt: Date? = Date(),
        variants: [VideoVariant]? = nil,
        captionTracks: [CaptionTrack] = [],
        transcript: [TranscriptSegment] = []
    ) -> VideoMetadata {
        let defaultVariants = variants ?? [
            VideoVariant(url: "https://example.com/large.mp4", width: 1920, height: 1080, quality: "1080p", codec: "H264", filesize: nil, fps: 30, mimeType: "video/mp4"),
            VideoVariant(url: "https://example.com/small.mp4", width: 640, height: 360, quality: "360p", codec: "H264", filesize: nil, fps: 30, mimeType: "video/mp4"),
        ]
        
        return VideoMetadata(
            videoId: "123456",
            title: "Test Video",
            description: "A test video",
            uploader: "Test User",
            uploaderId: "user123",
            uploaderUrl: "https://vimeo.com/user123",
            duration: duration,
            width: 1920,
            height: 1080,
            license: nil,
            language: "en",
            viewCount: viewCount,
            likeCount: likeCount,
            commentCount: commentCount,
            createdAt: createdAt,
            releasedAt: nil,
            thumbnails: [
                ThumbnailInfo(url: "https://i.vimeocdn.com/video/large.jpg", width: 1920, height: 1080),
                ThumbnailInfo(url: "https://i.vimeocdn.com/video/small.jpg", width: 640, height: 360),
            ],
            variants: defaultVariants,
            captionTracks: captionTracks,
            transcript: transcript,
            transcriptLanguage: transcript.isEmpty ? nil : "en"
        )
    }
    
}
