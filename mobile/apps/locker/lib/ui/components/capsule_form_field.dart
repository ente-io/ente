import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class CapsuleDisplayField extends StatefulWidget {
  const CapsuleDisplayField({
    super.key,
    required this.labelText,
    required this.value,
    this.isSecret = false,
    this.maxLines,
    this.lineHeight,
    this.onCopy,
    this.contentPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  });

  final String labelText;
  final String value;
  final bool isSecret;
  final int? maxLines;
  final double? lineHeight;
  final VoidCallback? onCopy;
  final EdgeInsets contentPadding;

  @override
  State<CapsuleDisplayField> createState() => _CapsuleDisplayFieldState();
}

class _CapsuleDisplayFieldState extends State<CapsuleDisplayField> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final displayValue = (widget.isSecret && !_isVisible)
        ? '•' * widget.value.length
        : widget.value;
    final textLineHeight =
        widget.lineHeight ?? ((widget.maxLines ?? 1) > 1 ? 1.5 : 1.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText.isNotEmpty) ...[
          Text(
            widget.labelText,
            style: textTheme.body,
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: widget.contentPadding,
            child: Row(
              crossAxisAlignment: (widget.maxLines ?? 1) > 1
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: (widget.isSecret && !_isVisible)
                      ? Text(
                          displayValue,
                          style:
                              textTheme.body.copyWith(height: textLineHeight),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                        )
                      : SelectableText(
                          displayValue,
                          style:
                              textTheme.body.copyWith(height: textLineHeight),
                          maxLines: widget.maxLines,
                        ),
                ),
                if (widget.isSecret) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isVisible = !_isVisible;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.fillBase.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isVisible ? Icons.visibility : Icons.visibility_off,
                        size: 16,
                        semanticLabel:
                            _isVisible ? 'hide_password' : 'show_password',
                        color: colorScheme.textMuted,
                      ),
                    ),
                  ),
                ],
                if (widget.onCopy != null) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: widget.onCopy,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.fillBase.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.copy,
                        size: 16,
                        color: colorScheme.textMuted,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
