# Releases

Create a PR to bump up the version in `pubspec.yaml`.

> [!NOTE]
>
> Use [semver](https://semver.org/) for the tags, with `photos-` as a prefix.
> Multiple beta releases for the same upcoming version can be done by adding
> build metadata at the end, e.g. `photos-v1.2.3-beta+3`.

Once that is merged, tag main, and push the tag.

```sh
git tag photos-v1.2.3
git push origin photos-v1.2.3
```

This'll trigger a GitHub workflow that:

* Creates a new draft GitHub release and attaches the build artifacts to it
  (mobile APKs),

Once the workflow completes, go to the draft GitHub release that was created.

> [!NOTE]
>
> Keep the title of the release same as the tag.

Set "Previous tag" to the last release of auth and press "Generate release
notes". The generated release note will contain all PRs and new contributors
from all the releases in the monorepo, so you'll need to filter them to keep
only the things that relate to the Photos mobile app.
