package io.ente.ensu.data.network

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
object EmptyResponse

@Serializable
data class ErrorResponse(
    @SerialName("code") val code: String? = null,
    @SerialName("message") val message: String
)
