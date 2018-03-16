//
//  SettingViewController.swift
//  Ruler
//
//  Created by Tbxark on 19/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
    
    
    @IBOutlet weak var unitSegment: UISegmentedControl!
    @IBOutlet weak var displaySwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        unitSegment.selectedSegmentIndex = MeasurementUnit.Unit.all.index(of: ApplicationSetting.Status.defaultUnit)!
        displaySwitch.isOn = ApplicationSetting.Status.displayFocus
        displaySwitch.onTintColor = UIColor(red:0.996, green:0.835, blue:0.380, alpha:1.000)
    }
    
    
    @IBAction func lengthUnitDidChange(_ sender: UISegmentedControl) {
        ApplicationSetting.Status.defaultUnit = MeasurementUnit.Unit.all[sender.selectedSegmentIndex]
    }
    
    @IBAction func closeButtonDidClick(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func planeFocusDidChange(_ sender: UISwitch) {
        ApplicationSetting.Status.displayFocus = sender.isOn
    }
    
    @IBAction func pixoAppDidTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://itunes.apple.com/app/id1333531743")!,
                                  options: [:],
                                  completionHandler: nil)
    }
    @IBAction func playAppDidTap(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://itunes.apple.com/app/id1071726144")!,
                                  options: [:],
                                  completionHandler: nil)
    }
}
