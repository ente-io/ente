package io.ente.ensu.chat

import android.icu.lang.UCharacter
import android.icu.lang.UCharacterDirection
import android.icu.text.BreakIterator
import android.text.TextDirectionHeuristics
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.ParagraphStyle
import androidx.compose.ui.text.input.OffsetMapping
import androidx.compose.ui.text.input.TransformedText
import androidx.compose.ui.text.input.VisualTransformation
import java.util.Locale
import java.util.TreeSet

internal object LongMessageVisualTransformation : VisualTransformation {
    private const val LongParagraphLength = 8192
    private const val LayoutSectionLength = 2048

    override fun filter(text: AnnotatedString): TransformedText {
        val breaks = TreeSet<Int>()
        var characters: BreakIterator? = null
        var words: BreakIterator? = null
        var start = 0
        while (start < text.length) {
            val end = text.text.indexOf('\n', start).let { if (it < 0) text.length else it }
            if (
                end - start > LongParagraphLength &&
                    !hasDirectionSensitiveText(text.text, start, end)
            ) {
                val iterator =
                    characters
                        ?: BreakIterator.getCharacterInstance(Locale.ROOT).also {
                            it.setText(text.text)
                            characters = it
                        }
                val direction = paragraphDirection(text.text, start, end)
                val wordIterator =
                    words
                        ?: BreakIterator.getWordInstance(Locale.getDefault()).also {
                            it.setText(text.text)
                            words = it
                        }
                var previousWordBoundary = start
                var nextWordBoundary = wordIterator.following(start)
                val paragraphBreaks = mutableListOf<Int>()
                var sectionStart = start
                var preservesDirection = true
                while (sectionStart < end) {
                    val boundary =
                        if (end - sectionStart > LayoutSectionLength) {
                            val target = sectionStart + LayoutSectionLength
                            while (
                                nextWordBoundary != BreakIterator.DONE && nextWordBoundary <= target
                            ) {
                                if (
                                    iterator.isBoundary(nextWordBoundary) &&
                                        (!isPunctuation(
                                            Character.codePointBefore(text.text, nextWordBoundary)
                                        ) ||
                                            !isPunctuation(
                                                Character.codePointAt(text.text, nextWordBoundary)
                                            ))
                                ) {
                                    previousWordBoundary = nextWordBoundary
                                }
                                nextWordBoundary = wordIterator.next()
                            }
                            if (previousWordBoundary > sectionStart) {
                                previousWordBoundary
                            } else {
                                iterator.following(target - 1).let {
                                    if (it == BreakIterator.DONE || it >= end) end else it
                                }
                            }
                        } else {
                            end
                        }
                    if (paragraphDirection(text.text, sectionStart, boundary) != direction) {
                        preservesDirection = false
                        break
                    }
                    if (boundary < end) paragraphBreaks.add(boundary)
                    sectionStart = boundary
                }
                if (preservesDirection) breaks.addAll(paragraphBreaks)
            }
            start = end + 1
        }
        if (breaks.isEmpty()) return TransformedText(text, OffsetMapping.Identity)

        text.paragraphStyles.forEach {
            breaks.add(it.start)
            breaks.add(it.end)
        }
        breaks.add(text.length)
        val styled = AnnotatedString.Builder()
        var previous = 0
        breaks.forEach { end ->
            if (end > previous) {
                val section = text.subSequence(previous, end)
                styled.append(section)
                if (section.paragraphStyles.isEmpty()) {
                    styled.addStyle(ParagraphStyle(), previous, end)
                }
            }
            previous = end
        }
        return TransformedText(styled.toAnnotatedString(), OffsetMapping.Identity)
    }

    private fun isPunctuation(codePoint: Int): Boolean =
        when (Character.getType(codePoint)) {
            Character.CONNECTOR_PUNCTUATION.toInt(),
            Character.DASH_PUNCTUATION.toInt(),
            Character.END_PUNCTUATION.toInt(),
            Character.FINAL_QUOTE_PUNCTUATION.toInt(),
            Character.INITIAL_QUOTE_PUNCTUATION.toInt(),
            Character.OTHER_PUNCTUATION.toInt(),
            Character.START_PUNCTUATION.toInt() -> true
            else -> false
        }

    private fun hasDirectionSensitiveText(text: String, start: Int, end: Int): Boolean {
        var index = start
        while (index < end) {
            val codePoint = Character.codePointAt(text, index)
            when (UCharacter.getDirection(codePoint)) {
                UCharacterDirection.RIGHT_TO_LEFT,
                UCharacterDirection.RIGHT_TO_LEFT_ARABIC,
                UCharacterDirection.ARABIC_NUMBER,
                UCharacterDirection.LEFT_TO_RIGHT_EMBEDDING,
                UCharacterDirection.LEFT_TO_RIGHT_OVERRIDE,
                UCharacterDirection.RIGHT_TO_LEFT_EMBEDDING,
                UCharacterDirection.RIGHT_TO_LEFT_OVERRIDE,
                UCharacterDirection.POP_DIRECTIONAL_FORMAT,
                UCharacterDirection.LEFT_TO_RIGHT_ISOLATE.toInt(),
                UCharacterDirection.RIGHT_TO_LEFT_ISOLATE.toInt(),
                UCharacterDirection.FIRST_STRONG_ISOLATE.toInt(),
                UCharacterDirection.POP_DIRECTIONAL_ISOLATE.toInt() -> return true
            }
            index += Character.charCount(codePoint)
        }
        return false
    }

    private fun paragraphDirection(text: String, start: Int, end: Int): Pair<Boolean, Boolean> =
        TextDirectionHeuristics.FIRSTSTRONG_LTR.isRtl(text, start, end - start) to
            TextDirectionHeuristics.FIRSTSTRONG_RTL.isRtl(text, start, end - start)
}
