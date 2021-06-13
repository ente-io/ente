package top.kikt.imagescanner.core.cache

import top.kikt.imagescanner.core.entity.AssetEntity

class CacheContainer {

    // key is path
    // value is asset entity
    private val assetMap = HashMap<String, AssetEntity>()

    fun putAsset(assetEntity: AssetEntity) {
        assetMap[assetEntity.id] = assetEntity
    }

    fun getAsset(id: String): AssetEntity? {
        return assetMap[id]
    }

    fun clearCache() {
        assetMap.clear()
    }
}