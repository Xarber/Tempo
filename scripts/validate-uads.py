# SPDX-License-Identifier: AGPL-3.0-only
"""Validate Tempo's compliance configuration independently of product quality."""
import json
from datetime import date
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker

ROOT = Path(__file__).resolve().parents[1]


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def load(path):
    target = (ROOT / path).resolve()
    if not target.is_relative_to(ROOT):
        raise ValueError(f"Path escapes the repository: {path}")
    return json.loads(target.read_text(), object_pairs_hook=unique_object)


def validate():
    manifest = load("uads.json")
    schema = load("config/uads-schema.json")
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema, format_checker=FormatChecker()).validate(manifest)
    requirements = manifest["requirements"]
    if requirements.keys() != load("config/uads-requirements.json").keys():
        raise ValueError("Manifest requirement IDs must match the registry")
    exceptions = {}
    for exception in manifest["exceptions"]:
        key = exception["requirement"]
        if key not in requirements or key in exceptions:
            raise ValueError(f"Unknown or duplicate exception: {key}")
        approved = date.fromisoformat(exception["approvedOn"])
        review = date.fromisoformat(exception["reviewOn"])
        if not approved <= date.today() <= review:
            raise ValueError(f"Exception outside its approval window: {key}")
        exceptions[key] = exception
    for key, entry in requirements.items():
        state = entry["state"]
        if state == "passed" and not entry["evidence"]:
            raise ValueError(f"Missing evidence: {key}")
        if state == "not-applicable" and (
            entry["applicability"] not in {"conditional", "not-applicable"}
            or not entry.get("reason")
        ):
            raise ValueError(f"Missing applicability justification: {key}")
        waived = entry["applicability"] == "approved-exception" and state == "waived"
        if (key in exceptions) != waived or (state == "waived" and not waived):
            raise ValueError(f"Inconsistent exception state: {key}")
        for path in entry["evidence"]:
            target = (ROOT / path).resolve()
            if not target.is_relative_to(ROOT) or not target.is_file():
                raise ValueError(f"Missing or invalid evidence path: {path}")
    for key in ("performance", "releaseMetadata"):
        load(manifest["quality"][key])
    workflow = (ROOT / manifest["quality"]["workflow"]).resolve()
    if not workflow.is_relative_to(ROOT) or not workflow.is_file():
        raise ValueError("Missing quality workflow")
    if not (ROOT / "docs/ACTIVE_TASKS.md").is_file():
        raise ValueError("Missing persistent task queue")
    print(f"Validated {len(requirements)} requirement groups. Product verification is separate.")


if __name__ == "__main__":
    validate()
