## Releases

> [!NOTE]
>
> TODO(MR): This document needs to be audited and changed as we do the first
> release from this new monorepo.

The Github Action that builds the desktop binaries is triggered by pushing a tag
matching the pattern `photos-desktop-v1.2.3`. This value should match the
version in `package.json`.

So the process for doing a release would be.

1. Create a new branch (can be named anything). On this branch, include your
   changes.

2. Mention the changes in `CHANGELOG.md`.

3. Changing the `version` in `package.json` to `1.x.x`.

4. Commit and push to remote

    ```sh
    git add package.json && git commit -m 'Release v1.x.x'
    git tag v1.x.x
    git push && git push --tags
    ```

This by itself will already trigger a new release. The GitHub action will create
a new draft release that can then be used as descibed below.

To wrap up, we also need to merge back these changes into main. So for that,

5. Open a PR for the branch that we're working on (where the above tag was
   pushed from) to get it merged into main.

6. In this PR, also increase the version number for the next release train. That
   is, supposed we just released `v4.0.1`. Then we'll change the version number
   in main to `v4.0.2-next.0`. Each pre-release will modify the `next.0` part.
   Finally, at the time of the next release, this'll become `v4.0.2`.

The GitHub Action runs on Windows, Linux and macOS. It produces the artifacts
defined in the `build` value in `package.json`.

-   Windows - An NSIS installer.
-   Linux - An AppImage, and 3 other packages (`.rpm`, `.deb`, `.pacman`)
-   macOS - A universal DMG

Additionally, the GitHub action notarizes the macOS DMG. For this it needs
credentials provided via GitHub secrets.

During the build the Sentry webpack plugin checks to see if SENTRY_AUTH_TOKEN is
defined. If so, it uploads the sourcemaps for the renderer process to Sentry
(For our GitHub action, the SENTRY_AUTH_TOKEN is defined as a GitHub secret).

The sourcemaps for the main (node) process are currently not sent to Sentry
(this works fine in practice since the node process files are not minified, we
only run `tsc`).

Once the build is done, a draft release with all these artifacts attached is
created. The build is idempotent, so if something goes wrong and we need to
re-run the GitHub action, just delete the draft release (if it got created) and
start a new run by pushing a new tag (if some code changes are required).

If no code changes are required, say the build failed for some transient network
or sentry issue, we can even be re-run by the build by going to Github Action
age and rerun from there. This will re-trigger for the same tag.

If everything goes well, we'll have a release on GitHub, and the corresponding
source maps for the renderer process uploaded to Sentry. There isn't anything
else to do:

-   The website automatically redirects to the latest release on GitHub when
    people try to download.

-   The file formats with support auto update (Windows `exe`, the Linux AppImage
    and the macOS DMG) also check the latest GitHub release automatically to
    download and apply the update (the rest of the formats don't support auto
    updates).

-   We're not putting the desktop app in other stores currently. It is available
    as a `brew cask`, but we only had to open a PR to add the initial formula,
    now their maintainers automatically bump the SHA, version number and the
    (derived from the version) URL in the formula when their tools notice a new
    release on our GitHub.

We can also publish the draft releases by checking the "pre-release" option.
Such releases don't cause any of the channels (our website, or the desktop app
auto updater, or brew) to be notified, instead these are useful for giving links
to pre-release builds to customers. Generally, in the version number for these
we'll add a label to the version, e.g. the "beta.x" in `1.x.x-beta.x`. This
should be done both in `package.json`, and what we tag the commit with.
