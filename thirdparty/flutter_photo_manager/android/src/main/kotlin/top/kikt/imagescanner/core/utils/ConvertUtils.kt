package top.kikt.imagescanner.core.utils

import android.provider.MediaStore
import top.kikt.imagescanner.AssetType
import top.kikt.imagescanner.core.entity.*

/// create 2019-09-05 by cai


object ConvertUtils {
  fun convertToGalleryResult(list: List<GalleryEntity>): Map<String, Any> {
    val data = ArrayList<Map<String, Any>>()

    for (entity in list) {
      val element = mutableMapOf<String, Any>(
          "id" to entity.id,
          "name" to entity.name,
          "length" to entity.length,
          "isAll" to entity.isAll
      )

      if (entity.modifiedDate != null) {
        element["modified"] = entity.modifiedDate!!
      }

      if (entity.length > 0) {
        data.add(element)
      }
    }

    return mapOf(
        "data" to data
    )
  }

  fun convertToAssetResult(list: List<AssetEntity>): Map<String, Any?> {
    val data = ArrayList<Map<String, Any?>>()

    for (entity in list) {
      val element = hashMapOf(
          "id" to entity.id,
          "duration" to entity.duration / 1000,
          "type" to entity.type,
          "createDt" to entity.createDt,
          "width" to entity.width,
          "height" to entity.height,
          "orientation" to entity.orientation,
          "modifiedDt" to entity.modifiedDate,
          "lat" to entity.lat,
          "lng" to entity.lng,
          "title" to entity.displayName,
          "relativePath" to entity.relativePath
      )

      if (entity.mimeType != null) {
        element["mimeType"] = entity.mimeType
      }

      data.add(element)
    }

    return mapOf(
        "data" to data
    )
  }

  fun convertToAssetResult(entity: AssetEntity): Map<String, Any?> {

    val data = hashMapOf(
        "id" to entity.id,
        "duration" to entity.duration / 1000,
        "type" to entity.type,
        "createDt" to entity.createDt,
        "width" to entity.width,
        "height" to entity.height,
        "modifiedDt" to entity.modifiedDate,
        "lat" to entity.lat,
        "lng" to entity.lng,
        "title" to entity.displayName,
        "relativePath" to entity.relativePath
    )

    if (entity.mimeType != null) {
      data["mimeType"] = entity.mimeType
    }

    return mapOf(
        "data" to data
    )
  }

  private fun getOptionWithKey(map: Map<*, *>, key: String): FilterCond {
    if (map.containsKey(key)) {
      val value = map[key]
      if (value is Map<*, *>) {
        return convertToOption(value)
      }
    }
    return FilterCond()
  }

  fun getOptionFromType(map: Map<*, *>, type: AssetType): FilterCond {
    return when (type) {
      AssetType.Video -> {
        getOptionWithKey(map, "video")
      }
      AssetType.Image -> {
        getOptionWithKey(map, "image")
      }
      AssetType.Audio -> {
        getOptionWithKey(map, "audio")
      }
    }
  }

  private fun convertToOption(map: Map<*, *>): FilterCond {
    val filterOptions = FilterCond()
    filterOptions.isShowTitle = map["title"] as Boolean

    val sizeConstraint = FilterCond.SizeConstraint()
    filterOptions.sizeConstraint = sizeConstraint
    val sizeMap = map["size"] as Map<*, *>
    sizeConstraint.minWidth = sizeMap["minWidth"] as Int
    sizeConstraint.maxWidth = sizeMap["maxWidth"] as Int
    sizeConstraint.minHeight = sizeMap["minHeight"] as Int
    sizeConstraint.maxHeight = sizeMap["maxHeight"] as Int
    sizeConstraint.ignoreSize = sizeMap["ignoreSize"] as Boolean

    val durationConstraint = FilterCond.DurationConstraint()
    filterOptions.durationConstraint = durationConstraint
    val durationMap = map["duration"] as Map<*, *>
    durationConstraint.min = (durationMap["min"] as Int).toLong()
    durationConstraint.max = (durationMap["max"] as Int).toLong()

    return filterOptions
  }

  fun convertToDateCond(map: Map<*, *>): DateCond {
    val min = map["min"].toString().toLong()
    val max = map["max"].toString().toLong()
    val ignore = map["ignore"].toString().toBoolean()
    return DateCond(min, max, ignore)
  }

  fun convertFilterOptionsFromMap(map: Map<*, *>): FilterOption {
    return FilterOption(map)
  }

  fun convertOrderByCondList(orders: List<*>): List<OrderByCond> {
    val list = ArrayList<OrderByCond>()

    for (order in orders) {
      val map = order as Map<*, *>
      val keyIndex = map["type"] as Int
      val asc = map["asc"] as Boolean

      val key = when (keyIndex) {
        0 -> MediaStore.MediaColumns.DATE_ADDED
        1 -> MediaStore.MediaColumns.DATE_MODIFIED
        else -> null
      } ?: continue

      list.add(OrderByCond(key, asc))
    }

    return list
  }
}