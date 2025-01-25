## Releases

Conceptually, the release is straightforward:

1. We trigger a GitHub workflow that creates a (pre-)release with the build.

2. When ready, we make that release the latest.

3. The download links on our website, and existing apps already check the latest
   GitHub release and update automatically.

The complication comes from the fact that electron-builder's auto updater (the
mechanism that we use for auto updates) doesn't work with monorepos. So we need
to keep a separate repository just for holding the releases.

- Source code lives here, in [ente-io/ente](https://github.com/ente-io/ente).

- Releases are done from
  [ente-io/photos-desktop](https://github.com/ente-io/photos-desktop).

## Nightly builds

Nightly builds of `main` are published by a scheduled workflow automatically.
Each such workflow run will update the artifacts attached to the same
(pre-existing) pre-release.

If needed, this workflow can also be manually triggered:

```sh
gh workflow run desktop-release.yml --source=<branch>
```

## Release checklist

1. Update source repo to set version `1.x.x` in `package.json` and finalize the
   CHANGELOG.

2. Merge PR then tag the merge commit on `main` in the source repo:

    ```sh
    git tag photosd-v1.x.x
    git push origin photosd-v1.x.x
    ```

3. In the release repo:

    ```sh
    ./.github/trigger-release.sh v1.x.x
    ```

This'll trigger the workflow and create a new pre-release. We can edit this to
add the release notes, and convert it to a release.

Once it is marked as latest, the release goes live.

We are done at this point, and can now update the other pre-release that'll hold
subsequent nightly builds.

1. Update `package.json` in the source repo to use version `1.x.x-beta`, and
   merge these changes into `main`.

2. In the release repo, delete the existing _nightly_ pre-release, then:

    ```sh
    git tag v1.x.x-beta
    git push origin v1.x.x-beta
    ```

3. Start a new run of the workflow (`gh workflow run desktop-release.yml`).

4. Once the workflow creates the new 1.x.x-beta pre-release, edit its
   description to "Nightly builds".

Subsequent scheduled nightly workflows will keep updating this pre-release.

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
