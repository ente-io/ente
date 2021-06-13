package top.kikt.imagescanner.core.entity

/// create 2019-09-05 by cai
data class GalleryEntity(
    val id: String,
    val name: String,
    var length: Int,
    val typeInt: Int,
    var isAll: Boolean = false,
    var modifiedDate: Long? = null
)