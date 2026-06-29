import Foundation

typealias EnsuRustModelPreset = ConfigModelPreset
typealias EnsuRustDefaultsValue = ConfigDefaults

enum EnsuRustDefaults {
    static let shared: EnsuRustDefaultsValue = configDefaults()
}
