@file:Suppress("PackageDirectoryMismatch")

package io.ente.screensaver.ente

import android.content.Context
import io.ente.screensaver.R

fun EntePublicAlbumUrlParser.ParseResult.Error.toDisplayMessage(context: Context): String {
    val detailText = this.detail
        ?.takeIf { it.isNotBlank() }
        ?: context.getString(R.string.setup_error_unknown_detail)

    return when (this.code) {
        EntePublicAlbumUrlParser.ParseResult.Error.Code.EMPTY_URL ->
            context.getString(R.string.setup_error_empty_url)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.INVALID_URL ->
            context.getString(R.string.setup_error_invalid_url)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.MISSING_ACCESS_TOKEN ->
            context.getString(R.string.setup_error_missing_access_token)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.MISSING_COLLECTION_KEY ->
            context.getString(R.string.setup_error_missing_collection_key)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.INVALID_COLLECTION_KEY ->
            context.getString(R.string.setup_error_invalid_collection_key)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.INVALID_COLLECTION_KEY_LENGTH ->
            context.getString(R.string.setup_error_invalid_collection_key_length)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.FETCH_ALBUM_INFO_FAILED ->
            context.getString(R.string.setup_error_fetch_album_info, detailText)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.MISSING_PASSWORD_PARAMETERS ->
            context.getString(R.string.setup_error_missing_password_parameters)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.PASSWORD_HASH_DERIVATION_FAILED ->
            context.getString(R.string.setup_error_password_hash_derivation, detailText)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.INCORRECT_PASSWORD ->
            context.getString(R.string.setup_error_incorrect_password)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.PASSWORD_VERIFICATION_FAILED ->
            context.getString(R.string.setup_error_password_verification, detailText)

        EntePublicAlbumUrlParser.ParseResult.Error.Code.PASSWORD_REQUIRED ->
            context.getString(R.string.setup_error_password_required)
    }
}
