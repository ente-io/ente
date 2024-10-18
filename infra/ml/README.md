# Ente ML playground

This is a central place to keep track of any (Python) code used for prepping our ML models. The purpose of storing it here is to have some kind of version control over the alterations made to the models.

Most of the code is in [Jupyter Notebooks](https://jupyter.org/), which facilitates quick interation and good documentation.

## Running any notebook

In case you're using VSCode, make sure you've installed the [Jupyter](https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter) extension and only have a [single window](https://github.com/microsoft/vscode/issues/125993#issuecomment-2099627960) open.

1. [Install uv](https://docs.astral.sh/uv/getting-started/installation/)
2. Run `uv sync`
3. Run `uv venv`
4. In any notebook, make sure to select the virtual environment kernel from `.venv/bin/python` in the top (right corner on VSCode)

## Notebooks and git

Please make sure to always clear output data inside a notebook before committing changes to git.
Jupyter notebooks are known to not always work nicely with Git versioning control when there is output in them.
