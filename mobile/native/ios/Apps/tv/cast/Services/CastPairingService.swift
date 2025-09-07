//
//  CastPairingService.swift
//  tv
//
//  Created by Neeraj Gupta on 28/08/25.
//

import SwiftUI
import CryptoKit
import Foundation
import EnteCrypto

// MARK: - Cast Session Management

@MainActor
class CastSession: ObservableObject {
    @Published var state: CastSessionState = .idle
    @Published var isActive: Bool = false
    
    var deviceCode: String? {
        if case .waitingForPairing(let code) = state {
            return code
        }
        return nil
    }
    
    var payload: CastPayload? {
        if case .connected(let payload) = state {
            return payload
        }
        return nil
    }
    
    func setState(_ newState: CastSessionState) {
        state = newState
        isActive = !isIdle
    }
    
    private var isIdle: Bool {
        if case .idle = state {
            return true
        }
        return false
    }
}

// MARK: - Real Cast Pairing Service

class RealCastPairingService {
    private let baseURL = "https://api.ente.io"
    private var pollingTimer: Timer?
    private var lastLoggedMessages: [String: Date] = [:]
    private let logThrottleInterval: TimeInterval = 5.0 // 5 seconds
    private var isPolling: Bool = false
    private var isFetchingPayload: Bool = false
    private var hasDeliveredPayload: Bool = false
    private var pollingStartTime: Date?
    private let initialPollingInterval: TimeInterval = 2.0 // 2 seconds initially
    private let extendedPollingInterval: TimeInterval = 5.0 // 5 seconds after 60 seconds
    private let pollingIntervalSwitchTime: TimeInterval = 60.0 // Switch after 60 seconds
    private var hasLoggedIntervalSwitch: Bool = false
    
    private func getCurrentPollingInterval() -> TimeInterval {
        guard let startTime = pollingStartTime else { return initialPollingInterval }
        let elapsed = Date().timeIntervalSince(startTime)
        let newInterval = elapsed >= pollingIntervalSwitchTime ? extendedPollingInterval : initialPollingInterval
        
        // Log when switching to extended interval for the first time
        if elapsed >= pollingIntervalSwitchTime && newInterval == extendedPollingInterval && !hasLoggedIntervalSwitch {
            print("🕐 Switched to extended polling interval (\(extendedPollingInterval)s) after \(Int(elapsed))s")
            hasLoggedIntervalSwitch = true
        }
        
        return newInterval
    }
    
    // Generate real X25519 keypair using EnteCrypto
    private func generateKeyPair() -> (publicKey: Data, privateKey: Data) {
        let keys = EnteCrypto.generateCastKeyPair()
        return (
            publicKey: Data(base64Encoded: keys.publicKey)!,
            privateKey: Data(base64Encoded: keys.privateKey)!
        )
    }
    
    func registerDevice() async throws -> CastDevice {
        print("🔑 Generating real X25519 keypair...")
        let keys = generateKeyPair()
        let publicKeyBase64 = keys.publicKey.base64EncodedString()
        
        print("📡 Registering device with Ente production server...")
        print("🌐 POST \(baseURL)/cast/device-info")
        
        let url = URL(string: "\(baseURL)/cast/device-info")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["publicKey": publicKeyBase64]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CastError.networkError("Invalid response")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        
        let deviceResponse = try JSONDecoder().decode(DeviceRegistrationResponse.self, from: data)
        
        print("✅ Device registered! Code from server: \(deviceResponse.deviceCode)")
        
        return CastDevice(
            deviceCode: deviceResponse.deviceCode,
            publicKey: keys.publicKey,
            privateKey: keys.privateKey
        )
    }
    
    func startPolling(device: CastDevice, onPayloadReceived: @escaping (CastPayload) -> Void, onError: @escaping (Error) -> Void) {
        guard !hasDeliveredPayload else { return }
        guard !isPolling else { return }
        print("🔍 Starting real polling of Ente production server...")
        pollingTimer?.invalidate()
        isPolling = true
        pollingStartTime = Date()
        hasLoggedIntervalSwitch = false
        
        scheduleNextPoll(device: device, onPayloadReceived: onPayloadReceived, onError: onError)
    }
    
