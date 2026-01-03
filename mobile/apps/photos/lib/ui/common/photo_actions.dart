// mobile/lib/ui/common/photo_actions.dart (Conceptual)

ListTile(
  leading: const Icon(Icons.cloud_download),
  title: const Text('Available Offline'),
  trailing: Switch(
    value: file.isPinnedOffline,
    onChanged: (value) async {
      if (value) {
        await fileService.pinFileForOffline(file);
      } else {
        await fileService.unpinFile(file);
      }
    },
  ),
)
