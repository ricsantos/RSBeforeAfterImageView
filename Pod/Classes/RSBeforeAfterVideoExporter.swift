//
//  RSBeforeAfterVideoExporter.swift
//
//  Created by Ric Santos on 13/5/2025.
//

import UIKit
import AVFoundation
import CoreGraphics

public struct VideoExportSegment {
    public let position: CGFloat
    public let duration: TimeInterval
    
    public init(position: CGFloat, duration: TimeInterval) {
        self.position = max(0.0, min(1.0, position))
        self.duration = duration
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
    private let videoSize: CGSize
    
    public init(videoSize: CGSize = CGSize(width: 1080, height: 1080)) {
        self.videoSize = videoSize
    }
    
    public func exportVideo(
        beforeImage: UIImage,
        afterImage: UIImage,
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
        startingPosition: CGFloat,
        segments: [VideoExportSegment],
        outputURL: URL
    ) throws -> URL {
        
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
        let offscreenView = createOffscreenView(beforeImage: beforeImage, afterImage: afterImage)
        
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
    
    private func createOffscreenView(beforeImage: UIImage, afterImage: UIImage) -> RSBeforeAfterImageView {
        let view = RSBeforeAfterImageView(frame: CGRect(origin: .zero, size: videoSize))
        view.configure(before: beforeImage, after: afterImage)
        
        // Force layout
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        return view
    }
    
    private func generateFrames(
        offscreenView: RSBeforeAfterImageView,
        startingPosition: CGFloat,
        segments: [VideoExportSegment],
        pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor,
        videoWriterInput: AVAssetWriterInput
    ) throws {
        
        var currentTime: CMTime = .zero
        var currentPosition = startingPosition
        
        // Set initial position
        offscreenView.setDividerPosition(currentPosition, animated: false)
        
        for segment in segments {
            let segmentFrameCount = Int(segment.duration * Double(frameRate))
            let frameDuration = CMTime(value: 1, timescale: frameRate)
            
            let startPos = currentPosition
            let endPos = segment.position
            let positionDelta = (endPos - startPos) / CGFloat(segmentFrameCount)
            
            for frameIndex in 0..<segmentFrameCount {
                // Wait for writer to be ready
                while !videoWriterInput.isReadyForMoreMediaData {
                    Thread.sleep(forTimeInterval: 0.01)
                }
                
                // Calculate current position for this frame
                let framePosition = startPos + (positionDelta * CGFloat(frameIndex))
                
                // Update view position (without animation for offscreen rendering)
                offscreenView.setDividerPosition(framePosition, animated: false)
                
                // Force layout update
                offscreenView.setNeedsLayout()
                offscreenView.layoutIfNeeded()
                
                // Render frame to pixel buffer
                guard let pixelBuffer = createPixelBuffer(from: offscreenView, 
                                                        pixelBufferPool: pixelBufferAdaptor.pixelBufferPool) else {
                    throw ExportError.exportFailed("Failed to create pixel buffer")
                }
                
                // Append frame
                let success = pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: currentTime)
                if !success {
                    throw ExportError.exportFailed("Failed to append frame at time \(currentTime)")
                }
                
                currentTime = CMTimeAdd(currentTime, frameDuration)
            }
            
            currentPosition = segment.position
        }
    }
    
    private func createPixelBuffer(from view: RSBeforeAfterImageView, 
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
            width: Int(videoSize.width),
            height: Int(videoSize.height),
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
        cgContext.translateBy(x: 0, y: videoSize.height)
        cgContext.scaleBy(x: 1.0, y: -1.0)
        
        // Render view to context
        view.layer.render(in: cgContext)
        
        CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        
        return buffer
    }
}
