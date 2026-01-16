import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:url_launcher/url_launcher_string.dart";

/// A row of social media icon buttons
class SocialIconsRow extends StatelessWidget {
  const SocialIconsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIconButton(
          icon: HugeIcons.strokeRoundedDiscord,
          url: "https://ente.io/discord",
          color: colorScheme.textMuted,
        ),
        const SizedBox(width: 8),
        _SocialIconButton(
          icon: HugeIcons.strokeRoundedYoutube,
          url: "https://youtube.com/@enteio",
          color: colorScheme.textMuted,
        ),
        const SizedBox(width: 8),
        _SocialIconButton(
          icon: HugeIcons.strokeRoundedGithub,
          url: "https://github.com/ente-io",
          color: colorScheme.textMuted,
        ),
        const SizedBox(width: 8),
        _SocialIconButton(
          icon: HugeIcons.strokeRoundedNewTwitter,
          url: "https://twitter.com/enteio",
          color: colorScheme.textMuted,
        ),
        const SizedBox(width: 8),
        _SocialIconButton(
          icon: HugeIcons.strokeRoundedMastodon,
          url: "https://fosstodon.org/@ente",
          color: colorScheme.textMuted,
        ),
        const SizedBox(width: 8),
        _SocialIconButton(
          icon: HugeIcons.strokeRoundedReddit,
          url: "https://reddit.com/r/enteio",
          color: colorScheme.textMuted,
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final dynamic icon;
  final String url;
  final Color color;

  const _SocialIconButton({
    required this.icon,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        launchUrlString(
          url,
          mode: LaunchMode.externalApplication,
        );
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
