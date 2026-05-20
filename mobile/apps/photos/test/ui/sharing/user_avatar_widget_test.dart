import 'package:flutter_test/flutter_test.dart';
import 'package:photos/ui/sharing/album_share_info_widget.dart';
import 'package:photos/ui/sharing/more_count_badge.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';

void main() {
  test('AvatarType exposes Figma-aligned xs and small sizes', () {
    expect(getAvatarSize(AvatarType.xs), 16);
    expect(getAvatarSize(AvatarType.small), 20);
    expect(getAvatarSize(AvatarType.medium), 24);
    expect(getAvatarSize(AvatarType.regular), 28);
    expect(getAvatarSize(AvatarType.large), 32);
    expect(getAvatarSize(AvatarType.huge), 56);
  });

  test('share badges keep xs separate from small', () {
    expect(moreCountTypeFromAvatarType(AvatarType.xs), MoreCountType.xs);
    expect(moreCountTypeFromAvatarType(AvatarType.small), MoreCountType.small);
  });
}
