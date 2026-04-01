#!/usr/bin/env python3
"""PostToolUse hook: validate Mermaid .mmd files for GitHub rendering issues."""

import sys
import json
import re

data = json.load(sys.stdin)
fp = data.get("tool_input", {}).get("file_path", "")

if not fp.endswith(".mmd"):
    sys.exit(0)

try:
    content = open(fp).read()
except Exception:
    sys.exit(0)

errors = []
lines = content.split("\n")

in_er = False
in_graph = False
in_entity = False

RESERVED_KEYWORDS = {"PK", "SK", "FK", "UK"}
INVALID_ER_TYPES = {"json", "object", "array", "any"}
SPECIAL_CHARS_IN_COMMENT = re.compile(r'"[^"]*[#{}|][^"]*"')
ENTITY_OPEN = re.compile(r"^\s+\w[\w_]*\s*\{")
ENTITY_CLOSE = re.compile(r"^\s*\}")
# erDiagram attribute: type name [PK|FK|UK] ["comment"]
# Second token is the attribute NAME — flag only if it's a reserved keyword
ER_ATTR = re.compile(
    r"^\s+(\w+)\s+(\w+)((?:\s+(?:PK|FK|UK|SK))?)((?:\s+\"[^\"]*\")?)\s*$"
)

for i, line in enumerate(lines, 1):
    stripped = line.strip()

    if stripped == "erDiagram":
        in_er = True
        in_graph = False
        continue
    if re.match(r"^(graph|flowchart)\b", stripped):
        in_graph = True
        in_er = False
        continue

    if in_er:
        if ENTITY_OPEN.match(line):
            in_entity = True
            continue
        if ENTITY_CLOSE.match(line) and in_entity:
            in_entity = False
            continue

        if in_entity:
            m = ER_ATTR.match(line)
            if m:
                attr_type, attr_name = m.group(1), m.group(2)
                comment_str = m.group(4).strip() if m.group(4) else ""

                # Rule 1: attribute NAME (2nd token) is a reserved keyword
                # Valid:   "string id PK"       — PK is 3rd token (key marker)
                # Invalid: "string PK \"desc\"" — PK is 2nd token (attribute name)
                if attr_name in RESERVED_KEYWORDS:
                    suggestions = {
                        "PK": "partitionKey",
                        "SK": "sortKey",
                        "FK": "foreignKey",
                        "UK": "uniqueKey",
                    }
                    errors.append(
                        f"Line {i}: '{attr_name}' used as attribute name — it is a reserved "
                        f"Mermaid key marker (causes ATTRIBUTE_KEY parse error on GitHub). "
                        f"Use '{suggestions.get(attr_name, attr_name.lower())}' as the name, "
                        f"or use the key marker form: 'string myField {attr_name}'"
                    )

                # Rule 2: invalid attribute types
                if attr_type in INVALID_ER_TYPES:
                    errors.append(
                        f"Line {i}: '{attr_type}' is not a valid erDiagram attribute type "
                        f"(GitHub Mermaid supports: string, number, boolean, date). "
                        f"Use 'string' instead."
                    )

                # Rule 3: special chars in quoted attribute comments
                if comment_str and SPECIAL_CHARS_IN_COMMENT.search(comment_str):
                    errors.append(
                        f"Line {i}: Quoted comment {comment_str} contains a special character "
                        f"(#, {{, }}, |) — GitHub Mermaid rejects these. Use plain text only."
                    )

    # Rule 4: literal \n in graph/flowchart node labels
    if in_graph and re.search(r"\[.*\\n.*\]", line):
        errors.append(
            f"Line {i}: Literal \\n in node label — use <br/> for line breaks in "
            f"graph/flowchart diagrams (GitHub Mermaid rejects \\n)."
        )

if errors:
    print("Mermaid validation failed — fix before posting to GitHub:", file=sys.stderr)
    for e in errors:
        print(f"  \u2717 {e}", file=sys.stderr)
    sys.exit(2)

sys.exit(0)
