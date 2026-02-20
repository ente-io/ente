# Infra ML Workspace

`infra/ml` is split into two focused areas:

- `playground/`: exploratory ML notebooks, model prep experiments, and sample assets.
- `test/`: ML indexing parity framework (Python ground truth, desktop/mobile runners, comparator, and CI entrypoints).

Shared Python project configuration stays at this root:

- `pyproject.toml`
- `uv.lock`
- `.python-version`
- `.gitignore`

Use the directory-specific READMEs for day-to-day work:

- `infra/ml/playground/README.md`
- `infra/ml/test/README.md`
