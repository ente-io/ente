# Welcome!

If you're new to web stuff or coming back to it after mobile/backend
development, here is a recommended workflow:

1. Install **VS Code**.

2. Install the **Prettier** and **ESLint** extensions.

3. Enable the VS Code setting to format on save.

4. Install **node** on your machine. There are myriad ways to do this, here are
   some examples:

    - macOS: `brew install node@20`

    - Ubuntu: `sudo apt install nodejs npm && sudo npm i -g corepack`

5. Enable corepack. This allows us to use the correct version of our package
   manager (**Yarn**):

    ```sh

    corepack enable
    ```

    If now you run `yarn --version` in the web directory, you should be seeing a
    1.22.xx version, otherwise your `yarn install` will fail.

    ```sh
    $ yarn --version
    1.22.22
    ```

That's it. Enjoy coding!
