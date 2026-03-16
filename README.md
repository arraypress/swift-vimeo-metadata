# Swift Vimeo Metadata

A Swift library for fetching metadata, video download URLs, and transcripts from Vimeo videos. No API key, developer account, or user authentication required — uses Vimeo's OAuth client credentials (same approach as yt-dlp).

## Features

- 🎯 **Simple API** — fetch video metadata with a single async call
- 📊 **Rich metadata** — title, description, uploader, duration, views, likes, comments, license
- 🎬 **Direct MP4 URLs** — progressive download URLs at multiple qualities (360p–4K)
- 📝 **Transcripts** — fetch and parse WebVTT captions into timestamped segments
- 🌍 **Multi-language captions** — request specific languages with automatic fallback
- 🖼️ **Thumbnails** — multiple sizes sorted by resolution
- 🔒 **No API key required** — uses public OAuth client credentials
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS
- ⚡ **Async/await** native — built for modern Swift concurrency
- 🛡️ **Typed error handling** — specific errors for every failure case
- 🔗 **Flexible input** — supports all Vimeo URL formats and raw video IDs

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-vimeo-metadata.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Choose version requirements

## Usage

### Fetch Video Metadata

```swift
import VimeoMetadata

let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")

print(video.title)
print("\(video.uploader ?? "Unknown") — \(video.formattedDuration)")
print("Views: \(video.formattedViewCount ?? "N/A")")
print("Likes: \(video.formattedLikeCount ?? "N/A")")
print("Comments: \(video.formattedCommentCount ?? "N/A")")
print("Date: \(video.formattedDate ?? "N/A")")
```

### Video Download URLs

Direct MP4 download URLs at multiple quality levels — no HLS parsing needed.

```swift
let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")

// Best quality MP4
if let url = video.bestDownloadUrl {
    print("Download: \(url)")
}

// All available qualities
for variant in video.variants {
    print("\(variant.quality ?? "?") — \(variant.width)x\(variant.height)")
    if let size = variant.filesize {
        print("  Size: \(size / 1_000_000)MB")
    }
    print("  URL: \(variant.url)")
}
```

### Transcripts

Captions are fetched and parsed automatically when available.

```swift
let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")

// Plain text transcript
if !video.transcript.isEmpty {
    print(video.plainText)
}

// Timestamped
print(video.timestampedText)

// Individual segments
for segment in video.transcript {
    print("[\(segment.formattedStart)] \(segment.text)")
}
```

### List Available Captions

```swift
let captions = try await VimeoMetadata.listCaptions("https://vimeo.com/123456789")

for track in captions.tracks {
    print("\(track.displayLanguage ?? track.language) — \(track.type ?? "unknown")")
}
```

### Specify Language Preferences

```swift
// Prefer German, fall back to English
let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789", languages: ["de", "en"])
print("Transcript language: \(video.transcriptLanguage ?? "none")")
```

### Skip Transcript Fetching

If you only need metadata and video URLs, skip the transcript to save a network request.

```swift
let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789", fetchTranscript: false)
// video.transcript will be empty, but metadata and variants are populated
```

### URL Formats

All common Vimeo URL formats are supported:

```swift
let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")
let video = try await VimeoMetadata.fetch("https://vimeo.com/video/123456789")
let video = try await VimeoMetadata.fetch("https://player.vimeo.com/video/123456789")
let video = try await VimeoMetadata.fetch("https://vimeo.com/channels/staffpicks/123456789")
let video = try await VimeoMetadata.fetch("https://vimeo.com/groups/name/videos/123456789")
let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789/abcdef1234") // unlisted
let video = try await VimeoMetadata.fetch("123456789") // raw ID
```

### Error Handling

