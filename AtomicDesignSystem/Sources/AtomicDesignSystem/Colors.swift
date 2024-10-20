//
//  File.swift
//  AtomicDesignSystem
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation
import UIKit

public enum Colors {
    case primary
    case secondary
    case text
    case textSecondary
    case textTertiary
    case success
    case error
    
    public var value: UIColor {
        switch self {
        case .primary: return UIColor(hex: "#F5F5F7") // Kirli beyaz tonları (açık gri-beyaz)
        case .secondary: return UIColor(hex: "#34C759") // İkincil renk (yeşil)
        case .text: return UIColor(hex: "#2C2C2E") // Koyu gri (Dark)
        case .textSecondary: return UIColor(hex: "#636366") // Orta gri
        case .textTertiary: return UIColor(hex: "#AEAEB2") // Daha açık gri
        case .success: return UIColor(hex: "#34C759") // Başarılı işlem rengi (yeşil)
        case .error: return UIColor(hex: "#FF3B30") // Hata veya iptal rengi (kırmızı)
        }
    }
}

// UIColor extension to support hex color
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 1  // Skip the '#' character
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let red = CGFloat((rgbValue & 0xff0000) >> 16) / 255.0
        let green = CGFloat((rgbValue & 0xff00) >> 8) / 255.0
        let blue = CGFloat(rgbValue & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
