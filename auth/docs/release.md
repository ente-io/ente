# Releases

1. Create a PR to bump up the version number in `pubspec.yaml`.

2. Once that is merged, tag main and push the tag. This'll trigger a GitHub
   workflow that:

   a. Creates a new draft GitHub release and attaches all the build artifacts to
      it (mobile APKs and various desktop packages)

   b. Creates a new release in the internal track on Play Store.

3. (TODO(MR): Fix this after the monorepo move) Xcode Cloud has already been
   configured and will automatically build and release to TestFlight when step 1
   was merged to main (you can see logs under the PR checks).

If you want to make changes to the workflow itself, or test it out, you can push
a tag like `auth-v1.2.3-test` (where v1.2.3 is the next expected version that'll
go out). For more details, see the comments on top of the [auth-release
workflow](.github/workflows/auth-release.yml).
