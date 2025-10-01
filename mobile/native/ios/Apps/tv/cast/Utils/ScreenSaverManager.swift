//
//  ScreenSaverManager.swift
//  tv
//
//  Created by Claude on 03/09/25.
//

import Foundation
import UIKit

#if canImport(UIKit)
import UIKit
#endif

@MainActor
class ScreenSaverManager: ObservableObject {
    private static let shared = ScreenSaverManager()
    private var isDisabled = false
    private var refreshTimer: Timer?
    
    static func preventScreenSaver() {
        shared.startPrevention()
    }
    
    static func allowScreenSaver() {
        shared.stopPrevention()
    }
    
    private func startPrevention() {
        guard !isDisabled else { 
            print("🚫 Screen saver prevention already enabled")
            return 
        }
        
        #if os(tvOS)
        UIApplication.shared.isIdleTimerDisabled = true
        isDisabled = true
        print("🚫 Screen saver prevention enabled")
        
        // Fallback for problematic tvOS versions where isIdleTimerDisabled doesn't work reliably
        // This timer periodically refreshes the setting to ensure it stays disabled
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            UIApplication.shared.isIdleTimerDisabled = false
            UIApplication.shared.isIdleTimerDisabled = true
        }
        #endif
    }
    
    private func stopPrevention() {
        guard isDisabled else { 
            print("✅ Screen saver prevention already disabled")
            return 
        }
        
        #if os(tvOS)
        refreshTimer?.invalidate()
        refreshTimer = nil
        UIApplication.shared.isIdleTimerDisabled = false
        isDisabled = false
        print("✅ Screen saver prevention disabled")
        #endif
    }
    
    // Cleanup method for app termination
    static func cleanup() {
        shared.stopPrevention()
    }
}