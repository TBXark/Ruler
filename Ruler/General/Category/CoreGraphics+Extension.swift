//
//  CoreGraphics+Extension.swift
//  Ruler
//
//  Created by Tbxark on 25/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit



// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
    var average: CGFloat? {
        guard !isEmpty else {
            return nil
        }
        
        var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
            var cur = cur
            cur += next
            return cur
        }
        let fcount = CGFloat(count)
        ret /= fcount
        return ret
    }
}


extension RangeReplaceableCollection where IndexDistance == Int {
    mutating func keepLast(_ elementsToKeep: Int) {
        if count > elementsToKeep {
            self.removeFirst(count - elementsToKeep)
        }
    }
}

// MARK: - CGPoint extensions

extension CGPoint {
    
    init(_ size: CGSize) {
        self.x = size.width
        self.y = size.height
    }
    
    init(_ vector: SCNVector3) {
        self.x = CGFloat(vector.x)
        self.y = CGFloat(vector.y)
    }
    
    func distanceTo(_ point: CGPoint) -> CGFloat {
        return (self - point).length()
    }
    
    func length() -> CGFloat {
        return sqrt(self.x * self.x + self.y * self.y)
    }
    
    func midpoint(_ point: CGPoint) -> CGPoint {
        return (self + point) / 2
    }
    
    func friendlyString() -> String {
        return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
    }
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}

func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}

func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}

func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}

func /= (left: inout CGPoint, right: CGFloat) {
    left = left / right
}

func *= (left: inout CGPoint, right: CGFloat) {
    left = left * right
}

// MARK: - CGSize extensions

extension CGSize {
    
    init(_ point: CGPoint) {
        self.width = point.x
        self.height = point.y
    }
    
    func friendlyString() -> String {
        return "(\(String(format: "%.2f", width)), \(String(format: "%.2f", height)))"
    }
}

func + (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width + right.width, height: left.height + right.height)
}

func - (left: CGSize, right: CGSize) -> CGSize {
    return CGSize(width: left.width - right.width, height: left.height - right.height)
}

func += (left: inout CGSize, right: CGSize) {
    left = left + right
}

func -= (left: inout CGSize, right: CGSize) {
    left = left - right
}

func / (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width / right, height: left.height / right)
}

func * (left: CGSize, right: CGFloat) -> CGSize {
    return CGSize(width: left.width * right, height: left.height * right)
}

func /= (left: inout CGSize, right: CGFloat) {
    left = left / right
}

func *= (left: inout CGSize, right: CGFloat) {
    left = left * right
}

// MARK: - CGRect extensions

extension CGRect {
    
    var mid: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}

