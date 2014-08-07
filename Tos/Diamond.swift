//
//  Diamond.swift
//  Tos
//
//  Created by Green on 2014/7/4.
//  Copyright (c) 2014年 Green. All rights reserved.
//

import UIKit
import QuartzCore

enum DiamondType : Int {
	case Unknow = -1
	case Red = 0
	case Blue = 1
	case Green = 2
	case Yellow = 3
	case Purple = 4

	func typeColor() -> CGColor
	{
		switch (self) {
		case .Red :		return UIColor.redColor().CGColor
		case .Blue:		return UIColor.blueColor().CGColor
		case .Green:	return UIColor.greenColor().CGColor
		case .Yellow:	return UIColor.yellowColor().CGColor
		case .Purple:	return UIColor.purpleColor().CGColor
		case .Unknow:	return UIColor.clearColor().CGColor
		}
	}

    static let typeCount : Int = 5;
	static func covertIntToDiamondType(aInt : Int) -> DiamondType {
		switch (aInt) {
		case 0: return .Red
		case 1:	return .Blue
		case 2:	return .Green
		case 3:	return .Yellow
		case 4:	return .Purple
		default: break
		}
		return .Unknow
	}
}

class Diamond : CALayer, NSCopying {

	var columnIndex : NSInteger = NSNotFound
	var rowIndex : NSInteger = NSNotFound
	var type : DiamondType = .Unknow
	{
		didSet {
			self.backgroundColor = type.typeColor()
		}
	}
	
	var draging : Bool = false
	{
		didSet {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
			self.opacity = draging == true ? 0.1 : 1.0
            CATransaction.commit()
		}
	}

	var isCheckedV : Bool = false
	var isCheckedH : Bool = false

	override init() {
		super.init()
		self.contentsScale = UIScreen.mainScreen().scale
		self.masksToBounds = true;
		self.borderWidth = 1.0
		self.borderColor = UIColor.blackColor().CGColor;
		self.cornerRadius = 4.0
	}

	override init(layer: AnyObject!)
	{
		super.init(layer:layer)
		self.contentsScale = UIScreen.mainScreen().scale
		self.masksToBounds = true;
		self.borderWidth = 1.0
		self.borderColor = UIColor.blackColor().CGColor;
		self.cornerRadius = 4.0
	}

	required init(coder aDecoder: NSCoder!) {
		super.init(coder: aDecoder)
	}

	func resetCheckState ()
	{
		isCheckedH = false
		isCheckedV = false
	}

	func copyWithZone(zone: NSZone) -> AnyObject!
	{
		let d = Diamond()
		d.columnIndex = columnIndex
		d.rowIndex = rowIndex
		d.type = type
		d.frame = self.frame
		return d
	}
}
