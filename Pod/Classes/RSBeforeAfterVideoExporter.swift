//
//  RSBeforeAfterVideoExporter.swift
//
//  Created by Ric Santos on 13/5/2025.
//

import UIKit
import AVFoundation
import CoreGraphics

public enum EasingFunction {
    case linear
    case easeInOut
    case easeIn
    case easeOut
    case easeInBack
    case easeOutBack
    case easeInOutBack
    
    func apply(to t: CGFloat) -> CGFloat {
        let clampedT = max(0.0, min(1.0, t))
        
        switch self {
        case .linear:
            return clampedT
        case .easeInOut:
            return clampedT < 0.5 
                ? 2.0 * clampedT * clampedT 
                : 1.0 - pow(-2.0 * clampedT + 2.0, 3.0) / 2.0
        case .easeIn:
            return clampedT * clampedT
        case .easeOut:
            return 1.0 - (1.0 - clampedT) * (1.0 - clampedT)
        case .easeInBack:
            let c1: CGFloat = 1.70158
            let c3: CGFloat = c1 + 1.0
            return c3 * clampedT * clampedT * clampedT - c1 * clampedT * clampedT
        case .easeOutBack:
            let c1: CGFloat = 1.70158
            let c3: CGFloat = c1 + 1.0
            return 1.0 + c3 * pow(clampedT - 1.0, 3.0) + c1 * pow(clampedT - 1.0, 2.0)
        case .easeInOutBack:
            let c1: CGFloat = 1.70158
            let c2: CGFloat = c1 * 1.525
            return clampedT < 0.5
                ? (pow(2.0 * clampedT, 2.0) * ((c2 + 1.0) * 2.0 * clampedT - c2)) / 2.0
                : (pow(2.0 * clampedT - 2.0, 2.0) * ((c2 + 1.0) * (clampedT * 2.0 - 2.0) + c2) + 2.0) / 2.0
        }
    }
}

public enum ExportMode {
    case plain   // Match input image aspect ratio, no background
    case social  // 9:16 canvas with RSBeforeAfterImageView centered
}

public struct VideoExportSegment {
    public let position: CGFloat
    public let duration: TimeInterval
    public let easing: EasingFunction
    
    public init(position: CGFloat, duration: TimeInterval, easing: EasingFunction = .easeInOut) {
        self.position = max(0.0, min(1.0, position))
        self.duration = duration
        self.easing = easing
    }
}

public class RSBeforeAfterVideoExporter {
    
    public enum ExportError: Error {
        case invalidImages
        case invalidSegments
        case writerSetupFailed
        case exportFailed(String)
    }
    
    private let frameRate: Int32 = 30
    
    public init() {
        // No longer need to store videoSize as it's calculated per export
    }
    
