package io.ente.ensu.data.network

class ApiException(val code: Int, message: String?) : Exception(message)

class InvalidResponseException(message: String = "Invalid server response") : Exception(message)
