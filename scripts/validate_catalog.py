from __future__ import annotations

import csv
import sys
from collections import Counter
from pathlib import Path
from urllib.parse import urlparse


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "data" / "skills.csv"
EXPECTED_TOTAL = 985
EXPECTED_KINDS = {
    "public-catalog": 880,
    "plugin-provided": 100,
    "codex-system": 3,
    "openai-curated": 1,
    "official-external": 1,
}
REQUIRED_COLUMNS = {"name", "kind", "plugin", "source"}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)


def main() -> int:
    if not CATALOG.exists():
        fail(f"catalog not found: {CATALOG}")
        return 1

    with CATALOG.open(newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        fieldnames = set(reader.fieldnames or [])
        if fieldnames != REQUIRED_COLUMNS:
            fail(f"unexpected columns: {sorted(fieldnames)}")
            return 1
        rows = list(reader)

    errors: list[str] = []
    names = [row["name"].strip() for row in rows]
    counts = Counter(row["kind"].strip() for row in rows)
    duplicates = sorted(name for name, count in Counter(names).items() if count > 1)

    if len(rows) != EXPECTED_TOTAL:
        errors.append(f"expected {EXPECTED_TOTAL} rows, found {len(rows)}")
    if len(set(names)) != EXPECTED_TOTAL:
        errors.append(f"expected {EXPECTED_TOTAL} unique names, found {len(set(names))}")
    if duplicates:
        errors.append(f"duplicate names: {', '.join(duplicates)}")
    if dict(counts) != EXPECTED_KINDS:
        errors.append(f"unexpected kind counts: {dict(counts)}")

    for number, row in enumerate(rows, start=2):
        name = row["name"].strip()
        kind = row["kind"].strip()
        plugin = row["plugin"].strip()
        source = row["source"].strip()

        if not name:
            errors.append(f"row {number}: empty name")
        if kind == "plugin-provided" and not plugin:
            errors.append(f"row {number}: plugin skill {name!r} has no plugin name")
        if kind != "plugin-provided" and not source:
            errors.append(f"row {number}: public/system skill {name!r} has no source")
        if source:
            parsed = urlparse(source)
            if parsed.scheme != "https" or parsed.netloc != "github.com":
                errors.append(f"row {number}: invalid GitHub source for {name!r}: {source}")

    if errors:
        for error in errors:
            fail(error)
        return 1

    print(f"Catalog OK: {len(rows)} unique skills")
    for kind in sorted(EXPECTED_KINDS):
        print(f"  {kind}: {counts[kind]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

