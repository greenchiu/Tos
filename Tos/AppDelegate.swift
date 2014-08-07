//
//  AppDelegate.swift
//  Tos
//
//  Created by Green on 2014/7/4.
//  Copyright (c) 2014年 Green. All rights reserved.
//

import UIKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
                            
	var window: UIWindow?


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
		// Override point for customization after application launch.
		var viewController = ViewController()
		window = UIWindow(frame: UIScreen.mainScreen().bounds)
		window!.rootViewController = viewController
		window!.makeKeyAndVisible()
		return true
	}


}

