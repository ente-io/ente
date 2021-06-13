package top.kikt.imagescanner.core.utils

/// create 2020-03-20 by cai
object RequestTypeUtils {
  
  private const val typeImage = 1
  private const val typeVideo = 1.shl(1)
  private const val typeAudio = 1.shl(2)
  
  fun containsImage(type: Int): Boolean {
    return checkType(type, typeImage)
  }
  
  fun containsVideo(type: Int): Boolean {
    return checkType(type, typeVideo)
  }
  
  fun containsAudio(type: Int): Boolean {
    return checkType(type, typeAudio)
  }
  
  private fun checkType(type: Int, targetType: Int): Boolean {
    return type and targetType == targetType
  }
}