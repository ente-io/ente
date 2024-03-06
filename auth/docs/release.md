# Releases

Create a PR to bump up the version in `pubspec.yaml`. Once that is merged, tag
main, and push the tag.

```sh
git tag auth-v1.2.3
git push origin auth-v1.2.3
```

This'll trigger a GitHub workflow that:

* Creates a new draft GitHub release and attaches all the build artifacts to it
  (mobile APKs and various desktop packages),

* Creates a new release in the internal track on Play Store.

Once the workflow completes, go to the draft GitHub release that was created.
Set "Previous tag" to the last release of auth and press "Generate release
notes". The generated release note will contain all PRs and new contributors
from all the releases in the monorepo, so you'll need to filter them to keep
only the things that relate to the auth.
