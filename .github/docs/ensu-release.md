# Ensu release process

> The following assumes main is `0.1.16-beta`, we want to release `0.1.16` and move main to `0.1.17-beta`.

## Normal development

Nightly builds of `main` are automatically created every weekday morning (IST), and can also be created by running `ensu-build.yml` manually. These builds are attached to the draft `ensu-v0.1.16-beta` GitHub release; each nightly keeps updating the same draft.

> [!NOTE]
>
> All builds (nightly and RC) are also uploaded to Play Store internal testing (Android) and TestFlight (iOS).
>
> See [apple-signing.md](./apple-signing.md) for certificate, API key, and provisioning profile setup and rotation.

## Start release

```bash
gh workflow run ensu-release.yml \
  -f action=start \
  -f version=0.1.16
```

This:

1. Creates a release branch `release/ensu-v0.1.16` with the version set to `0.1.16`
2. Pushes the branch, which triggers `ensu-build.yml` and creates the draft `ensu-v0.1.16-rc` GitHub release
3. Removes the `ensu-v0.1.16-beta` draft and tag

The workflow also opens a PR to move `main` to `0.1.17-beta`. Merge that PR after it is created. Scheduled nightlies are skipped while the release branch exists.

## Update the RC if needed

Cherry pick fixes to the release branch and push to replace the current RC.

```bash
git switch release/ensu-v0.1.16
git cherry-pick <fix-sha>
git push
```

## Finalize release

```bash
gh workflow run ensu-release.yml \
  -f action=finalize \
  -f version=0.1.16
```

This does not create another build. It tags the last RC commit as `ensu-v0.1.16`, moves the GitHub draft from `ensu-v0.1.16-rc` to `ensu-v0.1.16`, removes the RC tag, and deletes the release branch.

## Retries

`ensu-build.yml` is safe to retry. Both nightly and RC builds update fixed draft releases (`ensu-v0.1.16-beta` and `ensu-v0.1.16-rc`), and reruns update the same draft.

> If a build has already reached Play Store or TestFlight, trigger a new workflow run instead of re-running failed jobs so that it gets a new build number.

`ensu-release.yml` changes release state. If it fails, inspect the failed step before re-running. After it has pushed a branch, created a tag, or moved a draft release, either finish the remaining step manually or undo the partial state first. Cleanup is intentionally late: `action=start` pushes the release branch before deleting the beta draft, and `action=finalize` deletes the release branch last.
