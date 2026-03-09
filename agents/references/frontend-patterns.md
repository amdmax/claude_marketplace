# Frontend Implementation Patterns

## TypeScript Build Scripts

- Pattern: `src/build-*.ts` (e.g., `build-catalog.ts`, `build-courses.ts`)
- Export named functions for testability
- Follow existing esbuild/lightningcss pipeline patterns

## Eta Templates

- Location: `src/templates/*.eta`
- Access data via template parameters passed from build scripts
- Preserve existing template structure — add IDs/classes, don't restructure

## CSS Architecture (Layered System)

- All styling in `src/styles/` — no inline styles
- Follow layer numbering convention (check existing files for prefix)
- Add new styles in appropriate layer file; never modify existing layer structure
- Theme variables defined in CSS custom properties — use variables, not hardcoded values

## Data Files

- Location: `src/data/*.json`
- Schema must match what templates expect
- Keep data files pure JSON — no comments

## File Boundaries

- **Can write/edit:** `src/**`, `output-catalog/**`, `content/**`, CSS files in `src/styles/`
- **Cannot edit:** `tests/**`, `infrastructure/**`, `lambda/**`
