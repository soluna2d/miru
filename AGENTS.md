# Repository Instructions

## Communication

- Use Simplified Chinese for explanations, discussion, plans, and summaries.
- Use English for code, comments, identifiers, commit messages, and Markdown code blocks.
- Prefer concise, high-signal responses. Assume the user is an experienced backend/database engineer.

## Workflow

- Read relevant code before proposing non-trivial implementation changes.
- For non-trivial work, use a Plan/Code workflow: first align on the concrete approach, then implement.
- Keep changes scoped to the requested task.
- Do not introduce unrelated refactors or compatibility layers unless explicitly requested.
- Do not use destructive git commands or history rewriting unless explicitly requested.
- Do not revert or overwrite user changes.
- Use scope commit messages, for example `test harness: add Soluna-backed runner`.
- Do not use conventional commit prefixes such as `feat:`, `fix:`, or `chore:`.

## Repository

- Soluna should be kept as a git submodule.
- Keep dependency code out of this repository unless it is Miru-owned glue, fixtures, tests, or configuration.

## Tests

- The unified test entry is `test.dl`.
- `test.dl` should point to `test.lua`.
- `test.lua` should delegate to `test.runner`.
- Test files live only under `test/smoke` and `test/feature`.
- The runner should collect `test/{smoke,feature}/test_*.lua`.
- Do not add alternate test entry files for focused tests; use `TEST_KIND` and `TEST_NAME` selection through the unified runner.

## Verification

- Run focused tests for changed behavior before claiming completion.
- When changing runtime behavior, add or update tests first where practical.
- State exactly which commands were run and whether they passed.
