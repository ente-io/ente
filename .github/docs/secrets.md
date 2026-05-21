# Secrets

## RELEASE_BRANCH_PUSH_TOKEN

- Fine-grained PAT for `ente-io/ente` with `Contents: read/write`.
- Used by the workflows which trigger releases to create, update, and delete `release/*` branches.
- The PAT owner must be allowed to bypass the `release/*` branch ruleset.
