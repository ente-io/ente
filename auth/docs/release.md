# Releases

Create a PR to bump up the version number in `pubspec.yaml`.

Once that is merged, tag main (using the `auth-v1.2.3` format), and push the
tag. This'll trigger a GitHub workflow that:

* Creates a new draft GitHub release and attaches all the build artifacts to it
  (mobile APKs and various desktop packages),

* Creates a new release in the internal track on Play Store.

(TODO(MR): Fix this after the monorepo move) Xcode Cloud has already been
configured and will automatically build and release to TestFlight when step 1
was merged to main (you can see logs under the PR checks).

If you want to make changes to the workflow itself, or test it out, you can push
a tag like `auth-v1.2.3-test` (where v1.2.3 is the next expected version that'll
go out). For more details, see the comments on top of the [auth-release
workflow](.github/workflows/auth-release.yml).

Once the workflow completes, go to the draft GitHub release it that was created.
Use the "Generate release notes" button after setting the "Previous tag" for the
last release of auth. The generated release note will contain all PRs and new
contributors from all the releases in the monorepo, so you'll need to filter
them to keep only the things that relate to auth.
