# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BuckarooBanzai is a Swift networking library designed as a lightweight, service-oriented HTTP client. It provides a protocol-based approach for making network requests with support for async/await, Combine publishers, and comprehensive testing capabilities.

## Development Commands

### Building and Testing
- **Build**: Use Xcode or `swift build` (Swift Package Manager)
- **Test**: Use Xcode Test Navigator or `swift test`
- **CocoaPods**: `pod install` and `pod lib lint BuckarooBanzai.podspec`

### Package Management
This project supports both Swift Package Manager and CocoaPods:
- Swift Package Manager: `Package.swift` (iOS 15.0+, Swift 5.9+)
- CocoaPods: `BuckarooBanzai.podspec` (iOS 15.0+, Swift 5.0+)

## Architecture

### Core Components

**BuckarooBanzai** (`BuckarooBanzai.swift`): Main singleton class that handles all network operations
- Uses a dedicated `OperationQueue` for network calls (max 4 concurrent operations)
- Provides async/await methods and Combine publishers
- Handles request validation, serialization, and response processing

**Service Protocol** (`Protocols/Service.swift`): Defines the contract for network service configurations
- Encapsulates all request parameters (URL, method, headers, body, etc.)
- Supports test responses for offline testing
- Extensible through custom serializers and session delegates

**HTTPResponse** (`Data Structs/HTTPResponse.swift`): Response container with convenience methods
- Contains status code, headers, and body data
- Provides JSON decoding and image conversion utilities
- Extended with additional parsing methods in `HTTPResponse+ext.swift`

### Supporting Types

**Enumerations** (`Enumerations/`):
- `HTTPRequestMethod`: HTTP verbs including custom methods
- `HTTPAcceptType`: Content types for Accept headers
- `HTTPContentType`: Content types for request bodies
- `BBError`: Library-specific error types with contextual information

**Serializers** (`Serializers/`):
- `JSONRequestSerializer`: Converts parameters to JSON
- `FormRequestSerializer`: Converts parameters to URL-encoded form data
- `RequestSerializer` protocol for custom serialization

### Key Patterns

1. **Service-Oriented Design**: Each API call is encapsulated in a struct/class conforming to `Service`
2. **Protocol-Based Configuration**: Services define their requirements through protocol properties
3. **Async/Await First**: Primary API uses Swift's async/await with Combine support as alternative
4. **Comprehensive Error Handling**: Custom error types with HTTP response context
5. **Test-Friendly**: Services can provide mock responses for offline testing

## Testing

Tests are located in `BuckarooBanzaiTests/` and cover:
- JSON and Form serialization
- Response decoding (JSON, Images)
- Service execution with test responses
- Error handling scenarios

Use XCTest framework with `@testable import BuckarooBanzai` for testing.

## Usage Pattern

1. Create a service conforming to `Service` protocol
2. Configure request parameters (URL, method, headers, etc.)
3. Call `BuckarooBanzai.shared.start(service:)` with async/await
4. Handle `HTTPResponse` or decode directly to models
5. Use test responses for offline development/testing