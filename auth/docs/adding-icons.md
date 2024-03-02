## Icons

Ente Auth supports the icon pack provided by
[simple-icons](https://github.com/simple-icons/simple-icons).

If you would like to add your own custom icon, please open a pull-request with
the relevant SVG placed within `assets/custom-icons/icons` and add the
corresponding entry within `assets/custom-icons/_data/custom-icons.json`.

This JSON file contains the following attributes:

| Attribute | Usecase | Required |
|---|---|---|
| `title` | Name of the service. | Yes |
| `slug` | If the icon's SVG file has a name different from the `title` | No |
| `hex` | Color code for the icon  | No |
| `altNames` | If the same service goes by different names or has different instances (eg. Mastodon) | No |

Here is an [example PR](https://github.com/ente-io/ente/pull/213).
