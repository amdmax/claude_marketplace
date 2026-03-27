---
name: marketplace:list
description: List all skills across every bundle in this marketplace, formatted as plugin | namespace | skill.
---

## Execution

Run the following command and display the output:

```bash
python3 -c "
import os, glob
print(f'{\"plugin\":<25} | {\"namespace\":<15} | skill')
print(f'{chr(45)*25}-+-{chr(45)*15}-+-------')
for path in sorted(glob.glob('bundles/*/skills/*/')) :
    parts = path.rstrip('/').split('/')
    bundle, skill_dir = parts[1], parts[3]
    ns, name = skill_dir.split(':', 1) if ':' in skill_dir else ('-', skill_dir)
    print(f'{bundle:<25} | {ns:<15} | {name}')
"
```

Output the results as-is — no additional formatting or commentary.
