//
//  PopButton.swift
//  Ruler
//
//  Created by Tbxark on 25/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit


extension UIButton {
    public convenience init(size: CGSize, image: UIImage?) {
        self.init(frame: CGRect(origin: CGPoint.zero, size: size))
        setImage(image, for: .normal)
        setImage(image, for: .disabled)

    }
    
    public var disabledImage: UIImage? {
        get {
            return image(for: .disabled)
        }
        set {
            setImage(newValue, for: .disabled)
        }
    }
    
    public var normalImage: UIImage? {
        get {
            return image(for: .normal)
        }
        set {
            setImage(newValue, for: .normal)
        }
    }
}

class PopButton: UIControl {
    
    private(set) var isOn = false
    let buttonArray:  [UIButton]
    init(buttons: UIButton...) {
        buttonArray = buttons
        let w = buttons.map({ $0.frame.width }).max()
        let h = buttons.map({ $0.frame.height }).max()
        super.init(frame: CGRect(x: 0, y: 0, width: w ?? 0, height: h ?? 0))
        let p = CGPoint(x: frame.width/2, y: frame.height/2)
        for b in buttons {
            addSubview(b)
            b.center = p
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show() {
        guard !isOn else { return }
        isOn = true
        var centerY = frame.height/2
        var buttons = buttonArray
        let lastButton = buttons.removeLast()
        centerY -= lastButton.frame.height / 2
        for btn in buttons.reversed() {
            centerY -= btn.frame.height + 10
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: UIViewAnimationOptions.curveEaseOut,
                           animations: {
                            btn.center.y = centerY
            }, completion: nil)
        }
    }
    
    func dismiss() {
        guard isOn else { return }
        isOn = false
        let p = CGPoint(x: frame.width/2, y: frame.height/2)
        for btn in buttonArray {
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           options: UIViewAnimationOptions.curveEaseOut,
                           animations: {
                            btn.center = p
            }, completion: nil)
        }
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isOn, point.x >= 0 , point.x <= frame.width else {
            return super.hitTest(point, with: event)
        }
        for btn in buttonArray {
            guard btn.frame.contains(point) else { continue }
            return btn
        }

        return super.hitTest(point, with: event)
    }
    
}
