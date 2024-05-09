## Releases

Conceptually, the release is straightforward: We trigger a GitHub workflow that
creates a draft release with artifacts built. When ready, we publish that
release. The download links on our website, and existing apps already check the
latest GitHub release and update accordingly.

The complication comes by the fact that electron-builder's auto updaterr (the
mechanism that we use for auto updates) doesn't work with monorepos. So we need
to keep a separate (non-mono) repository just for doing releases.

-   Source code lives here, in [ente-io/ente](https://github.com/ente-io/ente).

-   Releases are done from
    [ente-io/photos-desktop](https://github.com/ente-io/photos-desktop).

## Workflow - Release Candidates

Leading up to the release, we can make one or more draft releases that are not
intended to be published, but serve as test release candidates.

The workflow for making such "rc" builds is:

1.  Update `package.json` in the source repo to use version `1.x.x-rc`. Create a
    new draft release in the release repo with title `1.x.x-rc`. In the tag
    input enter `v1.x.x-rc` and select the option to "create a new tag on
    publish".

2.  Push code to the `desktop/rc` branch in the source repo.

3.  Trigger the GitHub action in the release repo

    ```sh
    gh workflow run desktop-release.yml
    ```

We can do steps 2 and 3 multiple times; each time it'll just update the
artifacts attached to the same draft.

## Workflow - Release

1.  Update `package.json` in the source repo to use version `1.x.x`. Create a
    new draft release in the release repo with tag `v1.x.x`.

2.  Push code to the `desktop/rc` branch in the source repo. Remember to update
    update the CHANGELOG.

3.  In the release repo

    ```sh
    ./.github/trigger-release.sh v1.x.x
    ```

4.  If the build is successful, tag `desktop/rc` and merge it into main:

    ```sh
    # Assuming we're on desktop/rc that just got build

    git tag photosd-v1.x.x
    git push origin photosd-v1.x.x

    # Now open a PR to merge it into main
    ```

## Post build

The GitHub Action runs on Windows, Linux and macOS. It produces the artifacts
defined in the `build` value in `package.json`.

-   Windows - An NSIS installer.
-   Linux - An AppImage, and 3 other packages (`.rpm`, `.deb`, `.pacman`)
-   macOS - A universal DMG

Additionally, the GitHub action notarizes and signs the macOS DMG (For this it
uses credentials provided via GitHub secrets).

To rollout the build, we need to publish the draft release. Thereafter,
everything is automated:

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
