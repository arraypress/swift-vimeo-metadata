//
//  VimeoMetadataError.swift
//  VimeoMetadata
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Errors that can occur when fetching Vimeo video metadata.
///
/// ```swift
/// do {
///     let video = try await VimeoMetadata.fetch(url)
/// } catch VimeoMetadataError.videoNotFound {
///     print("Video doesn't exist or is private")
/// } catch VimeoMetadataError.rateLimited {
///     print("Too many requests — try again later")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum VimeoMetadataError: Error, LocalizedError, Equatable, Sendable {
    
    /// The provided URL is not a valid Vimeo video URL.
    case invalidUrl
    
    /// Could not extract a video ID from the URL.
    case invalidVideoId
    
    /// The video was not found (deleted, private, or unavailable).
    case videoNotFound
    
    /// The video requires a password to access.
    ///
    /// Pass the password via the `password` parameter:
    /// ```swift
    /// let video = try await VimeoMetadata.fetch(url, password: "secret")
    /// ```
    case passwordRequired
    
    /// The provided password was incorrect.
    case wrongPassword
    
    /// Vimeo is rate-limiting requests from this IP.
    case rateLimited
    
    /// Failed to obtain an OAuth token from Vimeo's API.
    case tokenFailed
    
    /// No captions/subtitles are available for this video.
    case noCaptions
    
    /// No caption was found matching the requested languages.
    case noCaptionForLanguage(requested: [String], available: [String])
    
    /// A network request failed.
    case networkError(String)
    
    /// Failed to parse response data.
    case parsingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid Vimeo URL. Provide a URL like https://vimeo.com/123456789"
        case .invalidVideoId:
            return "Could not extract a video ID from the URL."
        case .videoNotFound:
            return "Video not found. It may have been deleted or set to private."
        case .passwordRequired:
            return "This video requires a password to access. Pass it via the password parameter."
        case .wrongPassword:
            return "The provided password was incorrect."
        case .rateLimited:
            return "Vimeo is rate-limiting requests. Try again later."
        case .tokenFailed:
            return "Failed to obtain an OAuth token from Vimeo."
        case .noCaptions:
            return "No captions available for this video."
        case .noCaptionForLanguage(let requested, let available):
            return "No caption found for \(requested.joined(separator: ", ")). Available: \(available.joined(separator: ", "))"
        case .networkError(let message):
            return "Network error: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
    
}
