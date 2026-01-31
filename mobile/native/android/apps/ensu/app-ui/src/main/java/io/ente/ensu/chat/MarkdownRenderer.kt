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
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import io.ente.ensu.designsystem.EnsuColor
import io.ente.ensu.designsystem.EnsuCornerRadius
import io.ente.ensu.designsystem.HugeIcons
import io.ente.ensu.designsystem.EnsuSpacing
import io.ente.ensu.designsystem.EnsuTypography

@Composable
fun MarkdownView(
    markdown: String,
    enableSelection: Boolean = true,
    trailingCursor: Boolean = false
) {
    val blocks = remember(markdown) { MarkdownParser.parse(markdown) }
    val content = @Composable {
        Column(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.md.dp)) {
            blocks.forEachIndexed { index, block ->
                key(index) {
                    val appendCursor = trailingCursor && index == blocks.lastIndex
                    when (block) {
                        is MarkdownBlock.Heading -> {
                            Text(
                                text = markdownAnnotatedText(block.text, appendCursor),
                                style = headingStyle(block.level),
                                color = EnsuColor.textPrimary()
                            )
                        }
                        is MarkdownBlock.Paragraph -> {
                            Text(
                                text = markdownAnnotatedText(block.text, appendCursor),
                                style = EnsuTypography.message,
                                color = EnsuColor.textPrimary()
                            )
                        }
                        is MarkdownBlock.BlockQuote -> {
                            BlockQuoteView(text = block.text, appendCursor = appendCursor)
                        }
                        is MarkdownBlock.Code -> {
                            CodeBlockView(code = block.text)
                            if (appendCursor) {
                                TrailingCursor()
                            }
                        }
                        is MarkdownBlock.Math -> {
                            MathBlockView(text = block.text)
                            if (appendCursor) {
                                TrailingCursor()
                            }
                        }
                        is MarkdownBlock.ListItems -> {
                            Column(verticalArrangement = Arrangement.spacedBy(EnsuSpacing.xs.dp)) {
                                block.items.forEachIndexed { itemIndex, item ->
                                    key(itemIndex) {
                                        val itemCursor = appendCursor && itemIndex == block.items.lastIndex
                                        Row(
                                            verticalAlignment = Alignment.Top,
                                            horizontalArrangement = Arrangement.spacedBy(EnsuSpacing.sm.dp)
                                        ) {
                                            Text(
                                                text = "•",
                                                style = EnsuTypography.message,
                                                color = EnsuColor.textPrimary()
                                            )
                                            Text(
                                                text = markdownAnnotatedText(item, itemCursor),
                                                style = EnsuTypography.message,
                                                color = EnsuColor.textPrimary()
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        MarkdownBlock.Divider -> {
                            Divider(color = EnsuColor.border())
                            if (appendCursor) {
                                TrailingCursor()
                            }
                        }
                    }
                }
            }
        }
    }

    if (enableSelection) {
        SelectionContainer {
            content()
        }
    } else {
        content()
    }
}

@Composable
private fun BlockQuoteView(text: String, appendCursor: Boolean = false) {
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
            text = markdownAnnotatedText(text, appendCursor),
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
                    end = (EnsuSpacing.cardPadding + 32).dp,
                    top = EnsuSpacing.cardPadding.dp,
                    bottom = (EnsuSpacing.cardPadding + 32).dp
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
                .align(Alignment.BottomEnd)
                .padding(EnsuSpacing.xs.dp)
                .size(28.dp)
        ) {
            Icon(
                painter = painterResource(HugeIcons.Copy01Icon),
                contentDescription = "Copy code",
                tint = EnsuColor.textMuted(),
                modifier = Modifier.size(16.dp)
            )
        }
    }
}

@Composable
private fun MathBlockView(text: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(EnsuColor.fillFaint(), RoundedCornerShape(EnsuCornerRadius.codeBlock.dp))
            .border(1.dp, EnsuColor.border(), RoundedCornerShape(EnsuCornerRadius.codeBlock.dp))
    ) {
        LaTeXView(
            latex = text,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun TrailingCursor() {
    Text(
        text = "▍",
        style = EnsuTypography.message,
        color = EnsuColor.textPrimary()
    )
}

private fun headingStyle(level: Int): TextStyle {
    val size = when (level) {
        1 -> 20.sp
        2 -> 18.sp
        else -> 16.sp
    }
    return EnsuTypography.message.copy(fontSize = size, fontWeight = FontWeight.SemiBold, lineHeight = (size.value + 6).sp)
}

private fun markdownAnnotatedText(text: String, appendCursor: Boolean = false): AnnotatedString {
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
        if (appendCursor) {
            append("▍")
        }
    }
}

private sealed class MarkdownBlock {
    data class Heading(val level: Int, val text: String) : MarkdownBlock()
    data class Paragraph(val text: String) : MarkdownBlock()
    data class BlockQuote(val text: String) : MarkdownBlock()
    data class Code(val text: String) : MarkdownBlock()
    data class Math(val text: String) : MarkdownBlock()
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
        val mathLines = mutableListOf<String>()
        var mathEndDelimiter: String? = null

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

        fun flushMath() {
            if (mathEndDelimiter != null) {
                if (mathLines.isNotEmpty()) {
                    blocks.add(MarkdownBlock.Math(mathLines.joinToString("\n")))
                }
                mathLines.clear()
                mathEndDelimiter = null
            }
        }

        fun startMath(endDelimiter: String, initialContent: String? = null) {
            flushParagraph()
            flushList()
            mathEndDelimiter = endDelimiter
            mathLines.clear()
            if (!initialContent.isNullOrBlank()) {
                mathLines.add(initialContent)
            }
        }

        fun isBracketMathLine(trimmed: String): Boolean {
            if (!trimmed.startsWith("[") || !trimmed.endsWith("]") || trimmed.length <= 2) {
                return false
            }
            if (trimmed.contains("](") || trimmed.contains("]:")) {
                return false
            }
            return true
        }

        for (line in lines) {
            val trimmed = line.trim()

            if (mathEndDelimiter != null) {
                val endDelimiter = mathEndDelimiter!!
                if (trimmed == endDelimiter) {
                    flushMath()
                    continue
                }
                if (endDelimiter != "]" && trimmed.endsWith(endDelimiter)) {
                    val content = trimmed.removeSuffix(endDelimiter).trimEnd()
                    if (content.isNotEmpty()) {
                        mathLines.add(content)
                    }
                    flushMath()
                    continue
                }
                mathLines.add(line)
                continue
            }

            if (trimmed == "\\[" || trimmed == "$$" || trimmed == "[") {
                val endDelimiter = when (trimmed) {
                    "\\[" -> "\\]"
                    "$$" -> "$$"
                    else -> "]"
                }
                startMath(endDelimiter)
                continue
            }

            if (trimmed.startsWith("\\[")) {
                val content = trimmed.removePrefix("\\[").trimStart()
                if (content.endsWith("\\]")) {
                    val inner = content.removeSuffix("\\]").trim()
                    blocks.add(MarkdownBlock.Math(inner))
                } else {
                    startMath("\\]", content)
                }
                continue
            }

            if (trimmed.startsWith("$$")) {
                val content = trimmed.removePrefix("$$").trimStart()
                if (content.endsWith("$$")) {
                    val inner = content.removeSuffix("$$").trim()
                    blocks.add(MarkdownBlock.Math(inner))
                } else {
                    startMath("$$", content)
                }
                continue
            }

            if (isBracketMathLine(trimmed)) {
                val inner = trimmed.removePrefix("[").removeSuffix("]").trim()
                blocks.add(MarkdownBlock.Math(inner))
                continue
            }

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
        flushMath()
        return blocks
    }
}