```swift
do {
    let video = try await VimeoMetadata.fetch(url)
    print(video.title)
} catch VimeoMetadataError.videoNotFound {
    print("Video doesn't exist or is private")
} catch VimeoMetadataError.passwordRequired {
    print("Video requires a password")
} catch VimeoMetadataError.rateLimited {
    print("Too many requests — try again later")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

## Models

### `VideoMetadata`

The main result struct containing all video data.

| Property | Type | Description |
|----------|------|-------------|
| `videoId` | `String` | Vimeo video ID |
| `title` | `String` | Video title |
| `description` | `String?` | Video description |
| `uploader` | `String?` | Creator's display name |
| `uploaderId` | `String?` | Creator's user ID |
| `uploaderUrl` | `String?` | Creator's profile URL |
| `duration` | `Int` | Duration in seconds |
| `formattedDuration` | `String` | Duration as `"M:SS"` or `"H:MM:SS"` |
| `width` | `Int?` | Video width in pixels |
| `height` | `Int?` | Video height in pixels |
| `license` | `String?` | Content license |
| `language` | `String?` | Video language code |
| `viewCount` | `Int?` | Number of plays |
| `formattedViewCount` | `String?` | Plays with grouping separators |
| `likeCount` | `Int?` | Number of likes |
| `commentCount` | `Int?` | Number of comments |
| `createdAt` | `Date?` | Upload date |
| `releasedAt` | `Date?` | Release date |
| `thumbnails` | `[ThumbnailInfo]` | Thumbnails sorted by size (largest first) |
| `thumbnailUrl` | `String?` | Best thumbnail URL |
| `variants` | `[VideoVariant]` | MP4 download URLs at multiple qualities |
| `bestDownloadUrl` | `URL?` | Highest-quality direct MP4 URL |
| `captionTracks` | `[CaptionTrack]` | Available caption tracks |
| `transcript` | `[TranscriptSegment]` | Parsed transcript segments |
| `transcriptLanguage` | `String?` | Language of the fetched transcript |
| `plainText` | `String` | All transcript text joined |
| `timestampedText` | `String` | Transcript with `[M:SS]` timestamps |
| `url` | `String` | Full Vimeo video URL |

### `VideoVariant`

A single video quality variant with direct MP4 download URL.

| Property | Type | Description |
|----------|------|-------------|
| `url` | `String` | Direct MP4 download URL |
| `width` | `Int` | Width in pixels |
| `height` | `Int` | Height in pixels |
| `quality` | `String?` | Quality label (e.g., `"1080p"`) |
| `codec` | `String?` | Video codec |
| `filesize` | `Int?` | File size in bytes |
| `fps` | `Int?` | Frames per second |
| `downloadUrl` | `URL?` | Typed download URL |

### `CaptionTrack`

An available caption/subtitle track.

| Property | Type | Description |
|----------|------|-------------|
| `language` | `String` | Language code |
| `displayLanguage` | `String?` | Human-readable language name |
| `type` | `String?` | Track type (e.g., `"captions"`) |
| `isActive` | `Bool` | Whether this is the default track |

### `TranscriptSegment`

A single timed segment from a caption track.

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | The text content |
| `start` | `Double` | Start time in seconds |
| `duration` | `Double` | Display duration in seconds |
| `end` | `Double` | End time |
| `language` | `String` | Language code |
| `formattedStart` | `String` | Start time as `"M:SS"` |

## How It Works

The library makes up to four HTTP requests:

1. **OAuth token** — POST to `api.vimeo.com/oauth/authorize/client` with macOS client credentials. Returns a bearer token. Cached in memory for subsequent requests.
2. **Video data** — GET `api.vimeo.com/videos/{id}` with the bearer token. Returns title, description, duration, uploader, thumbnails, engagement counts, and `play.progressive` array with direct MP4 URLs.
3. **Text tracks** — GET `api.vimeo.com/videos/{id}/texttracks?include_transcript=true`. Returns VTT caption URLs by language. Skipped if `fetchTranscript: false`.
4. **VTT file** — GET the best matching caption URL. Parses into timed segments. Skipped if no captions match the requested languages.

For subsequent requests, only steps 2–4 are needed (token is cached).

## Limitations

- **Password-protected videos** — Not supported. The `passwordRequired` error is thrown.
- **Private/embed-only videos** — Not accessible without user authentication.
- **Rate limiting** — Vimeo may rate-limit requests. The OAuth token helps, but excessive requests will still be throttled.
- **API stability** — Uses Vimeo's official API with client credentials from their macOS app. More stable than scraping, but client credentials may be rotated.

## Testing

```bash
swift test
```

The test suite includes unit tests for video ID extraction, VTT parsing, timestamp formatting, caption track selection, and computed properties, plus integration tests that hit Vimeo's live API.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License — see LICENSE file for details.

## Author

Created by David Sherlock ([ArrayPress](https://github.com/arraypress)) in 2026.
