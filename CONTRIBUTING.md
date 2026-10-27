# Contributing

Thank you for improving Codex Skills Hub.

## Catalog changes

Every catalog entry must have:

1. A unique, stable skill name.
2. One supported `kind` value.
3. A public GitHub source when one exists.
4. A plugin name when `kind` is `plugin-provided`.
5. No credentials, tokens, cookies, private files, or copied account configuration.

Supported kinds are:

- `public-catalog`
- `plugin-provided`
- `codex-system`
- `openai-curated`
- `official-external`

## Before submitting

Run:

```powershell
python .\scripts\validate_catalog.py
```

Explain the upstream source and why the entry is useful. Do not submit third-party code unless its license permits redistribution and attribution is preserved.

## Pull requests

Keep pull requests focused. Include:

- a short motivation;
- the source repository;
- validation output;
- any licensing or compatibility notes.


