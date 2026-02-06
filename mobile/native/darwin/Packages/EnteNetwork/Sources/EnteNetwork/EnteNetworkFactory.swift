import Foundation
import EnteCore
import Logging

// MARK: - Ente Network Factory

public class EnteNetworkFactory {
    private let apiClient: APIClient
    public let configuration: NetworkConfiguration
    private let logger = Logger(label: "EnteNetworkFactory")
    
    public init(
        configuration: NetworkConfiguration = .default,
        app: EnteApp,
        authTokenProvider: AuthTokenProvider? = nil
    ) {
        self.configuration = configuration
        self.apiClient = APIClient(
            configuration: configuration,
            app: app,
            authTokenProvider: authTokenProvider
        )
        
        logger.info("Initialized network factory for app: \(app.displayName)")
        logger.info("API endpoint: \(configuration.apiEndpoint)")
        if let castEndpoint = configuration.castEndpoint {
            logger.info("Cast endpoint: \(castEndpoint)")
        }
    }
    
    // MARK: - Convenience Initializers
    
    public convenience init(
        environment: EnteEnvironment,
        app: EnteApp,
        authTokenProvider: AuthTokenProvider? = nil
    ) {
        self.init(
            configuration: environment.networkConfiguration,
            app: app,
            authTokenProvider: authTokenProvider
        )
    }
    
    public convenience init(
        customEndpoint: URL,
        app: EnteApp,
        authTokenProvider: AuthTokenProvider? = nil
    ) {
        let config = NetworkConfiguration.selfHosted(baseURL: customEndpoint)
        self.init(
            configuration: config,
            app: app,
            authTokenProvider: authTokenProvider
        )
    }
    
    // MARK: - Gateway Access
    
    /// Core authentication gateway for sign-in flows
    public lazy var authentication = AuthenticationGateway(client: apiClient)
    
    /// TV/Cast specific gateway - uses dedicated cast endpoints
    public lazy var cast = CastGateway(client: apiClient)
    
    // TODO: Add other gateways as needed
    // public lazy var users = UserGateway(client: apiClient)
    // public lazy var files = FilesGateway(client: apiClient)
    // public lazy var collections = CollectionsGateway(client: apiClient)
    // public lazy var billing = BillingGateway(client: apiClient)
    // public lazy var trash = TrashGateway(client: apiClient)
    // public lazy var storageBonus = StorageBonusGateway(client: apiClient)
    // public lazy var family = FamilyGateway(client: apiClient)
    // public lazy var remoteStore = RemoteStoreGateway(client: apiClient)
    // public lazy var push = PushGateway(client: apiClient)
    // public lazy var keyExchange = KeyExchangeGateway(client: apiClient)
    
    // MARK: - Configuration Updates
    
    public func updateConfiguration(_ newConfiguration: NetworkConfiguration) {
        // This would require updating the APIClient's configuration
        // For now, we recommend creating a new factory instance
        logger.warning("Configuration updates require creating a new NetworkFactory instance")
    }
}