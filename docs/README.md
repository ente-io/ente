# Docs

Help and documentation for Ente's products

> [!CAUTION]
>
> **Currently not published**. There are bits we need to clean up before
> publishing these docs. They'll likely be available at help.ente.io once we
> wrap those loose ends up.

## Quick edits

You can edit these files directly on GitHub and open a pull request.
[help.ente.io](https://help.ente.io) will automatically get updated with your
changes in a few minutes after your pull request is merged.

## Running locally


The above workflow is great since it doesn't require you to setup anything on
your local machine. But if you plan on contributing frequently, you might find
it easier to run everything locally.

Clone this repository

```sh
git clone https://github.com/ente-io/ente
```

Change to this directory

```sh
cd ente/docs
```

Install dependencies

```sh
yarn install
```

Then start a local server

```sh
yarn dev
```

For an editor, VSCode is a good choice. Also install the Prettier extension for
VSCode, and set VSCode to format on save. This way the editor will automatically
format and wrap the text using the project's standard, so you can just focus on
the content.

## Have fun!

Note that we currently don't enforce these formatting standards to make it easy
for people unfamiliar with programming to also be able to make edits from GitHub
directly.

This is a common theme - unlike the rest of the codebase where we expect some
baseline understanding of the tools involved, the docs are meant to be a place
for non-technical people to also provide their input. The reason for this is not
to increase the number of docs, but to bring more diversity to them. Such
diversity of viewpoints is essential for evolving documents that can be of help
to people of varying level of familiarity with tech.

If you're unsure about how to do something, just look around in the other files
and copy paste whatever seems to match the look of what you're trying to do. And
remember, writing docs should not be a chore, have fun!
