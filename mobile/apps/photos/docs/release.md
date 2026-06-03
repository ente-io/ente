# Releases

Photos uses the shared app release process documented in `.github/docs/app-release.md`.

## F-Droid

For F-Droid, create an `fdroid-v` tag with the same pubspec version.

```sh
./scripts/create_tag.sh fdroid-v1.2.3
git push origin fdroid-v1.2.3
```
