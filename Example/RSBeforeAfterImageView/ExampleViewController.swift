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
        self.beforeAfterImageView.configure(
            before: UIImage(named: "r33_before")!,
            after: UIImage(named: "r33_after")!
        )
    }
    
    @objc func exportVideoTapped() {
        guard let beforeImage = UIImage(named: "r33_before"),
              let afterImage = UIImage(named: "r33_after") else {
            showAlert(title: "Error", message: "Could not load images")
            return
        }
        
        // Show loading state
        exportButton.isEnabled = false
        exportButton.setTitle("Exporting...", for: .normal)
        exportButton.backgroundColor = UIColor.systemGray
        
        // Create video segments with animation
        let segments = [
            VideoExportSegment(position: 0.0, duration: 1.0),   // Start at left
            VideoExportSegment(position: 1.0, duration: 2.0),   // Slide to right over 2 seconds
            VideoExportSegment(position: 0.5, duration: 1.0),   // Back to center
            VideoExportSegment(position: 0.8, duration: 1.5),   // To 80%
            VideoExportSegment(position: 0.2, duration: 1.5)    // To 20%
        ]
        
        // Create output URL in Documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("before_after_export_\(Date().timeIntervalSince1970).mp4")
        
        // Create exporter and start export
        let exporter = RSBeforeAfterVideoExporter(videoSize: CGSize(width: 720, height: 720))
        
        exporter.exportVideo(
            beforeImage: beforeImage,
            afterImage: afterImage,
            startingPosition: 0.0,
            segments: segments,
            outputURL: outputURL
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.resetExportButton()
                
                switch result {
                case .success(let videoURL):
                    self?.playVideo(at: videoURL)
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
    
    private func playVideo(at url: URL) {
        let player = AVPlayer(url: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        
        present(playerViewController, animated: true) {
            player.play()
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
