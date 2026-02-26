//
//  CastViewModel.swift
//  tv
//
//  Created by Neeraj Gupta on 28/08/25.
//

import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

@MainActor
class CastViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentView: CurrentView = .connecting
    @Published var deviceCode: String = ""
    @Published var currentImageData: Data?
    @Published var currentVideoData: Data?
    @Published var currentFile: CastFile?
    @Published var statusMessage: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let pairingService: RealCastPairingService
    private var lastLoggedMessages: [String: Date] = [:]
    private let logThrottleInterval: TimeInterval = 3.0 // 3 seconds
    private let castSession: CastSession
    
    // MARK: - Public Properties  
    public let slideshowService: RealSlideshowService
    
    enum CurrentView {
        case pairing
        case connecting
        case slideshow
        case error
        case empty
    }
    
    init() {
        print("🚀 Initializing with REAL Ente production server calls!")
        
        self.castSession = CastSession()
        self.pairingService = RealCastPairingService()
        self.slideshowService = RealSlideshowService()
        
        setupBindings()
        
        // Auto-start cast session on app launch (like web implementation)
        startCastSession()
    }
    
    private func setupBindings() {
        // Bind to cast session state changes
        castSession.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleStateChange(state)
            }
            .store(in: &cancellables)
        
        // Bind to slideshow service updates
        slideshowService.$currentImageData
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentImageData, on: self)
            .store(in: &cancellables)
        // Auto-transition once first image arrives (covers single-image albums and empty-to-populated)
        slideshowService.$currentImageData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if data != nil && (self.currentView == .connecting || self.currentView == .empty) {
                    self.currentView = .slideshow
                    self.statusMessage = ""
                    self.isLoading = false
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
        
        slideshowService.$currentVideoData
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentVideoData, on: self)
            .store(in: &cancellables)
        slideshowService.$currentVideoData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self = self else { return }
                if data != nil && (self.currentView == .connecting || self.currentView == .empty) {
                    self.currentView = .slideshow
                    self.statusMessage = ""
                    self.isLoading = false
                    self.errorMessage = nil
                }
            }
            .store(in: &cancellables)
        
        slideshowService.$currentFile
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentFile, on: self)
            .store(in: &cancellables)
        
        slideshowService.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleSlideshowError(error)
            }
            .store(in: &cancellables)
        
        // Listen for authentication expired notifications
        NotificationCenter.default.publisher(for: .authenticationExpired)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleAuthenticationExpired()
            }
            .store(in: &cancellables)
        
        // Listen for slideshow restarted notifications
        NotificationCenter.default.publisher(for: .slideshowRestarted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleSlideshowRestarted()
            }
            .store(in: &cancellables)
        
        // Listen for app lifecycle events to manage screen saver prevention
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                ScreenSaverManager.allowScreenSaver()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.currentView == .slideshow {
                    ScreenSaverManager.preventScreenSaver()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startCastSession() {
        castSession.setState(.registering)
        currentView = .connecting
        isLoading = true
        statusMessage = "Registering device..."
        
        Task {
            do {
                // Register device with the server
                let device = try await pairingService.registerDevice()
                
                await MainActor.run {
                    deviceCode = device.deviceCode
                    castSession.setState(.waitingForPairing(deviceCode: device.deviceCode))
                    currentView = .pairing
                    statusMessage = "Waiting for connection..."
                    isLoading = false
                }
                
                // Start polling for payload
                pairingService.startPolling(
                    device: device,
                    onPayloadReceived: { [weak self] payload in
                        Task { @MainActor in
                            self?.handlePayloadReceived(payload)
                        }
                    },
                    onError: { [weak self] error in
                        Task { @MainActor in
                            self?.handleNetworkError(error)
                        }
                    }
                )
                
            } catch {
                handleNetworkError(error)
            }
        }
    }
    
    func resetSession() async {
        print("🔄 Resetting cast session...")
        
        // Ensure screen saver prevention is disabled during reset
        ScreenSaverManager.allowScreenSaver()
        
        currentView = .connecting
        deviceCode = ""
        currentImageData = nil
        currentVideoData = nil
        currentFile = nil
        statusMessage = ""
        isLoading = false
        errorMessage = nil
        
        // Clean up services
        pairingService.stopPolling()
        await slideshowService.stop()
        castSession.setState(.idle)
        print("✅ Cast session reset complete")
    }
    
    private func handlePayloadReceived(_ payload: CastPayload) {
        // Idempotency: if we're already connected with same payload, skip
        if case .connected(let existing) = castSession.state, existing == payload {
            return
        }
        print("🎉 Cast payload received successfully!")
        
        // Update cast session with the payload
        castSession.setState(.connected(payload))
        currentView = .connecting
        statusMessage = ""
        isLoading = true
        
        // Stop polling once we receive payload
    // pairingService.stopPolling() // redundant; pairing service already stops itself when delivering payload
        
        // Start the slideshow with the full payload
        Task {
            // Add a small delay to prevent flickering from rapid state changes
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await slideshowService.start(castPayload: payload)
            
            // Additional delay to ensure slideshow is properly loaded
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                let hasError = slideshowService.error != nil && !slideshowService.error!.isEmpty
                
                if hasError {
                    handleSlideshowError(slideshowService.error!)
                } else {
                    currentView = .slideshow
                    statusMessage = ""
                    isLoading = false
                }
            }
        }
    }
    
    func retryOperation() {
        errorMessage = nil
        
        switch currentView {
        case .error:
            startCastSession()
        default:
            break
        }
    }
    
    // MARK: - Slideshow Navigation
    
    func nextSlide() {
        guard currentView == .slideshow else { return }
        
        Task {
            await slideshowService.nextSlide()
        }
    }
    
    func previousSlide() {
        guard currentView == .slideshow else { return }
        
        Task {
            await slideshowService.previousSlide()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleStateChange(_ state: CastSessionState) {
        switch state {
        case .idle:
            currentView = .connecting
            
        case .registering:
            currentView = .connecting
            statusMessage = "Registering device..."
            isLoading = true
            
        case .waitingForPairing(let code):
            deviceCode = code
            currentView = .pairing
            statusMessage = "Waiting for connection..."
            isLoading = false
            
        case .connected(let payload):
            handlePayloadReceived(payload)
            
        case .error(let message):
            handleError(message)
        }
    }
    
    
    private func handleSlideshowError(_ error: String) {
        // Prevent stale slideshow errors from a previous (expired) session
        // from overriding the fresh pairing code UI. Only react to slideshow
        // errors once we are actually in a connected/slideshow flow.
        // Exception: Allow empty state errors even during connecting
        let isEmptyStateError = error.contains("No media files") ||
            error.contains("available in this album") ||
            error.contains("available in this collection") ||
            error.contains("Empty file list")
        
        if (currentView == .pairing || currentView == .connecting) && !isEmptyStateError {
            // Ignore slideshow-originating errors during pairing / reconnection, except empty state
            return
        }
        
        if isEmptyStateError {
            currentView = .empty
            statusMessage = ""
            isLoading = false
        } else {
            handleError(error)
        }
    }
    
    
    private func handleError(_ message: String) {
        print("❌ Cast Error: \(message)")
        currentView = .error
        errorMessage = message
        isLoading = false
        statusMessage = ""
        castSession.setState(.error(message))
    }
    
    private func handleNetworkError(_ error: Error) {
        // Show error immediately
        handleError("An error occurred: \(error.localizedDescription)")
        
        // Wait 5 seconds then reset state for new device registration
        Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
            await MainActor.run {
                // Reset to start new device registration
                startCastSession()
            }
        }
    }
    
    private func handleAuthenticationExpired() {
        print("🔐 Authentication expired notification received - clearing all state and restarting")
        Task {
            await resetSession()
            // Clear all in-memory token state in slideshow service
            await slideshowService.clearExpiredTokenState()
            // Reset pairing service to allow fresh polling
            pairingService.resetForNewSession()
            
            // Ensure we're in a clean state before starting new session
            await MainActor.run {
                // Directly set to pairing once device registration begins to avoid brief empty/error flicker
                currentView = .connecting
                errorMessage = nil
                statusMessage = "Starting fresh session..."
                isLoading = true
            }
            
            // Generate fresh device code for new pairing
            startCastSession()
        }
    }
    
    private func handleSlideshowRestarted() {
        print("🎬 Slideshow restarted notification received")
        // Wait for image data to be available before transitioning
        // The binding will handle the transition when data arrives
        statusMessage = ""
        isLoading = false
        errorMessage = nil
        
        // Only transition if we already have image data
        if slideshowService.currentImageData != nil || slideshowService.currentVideoData != nil {
            print("🎬 Image/video data available - transitioning to slideshow view")
            currentView = .slideshow
        } else {
            print("⏳ Waiting for image data before transitioning to slideshow view")
        }
    }
    
}
