package io.ente.ensu.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ContentCopy
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography

@Composable
fun MarkdownView(markdown: String) {
    val blocks = MarkdownParser.parse(markdown)
    SelectionContainer {
        Column(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)) {
            blocks.forEach { block ->
                when (block) {
                    is MarkdownBlock.Heading -> {
                        Text(
                            text = markdownAnnotatedText(block.text),
                            style = headingStyle(block.level),
                            color = EnsuColor.textPrimary()
                        )
                    }
                    is MarkdownBlock.Paragraph -> {
                        Text(
                            text = markdownAnnotatedText(block.text),
                            style = EnsuTypography.message,
                            color = EnsuColor.textPrimary()
                        )
                    }
                    is MarkdownBlock.BlockQuote -> {
                        BlockQuoteView(text = block.text)
                    }
                    is MarkdownBlock.Code -> {
                        CodeBlockView(code = block.text)
                    }
                    is MarkdownBlock.ListItems -> {
                        Column(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.xs.dp)) {
                            block.items.forEach { item ->
                                Row(verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)) {
                                    Text(text = "•", style = EnsuTypography.message, color = EnsuColor.textPrimary())
                                    Text(
                                        text = markdownAnnotatedText(item),
                                        style = EnsuTypography.message,
                                        color = EnsuColor.textPrimary()
                                    )
                                }
                            }
                        }
                    }
                    MarkdownBlock.Divider -> {
                        Divider(color = EnsuColor.border())
                    }
                }
            }
        }
    }
}

@Composable
private fun BlockQuoteView(text: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .height(IntrinsicSize.Min)
            .background(EnsuColor.fillFaint(), RoundedCornerShape(EnsuCornerRadius.card.dp))
            .padding(EnsuSpacing.cardPadding.dp)
    ) {
        Box(
            modifier = Modifier
                .fillMaxHeight()
                .width(3.dp)
                .background(EnsuColor.border())
        )
        Spacer(modifier = Modifier.width(EnsuSpacing.sm.dp))
        Text(
            text = markdownAnnotatedText(text),
            style = EnsuTypography.message,
            color = EnsuColor.textPrimary()
        )
    }
}

@Composable
private fun CodeBlockView(code: String) {
    val clipboard = LocalClipboardManager.current
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(EnsuColor.fillFaint(), RoundedCornerShape(EnsuCornerRadius.codeBlock.dp))
            .border(1.dp, EnsuColor.border(), RoundedCornerShape(EnsuCornerRadius.codeBlock.dp))
    ) {
        Row(
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(
                    start = EnsuSpacing.cardPadding.dp,
                    end = (EnsuSpacing.cardPadding + 28).dp,
                    top = EnsuSpacing.cardPadding.dp,
                    bottom = EnsuSpacing.cardPadding.dp
                )
        ) {
            Text(
                text = code,
                style = EnsuTypography.code,
                color = EnsuColor.textPrimary()
            )
        }

        IconButton(
            onClick = { clipboard.setText(AnnotatedString(code)) },
            modifier = Modifier
                .align(Alignment.TopEnd)
                .padding(EnsuSpacing.xs.dp)
                .size(28.dp)
        ) {
            Icon(
                imageVector = Icons.Outlined.ContentCopy,
                contentDescription = "Copy code",
                tint = EnsuColor.textMuted()
            )
        }
    }
}

private fun headingStyle(level: Int): TextStyle {
    val size = when (level) {
        1 -> 20.sp
        2 -> 18.sp
        else -> 16.sp
    }
    return EnsuTypography.message.copy(fontSize = size, fontWeight = FontWeight.SemiBold, lineHeight = (size.value + 6).sp)
}

