//
//  ExampleViewController.swift
//  RSBeforeAfterImageView
//
//  Created by Ric Santos on 06/17/2025.
//  Copyright (c) 2025 Ric Santos. All rights reserved.
//

import UIKit
import RSBeforeAfterImageView
import SnapKit
import AVKit

class ExampleViewController: UIViewController {
    var beforeAfterImageView: RSBeforeAfterImageView!
    var exportButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Before After"
        
        self.view.backgroundColor = UIColor.systemBackground
        
        let topSpacer = UIView()
        self.view.addSubview(topSpacer)
        topSpacer.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            make.height.greaterThanOrEqualTo(8)
        }
        
        let imageAspectRatio = Double(1024)/Double(1536)
        self.beforeAfterImageView = RSBeforeAfterImageView()
        self.beforeAfterImageView.backgroundColor = UIColor.secondarySystemBackground
        self.view.addSubview(self.beforeAfterImageView)
        self.beforeAfterImageView.snp.makeConstraints { make in
            make.top.equalTo(topSpacer.snp.bottom)
            make.width.lessThanOrEqualTo(600)
            make.width.equalToSuperview().inset(32).priority(.high)
            make.centerX.equalToSuperview()
            make.height.equalTo(self.beforeAfterImageView.snp.width).dividedBy(imageAspectRatio)
        }
        
        // Add Export Video button
        self.exportButton = UIButton(type: .system)
        self.exportButton.setTitle("Export Video", for: .normal)
        self.exportButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        self.exportButton.backgroundColor = UIColor.systemBlue
        self.exportButton.setTitleColor(.white, for: .normal)
        self.exportButton.layer.cornerRadius = 12
        self.exportButton.addTarget(self, action: #selector(exportVideoTapped), for: .touchUpInside)
        self.view.addSubview(self.exportButton)
        
        self.exportButton.snp.makeConstraints { make in
            make.top.equalTo(self.beforeAfterImageView.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
        
        let bottomSpacer = UIView()
        self.view.addSubview(bottomSpacer)
        bottomSpacer.snp.makeConstraints { make in
            make.top.equalTo(self.exportButton.snp.bottom)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.greaterThanOrEqualTo(8)
            make.height.equalTo(topSpacer).priority(.high)
        }
        
        self.loadBeforeAfterAssets()
        
        self.beforeAfterImageView.grabHandleSize = CGSize(width: 36, height: 36)
        self.beforeAfterImageView.grabHandleCornerRadius = 18
        self.beforeAfterImageView.grabHandleBackgroundStyle = .blur(.regular)
        self.beforeAfterImageView.grabHandleIcon = UIImage(systemName: "arrowtriangle.left.and.line.vertical.and.arrowtriangle.right.fill")
        self.beforeAfterImageView.dividerWidth = 1
        self.beforeAfterImageView.setDividerPosition(0.0, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //assert(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ExampleViewController.viewDidAppear")

        self.beforeAfterImageView.setDividerPosition(0.8, animated: true, duration: 0.6) {
            print("Divider position set to 1.0")
            self.beforeAfterImageView.setDividerPosition(0.5, animated: true, duration: 0.3) {
                print("Divider position set to 0.5")
            }
        }
    }
    
    func loadBeforeAfterAssets() {
        //let beforeImage = UIImage(named: "r33_before")
        //let afterImage = UIImage(named: "r33_after")
        let beforeImage = UIImage(named: "birthday_girl_before")
        let afterImage = UIImage(named: "birthday_girl_after")
        
        self.beforeAfterImageView.configure(
            before: beforeImage!,
            after: afterImage!
        )
    }
    
    @objc func exportVideoTapped() {
        guard let beforeImage = self.beforeAfterImageView.bottomImageView.image,
              let afterImage = self.beforeAfterImageView.topImageView.image else {
            showAlert(title: "Error", message: "Could not load images")
            return
        }

        // Show action sheet to select export mode
        let actionSheet = UIAlertController(title: "Export Video", message: "Choose export format", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Plain Video", style: .default) { _ in
            self.exportVideo(beforeImage: beforeImage, afterImage: afterImage, mode: .plain)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Social Media Video", style: .default) { _ in
            self.exportVideo(beforeImage: beforeImage, afterImage: afterImage, mode: .social)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = exportButton
            popover.sourceRect = exportButton.bounds
        }
        
        present(actionSheet, animated: true)
    }
    
    private func exportVideo(beforeImage: UIImage, afterImage: UIImage, mode: ExportMode) {
        // Show loading state
        exportButton.isEnabled = false
        exportButton.setTitle("Exporting...", for: .normal)
        exportButton.backgroundColor = UIColor.systemGray
        
        // Record start time for duration tracking
        let exportStartTime = Date()
        
        // Create video segments with smooth easing animations
        let segments = [
            VideoExportSegment(position: 0.0, duration: 0.8, easing: .easeOut),        // Start at left with ease out
            VideoExportSegment(position: 1.0, duration: 2.5, easing: .easeInOut),      // Slide to right smoothly
            VideoExportSegment(position: 0.5, duration: 1.2, easing: .easeInOutBack),  // Back to center with bounce
            VideoExportSegment(position: 0.8, duration: 1.0, easing: .easeInOut),      // To 80% smoothly
            VideoExportSegment(position: 0.2, duration: 1.5, easing: .easeInOut),      // To 20% smoothly
            VideoExportSegment(position: 0.5, duration: 0.8, easing: .easeIn)          // End at center
        ]
        
        // Create output URL in Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modeString = mode == .plain ? "plain" : "social"
        let outputURL = documentsPath.appendingPathComponent("before_after_\(modeString)_\(Date().timeIntervalSince1970).mp4")
        
        // Create exporter and start export
        let exporter = RSBeforeAfterVideoExporter()
        
        exporter.exportVideo(
            beforeImage: beforeImage,
            afterImage: afterImage,
            mode: mode,
            startingPosition: 0.0,
            segments: segments,
            outputURL: outputURL
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.resetExportButton()
                
                switch result {
                case .success(let videoURL):
                    let exportDuration = Date().timeIntervalSince(exportStartTime)
                    let videoDuration = segments.reduce(0) { $0 + $1.duration }
                    print("Export complete: \(videoURL)")
                    print(" - export time: \(String(format: "%.2f", exportDuration)) seconds")
                    print(" - video duration: \(String(format: "%.2f", videoDuration)) seconds")
                    self?.showPostExportOptions(for: videoURL)
                case .failure(let error):
                    self?.showAlert(title: "Export Failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func resetExportButton() {
        exportButton.isEnabled = true
        exportButton.setTitle("Export Video", for: .normal)
        exportButton.backgroundColor = UIColor.systemBlue
    }
    
    private func showPostExportOptions(for videoURL: URL) {
        let actionSheet = UIAlertController(title: "Video Exported", message: "What would you like to do with your video?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "View", style: .default) { _ in
            self.playVideo(at: videoURL)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Share", style: .default) { _ in
            self.shareVideo(at: videoURL)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // iPad support
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(actionSheet, animated: true)
    }
    
    private func playVideo(at url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    private func shareVideo(at url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