    private func scheduleNextPoll(device: CastDevice, onPayloadReceived: @escaping (CastPayload) -> Void, onError: @escaping (Error) -> Void) {
        guard isPolling && !hasDeliveredPayload else { return }
        
        let currentInterval = getCurrentPollingInterval()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: currentInterval, repeats: false) { [weak self] _ in
            Task {
                await self?.checkForPayload(device: device, onPayloadReceived: onPayloadReceived, onError: onError)
                // Schedule next poll after this one completes
                await MainActor.run {
                    self?.scheduleNextPoll(device: device, onPayloadReceived: onPayloadReceived, onError: onError)
                }
            }
        }
    }
    
    private func checkForPayload(device: CastDevice, onPayloadReceived: @escaping (CastPayload) -> Void, onError: @escaping (Error) -> Void) async {
        if hasDeliveredPayload { return }
        if isFetchingPayload { return }
        isFetchingPayload = true
        defer { isFetchingPayload = false }
        do {
            let url = URL(string: "\(baseURL)/cast/cast-data/\(device.deviceCode)")!
            print("📡 GET \(url.absoluteString)")
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CastError.networkError("Invalid response")
            }
            
            if httpResponse.statusCode == 404 {
                // No payload available yet - this is expected
                print("⏳ No encrypted payload available yet")
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                throw CastError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8))
            }
            
            let castDataResponse = try JSONDecoder().decode(CastDataResponse.self, from: data)
            
            guard let encryptedData = castDataResponse.encCastData else {
                print("⏳ No encrypted payload in response yet")
                return
            }
            
            print("🔓 Received encrypted payload! Decrypting...")
            
            // Decrypt the payload using our private key
            let payload = try await decryptPayload(encryptedData: encryptedData, privateKey: device.privateKey)
            
            print("✅ Successfully decrypted cast payload!")
            hasDeliveredPayload = true
            stopPolling()
            
            await MainActor.run {
                onPayloadReceived(payload)
            }
            
        } catch {
            print("❌ Polling error: \(error)")
            await MainActor.run {
                onError(error)
            }
        }
    }
    
    private func decryptPayload(encryptedData: String, privateKey: Data) async throws -> CastPayload {
        // Generate public key from private key for sealed box decryption
        let publicKey: Data
        do {
            let curve25519PrivateKey = try CryptoKit.Curve25519.KeyAgreement.PrivateKey(rawRepresentation: privateKey)
            publicKey = curve25519PrivateKey.publicKey.rawRepresentation
        } catch {
            throw CastError.decryptionError("Failed to derive public key from private key: \(error)")
        }
        
        // Use EnteCrypto for cast payload decryption
        do {
            let decryptedData = try EnteCrypto.decryptCastPayload(
                encryptedPayload: encryptedData,
                recipientPublicKey: publicKey.base64EncodedString(),
                recipientPrivateKey: privateKey.base64EncodedString()
            )
            
            // Handle potential base64 preprocessing from mobile client
            let finalData: Data
            if let base64String = String(data: decryptedData, encoding: .utf8),
               let jsonData = Data(base64Encoded: base64String) {
                finalData = jsonData
            } else {
                finalData = decryptedData
            }
            
            let payload = try JSONDecoder().decode(CastPayload.self, from: finalData)
            return payload
        } catch {
            throw CastError.decryptionError("EnteCrypto cast payload decryption failed: \(error)")
        }
    }
    
    func stopPolling() {
        guard isPolling else { return }
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
        pollingStartTime = nil
        print("⏹️ Stopped polling production server")
    }
    
    func resetForNewSession() {
        print("🔄 Resetting pairing service for new session")
        stopPolling()
        hasDeliveredPayload = false
        hasLoggedIntervalSwitch = false
    }
}