private fun markdownAnnotatedText(text: String): AnnotatedString {
    val pattern = Regex("(\\*\\*[^*]+\\*\\*|`[^`]+`|\\*[^*]+\\*)")
    val codeFamily = EnsuTypography.code.fontFamily
    return buildAnnotatedString {
        var currentIndex = 0
        pattern.findAll(text).forEach { match ->
            val start = match.range.first
            val end = match.range.last + 1
            if (start > currentIndex) {
                append(text.substring(currentIndex, start))
            }
            val token = match.value
            when {
                token.startsWith("**") -> {
                    withStyle(SpanStyle(fontWeight = FontWeight.SemiBold)) {
                        append(token.removePrefix("**").removeSuffix("**"))
                    }
                }
                token.startsWith("`") -> {
                    withStyle(SpanStyle(fontFamily = codeFamily)) {
                        append(token.removePrefix("`").removeSuffix("`"))
                    }
                }
                token.startsWith("*") -> {
                    withStyle(SpanStyle(fontStyle = FontStyle.Italic)) {
                        append(token.removePrefix("*").removeSuffix("*"))
                    }
                }
            }
            currentIndex = end
        }
        if (currentIndex < text.length) {
            append(text.substring(currentIndex))
        }
    }
}

private sealed class MarkdownBlock {
    data class Heading(val level: Int, val text: String) : MarkdownBlock()
    data class Paragraph(val text: String) : MarkdownBlock()
    data class BlockQuote(val text: String) : MarkdownBlock()
    data class Code(val text: String) : MarkdownBlock()
    data class ListItems(val items: List<String>) : MarkdownBlock()
    data object Divider : MarkdownBlock()
}

private object MarkdownParser {
    fun parse(text: String): List<MarkdownBlock> {
        val blocks = mutableListOf<MarkdownBlock>()
        val segments = text.split("```")
        segments.forEachIndexed { index, segment ->
            if (index % 2 == 1) {
                val code = segment.trim()
                if (code.isNotEmpty()) {
                    blocks.add(MarkdownBlock.Code(code))
                }
            } else {
                blocks.addAll(parseTextBlocks(segment))
            }
        }
        return blocks
    }

    private fun parseTextBlocks(text: String): List<MarkdownBlock> {
        val lines = text.split("\n")
        val blocks = mutableListOf<MarkdownBlock>()
        val paragraph = mutableListOf<String>()
        val listItems = mutableListOf<String>()

        fun flushParagraph() {
            if (paragraph.isNotEmpty()) {
                blocks.add(MarkdownBlock.Paragraph(paragraph.joinToString("\n")))
                paragraph.clear()
            }
        }

        fun flushList() {
            if (listItems.isNotEmpty()) {
                blocks.add(MarkdownBlock.ListItems(listItems.toList()))
                listItems.clear()
            }
        }

        for (line in lines) {
            val trimmed = line.trim()
            if (trimmed.isEmpty()) {
                flushParagraph()
                flushList()
                continue
            }

            if (trimmed == "---" || trimmed == "***" || trimmed == "___") {
                flushParagraph()
                flushList()
                blocks.add(MarkdownBlock.Divider)
                continue
            }

            if (trimmed.startsWith("# ") || trimmed.startsWith("## ") || trimmed.startsWith("### ")) {
                flushParagraph()
                flushList()
                val level = trimmed.takeWhile { it == '#' }.length.coerceIn(1, 3)
                val headingText = trimmed.dropWhile { it == '#' || it == ' ' }
                blocks.add(MarkdownBlock.Heading(level, headingText))
                continue
            }

            if (trimmed.startsWith(">")) {
                flushParagraph()
                flushList()
                val quote = trimmed.dropWhile { it == '>' || it == ' ' }
                blocks.add(MarkdownBlock.BlockQuote(quote))
                continue
            }

            if (trimmed.startsWith("- ") || trimmed.startsWith("* ")) {
                flushParagraph()
                listItems.add(trimmed.drop(2))
                continue
            }

            val orderedMatch = Regex("^(\\d+)\\. ").find(trimmed)
            if (orderedMatch != null) {
                flushParagraph()
                listItems.add(trimmed.substring(orderedMatch.value.length))
                continue
            }

            paragraph.add(line)
        }

        flushParagraph()
        flushList()
        return blocks
    }
}
