//
//  LineNode.swift
//  Ruler
//
//  Created by Tbxark on 18/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//


import UIKit
import SceneKit
import ARKit

class LineNode: NSObject {
    let startNode: SCNNode
    let endNode: SCNNode
    var lineNode: SCNNode?
    let textNode: SCNNode
    let sceneView: ARSCNView?
    private var recentFocusSquarePositions = [SCNVector3]()

    init(startPos: SCNVector3,
         sceneV: ARSCNView,
         color: (start: UIColor, end: UIColor) = (UIColor.green, UIColor.red),
         font: UIFont = UIFont.boldSystemFont(ofSize: 10) ) {
        sceneView = sceneV
        
        let scale = 1/400.0
        let scaleVector = SCNVector3(scale, scale, scale)

        func buildSCNSphere(color: UIColor) -> SCNSphere {
            let dot = SCNSphere(radius:1)
            dot.firstMaterial?.diffuse.contents = color
            dot.firstMaterial?.lightingModel = .constant
            dot.firstMaterial?.isDoubleSided = true
            return dot
        }
   
        
        startNode = SCNNode(geometry: buildSCNSphere(color: color.start))
        startNode.scale = scaleVector
        startNode.position = startPos
        sceneView?.scene.rootNode.addChildNode(startNode)
        
        endNode = SCNNode(geometry: buildSCNSphere(color: color.end))
        endNode.scale = scaleVector
        
        lineNode = nil
        
        let text = SCNText (string: "--", extrusionDepth: 0.1)
        text.font = font
        text.firstMaterial?.diffuse.contents = UIColor.white
        text.alignmentMode  = kCAAlignmentCenter
        text.truncationMode = kCATruncationMiddle
        text.firstMaterial?.isDoubleSided = true
        textNode = SCNNode(geometry: text)
        textNode.scale = SCNVector3(1/500.0, 1/500.0, 1/500.0)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeFromParent()
    }
    
    public func updatePosition(pos: SCNVector3, camera: ARCamera?, unit: MeasurementUnit.Unit = MeasurementUnit.Unit.centimeter) -> Float {
        let posEnd = updateTransform(for: pos, camera: camera)
        
        if endNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(endNode)
        }
        endNode.position = posEnd
        
        let posStart = startNode.position
        let middle = SCNVector3((posStart.x+posEnd.x)/2.0, (posStart.y+posEnd.y)/2.0+0.002, (posStart.z+posEnd.z)/2.0)
        
        let text = textNode.geometry as! SCNText
        let length = posEnd.distanceFromPos(pos: startNode.position)
        text.string = MeasurementUnit(meterUnitValue: length).string(type: unit)
        textNode.setPivot()
        textNode.position = middle
        if textNode.parent == nil {
            sceneView?.scene.rootNode.addChildNode(textNode)
        }
        
        lineNode?.removeFromParentNode()
        lineNode = lineBetweenNodeA(nodeA: startNode, nodeB: endNode)
        sceneView?.scene.rootNode.addChildNode(lineNode!)
        
        return length
    }
    
    func removeFromParent() -> Void {
        startNode.removeFromParentNode()
        endNode.removeFromParentNode()
        lineNode?.removeFromParentNode()
        textNode.removeFromParentNode()
    }
    
    // MARK: - Private
    
    private func lineBetweenNodeA(nodeA: SCNNode, nodeB: SCNNode) -> SCNNode {
        
        return CylinderLine(parent: sceneView!.scene.rootNode,
                            v1: nodeA.position,
                            v2: nodeB.position,
                            radius: 0.001,
                            radSegmentCount: 16,
                            color: UIColor.white)
        
    }
    
    
    private func updateTransform(for position: SCNVector3, camera: ARCamera?) -> SCNVector3 {
        recentFocusSquarePositions.append(position)
        recentFocusSquarePositions.keepLast(8)
        if let camera = camera {
            let tilt = abs(camera.eulerAngles.x)
            let threshold1: Float = Float.pi / 2 * 0.65
            let threshold2: Float = Float.pi / 2 * 0.75
            let yaw = atan2f(camera.transform.columns.0.x, camera.transform.columns.1.x)
            var angle: Float = 0
            
            switch tilt {
            case 0..<threshold1:
                angle = camera.eulerAngles.y
            case threshold1..<threshold2:
                let relativeInRange = abs((tilt - threshold1) / (threshold2 - threshold1))
                let normalizedY = normalize(camera.eulerAngles.y, forMinimalRotationTo: yaw)
                angle = normalizedY * (1 - relativeInRange) + yaw * relativeInRange
            default:
                angle = yaw
            }
            textNode.runAction(SCNAction.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0))
        }
        
        if let average = recentFocusSquarePositions.average {
            return average
        }
        
        return SCNVector3Zero
    }
    
    private func normalize(_ angle: Float, forMinimalRotationTo ref: Float) -> Float {

        var normalized = angle
        while abs(normalized - ref) > Float.pi / 4 {
            if angle > ref {
                normalized -= Float.pi / 2
            } else {
                normalized += Float.pi / 2
            }
        }
        return normalized
    }
}