    public func exportVideo(
        beforeImage: UIImage,
        afterImage: UIImage,
        mode: ExportMode,
        startingPosition: CGFloat = 0.0,
        segments: [VideoExportSegment],
        outputURL: URL,
        completion: @escaping (Result<URL, ExportError>) -> Void
    ) {
        guard !segments.isEmpty else {
            completion(.failure(.invalidSegments))
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let url = try self.generateVideo(
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    mode: mode,
                    startingPosition: startingPosition,
                    segments: segments,
                    outputURL: outputURL
                )
                DispatchQueue.main.async {
                    completion(.success(url))
                }
            } catch let error as ExportError {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.exportFailed(error.localizedDescription)))
                }
            }
        }
    }
    
    private func generateVideo(
        beforeImage: UIImage,
        afterImage: UIImage,
        mode: ExportMode,
        startingPosition: CGFloat,
        segments: [VideoExportSegment],
        outputURL: URL
    ) throws -> URL {
        
        // Calculate video size based on mode and input images
        let videoSize = calculateVideoSize(for: mode, inputImage: beforeImage)
        
        // Remove existing file if it exists
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }
        
        // Setup video writer
        let videoWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: videoSize.width,
            AVVideoHeightKey: videoSize.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 2000000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264BaselineAutoLevel
            ]
        ]
        
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let pixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: videoSize.width,
            kCVPixelBufferHeightKey as String: videoSize.height
        ]
        
        let pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: pixelBufferAttributes
        )
        
        guard videoWriter.canAdd(videoWriterInput) else {
            throw ExportError.writerSetupFailed
        }
        
        videoWriter.add(videoWriterInput)
        
        // Start writing
        guard videoWriter.startWriting() else {
            throw ExportError.writerSetupFailed
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        // Create offscreen view for rendering
        let offscreenView = createOffscreenView(
            beforeImage: beforeImage, 
            afterImage: afterImage, 
            mode: mode, 
            videoSize: videoSize
        )
        
        // Generate frames
        try generateFrames(
            offscreenView: offscreenView,
            startingPosition: startingPosition,
            segments: segments,
            pixelBufferAdaptor: pixelBufferAdaptor,
            videoWriterInput: videoWriterInput
        )
        
        // Finish writing
        videoWriterInput.markAsFinished()
        
        let semaphore = DispatchSemaphore(value: 0)
        var finalError: Error?
        
        videoWriter.finishWriting {
            if videoWriter.status == .failed {
                finalError = videoWriter.error ?? ExportError.exportFailed("Unknown error")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        if let error = finalError {
            throw ExportError.exportFailed(error.localizedDescription)
        }
        
        return outputURL
    }
    
    private func calculateVideoSize(for mode: ExportMode, inputImage: UIImage) -> CGSize {
        switch mode {
        case .plain:
            // Match input image aspect ratio
            let inputSize = inputImage.size
            let aspectRatio = inputSize.width / inputSize.height
            
            // Target 720p-ish resolution, maintaining aspect ratio
            let targetWidth: CGFloat = 720
            let calculatedHeight = targetWidth / aspectRatio
            
            return CGSize(width: targetWidth, height: calculatedHeight)
            
        case .social:
            // Fixed 9:16 aspect ratio for social media (1080x1920)
            return CGSize(width: 1080, height: 1920)
        }
    }
    
    private func createOffscreenView(
        beforeImage: UIImage, 
        afterImage: UIImage, 
        mode: ExportMode, 
        videoSize: CGSize
    ) -> UIView {
        
        switch mode {
        case .plain:
            // Direct RSBeforeAfterImageView, full frame
            return createPlainOffscreenView(
                beforeImage: beforeImage, 
                afterImage: afterImage, 
                size: videoSize
            )
            
        case .social:
            // Container view with orange background and centered RSBeforeAfterImageView
            return createSocialOffscreenView(
                beforeImage: beforeImage, 
                afterImage: afterImage, 
                canvasSize: videoSize
            )
        }
    }
    
    private func createPlainOffscreenView(
        beforeImage: UIImage, 
        afterImage: UIImage, 
        size: CGSize
    ) -> RSBeforeAfterImageView {
        // Create view on main thread to establish proper view hierarchy
        return DispatchQueue.main.sync {
            let view = RSBeforeAfterImageView(frame: CGRect(origin: .zero, size: size))
            view.configure(before: beforeImage, after: afterImage)
            
            // Force initial layout on main thread
            view.setNeedsLayout()
            view.layoutIfNeeded()
            
            return view
        }
    }
    
    private func createSocialOffscreenView(
        beforeImage: UIImage, 
        afterImage: UIImage, 
        canvasSize: CGSize
    ) -> UIView {
        // Create view hierarchy on main thread
        return DispatchQueue.main.sync {
            // Create container view with orange background
            let containerView = UIView(frame: CGRect(origin: .zero, size: canvasSize))
            containerView.backgroundColor = UIColor.systemOrange
            
            // Calculate RSBeforeAfterImageView size and position
            let inputAspectRatio = beforeImage.size.width / beforeImage.size.height
            let maxWidth = canvasSize.width * 0.8 // 80% of canvas width
            let maxHeight = canvasSize.height * 0.6 // 60% of canvas height
            
            let viewWidth: CGFloat
            let viewHeight: CGFloat
            
            // Scale to fit within max bounds while preserving aspect ratio
            let widthBasedHeight = maxWidth / inputAspectRatio
            let heightBasedWidth = maxHeight * inputAspectRatio
            
            if widthBasedHeight <= maxHeight {
                viewWidth = maxWidth
                viewHeight = widthBasedHeight
            } else {
                viewWidth = heightBasedWidth
                viewHeight = maxHeight
            }
            
            // Center the RSBeforeAfterImageView in the canvas
            let x = (canvasSize.width - viewWidth) / 2
            let y = (canvasSize.height - viewHeight) / 2
            
            let beforeAfterView = RSBeforeAfterImageView(frame: CGRect(
                x: x, y: y, width: viewWidth, height: viewHeight
            ))
            beforeAfterView.configure(before: beforeImage, after: afterImage)
            
            containerView.addSubview(beforeAfterView)
            
            // Force initial layout on main thread
            containerView.setNeedsLayout()
            containerView.layoutIfNeeded()
            beforeAfterView.setNeedsLayout()
            beforeAfterView.layoutIfNeeded()
            
            return containerView
        }
    }
    
    private func generateFrames(
        offscreenView: UIView,
        startingPosition: CGFloat,
        segments: [VideoExportSegment],
        pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor,
        videoWriterInput: AVAssetWriterInput
    ) throws {
        
        // Find the RSBeforeAfterImageView within the offscreen view (UI traversal must be on main thread)
        let beforeAfterView: RSBeforeAfterImageView? = DispatchQueue.main.sync {
            return findBeforeAfterImageView(in: offscreenView)
        }
        guard let beforeAfterView = beforeAfterView else {
            throw ExportError.exportFailed("Could not find RSBeforeAfterImageView in offscreen view")
        }
        
        var currentTime: CMTime = .zero
        var currentPosition = startingPosition
        
        // Set initial position on main thread
        DispatchQueue.main.sync {
            beforeAfterView.setDividerPosition(currentPosition, animated: false)
        }
        
        for segment in segments {
            let segmentFrameCount = Int(segment.duration * Double(frameRate))
            let frameDuration = CMTime(value: 1, timescale: frameRate)
            
            let startPos = currentPosition
            let endPos = segment.position
            let positionDelta = endPos - startPos
            
            for frameIndex in 0..<segmentFrameCount {
                // Wait for writer to be ready
                while !videoWriterInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.01)
                }
                
                // Calculate normalized time for this frame (0.0 to 1.0)
                let normalizedTime = CGFloat(frameIndex) / CGFloat(segmentFrameCount)
                
                // Apply easing function to get smooth interpolation
                let easedTime = segment.easing.apply(to: normalizedTime)
                
                // Calculate current position using eased interpolation
                let framePosition = startPos + (positionDelta * easedTime)
                
                // Batch update position and render on main thread
                // This is unavoidable for UIKit, but we minimize the work done
                let pixelBuffer: CVPixelBuffer? = DispatchQueue.main.sync {
                    // Update position and immediately render - no separate layout calls
                    beforeAfterView.setDividerPosition(framePosition, animated: false)
                    
                    // Render frame immediately without forcing layout (should auto-update)
                    return createPixelBuffer(from: offscreenView, 
                                           pixelBufferPool: pixelBufferAdaptor.pixelBufferPool)
                }
                
                guard let buffer = pixelBuffer else {
                    throw ExportError.exportFailed("Failed to create pixel buffer")
                }
                
                // Append frame
                let success = pixelBufferAdaptor.append(buffer, withPresentationTime: currentTime)
                if !success {
                    throw ExportError.exportFailed("Failed to append frame at time \(currentTime)")
                }
                
                currentTime = CMTimeAdd(currentTime, frameDuration)
            }
            
            currentPosition = segment.position
        }
    }
    
    private func findBeforeAfterImageView(in view: UIView) -> RSBeforeAfterImageView? {
        if let beforeAfterView = view as? RSBeforeAfterImageView {
            return beforeAfterView
        }
        
        for subview in view.subviews {
            if let found = findBeforeAfterImageView(in: subview) {
                return found
            }
        }
        
        return nil
    }
    
    private func createPixelBuffer(from view: UIView, 
                                 pixelBufferPool: CVPixelBufferPool?) -> CVPixelBuffer? {
        
        guard let pool = pixelBufferPool else {
            return nil
        }
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let context = CGContext(
            data: pixelData,
            width: Int(view.bounds.width),
            height: Int(view.bounds.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        )
        
        guard let cgContext = context else {
            CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
            return nil
        }
        
        // Flip coordinate system to match UIView
        cgContext.translateBy(x: 0, y: view.bounds.height)
        cgContext.scaleBy(x: 1.0, y: -1.0)
        
        // Render view to context
        view.layer.render(in: cgContext)
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}
