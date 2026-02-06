import Foundation
import Logging
import EnteCrypto
import EnteNetwork

public class CastPairingService {
    private let castGateway: CastGateway
    private let logger = Logger(label: "CastPairingService")
    private var pollingTask: Task<Void, Never>?
    
    public init(castGateway: CastGateway) {
        self.castGateway = castGateway
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - Device Registration
    
    public func registerDevice() async throws -> CastDevice {
        logger.info("Starting device registration")
        
        // Generate real X25519 keypair for this session
        let keyPair = EnteCrypto.generateKeyPair()
        logger.debug("Generated keypair for cast session")
        
        // Register with the server to get a device code
        let response = try await castGateway.registerDevice()
        
        logger.info("Device registered successfully with code: \(response.code)")
        
        return CastDevice(
            deviceCode: response.code,
            publicKey: keyPair.publicKey,
            privateKey: keyPair.privateKey
        )
    }
    
    // MARK: - Polling for Cast Payload
    
    public func startPolling(
        device: CastDevice,
        onPayloadReceived: @escaping (CastPayload) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        logger.info("Starting polling for device code: \(device.deviceCode)")
        
        stopPolling() // Stop any existing polling
        
        pollingTask = Task {
            await pollForPayload(
                device: device,
                onPayloadReceived: onPayloadReceived,
                onError: onError
            )
        }
    }
    
    public func stopPolling() {
        logger.info("Stopping polling")
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    private func pollForPayload(
        device: CastDevice,
        onPayloadReceived: @escaping (CastPayload) -> Void,
        onError: @escaping (Error) -> Void
    ) async {
        let pollInterval: TimeInterval = 2.0 // Poll every 2 seconds
        let maxAttempts = 150 // 5 minutes total (150 * 2 seconds)
        var attempts = 0
        
        while !Task.isCancelled && attempts < maxAttempts {
            do {
                attempts += 1
                
                // Check if payload is available
                if let payload = try await checkForPayload(device: device) {
                    logger.info("Payload received successfully")
                    await MainActor.run {
                        onPayloadReceived(payload)
                    }
                    return
                }
                
                // Wait before next poll
                try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                
            } catch {
                logger.error("Error during polling: \(error)")
                await MainActor.run {
                    onError(error)
                }
                return
            }
        }
        
        if attempts >= maxAttempts {
            logger.warning("Polling timeout reached")
            await MainActor.run {
                onError(EnteError.configurationError("Pairing timeout"))
            }
        }
    }
    
    private func checkForPayload(device: CastDevice) async throws -> CastPayload? {
        // This implements the web app's getCastPayload function
        // Check if encrypted payload is available and decrypt it
        
        do {
            let castData = try await castGateway.getCastData(deviceCode: device.deviceCode)
            
            // The response from museum contains encrypted payload data
            // We need to implement decryption similar to web implementation
            
            // TODO: Once the server API returns encrypted data, implement decryption:
            // 1. Get encrypted payload from castData
            // 2. Decrypt using our private key: EnteCrypto.sealedBoxOpen(encryptedData, publicKey, privateKey)
            // 3. Parse the decrypted JSON to get CastPayload
            
            // For now, convert from network model to our model
            // This assumes the server returns the raw data (not encrypted)
            return CastPayload(
                collectionID: castData.collectionID,
                collectionKey: "temp-key", // This should come from decrypted payload
                castToken: castData.castToken
            )
        } catch {
            // If the error is "not found" or similar, it means no payload yet
            if let enteError = error as? EnteError,
               case .serverError(let code, _) = enteError,
               code == 404 {
                return nil // No payload available yet
            }
            throw error // Re-throw other errors
        }
    }
}