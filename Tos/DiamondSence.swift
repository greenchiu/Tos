//
//  DiamondSence.swift
//  Tos
//
//  Created by Green on 2014/7/4.
//  Copyright (c) 2014年 Green. All rights reserved.
//

import UIKit
import QuartzCore

class DiamondScene : UIView {
    
    enum GameStatus : String {
        case Unknow = "Unknow"
        case CanDrag = "CanDrag"
        case CheckCombos = "CheckCombos"
        case EliminateComboDiamonds = "EliminateComboDiamonds"
        case UpdateMap = "UpdateMap"
    }
    
	let col = 6;
	let row = 5;
	let rowIntervalSpace : CGFloat = 4.0;
	let colIntervalSpace : CGFloat = 4.0;
	let diamondSize = CGSizeMake(48.0, 48.0)
	var diamondMap :[Diamond] = [Diamond]()
	var eliminateQueue : [[Diamond]] = []
	var needUpdateCountOfColumn:[Int:[NSInteger]] = [Int:[NSInteger]]()
	var selectedDiamond : Diamond? = nil
	var dimmyDiamond : Diamond? = nil
	var draging : Bool = false
    var isNeedCheck : Bool = false
    var comboCountOfSingleRound : Int = 0
    var scoreOfSingleRound : Int = 0
    var totalScore : Int = 0
    var status : GameStatus = .Unknow
    {
    didSet {
        println("Now status: \(self.status.toRaw())")
        switch (self.status) {
        case .CheckCombos:
            self.checkMap()
            break
        default: break
        }
        }
    }
    
	override init(frame: CGRect)
	{
		super.init( frame : frame );
		self.backgroundColor = UIColor.lightGrayColor();
	}

	required init(coder aDecoder: NSCoder!) {
		super.init(coder: aDecoder)
	}

	func resetScene() {
        for d in diamondMap {
            d.removeFromSuperlayer()
        }
        diamondMap.removeAll()
        self.resetDiamondMap()
        self.status = .CanDrag
	}

	func resetDiamondMap () {
		var hightInterval = diamondSize.height + rowIntervalSpace
		var widthInterval = diamondSize.width + colIntervalSpace
		for r in 0..<row {
			var rDiamondArray = NSMutableArray()
			for c in 0..<col {
				var d = Diamond()
				d.rowIndex = r
				d.columnIndex = c
				d.frame = CGRectMake(6.0 + CGFloat(c) * widthInterval,6.0 + CGFloat(r) * hightInterval, diamondSize.width, diamondSize.height)

				d.type = DiamondType.covertIntToDiamondType(Int(arc4random_uniform(UInt32(DiamondType.typeCount))))
				self.layer.addSublayer(d)
				diamondMap.append(d)
			}
		}
	}

	func vaildPosition(inRow:Int, inCol:Int) -> Bool
	{
		return (inRow >= 0 && inRow < row) && (inCol >= 0 && inCol < col)
	}

	func convertPointToRowAndColumn( point : CGPoint ) -> (row:Int, column:Int)
	{
		var hightInterval = diamondSize.height + rowIntervalSpace
		var widthInterval = diamondSize.width + colIntervalSpace
		var r = -1, c = -1;
		c = Int(CGFloat(point.x - 6.0) / widthInterval);
		r = Int(CGFloat(point.y - 6.0) / hightInterval);
		return (min(row, r), min(col, c))
	}

