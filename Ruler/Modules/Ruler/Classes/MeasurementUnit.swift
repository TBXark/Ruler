//
//  Distance.swift
//  Ruler
//
//  Created by Tbxark on 19/09/2017.
//  Copyright © 2017 Tbxark. All rights reserved.
//

import UIKit

struct MeasurementUnit {
    enum Unit: String {
        static let all: [Unit] = [.inch, .foot, .centimeter, .meter]
        case inch = "inch"
        case foot = "foot"
        case centimeter = "centimeter"
        case meter = "meter"
        func next() -> Unit {
            switch self {
            case .inch:
                return .foot
            case .foot:
                return .centimeter
            case .centimeter:
                return .meter
            case .meter:
                return .inch
            }
        }
        
        func meterScale(isArea: Bool = false) -> Float {
            let scale: Float = isArea ? 2 : 1
            switch self {
            case .meter: return pow(1, scale)
            case .centimeter: return pow(100, scale)
            case .inch: return pow(39.370, scale)
            case .foot: return pow(3.2808399, scale)
            }
        }
        
        func unitStr(isArea: Bool = false) -> String {
            switch self {
            case .meter:
                return isArea ? "m^2" : "m"
            case .centimeter:
                return isArea ? "cm^2" : "cm"
            case .inch:
                return isArea ? "in^2" : "in"
            case .foot:
                return isArea ? "ft^2" : "ft"
            }
        }
    }
    
    private let rawValue: Float
    private let isArea: Bool
    init(meterUnitValue value: Float, isArea: Bool = false) {
        self.rawValue = value
        self.isArea = isArea
    }
    
    
    func string(type: Unit) -> String {
        let unit = type.unitStr(isArea: isArea)
        let scale = type.meterScale(isArea: isArea)
        let res = rawValue * scale
        if  res < 0.1 {
            return String(format: "%.3f", res) +  unit
        } else if res < 1 {
            return String(format: "%.2f", res) +  unit
        } else if  res < 10 {
            return String(format: "%.1f", res) +  unit
        } else {
            return String(format: "%.0f", res) +  unit
        }
    }

    func attributeString(type: Unit,
                         valueFont: UIFont = UIFont.boldSystemFont(ofSize: 60),
                         unitFont: UIFont = UIFont.systemFont(ofSize: 20),
                         color: UIColor = UIColor.black) -> NSAttributedString {
        func buildAttributeString(value: String, unit: String) -> NSAttributedString {
            let main = NSMutableAttributedString()
            let v = NSMutableAttributedString(string: value,
                                              attributes: [NSAttributedStringKey.font: valueFont,
                                                           NSAttributedStringKey.foregroundColor: color])
            let u = NSMutableAttributedString(string: unit,
                                              attributes: [NSAttributedStringKey.font: unitFont,
                                                           NSAttributedStringKey.foregroundColor: color])
            main.append(v)
            main.append(u)
            return main
        }
        
        let unit = type.unitStr(isArea: isArea)
        let scale = type.meterScale(isArea: isArea)
        let res = rawValue * scale
        if  res < 0.1 {
            return buildAttributeString(value: String(format: "%.3f", res), unit: unit)
        } else if res < 1 {
            return buildAttributeString(value: String(format: "%.2f", res), unit: unit)
        } else if  res < 10 {
            return buildAttributeString(value: String(format: "%.1f", res), unit: unit)
        } else {
            return buildAttributeString(value: String(format: "%.0f", res), unit: unit)
        }
    }
}
