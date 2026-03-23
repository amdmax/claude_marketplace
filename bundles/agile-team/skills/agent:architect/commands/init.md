# Command: init

Bootstrap the project architecture workspace. One-time setup that scans the project and produces an architecture overview.

## Workflow

1. `mkdir -p WORKSPACE_DIR/adr`
2. Scan the codebase to identify:
   - Tech stack (package.json, pyproject.toml, go.mod, Cargo.toml, etc.)
   - Frameworks in use (check imports, config files)
   - Key directories and their purpose
3. Read existing ADRs in `WORKSPACE_DIR/adr/` if any exist — collect titles and numbers
4. Read NFR registry (`{{NFR_REGISTRY_FILE}}`) if it exists
5. Identify key architectural patterns in use (check tsconfig, webpack/vite config, Docker files, CI config, etc.)
6. Write `WORKSPACE_DIR/architecture-overview.md` with:
   - **Tech Stack** — languages, runtimes, major frameworks
   - **Key Architectural Patterns** — monolith/microservices, layering, DI, etc.
   - **Existing ADR Index** — list of ADR titles with file references (titles only)
   - **Known Constraints** — from NFR registry or inferred from config
   - **Directory Structure Overview** — top-level dirs with one-line purpose each
7. Report the file path and a brief summary to the user

## File Boundary

Write only to `WORKSPACE_DIR/architecture-overview.md`.
