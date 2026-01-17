//
//  FontUtils.swift
//  tv
//
//  Created on 28/08/25.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct FontUtils {
    
    // MARK: - Safe Font Creation
    
    private static func safeFont(name: String, size: CGFloat, fallback: Font) -> Font {
        #if canImport(UIKit)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        } else {
            return fallback
        }
        #else
        return .custom(name, size: size)
        #endif
    }
    
    // MARK: - Font Presets
    
    static func gilroyBlack(size: CGFloat) -> Font {
        return safeFont(name: "Gilroy-Black", size: size, fallback: .system(size: size, weight: .black))
    }
    
    static func gilroyExtraBold(size: CGFloat) -> Font {
        return safeFont(name: "Gilroy-Extrabold", size: size, fallback: .system(size: size, weight: .heavy))
    }
    
    static func interRegular(size: CGFloat) -> Font {
        return safeFont(name: "Inter-Regular", size: size, fallback: .system(size: size, weight: .regular))
    }
    
    static func interMedium(size: CGFloat) -> Font {
        return safeFont(name: "Inter-Medium", size: size, fallback: .system(size: size, weight: .medium))
    }
    
    static func interSemiBold(size: CGFloat) -> Font {
        return safeFont(name: "Inter-SemiBold", size: size, fallback: .system(size: size, weight: .semibold))
    }
    
    static func interBold(size: CGFloat) -> Font {
        return safeFont(name: "Inter-Bold", size: size, fallback: .system(size: size, weight: .bold))
    }
}