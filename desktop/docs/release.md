## Releases

The Github Action that builds the desktop binaries is triggered by pushing a tag
matching the pattern `photosd-v1.2.3`. This value should match the version in
`package.json`.

To make a new release

1. Create a new branch (can be named anything). On this branch, change the
   `version` in `package.json` to `1.x.x` and finalize `CHANGELOG.md`.

2. Commit, tag and push to remote. Note that the tag should have a `photosd-`
   prefix:

    ```sh
    git add CHANGELOG.md package.json
    git commit -m 'Release v1.x.x'
    git tag photosd-v1.x.x
    git push origin photosd-v1.x.x
    ```

   This will trigger the GitHub action that will create a new draft release.

3. To wrap up, increase the version number in `package.json` the next release
   train. That is, suppose we just released `v4.0.1`. Then we'll change the
   version number in main to `v4.0.2-beta.0`. Each pre-release will modify the
   `beta.0` part. Finally, at the time of the next release, this'll become
   `v4.0.2`.

4. Open a PR for the branch to get it merged into main.

The GitHub Action runs on Windows, Linux and macOS. It produces the artifacts
defined in the `build` value in `package.json`.

-   Windows - An NSIS installer.
-   Linux - An AppImage, and 3 other packages (`.rpm`, `.deb`, `.pacman`)
-   macOS - A universal DMG

Additionally, the GitHub action notarizes the macOS DMG. For this it needs
credentials provided via GitHub secrets.

To rollout the build, we need to publish the draft release. This needs to be
done in the old photos-desktop repository since that the Electron Updater
mechanism doesn't work well with monorepos. So we need to create a new tag with
changelog updates on
[photos-desktop](https://github.com/ente-io/photos-desktop/), use that to create
a new release, copying over all the artifacts.

Thereafter, everything is automated:

-   The website automatically redirects to the latest release on GitHub when
    people try to download.

-   The file formats with support auto update (Windows `exe`, the Linux AppImage
    and the macOS DMG) also check the latest GitHub release automatically to
    download and apply the update (the rest of the formats don't support auto
    updates yet).

-   We're not putting the desktop app in other stores currently. It is available
    as a `brew cask`, but we only had to open a PR to add the initial formula,
    now their maintainers automatically bump the SHA, version number and the
    (derived from the version) URL in the formula when their tools notice a new
    release on our GitHub.

We can also publish the draft releases by checking the "pre-release" option.
Such releases don't cause any of the channels (our website, or the desktop app
auto updater, or brew) to be notified, instead these are useful for giving links
to pre-release builds to customers.
