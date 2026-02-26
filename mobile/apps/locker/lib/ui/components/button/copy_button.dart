import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/l10n/l10n.dart";

class CopyButton extends StatefulWidget {
  final String url;

  const CopyButton({
    super.key,
    required this.url,
  });

  @override
  State<CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<CopyButton> {
  bool _isCopied = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return IconButton(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: widget.url));
        setState(() {
          _isCopied = true;
        });
        // Reset the state after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isCopied = false;
            });
          }
        });
      },
      icon: Icon(
        _isCopied ? Icons.check : Icons.copy,
        size: 16,
        color: _isCopied ? colorScheme.primary500 : colorScheme.primary500,
      ),
      iconSize: 16,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.all(4),
      tooltip: _isCopied
          ? context.l10n.linkCopiedToClipboard
          : context.l10n.copyLink,
    );
  }
}