	func switchDiamond( d1:Diamond!, d2:Diamond!)
	{
		var tempD : Diamond = d1.copy() as Diamond
		d1.rowIndex = d2.rowIndex
		d1.columnIndex = d2.columnIndex
		diamondMap[col * d1.rowIndex + d1.columnIndex] = d1
		d2.rowIndex = tempD.rowIndex
		d2.columnIndex = tempD.columnIndex
		diamondMap[col * d2.rowIndex + d2.columnIndex] = d2
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.15)
		d1.frame = d2.frame
		d2.frame = tempD.frame
		CATransaction.commit()
	}

	func resetSelectedDiamondState ()
	{
		if let tempD = selectedDiamond {
			selectedDiamond!.draging = false;
			selectedDiamond = nil
			dimmyDiamond!.removeFromSuperlayer();
			dimmyDiamond = nil
		}
		if isNeedCheck {
			isNeedCheck = false
            comboCountOfSingleRound = 0
            self.status = .CheckCombos
		}
	}

	func scanForVerticalCombos() -> [[Diamond]]
	{
		var verticalCombos:[[Diamond]] = [[Diamond]]()
		var comboMinR = 0, comboMaxR = 0
		var diff = 1
		var isCheckFinished = false

		var r = 0, c = 0
		while (!isCheckFinished) {
			let centerD = diamondMap[r * col + c]
			comboMinR = centerD.rowIndex
			comboMaxR = centerD.rowIndex
			if (!centerD.isCheckedV) {
				diff = 1
				while(true) {
					if (centerD.rowIndex + diff < row && centerD.type == diamondMap[(r + diff) * col + c].type) {
						comboMaxR = centerD.rowIndex + diff
						diff++
					}
					else {
						break
					}
				}

				diff = -1
				while(true) {
					if (centerD.rowIndex + diff >= 0 && centerD.type == diamondMap[(r + diff) * col + c].type) {
						comboMaxR = centerD.rowIndex + diff
						diff--
					}
					else {
						break
					}
				}

				if (comboMaxR - comboMinR >= 2) {
					var combo:[Diamond] = [Diamond]()
					for index in comboMinR...comboMaxR {
						var diamondInCombo = diamondMap[index * col + centerD.columnIndex]
						diamondInCombo.isCheckedV = true
						diamondMap[index * col + centerD.columnIndex] = diamondInCombo
						combo.append(diamondInCombo)
					}
					verticalCombos.append( combo )
				}
			}
			c++
			if (c >= col) {
				r++
				c = 0
			}
			if (r >= row) {
				isCheckFinished = true
			}
		}
		return verticalCombos
	}

	func scanForHorizontalCombos() -> [[Diamond]]
	{
		var horizontalCombos:[[Diamond]] = [[Diamond]]()
		var comboMinC = 0, comboMaxC = 0
		var diff = 1
		var isCheckFinished = false

		var r = 0, c = 0
		while (!isCheckFinished) {
			let centerDiamond = diamondMap[r * col + c]
			comboMaxC = centerDiamond.columnIndex
			comboMinC = centerDiamond.columnIndex
			if !centerDiamond.isCheckedH {

				diff = 1
				while (true) {
					if (centerDiamond.columnIndex + diff < col && centerDiamond.type == diamondMap[r * col + c + diff].type) {
						comboMaxC = centerDiamond.columnIndex + diff
						diff++
					}
					else {
						break
					}
				}

				diff = -1


				while (true) {
					if (centerDiamond.columnIndex + diff >= 0 && centerDiamond.type == diamondMap[r * col + c + diff].type) {
						comboMinC = centerDiamond.columnIndex + diff
						diff--
					}
					else {
						break
					}
				}

				if (comboMaxC - comboMinC >= 2) {
					var combo:[Diamond] = [Diamond]()
					for index in comboMinC...comboMaxC {
						var diamondInCombo = diamondMap[centerDiamond.rowIndex * col + index]
						diamondInCombo.isCheckedH = true
						diamondMap[centerDiamond.rowIndex * col + index] = diamondInCombo
						combo.append(diamondInCombo)
					}
					horizontalCombos.append(combo)
				}
			}

			c++
			if (c >= col) {
				r++
				c = 0
			}
			if (r >= row) {
				isCheckFinished = true
			}
		}

		return horizontalCombos
	}

	func mergeCombox(inout combos:[[Diamond]]) {
		if (combos.count > 1) {
			var neighborCombos:[[Diamond]] = [[Diamond]]()
			var removeIndexs = [Int]()

//			var temp = combos
//			var index = 0
//			while temp.isEmpty {
//				var currentCombo = temp.removeAtIndex(0)
//				var compareIndex = 0
//				while true {
//					if compareIndex >= temp.count {
//						break
//					}
//					var compareCombo = temp[compareIndex]
//					if compareComb[0].type != currentCombo[0].type {
//						compareIndex++
//						continue
//					}
//					compareIndex++
//				}
//				index++
//			}

			for currentIndex in 0..<combos.count - 1 {
				var currentCombo = combos[currentIndex]
				for compareIndex in currentIndex + 1..<combos.count {
					let compareCombo = combos[compareIndex]
					if (currentCombo[0].type != compareCombo[0].type) {
						continue
					}
					var isFindOutNeighbor = false
					for diamondIndex1 in 0..<currentCombo.count {
						let d1 = currentCombo[diamondIndex1]
						for diamondIndex2 in 0..<compareCombo.count {
							let d2 = compareCombo[diamondIndex2]
							if (d1.rowIndex == d2.rowIndex && (abs(d1.columnIndex - d2.columnIndex)  == 1) ||
								d1.columnIndex == d2.columnIndex && (abs(d1.rowIndex - d2.rowIndex)  == 1)) {
									neighborCombos.append(currentCombo)
									neighborCombos.append(compareCombo)
//									neighborCombos += (currentCombo + compareCombo)

									if (!contains(removeIndexs,compareIndex)) {
										removeIndexs.append(compareIndex)
									}
									if (!contains(removeIndexs,currentIndex)) {
										removeIndexs.append(currentIndex)
									}
									break
							}
						}

						if (isFindOutNeighbor == true) {
							break
						}
					}
				}
			}

			if (!removeIndexs.isEmpty) {
				removeIndexs.sort({ $1 < $0 })
				for removeIndex in 0..<removeIndexs.count {
					combos.removeAtIndex(removeIndexs[removeIndex])
				}
				combos += neighborCombos
				neighborCombos.removeAll(keepCapacity: false)
			}

			println("check combos intersection, now have \(combos.count) combo count.")
			var intersectionCombos:[[Diamond]] = [[Diamond]]()
			removeIndexs.removeAll(keepCapacity: false)
			for currentIndex in 0..<combos.count - 1 {
				var currentCombo = combos[currentIndex]
				for compareIndex in currentIndex + 1..<combos.count {
					let compareCombo = combos[compareIndex]
					if (currentCombo[0].type != compareCombo[0].type) {
						continue
					}
					var isFindoutIntersection = false
					for diamondIndex1 in 0..<currentCombo.count {
						let diamond1 = currentCombo[diamondIndex1]
						for diamondIndex2 in 0..<compareCombo.count {
							let diamond2 = compareCombo[diamondIndex2]
							if (diamond1.rowIndex == diamond2.rowIndex && diamond1.columnIndex == diamond2.columnIndex) {
								println("isEqaul \(diamond1) and \(diamond2) : \(diamond1 === diamond2)")
								isFindoutIntersection = true
								var filterTheSameDiamondCombo = [Diamond]()

								var indexOfIntersectionWithNewCombs = -1
								for idx in 0..<intersectionCombos.count {
									let aCombo = intersectionCombos[idx]
									for d in compareCombo {
										if (contains(aCombo, d)) {
											indexOfIntersectionWithNewCombs = idx
											break
										}
									}
									if (indexOfIntersectionWithNewCombs > 0) {
										break
									}
								}

								filterTheSameDiamondCombo += compareCombo
								filterTheSameDiamondCombo.removeAtIndex(diamondIndex2)

								if (indexOfIntersectionWithNewCombs < 0) {
									filterTheSameDiamondCombo += currentCombo
									intersectionCombos.append(filterTheSameDiamondCombo)
								}
								else {
									intersectionCombos[indexOfIntersectionWithNewCombs] += filterTheSameDiamondCombo
								}


								if (!contains(removeIndexs,compareIndex)) {
									removeIndexs.append(compareIndex)
								}
								if (!contains(removeIndexs,currentIndex)) {
									removeIndexs.append(currentIndex)
								}
								break
							}
						}

						if (isFindoutIntersection == true) {
							break
						}
					}
				}
			}

			if (!removeIndexs.isEmpty) {
				println("remove combos intersection")
				removeIndexs.sort({ $1 < $0 })
				for removeIndex in 0..<removeIndexs.count {
					combos.removeAtIndex(removeIndexs[removeIndex])
				}
				combos += intersectionCombos
				intersectionCombos.removeAll(keepCapacity: false)
			}
		}
	}
    
    func addDiamondAndUpdateMap ( columnUpdateCounts:[Int:[NSInteger]])
    {
        self.status = .UpdateMap
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.35)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
        for d in self.layer.sublayers {
            let d = d as Diamond
            for col in columnUpdateCounts.keys {
                if (d.columnIndex == col) {
                    var moveInterval = 0
                    for row in columnUpdateCounts[col]! {
                        if (d.rowIndex < row) {
                            moveInterval++
                        }
                    }
                    if (moveInterval == 0) {
                        continue
                    }
                    d.rowIndex += moveInterval
                    var frame = d.frame
                    frame.origin.y = 6.0 + CGFloat(d.rowIndex) * (diamondSize.height + rowIntervalSpace)
                    d.frame = frame
                }
            }
        }
        CATransaction.commit()

		var newDiamonds:[Diamond] = [Diamond]()
		for col in columnUpdateCounts.keys {
			let newAddCount = columnUpdateCounts[col]!.count
			for addIndex in 0 ..< newAddCount {
				var newDiamond = Diamond()
				newDiamond.columnIndex = col
				newDiamond.rowIndex = (newAddCount - addIndex) - 1
				newDiamond.type = DiamondType.covertIntToDiamondType(Int(arc4random_uniform(UInt32(DiamondType.typeCount))))
				newDiamond.frame.origin.x = 6.0 + CGFloat(col) * (diamondSize.width + colIntervalSpace)
				newDiamond.frame.origin.y = -CGFloat(addIndex+1) * (diamondSize.height + rowIntervalSpace)
				newDiamond.frame.size = diamondSize
				newDiamonds.append(newDiamond)
				self.layer.addSublayer(newDiamond)
			}
		}

        for diamond in self.layer.sublayers {
            let d = diamond as Diamond
			diamondMap.append(d)
        }
		diamondMap.sort({
			if($0.rowIndex == $1.rowIndex) {
				return $0.columnIndex < $1.columnIndex
			}
			else {
				return $0.rowIndex < $1.rowIndex
			}
		})

        dispatch_after( 1, dispatch_get_main_queue(), {
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                self.status = .CheckCombos
                })
            CATransaction.setAnimationDuration(0.35)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))
            for d in newDiamonds {
                d.frame.origin.y = 6.0 + CGFloat(d.rowIndex) * (self.diamondSize.height + self.rowIntervalSpace)
            }
            CATransaction.commit()
		})
    }

	func eliminateAnimation(combo:[Diamond])
	{
		CATransaction.begin()
		CATransaction.setAnimationDuration(0.35)
		CATransaction.setCompletionBlock({
			for d in combo {
				d.removeFromSuperlayer()
			}
			self.fireElimiateAnimation()
			})
		for d in combo {
			d.opacity = 0.0
		}
		CATransaction.commit()
	}

	func fireElimiateAnimation ()
	{
		if (!eliminateQueue.isEmpty) {
			var combo = eliminateQueue.removeLast()
			self.eliminateAnimation(combo)
		}
		else {
			self.addDiamondAndUpdateMap(needUpdateCountOfColumn)
		}
	}

    func eliminateCombos( combos inCombos:[[Diamond]] )
    {
		self.status = .EliminateComboDiamonds
		needUpdateCountOfColumn.removeAll(keepCapacity: false)
		for cb in inCombos {
			for d in cb {
				if (!contains(needUpdateCountOfColumn.keys, d.columnIndex)) {
					needUpdateCountOfColumn[d.columnIndex] = [NSInteger]()
				}
				var removesRowIndexOfCol:[NSInteger] = needUpdateCountOfColumn[d.columnIndex]! as [NSInteger]
				if (!contains(removesRowIndexOfCol, d.rowIndex)) {
					removesRowIndexOfCol.append(d.rowIndex)
					needUpdateCountOfColumn[d.columnIndex] = removesRowIndexOfCol
				}
			}
		}
		eliminateQueue += inCombos
		self.fireElimiateAnimation()
    }
    
	func checkMap ()
	{
		var cb2 = self.scanForHorizontalCombos()
		cb2 += self.scanForVerticalCombos()
		self.mergeCombox(&cb2)
        comboCountOfSingleRound += cb2.count
        if (!cb2.isEmpty) {
            diamondMap.removeAll(keepCapacity: false)
            self.eliminateCombos(combos: cb2)
		}
        else {
            println("This round you get \(comboCountOfSingleRound) combo(s).")
            self.status = .CanDrag
        }
	}

	override func touchesBegan(touches: NSSet!, withEvent event: UIEvent!)
	{
        if (self.status != .CanDrag) {
            return
        }
		let touch = touches!.anyObject() as UITouch
		let (r, c) = self.convertPointToRowAndColumn(touch.locationInView(self));
		if (!self.vaildPosition(r, inCol: c)) {
			return;
		}
		draging = true
		selectedDiamond = diamondMap[col * r + c];
		selectedDiamond!.draging = true;

		dimmyDiamond = Diamond()
		dimmyDiamond!.rowIndex = r
		dimmyDiamond!.columnIndex = c
		dimmyDiamond!.type = selectedDiamond!.type
		dimmyDiamond!.frame = selectedDiamond!.frame
		self.layer.addSublayer(dimmyDiamond)
	}
	override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!)
	{
		if (draging != true) {
			return;
		}
		let touch = touches!.anyObject() as UITouch
		let p = touch.locationInView(self);
		if (!CGRectContainsPoint(self.bounds, p)) {
			self.touchesCancelled(touches, withEvent: event)
			return;
		}

		let (r, c) = self.convertPointToRowAndColumn(touch.locationInView(self));
		if (!self.vaildPosition(r, inCol: c)) {
			return;
		}

		let frame = CGRectMake(p.x - diamondSize.width/2.0, p.y - diamondSize.height/2.0, diamondSize.width, diamondSize.height)
		CATransaction.begin();
		CATransaction.setDisableActions(true)
		dimmyDiamond!.frame = frame
		CATransaction.commit()

		if (r != selectedDiamond!.rowIndex || c != selectedDiamond!.columnIndex) {
			self.switchDiamond(selectedDiamond!, d2: diamondMap[col * r + c])
			isNeedCheck = true
		}
	}
	override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!)
	{
		draging = false;
		self.resetSelectedDiamondState()
	}
	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!)
	{
		draging = false;
		self.resetSelectedDiamondState()
	}
}
