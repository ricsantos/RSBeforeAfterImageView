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

class ExampleViewController: UIViewController {
    var beforeAfterImageView: RSBeforeAfterImageView!

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
        
        let bottomSpacer = UIView()
        self.view.addSubview(bottomSpacer)
        bottomSpacer.snp.makeConstraints { make in
            make.top.equalTo(self.beforeAfterImageView.snp.bottom)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            make.height.greaterThanOrEqualTo(8)
            make.height.equalTo(topSpacer).priority(.high)
        }
        
        self.loadBeforeAfterAssets()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        assert(false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("ExampleViewController.viewDidAppear")
    }
    
    func loadBeforeAfterAssets() {
        self.beforeAfterImageView.configure(
            before: UIImage(named: "r33_before")!,
            after: UIImage(named: "r33_after")!
        )
    }
}
