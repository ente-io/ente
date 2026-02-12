package io.ente.ensu.domain.model

data class AuthState(
    val isLoggedIn: Boolean = false,
    val email: String? = null
)
