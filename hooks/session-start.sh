#!/bin/bash

# SessionStart hook to inject project context at the beginning of each session
# Output is shown to Claude to provide project-specific context

cat <<EOF
Project: AIGENSA Vibe Coding Course
Architecture: Static HTML site with AWS CDK + Lambda@Edge auth

Key Directories:
- content/: Course materials (markdown)
- src/: HTML builder (markdown-it converter)
- output/: Generated static HTML
- infrastructure/: CDK stacks (S3, CloudFront, Cognito)
- lambda/: Lambda@Edge auth functions

Tech Stack:
- TypeScript (strict mode)
- AWS CDK for infrastructure
- markdown-it + Eta templates for HTML generation
- Lambda@Edge for authentication

Standards:
- Semantic commit messages
- All infrastructure changes must pass CDK synth
- Follow CLAUDE.md guidelines
EOF

exit 0
