---
title: Ente CLI Secrets - Self-hosting
description: A quick hotfix for keyring errors while running Ente CLI.
---

# Ente CLI Secrets

Ente CLI makes use of system keyring for storing sensitive information like your
passwords. And running the CLI straight out of the box might give you some
errors related to keyrings in some case.

Follow the below steps to run Ente CLI and also avoid keyrings errors.

Run:

```shell
# export the secrets path
export ENTE_CLI_SECRETS_PATH=./<path-to-secrets.txt>

./ente-cli
```

You can also add the above line to your shell's rc file, to prevent the need to
export manually every time.

Then one of the following:

1. If the file doesn't exist, Ente CLI will create it and fill it with a random
   32 character encryption key.
2. If you do create the file, please fill it with a cryptographically generated
   32 byte string.

And you are good to go.

## References

- [Ente CLI Secrets Path](https://www.reddit.com/r/selfhosted/comments/1gc09il/comment/lu2hox2/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)
- [Keyrings](https://man7.org/linux/man-pages/man7/keyrings.7.html)
