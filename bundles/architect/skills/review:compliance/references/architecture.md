# Architecture

```
Compliance Skill
├── SKILL.md
├── config.yaml
└── references/
    ├── openapi-generation.md (TypeScript → OpenAPI)
    ├── contract-testing.md (OpenAPI → Jest tests)
    ├── coverage-analysis.md (Coverage gaps → Tests)
    ├── acceptance-criteria.md (PRDs → Compliance)
    ├── architecture.md (this file)
    ├── validation.md (self-validation)
    └── examples.md (complete workflows)
```

**Design principles:**
- **Modular:** Each phase is independent and optional
- **Incremental:** Run single phases or full scan
- **Automated:** Generates artifacts, not just reports
- **Traceable:** Links commits → issues → PRDs → code
