## Icons

Ente Auth supports the icon pack provided by
[simple-icons](https://github.com/simple-icons/simple-icons).

If you would like to add your own custom icon, please open a pull-request with
the relevant SVG placed within `assets/custom-icons/icons` and add the
corresponding entry within `assets/custom-icons/_data/custom-icons.json`.

Note: the icon file name should be all lowercase with underscores in place of spaces 
and special characters. If you use underscores, make sure to provide the "slug" field
in the corresponding json entry.
Example: "Rockstar Games" would have an icon named "rockstar_games.svg".

The icon should ideally be a color that will display well on both light and dark
background to work with both the light and dark theme.

Please be careful to upload small and optimized icon files. If your icon file 
is over 50KB, it is likely not optimized. A good resource to optimize SVG files
is [svgviewer.dev](https://www.svgviewer.dev/) (click "optimize" at the top).

Note that the correspondence between the icon and the issuer is based on the name 
of the issuer provided by the user, excluding spaces. Only the text before the 
first dot "." or left parentheses "(" will be used for icon matching.
e.g. Issuer name provided: "github.com (Main account)" - Then "github" will be 
used for matching.

This JSON file contains the following attributes:

| Attribute | Usecase | Required |
|---|---|---|
| `title` | Name of the service. | Yes |
| `slug` | If the icon's SVG file has a name different from the `title` | No |
| `hex` | Color code for the icon  | No |
| `altNames` | If the same service goes by different names or has different instances (eg. Mastodon) | No |

Here is an [example PR](https://github.com/ente-io/ente/pull/213).
