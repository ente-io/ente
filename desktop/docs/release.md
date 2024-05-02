## Releases

Conceptually, the release is straightforward: We push a tag, a GitHub workflow
gets triggered that creates a draft release with artifacts built from that tag.
We then publish that release. The download links on our website, and existing
apps already know how to check for the latest GitHub release and update
accordingly.

The complication comes by the fact that Electron Updater (the mechanism that we
use for auto updates) doesn't work well with monorepos. So we need to keep a
separate (non-mono) repository just for doing releases.

-   Source code lives here, in [ente-io/ente](https://github.com/ente-io/ente).

-   Releases are done from
    [ente-io/photos-desktop](https://github.com/ente-io/photos-desktop).

## Workflow

The workflow is:

1.  Finalize the changes in the source repo.

    -   Update the CHANGELOG.
    -   Update the version in `package.json`
    -   `git commit -m 'Release v1.x.x'`
    -   Open PR, merge into main.

2.  Tag this commit with a tag matching the pattern `photosd-v1.2.3`, where
    `1.2.3` is the version in `package.json`

    ```sh
    git tag photosd-v1.x.x
    git push origin photosd-v1.x.x
    ```

3.  Head over to the releases repository, copy all relevant changes from the
    source repository, commit and push the changes.

    ```sh
    cp ../ente/desktop/CHANGELOG.md CHANGELOG.md
    git add CHANGELOG.md
    git commit -m 'Release v1.x.x'
    git push origin main
    ```

4.  Tag this commit, but this time _don't_ use the `photosd-` prefix. Push the
    tag to trigger the GitHub action.

    ```sh
    git tag v1.x.x
    git push origin v1.x.x
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
