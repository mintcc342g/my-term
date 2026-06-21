# Code style

Write self-documenting code; comment only what the code itself cannot convey. Applies to all languages.

- No comments that restate what the code already shows — encode meaning in names, rename rather than annotate.
- Keep a comment only when it adds non-obvious value: the *why* (intent, trade-off, constraint), a non-obvious gotcha/edge case, or a required tag (TODO/FIXME, license header, lint pragma, public-API doc).
- Prefer extracting a well-named function or variable over adding an explanatory comment.
- Treat complexity as a signal to simplify, not to annotate — try restructuring before commenting.
- Respect each file's established conventions (existing comment density, doc-comment style like JSDoc/godoc/docstrings); match the surrounding code.
