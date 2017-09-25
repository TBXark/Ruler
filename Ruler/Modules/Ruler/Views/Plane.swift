//
//  Plane.swift
//  Ruler
//
//  Created by Tbxark on 18/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import Foundation
import ARKit

class Plane: SCNNode {
    
    var anchor: ARPlaneAnchor
    var occlusionNode: SCNNode?
    let occlusionPlaneVerticalOffset: Float = -0.01
    
    
    var focusSquare: FocusSquare?
    
    init(_ anchor: ARPlaneAnchor, _ showDebugVisualization: Bool) {
        self.anchor = anchor
        super.init()
        createOcclusionNode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(_ anchor: ARPlaneAnchor) {
        self.anchor = anchor
        updateOcclusionNode()
    }
   
    func updateOcclusionSetting() {
        if occlusionNode == nil {
            createOcclusionNode()
        }
    }
    
    // MARK: Private
    
    private func createOcclusionNode() {

        let occlusionPlane = SCNPlane(width: CGFloat(anchor.extent.x - 0.05), height: CGFloat(anchor.extent.z - 0.05))
        let material = SCNMaterial()
        material.colorBufferWriteMask = []
        material.isDoubleSided = true
        occlusionPlane.materials = [material]
        occlusionNode = SCNNode()
        occlusionNode!.geometry = occlusionPlane
        occlusionNode!.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
        occlusionNode!.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
        
        self.addChildNode(occlusionNode!)
    }
    
    private func updateOcclusionNode() {
        guard let occlusionNode = occlusionNode, let occlusionPlane = occlusionNode.geometry as? SCNPlane else {
            return
        }
        occlusionPlane.width = CGFloat(anchor.extent.x - 0.05)
        occlusionPlane.height = CGFloat(anchor.extent.z - 0.05)
        
        occlusionNode.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
    }
}

