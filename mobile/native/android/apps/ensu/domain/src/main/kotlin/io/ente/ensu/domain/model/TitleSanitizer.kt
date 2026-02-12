package io.ente.ensu.domain.model

private val TitleLineBreakRegex = Regex("[\r\n\t]+")
private val TitleWhitespaceRegex = Regex("\\s+")

internal fun sanitizeTitleText(text: String): String {
    return text
        .replace(TitleLineBreakRegex, " ")
        .replace(TitleWhitespaceRegex, " ")
        .trim()
}
