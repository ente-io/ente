# Docs

Help and documentation for Ente's products.

You can find the live version of these at
**[help.ente.io](https://help.ente.io)**.

## Quick edits

You can edit these files directly on GitHub and open a pull request.
[help.ente.io](https://help.ente.io) will automatically get updated with your
changes in a few minutes after your pull request is merged.

## Running locally

The above workflow is great since it doesn't require you to setup anything on
your local machine. But if you plan on contributing frequently, you might find
it easier to run things locally.

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
the content. You can also format without VSCode by using the `yarn pretty`
command.

## Have fun!

If you're unsure about how to do something, just look around in the other files
and copy paste whatever seems to match the look of what you're trying to do. And
remember, writing docs should not be a chore, have fun!
