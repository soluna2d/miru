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
- Keep dependency code out of this repository unless it is Miru-owned example glue or configuration.
- `miru.lua` is the framework runtime. Public example and documentation sources live under `example/`.
- The documentation site must keep its own information architecture and visual language. Reuse Soluna's validated WebAssembly and Pages build mechanism, not the Soluna website implementation or styles.

## Example

- `example/main.game` is the native example entry.
- Components live under `example/components/` and should depend only on Miru and Soluna public modules.
- `example/site/` is a static documentation shell; `example/scripts/build-site.mjs` packages the same Lua example for WebAssembly.
- Keep component examples independently inspectable and interactive. They demonstrate patterns, not a bundled design system.

## Verification

- Run the native example for changed component behavior.
- Build the WebAssembly documentation artifact and validate it in a real browser at desktop and mobile viewports.
- State exactly which commands were run and whether they passed.
