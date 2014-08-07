//
//  ViewController.swift
//  Tos
//
//  Created by Green on 2014/7/4.
//  Copyright (c) 2014年 Green. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
                            
	override func viewDidLoad() {
		super.viewDidLoad()
		self.view.backgroundColor = UIColor.whiteColor()
		println("Hi, this is ViewController")

		var sence = DiamondScene(frame:CGRectMake(0, 180, 320,270))
		self.view.addSubview(sence)
		sence.resetScene()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}



	
}

