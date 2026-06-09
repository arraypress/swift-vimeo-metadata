# Swift Vimeo Metadata

A Swift library for fetching metadata, direct video download URLs, and transcripts from Vimeo videos. It uses Vimeo's OAuth client credentials (the same public macOS-client approach as yt-dlp), so no API key, developer account, or user login is required. Returns video details, uploader info, engagement counts, progressive MP4 URLs at multiple qualities, caption tracks, and parsed transcript segments.

## Features

- 🎯 **No authentication** — fetches via Vimeo's macOS client credentials; no API key, OAuth app, or user login
- 📥 **Direct MP4 URLs** — progressive download variants at multiple resolutions, sorted highest first, with `bestDownloadUrl`
- 📝 **Transcripts** — fetches and parses WebVTT captions into timed `TranscriptSegment` values
- 🌍 **Language preference** — request transcripts/captions by language with exact and prefix matching (`en` matches `en-US`)
- 🗒️ **Caption listing** — `listCaptions` enumerates available tracks without downloading content
- 🔒 **Password-protected videos** — submits the password via Vimeo's XSRF flow and retries automatically
- 🔗 **Flexible input** — accepts full URLs, `player.vimeo.com` links, channel/group/showcase URLs, unlisted-hash URLs, or raw numeric IDs
- 📊 **Rich metadata** — title, description, uploader, duration, dimensions, license, language, views, likes, comments, dates, thumbnails
- 🖼️ **Thumbnails** — all sizes sorted largest first, plus a convenience `thumbnailUrl`
- 🧾 **Formatted helpers** — `formattedDuration`, `formattedViewCount`, `plainText`, `timestampedText`, and more
- 🔁 **Token caching** — the OAuth token is cached in-process across requests
- 🍎 **Foundation only** — no third-party dependencies; Linux-compatible via `FoundationNetworking`

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-vimeo-metadata.git", from: "1.0.0")
]
```

## Usage

### Quick start

```swift
import VimeoMetadata

let video = try await VimeoMetadata.fetch("https://vimeo.com/123456789")

print(video.title)
print(video.uploader ?? "Unknown")
print("Duration: \(video.formattedDuration)")

// Best quality MP4 download
if let url = video.bestDownloadUrl {
    print("Download: \(url)")
}

// Transcript (if captions available)
if !video.transcript.isEmpty {
    print(video.plainText)
}

// All quality variants
for variant in video.variants {
    print("\(variant.quality ?? "?") — \(variant.width)x\(variant.height)")
}
```

### Without a transcript

```swift
import VimeoMetadata

let video = try await VimeoMetadata.fetch(
    "https://vimeo.com/123456789",
    fetchTranscript: false
)
```

### Preferred transcript languages

```swift
import VimeoMetadata

let video = try await VimeoMetadata.fetch(
    "https://vimeo.com/123456789",
    languages: ["de", "en"]
)
print(video.transcriptLanguage ?? "none")
print(video.timestampedText)
```

### Password-protected videos

```swift
import VimeoMetadata

let course = try await VimeoMetadata.fetch(
    "https://vimeo.com/68375962",
    password: "secret"
)
```

### Listing captions

```swift
import VimeoMetadata

let captions = try await VimeoMetadata.listCaptions("https://vimeo.com/123456789")
print("Available: \(captions.availableLanguages)")

if let track = captions.findTrack(languages: ["en"]) {
    print(track.displayLanguage ?? track.language)
}
```

### Handling errors

```swift
import VimeoMetadata

do {
    let video = try await VimeoMetadata.fetch(url)
} catch VimeoMetadataError.videoNotFound {
    print("Video doesn't exist or is private")
} catch VimeoMetadataError.passwordRequired {
    print("This video needs a password")
} catch VimeoMetadataError.rateLimited {
    print("Too many requests — try again later")
}
```

## How It Works

1. **Extract the video ID** (and optional unlisted hash) from the input URL or raw ID.
2. **Obtain an OAuth token** by POSTing the macOS client's Basic credentials to `api.vimeo.com/oauth/authorize/client` with the `client_credentials` grant. The token is cached in-process.
3. **Fetch video data** from `api.vimeo.com/videos/{id}` (with a specific `fields` list to minimise payload). A `400` indicating a password requirement triggers the XSRF password flow and a retry.
4. **Fetch text tracks** from the `/texttracks` endpoint with `include_transcript=true`.
5. **Fetch and parse VTT** — the best-matching caption file is downloaded and parsed into timed segments.

Download variants are collected from the `play.progressive`, `download`, and `files` arrays (skipping HLS/DASH adaptive entries) and sorted by resolution.

## Models

| Type | Description |
|------|-------------|
| `VideoMetadata` | Full result: IDs, title, description, uploader, duration, dimensions, license, engagement counts, dates, thumbnails, variants, caption tracks, transcript, plus formatted helpers |
| `VideoVariant` | A progressive MP4: url, width, height, quality, codec, filesize, fps, mimeType, and typed `downloadUrl` |
| `ThumbnailInfo` | A thumbnail url with width and height |
| `CaptionTrack` | An available caption track: language, displayLanguage, type, name, isActive |
| `CaptionList` | Available tracks with `availableLanguages` and `findTrack(languages:)` |
| `TranscriptSegment` | A timed transcript segment: text, start, duration, language, with `end` and `formattedStart` |
| `VideoID` | Static helpers to `extract` an ID and `extractUnlistedHash` from a URL |
| `VimeoMetadataError` | Typed errors: `invalidUrl`, `invalidVideoId`, `videoNotFound`, `passwordRequired`, `wrongPassword`, `rateLimited`, `tokenFailed`, `noCaptions`, `noCaptionForLanguage`, `networkError`, `parsingError` |

## Use Cases

- Building Vimeo download or archival tools
- Generating transcripts and searchable text from Vimeo videos
- Displaying rich video metadata in an app
- Accessing password-protected course videos programmatically

## Testing

```bash
swift test
```

The test suite covers video ID extraction, VTT parsing, caption matching, and metadata model behaviour.

## License

MIT License — see LICENSE file for details.

## Author

Created by David Sherlock ([ArrayPress](https://github.com/arraypress)) in 2026.
