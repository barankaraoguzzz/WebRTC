//
//  File.swift
//  AtomicDesignSystem
//
//  Created by Baran Karaoğuz on 19.10.2024.
//

import Foundation

import UIKit

public enum FontStyles {
    case heading1
    case heading2
    case body
    case bodySecondary
    case caption
    case button
    
    public var value: UIFont {
        switch self {
        case .heading1:
            return UIFont.systemFont(ofSize: 24, weight: .bold) // Başlık 1 (büyük ve kalın)
        case .heading2:
            return UIFont.systemFont(ofSize: 20, weight: .semibold) // Başlık 2 (orta boyut ve yarı kalın)
        case .body:
            return UIFont.systemFont(ofSize: 16, weight: .regular) // Gövde metni (normal metin)
        case .bodySecondary:
            return UIFont.systemFont(ofSize: 14, weight: .regular) // İkincil gövde metni (daha küçük)
        case .caption:
            return UIFont.systemFont(ofSize: 12, weight: .light) // Küçük alt metin (light font)
        case .button:
            return UIFont.systemFont(ofSize: 16, weight: .medium) // Buton fontu (orta kalınlık)
        }
    }
}
