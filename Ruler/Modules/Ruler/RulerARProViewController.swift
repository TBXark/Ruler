//
//  RulerARProViewController.swift
//  Ruler
//
//  Created by Tbxark on 25/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Photos
import AudioToolbox
import VideoToolbox


typealias Localization = R.string.rulerString

class RulerARProViewController: UIViewController {
    
    enum MeasurementMode {
        case length
        case area
        func toAttrStr() -> NSAttributedString {
            let str = self == .area ? R.string.rulerString.startArea() : R.string.rulerString.startLength()
            return NSAttributedString(string: str, attributes: [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 20),
                                                                 NSAttributedStringKey.foregroundColor: UIColor.black])
        }
    }
    struct Image {
        struct Menu {
            static let area = #imageLiteral(resourceName: "menu_area")
            static let length = #imageLiteral(resourceName: "menu_length")
            static let reset = #imageLiteral(resourceName: "menu_reset")
            static let setting = #imageLiteral(resourceName: "menu_setting")
            static let save = #imageLiteral(resourceName: "menu_save")
        }
        struct More {
            static let close = #imageLiteral(resourceName: "more_off")
            static let open = #imageLiteral(resourceName: "more_on")
        }
        struct Place {
            static let area = #imageLiteral(resourceName: "place_area")
            static let length = #imageLiteral(resourceName: "place_length")
            static let done = #imageLiteral(resourceName: "place_done")
        }
        struct Close {
            static let delete = #imageLiteral(resourceName: "cancle_delete")
            static let cancle = #imageLiteral(resourceName: "cancle_back")
        }
        struct Indicator {
            static let enable = #imageLiteral(resourceName: "img_indicator_enable")
            static let disable = #imageLiteral(resourceName: "img_indicator_disable")
        }
        struct Result {
            static let copy = #imageLiteral(resourceName: "result_copy")
        }
    }
    
    struct Sound {
        static var soundID: SystemSoundID = 0
        static func install() {
            guard let path = Bundle.main.path(forResource: "SetPoint", ofType: "wav") else { return  }
            let url = URL(fileURLWithPath: path)
            AudioServicesCreateSystemSoundID(url as CFURL, &soundID)
        }
        static func play() {
            guard soundID != 0 else { return }
            AudioServicesPlaySystemSound(soundID)
        }
        static func dispose() {
            guard soundID != 0 else { return }
            AudioServicesDisposeSystemSoundID(soundID)
        }

    }
    private let sceneView: ARSCNView =  ARSCNView(frame: UIScreen.main.bounds)
    private let indicator = UIImageView()
    private let resultLabel = UILabel().then({
        $0.textAlignment = .center
        $0.textColor = UIColor.black
        $0.numberOfLines = 0
        $0.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.heavy)
    })

    
    private var line: LineNode?
    private var lineSet: LineSetNode?
    
    
    private var lines: [LineNode] = []
    private var lineSets: [LineSetNode] = []
    private var planes = [ARPlaneAnchor: Plane]()
    private var focusSquare: FocusSquare?
    
    
    
    private var mode = MeasurementMode.length
    private var finishButtonState = false
    private var lastState: ARCamera.TrackingState = .notAvailable {
        didSet {
            switch lastState {
            case .notAvailable:
                guard HUG.isVisible else { return }
                HUG.show(title: Localization.arNotAvailable())
            case .limited(let reason):
                switch reason {
                case .initializing:
                    HUG.show(title: Localization.arInitializing(), message: Localization.arInitializingMessage(), inSource: self, autoDismissDuration: nil)
                case .insufficientFeatures:
                    HUG.show(title: Localization.arExcessiveMotion(), message: Localization.arInitializingMessage(), inSource: self, autoDismissDuration: 5)
                case .excessiveMotion:
                    HUG.show(title: Localization.arExcessiveMotion(), message: Localization.arExcessiveMotionMessage(), inSource: self, autoDismissDuration: 5)
                }
            case .normal:
                HUG.dismiss()
            }
        }
    }
    private var measureUnit = ApplicationSetting.Status.defaultUnit {
        didSet {
            let v = measureValue
            measureValue = v
        }
    }
    private var measureValue: MeasurementUnit? {
        didSet {
            if let m = measureValue {
                resultLabel.text = nil
                resultLabel.attributedText = m.attributeString(type: measureUnit)
            } else {
                resultLabel.attributedText = mode.toAttrStr()
            }
        }
    }
    
    
    
    private lazy var menuButtonSet: PopButton = PopButton(buttons: menuButton.measurement,
                                                          menuButton.save,
                                                          menuButton.reset,
                                                          menuButton.setting,
                                                          menuButton.more)
    
    private let placeButton = UIButton(size: CGSize(width: 80, height: 80), image: Image.Place.length)
    private let cancleButton = UIButton(size: CGSize(width: 60, height: 60), image: Image.Close.delete)
    private let finishButton = UIButton(size: CGSize(width: 60, height: 60), image: Image.Place.done)
    private let menuButton = (measurement: UIButton(size: CGSize(width: 50, height: 50), image: Image.Menu.area),
                         save: UIButton(size: CGSize(width: 50, height: 50), image: Image.Menu.save),
                        reset: UIButton(size: CGSize(width: 50, height: 50), image: Image.Menu.reset),
                        setting: UIButton(size: CGSize(width: 50, height: 50), image: Image.Menu.setting),
                        more: UIButton(size: CGSize(width: 60, height: 60), image: Image.More.close))
    
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutViewController()
        setupFocusSquare()
        Sound.install()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restartSceneView()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    private func layoutViewController() {
        let width = view.bounds.width
        let height = view.bounds.height
        view.backgroundColor = UIColor.black
        
        
        do {
            view.addSubview(sceneView)
            sceneView.frame = view.bounds
            sceneView.delegate = self
        }
        do {
            

            let resultLabelBg = UIView()
            resultLabelBg.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            resultLabelBg.layer.cornerRadius = 45
            resultLabelBg.clipsToBounds = true
            
            let copy = UIButton(size: CGSize(width: 30, height: 30), image: Image.Result.copy)
            copy.addTarget(self, action: #selector(RulerARProViewController.copyAction(_:)), for: .touchUpInside)
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(RulerARProViewController.changeMeasureUnitAction(_:)))
            resultLabel.addGestureRecognizer(tap)
            resultLabel.isUserInteractionEnabled = true
            
            
            resultLabelBg.frame = CGRect(x: 30, y: 30, width: width - 60, height: 90)
            copy.frame = CGRect(x: resultLabelBg.frame.maxX - 10 - 30,
                                y: resultLabelBg.frame.minY + (resultLabelBg.frame.height - 30)/2,
                                width: 30, height: 30)
            resultLabel.frame = resultLabelBg.frame.insetBy(dx: 10, dy: 0)
            resultLabel.attributedText = mode.toAttrStr()
            
            view.addSubview(resultLabelBg)
            view.addSubview(resultLabel)
            view.addSubview(copy)

            
            
        }
        
        do {
            indicator.image = Image.Indicator.disable
            view.addSubview(indicator)
            indicator.frame = CGRect(x: (width - 60)/2, y: (height - 60)/2, width: 60, height: 60)
        }
        do {
            view.addSubview(finishButton)
            view.addSubview(placeButton)
            finishButton.addTarget(self, action: #selector(RulerARProViewController.finishAreaAction(_:)), for: .touchUpInside)
            placeButton.addTarget(self, action: #selector(RulerARProViewController.placeAction(_:)), for: .touchUpInside)
            placeButton.frame = CGRect(x: (width - 80)/2, y: (height - 20 - 80), width: 80, height: 80)
            finishButton.center = placeButton.center
        }
        do {
            view.addSubview(cancleButton)
            cancleButton.addTarget(self, action: #selector(RulerARProViewController.deleteAction(_:)), for: .touchUpInside)
            cancleButton.frame = CGRect(x: 40, y: placeButton.frame.origin.y + 10, width: 60, height: 60)
        }
        do {
            view.addSubview(menuButtonSet)
            menuButton.more.addTarget(self, action: #selector(RulerARProViewController.showMenuAction(_:)), for: .touchUpInside)
            menuButton.setting.addTarget(self, action: #selector(RulerARProViewController.moreAction(_:)), for: .touchUpInside)
            menuButton.reset.addTarget(self, action: #selector(RulerARProViewController.restartAction(_:)), for: .touchUpInside)
            menuButton.measurement.addTarget(self, action: #selector(RulerARProViewController.changeMeasureMode(_:)), for: .touchUpInside)
            menuButton.save.addTarget(self, action: #selector(RulerARProViewController.saveImage(_:)), for: .touchUpInside)
            menuButtonSet.frame = CGRect(x: (width - 40 - 60), y: placeButton.frame.origin.y + 10, width: 60, height: 60)
            

        }
        
    }
    
    
    private func configureObserver() {
        func cleanLine() {
            line?.removeFromParent()
            line = nil
            for node in lines {
                node.removeFromParent()
            }
            
        }
        NotificationCenter.default.addObserver(forName: NSNotification.Name.UIApplicationDidEnterBackground, object: nil, queue: OperationQueue.main) { _ in
            cleanLine()
        }
    }
    
    deinit {
        Sound.dispose()
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Target Action
@objc private extension RulerARProViewController {
    // 保存测量结果
    func saveImage(_ sender: UIButton) {
        func saveImage(image: UIImage) {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { (isSuccess: Bool, error: Error?) in
                if let e = error {
                    HUG.show(title: Localization.saveFail(), message: e.localizedDescription)
                } else{
                    HUG.show(title: Localization.saveSuccess())
                }
            }
        }
        
        let image = sceneView.snapshot()
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            saveImage(image: image)
        default:
            PHPhotoLibrary.requestAuthorization { (status) in
                switch status {
                case .authorized:
                    saveImage(image: image)
                default:
                    HUG.show(title: Localization.saveFail(), message: Localization.saveNeedPermission())
                }
            }
        }
    }
    
    
    // 放置测量点
    func placeAction(_ sender: UIButton) {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseOut], animations: {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { (value) in
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: [.allowUserInteraction,.curveEaseIn], animations: {
                sender.transform = CGAffineTransform.identity
            }) { (value) in
            }
        }
        Sound.play()
        switch mode {
        case .length:
            if let l = line {
                lines.append(l)
                line = nil
            } else  {
                let startPos = sceneView.worldPositionFromScreenPosition(indicator.center, objectPos: nil)
                if let p = startPos.position {
                    line = LineNode(startPos: p, sceneV: sceneView)
                }
            }
        case .area:
            if let l = lineSet {
                l.addLine()
            } else {
                let startPos = sceneView.worldPositionFromScreenPosition(indicator.center, objectPos: nil)
                if let p = startPos.position {
                    lineSet = LineSetNode(startPos: p, sceneV: sceneView)
                }
            }
        }
    }
    
    // 重置视图
    func restartAction(_ sender: UIButton) {
        showMenuAction(sender)
        line?.removeFromParent()
        line = nil
        for node in lines {
            node.removeFromParent()
        }
        
        lineSet?.removeFromParent()
        lineSet = nil
        for node in lineSets {
            node.removeFromParent()
        }
        restartSceneView()
        measureValue = nil
    }
    
    // 删除上一操作
    func deleteAction(_ sender: UIButton) {
        switch mode {
        case .length:
            if line != nil {
                line?.removeFromParent()
                line = nil
            } else if let lineLast = lines.popLast() {
                lineLast.removeFromParent()
            } else {
                lineSets.popLast()?.removeFromParent()
            }
        case .area:
            if let ls = lineSet {
                if !ls.removeLine() {
                    lineSet = nil
                }
            } else if let lineSetLast = lineSets.popLast() {
                lineSetLast.removeFromParent()
            } else {
                lines.popLast()?.removeFromParent()
            }
        }
        cancleButton.normalImage = Image.Close.delete
        measureValue = nil
    }
    
    
    // 复制测量结果
    func copyAction(_ sender: UIButton) {
        UIPasteboard.general.string = resultLabel.text
        HUG.show(title: "已复制到剪贴版")
    }
    
    
    // 跳转设置
    func moreAction(_ sender: UIButton) {
        guard let vc = UIStoryboard(name: "SettingViewController", bundle: nil).instantiateInitialViewController() else {
            return
        }
        showMenuAction(sender)
        present(vc, animated: true, completion: nil)
    }
    
    
    // 显示菜单
    func showMenuAction(_ sender: UIButton) {
        if menuButtonSet.isOn {
            menuButtonSet.dismiss()
            menuButton.more.normalImage = Image.More.close
        } else {
            menuButtonSet.show()
            menuButton.more.normalImage = Image.More.open
        }
    }
    
    // 完成面积测量
    func finishAreaAction(_ sender: UIButton) {
        guard mode == .area,
            let line = lineSet,
            line.lines.count >= 2 else {
                lineSet = nil
                return
        }
        lineSets.append(line)
        lineSet = nil
        changeFinishState(state: false)
    }
    
    
    
    // 变换面积测量完成按钮状态
    func changeFinishState(state: Bool) {
        guard finishButtonState != state else { return }
        finishButtonState = state
        var center = placeButton.center
        if state {
            center.y -= 100
        }
        UIView.animate(withDuration: 0.3) {
            self.finishButton.center = center
        }
    }
    
    // 变换测量单位
    func changeMeasureUnitAction(_ sender: UITapGestureRecognizer) {
        measureUnit = measureUnit.next()
    }
    
    
    func changeMeasureMode(_ sender: UIButton) {
        showMenuAction(sender)
        lineSet = nil
        line = nil
        switch mode {
        case .area:
            changeFinishState(state: false)
            menuButton.measurement.normalImage = Image.Menu.area
            placeButton.normalImage  = Image.Place.length
            placeButton.disabledImage = Image.Place.length

            mode = .length
        case .length:
            menuButton.measurement.normalImage = Image.Menu.length
            placeButton.normalImage  = Image.Place.area
            placeButton.disabledImage = Image.Place.area
            mode = .area
        }
        resultLabel.attributedText = mode.toAttrStr()
    }
    
    
}


// MARK: - UI
fileprivate extension RulerARProViewController {
    
    func restartSceneView() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        measureUnit = ApplicationSetting.Status.defaultUnit
        resultLabel.attributedText = mode.toAttrStr()
        updateFocusSquare()
    }
    
    func updateLine() -> Void {
        let startPos = sceneView.worldPositionFromScreenPosition(self.indicator.center, objectPos: nil)
        if let p = startPos.position {
            let camera = self.sceneView.session.currentFrame?.camera
            let cameraPos = SCNVector3.positionFromTransform(camera!.transform)
            if cameraPos.distanceFromPos(pos: p) < 0.05 {
                if line == nil {
                    placeButton.isEnabled = false
                    indicator.image = Image.Indicator.disable
                }
                return;
            }
            placeButton.isEnabled = true
            indicator.image = Image.Indicator.enable
            switch mode {
            case .length:
                guard let currentLine = line else {
                    cancleButton.normalImage = Image.Close.delete
                    return
                }
                let length = currentLine.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera, unit: measureUnit)
                measureValue =  MeasurementUnit(meterUnitValue: length, isArea: false)
                cancleButton.normalImage = Image.Close.cancle
            case .area:
                guard let set = lineSet else {
                    changeFinishState(state: false)
                    cancleButton.normalImage = Image.Close.delete
                    return
                }
                let area = set.updatePosition(pos: p, camera: self.sceneView.session.currentFrame?.camera, unit: measureUnit)
                measureValue =  MeasurementUnit(meterUnitValue: area, isArea: true)
                changeFinishState(state: set.lines.count >= 2)
                cancleButton.normalImage = Image.Close.cancle
            }
        }
    }
}




// MARK： - AR


// MARK: - Plane
fileprivate extension RulerARProViewController {
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor) {
        
        let plane = Plane(anchor, false)
        planes[anchor] = plane
        node.addChildNode(plane)
        indicator.image = Image.Indicator.enable
    }
    
    func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
}

// MARK: - FocusSquare
fileprivate extension RulerARProViewController {
    
    func setupFocusSquare() {
        focusSquare?.isHidden = true
        focusSquare?.removeFromParentNode()
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
    }
    
    func updateFocusSquare() {
        if ApplicationSetting.Status.displayFocus {
            focusSquare?.unhide()
        } else {
            focusSquare?.hide()
        }
        let (worldPos, planeAnchor, _) = sceneView.worldPositionFromScreenPosition(sceneView.bounds.mid, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
}


// MARK: - ARSCNViewDelegate
extension RulerARProViewController: ARSCNViewDelegate {
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            HUG.show(title: (error as NSError).localizedDescription)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.updateLine()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        let state = camera.trackingState
        DispatchQueue.main.async {
            self.lastState = state
        }
    }
}
