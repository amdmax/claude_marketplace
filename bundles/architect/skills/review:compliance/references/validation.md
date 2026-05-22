# Validation

The skill self-validates by:
1. Checking OpenAPI specs with swagger-parser
2. Running generated tests with Jest
3. Verifying coverage thresholds
4. Cross-referencing PRD criteria with code

**No manual verification needed** - artifacts are tested during generation.

## Contributing

To extend the skill:

1. Add new API patterns to `openapi-generation.md`
2. Add test generators to `contract-testing.md`
3. Add PRD parsing patterns to `acceptance-criteria.md`
4. Update `config.yaml` with new options
5. Add examples to `examples.md`

Keep reference docs focused (<200 lines each).
