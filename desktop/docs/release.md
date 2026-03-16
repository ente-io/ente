## Releases

Conceptually, the release is straightforward:

1. We trigger a GitHub workflow that creates a (pre-)release with the build.

2. When ready, we make that release the latest.

3. The download links on our website, and existing apps already check the latest
   GitHub release and update automatically.

The complication comes from the fact that electron-builder's auto updater (the
mechanism that we use for auto updates) doesn't work with monorepos. So we need
to keep a separate repository just for holding the releases.

- Source code lives here, in [ente/ente](https://github.com/ente/ente).

- Releases are done from
  [ente/photos-desktop](https://github.com/ente/photos-desktop).

## Nightly builds

Nightly builds of `main` are published by a scheduled workflow automatically.
Each such workflow run will update the artifacts attached to the same
(pre-existing) pre-release.

If needed, this workflow can also be manually triggered:

```sh
gh workflow run desktop-release.yml --source=<branch>
```

## Release candidate for testing

1. Get latest main from upstream

2. Create new branch called `v1.x.x_release_candidate` and check out to it

3. Update the [CHANGELOG](../CHANGELOG.md)

4. Update [What's New](../../web/packages/new/photos/components/WhatsNew.tsx)

5. In [changelog.ts](../../web/packages/new/photos/services/changelog.ts), bump the version number

6. Open PR (title should be "[desktop] v1.x.x release candidate") and merge

7. Send the release candidate build for testing

## Release checklist

1. Get latest main from upstream

2. Create new branch called `v1.x.x` and check out to it

3. Remove "-beta" from version in [package.json](../package.json)

4. Finalize the [CHANGELOG](../CHANGELOG.md) - remove (unreleased) and make sure changelog is final

5. Update the [help changelog](../../docs/docs/photos/changelog.md) with the release notes (copy paste) for this version (make sure month is correct)

6. Open PR (title should be "[desktop] v1.x.x") and merge

7. Checkout to main, then get the latest upstream and then tag the merge commit on `main` in the source repo (this):

    ```sh
    git tag photosd-v1.x.x
    git push upstream photosd-v1.x.x
    ```

8. In the cloned release repo (https://github.com/ente/photos-desktop), run this command:

    ```sh
    ./.github/trigger-release.sh v1.x.x
    ```

9. This'll trigger the workflow and create a new "pre-release". It'll take around 20 minutes, wait until it's live.

10. Edit this pre-release to add the release notes (copy paste from changelog), check the "Set as the latest release" button and Update.

11. Once it is marked as latest, the release goes live.

12. Next, we need to create a new pre-release that'll hold subsequent nightly builds. Following steps are for that.

13. In the source repo, get latest main from upstream

14. Create new branch called `v1.x.(x+1)-beta` and check out to it

15. In [package.json](../package.json), change version to `1.x.(x+1)-beta`

16. Update the [CHANGELOG](../CHANGELOG.md) - add ## 1.x.(x+1)-beta (unreleased) with one empty point

17. Open PR (title should be "[desktop] v1.x.(x+1)-beta") and merge

18. In the release repo's [releases](https://github.com/ente/photos-desktop/releases), delete the existing _nightly_ pre-release:

19. In the cloned release repo (https://github.com/ente/photos-desktop), run this command:

    ```sh
    git tag v1.x.(x+1)-beta
    git push origin v1.x.(x+1)-beta
    ```

20. Run this [workflow](https://github.com/ente/photos-desktop/actions/workflows/desktop-release.yml)

21. Once the workflow creates the new v1.x.(x+1)-beta pre-release, edit its description to "Nightly builds".

22. Done

## Ad-hoc builds

To create extra one-off pre-releases in addition to the nightly `1.x.x-beta`s,

1. In your branch in the source repository, set the version in `package.json` to
   something different, say `1.x.x-foo`.

2. Create a new pre-release in the release repo with title `1.x.x-foo`. In the
   tag input enter `v1.x.x-foo` and select the option to "Create a new tag on
   publish".

3. Trigger the workflow in the release repo:

    ```sh
    gh workflow run desktop-release.yml --source=my-branch
    ```

## Details

The GitHub Action runs on Windows, Linux and macOS. It produces the artifacts
defined in the `build` value in `package.json`.

- Windows - An NSIS installer.
- Linux - An AppImage, and 3 other packages (`.rpm`, `.deb`, `.pacman`)
- macOS - A universal DMG

Additionally, the GitHub action notarizes and signs the macOS DMG (For this it
uses credentials provided via GitHub secrets).

To rollout the build, we need to publish the draft release. Thereafter,
everything is automated:

- The website automatically redirects to the latest release on GitHub when
  people try to download.

- The file formats with support auto update (Windows `exe`, the Linux AppImage
  and the macOS DMG) also check the latest GitHub release automatically to
  download and apply the update (the rest of the formats don't support auto
  updates yet).

- We're not putting the desktop app in other stores currently. It is available
  as a `brew cask`, but we only had to open a PR to add the initial formula, now
  their maintainers automatically bump the SHA, version number and the (derived
  from the version) URL in the formula when their tools notice a new release on
  our GitHub.
