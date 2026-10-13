import "package:ente_components/ente_components.dart";
import "package:ente_strings/ente_strings.dart";
import "package:flutter/material.dart";
import "package:photos/ui/viewer/gallery/gallery_layout_controls.dart";

class GalleryLayoutSettings extends StatelessWidget {
  const GalleryLayoutSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomSheetComponent(
      title: context.strings.layout,
      content: const GalleryLayoutControls(keepHeight: true),
    );
  }
}

class FloatingGalleryLayoutButton extends StatelessWidget {
  const FloatingGalleryLayoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.strings.layout,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.componentColors.fillLight,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconButtonComponent(
          icon: const Icon(Icons.more_vert_outlined),
          variant: IconButtonComponentVariant.circular,
          size: 48,
          tooltip: context.strings.layout,
          shouldSurfaceExecutionStates: false,
          onTap: () => showBottomSheetComponent<void>(
            context: context,
            builder: (_) => const GalleryLayoutSettings(),
          ),
        ),
      ),
    );
  }
}
