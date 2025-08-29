# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

RSBeforeAfterImageView is an iOS CocoaPod library that provides an interactive before/after image comparison view. Users can slide a divider to reveal different portions of two overlaid images, creating a smooth comparison experience.

## Architecture

- **Main Component**: `RSBeforeAfterImageView` class in `Pod/Classes/RSBeforeAfterImageView.swift`
  - Uses Core Animation layers for smooth masking and animations
  - Two `UIImageView` instances (bottom and top) with a sliding mask
  - Custom grab handle with configurable appearance and blur effects
  - Touch handling via `UIPanGestureRecognizer` for interactive sliding

- **Key View Hierarchy**:
  - `bottomImageView`: The "before" image (visible when divider is left)
  - `topImageView`: The "after" image (masked, visible when divider is right)  
  - `dividerView`: Visual separator line with shadow
  - `touchAreaView`: Larger touch target containing the grab handle
  - `grabHandle`: Customizable draggable element with optional icon

## Development Commands

### Building and Testing
```bash
# Install dependencies
cd Example
pod install

# Open workspace (required for development)
open RSBeforeAfterImageView.xcworkspace

# Build and run example app
# Use Xcode to build target 'RSBeforeAfterImageView_Example'

# Run tests  
# Use Xcode to run target 'RSBeforeAfterImageView_Tests'
```

### CocoaPods Development
```bash
# Validate podspec
pod lib lint RSBeforeAfterImageView.podspec

# Push to CocoaPods trunk (when ready for release)
pod trunk push RSBeforeAfterImageView.podspec
```

## Project Structure

- `Pod/Classes/`: Main library source code
- `Example/`: Demo application and workspace
- `Example/RSBeforeAfterImageView/`: Example implementation showing usage patterns
- `RSBeforeAfterImageView.podspec`: CocoaPods specification

## Key Implementation Details

- **Masking System**: Uses `CAShapeLayer` with animated path changes for smooth transitions
- **Touch Handling**: 64x80pt touch area centered on divider for better UX
- **Animation Support**: Programmatic position changes with customizable duration and easing
- **Customization**: Extensive grab handle customization (size, colors, blur effects, icons)
- **Layout**: Auto-layout compatible with proper constraint handling

## Dependencies

- **Production**: None (pure UIKit)
- **Example App**: SnapKit for layout constraints
- **Platform**: iOS 14.0+, Swift 5.0+

## Testing

Tests are located in `Example/Tests/` and run through the Xcode workspace. The main test target is `RSBeforeAfterImageView_Tests`.