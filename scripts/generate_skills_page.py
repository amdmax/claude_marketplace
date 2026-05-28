#!/usr/bin/env python3
"""
generate_skills_page.py — Self-contained HTML skills discovery page.

Reads bundles/*/plugin.json + bundles/*/skills/*/SKILL.md frontmatter,
renders a single-file HTML page (all CSS/JS inline, no CDN).
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: pyyaml required — run: pip install pyyaml", file=sys.stderr)
    sys.exit(1)

REPO_ROOT = Path(__file__).resolve().parent.parent
BUNDLES_DIR = REPO_ROOT / "bundles"
DEFAULT_OUTPUT = REPO_ROOT / "_site" / "index.html"


def _parse_frontmatter(path: Path) -> dict:
    if not path.is_file():
        return {}
    try:
        content = path.read_text(encoding="utf-8")
    except Exception:
        return {}
    lines = content.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    end = next((i for i, line in enumerate(lines[1:], 1) if line.strip() == "---"), None)
    if end is None:
        return {}
    try:
        data = yaml.safe_load("\n".join(lines[1:end]))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _hooks_summary(hooks: dict) -> list[str]:
    items = []
    for event, config in (hooks or {}).items():
        if isinstance(config, list):
            for entry in config:
                matcher = entry.get("matcher", "*") if isinstance(entry, dict) else "*"
                items.append(f"{event}: {matcher}")
        elif isinstance(config, dict):
            matcher = config.get("matcher", "")
            items.append(f"{event}{': ' + matcher if matcher else ''}")
        else:
            items.append(event)
    return items


def load_data() -> dict:
    bundles = []
    for bundle_dir in sorted(BUNDLES_DIR.iterdir()):
        if not bundle_dir.is_dir():
            continue
        plugin_json = bundle_dir / ".claude-plugin" / "plugin.json"
        if not plugin_json.is_file():
            continue
        try:
            plugin = json.loads(plugin_json.read_text(encoding="utf-8"))
        except Exception:
            continue

        skills = []
        skills_dir = bundle_dir / "skills"
        if skills_dir.is_dir():
            for skill_dir in sorted(skills_dir.iterdir()):
                if not skill_dir.is_dir():
                    continue
                fm = _parse_frontmatter(skill_dir / "SKILL.md")
                skills.append({
                    "name": str(fm.get("name", skill_dir.name)),
                    "description": str(fm.get("description", "")).strip(),
                    "tools": [str(t) for t in (fm.get("tools") or [])],
                    "tags": [str(t) for t in (fm.get("tags") or [])],
                    "hooks": _hooks_summary(fm.get("hooks") or {}),
                    "author": str(fm.get("author", "")),
                })

        bundles.append({
            "name": plugin.get("name", bundle_dir.name),
            "description": plugin.get("description", ""),
            "keywords": [str(k) for k in (plugin.get("keywords") or [])],
            "version": plugin.get("version", ""),
            "skills": skills,
        })

    total_skills = sum(len(b["skills"]) for b in bundles)
    return {
        "bundles": bundles,
        "total_bundles": len(bundles),
        "total_skills": total_skills,
        "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    }


HTML_TEMPLATE = r"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Claude Code Skills Marketplace</title>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --bg:#0d1117;--surface:#161b22;--surface2:#21262d;--surface3:#2d333b;
  --border:#30363d;--text:#c9d1d9;--muted:#8b949e;
  --accent:#a78bfa;--accent-bg:rgba(167,139,250,.12);
  --green:#3fb950;--blue:#58a6ff;--yellow:#d29922;
  --red:#f85149;--radius:10px;--font-mono:'SFMono-Regular',Consolas,monospace;
}
body{background:var(--bg);color:var(--text);font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',sans-serif;font-size:14px;line-height:1.6;min-height:100vh}
a{color:var(--accent);text-decoration:none}
/* Layout */
.wrapper{max-width:1100px;margin:0 auto;padding:32px 20px 64px}
/* Header */
.header{text-align:center;padding:40px 0 32px;border-bottom:1px solid var(--border);margin-bottom:32px}
.header h1{font-size:26px;font-weight:700;color:#fff;margin-bottom:6px;letter-spacing:-.3px}
.header h1 span{color:var(--accent)}
.header p{color:var(--muted);font-size:13px;margin-bottom:16px}
.stats{display:inline-flex;gap:24px;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);padding:10px 24px}
.stat{text-align:center}
.stat-val{font-size:22px;font-weight:700;color:#fff}
.stat-lbl{font-size:11px;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
/* Search */
.search-wrap{position:relative;margin-bottom:28px}
.search-wrap svg{position:absolute;left:14px;top:50%;transform:translateY(-50%);color:var(--muted);pointer-events:none}
#search{width:100%;background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);color:var(--text);font-size:14px;padding:10px 14px 10px 42px;outline:none;transition:border-color .15s}
#search::placeholder{color:var(--muted)}
#search:focus{border-color:var(--accent)}
/* No results */
.no-results{text-align:center;color:var(--muted);padding:60px 0;font-size:15px;display:none}
/* Bundle cards */
.bundle-card{background:var(--surface);border:1px solid var(--border);border-radius:var(--radius);margin-bottom:16px;overflow:hidden;transition:border-color .15s}
.bundle-card:hover{border-color:#484f58}
.bundle-header{display:flex;align-items:flex-start;gap:12px;padding:18px 20px;cursor:pointer;user-select:none}
.bundle-header:hover .bundle-name{color:var(--accent)}
.chevron{flex-shrink:0;margin-top:3px;color:var(--muted);transition:transform .2s;width:16px;height:16px}
.bundle-card.open .chevron{transform:rotate(90deg)}
.bundle-meta{flex:1;min-width:0}
.bundle-top{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin-bottom:4px}
.bundle-name{font-size:15px;font-weight:600;color:#fff;font-family:var(--font-mono)}
.badge{display:inline-flex;align-items:center;background:var(--accent-bg);color:var(--accent);border-radius:20px;padding:2px 9px;font-size:11px;font-weight:600;white-space:nowrap}
.bundle-desc{color:var(--muted);font-size:13px;margin-bottom:8px;line-height:1.5}
.keywords{display:flex;flex-wrap:wrap;gap:6px}
.kw{background:var(--surface2);color:var(--muted);border-radius:4px;padding:2px 7px;font-size:11px}
/* Skills list */
.skills-list{border-top:1px solid var(--border);display:none}
.bundle-card.open .skills-list{display:block}
.skill-row{border-bottom:1px solid var(--border);cursor:pointer;transition:background .12s}
.skill-row:last-child{border-bottom:none}
.skill-row:hover{background:var(--surface2)}
.skill-row.active{background:var(--surface2)}
.skill-summary{display:flex;align-items:baseline;gap:12px;padding:12px 20px}
.skill-name{font-family:var(--font-mono);color:var(--accent);font-size:13px;font-weight:500;white-space:nowrap;flex-shrink:0}
.skill-excerpt{color:var(--muted);font-size:12px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;flex:1}
.skill-chevron{flex-shrink:0;color:var(--muted);transition:transform .2s;width:12px;height:12px}
.skill-row.active .skill-chevron{transform:rotate(90deg)}
/* Skill detail */
.skill-detail{display:none;padding:16px 20px 20px;background:var(--surface2);border-top:1px solid var(--border)}
.skill-row.active .skill-detail{display:block}
.skill-desc{color:var(--text);font-size:13px;line-height:1.7;margin-bottom:14px}
.detail-row{display:flex;align-items:flex-start;gap:10px;margin-bottom:10px}
.detail-row:last-child{margin-bottom:0}
.detail-label{color:var(--muted);font-size:11px;font-weight:600;text-transform:uppercase;letter-spacing:.4px;white-space:nowrap;min-width:52px;padding-top:2px}
.chips{display:flex;flex-wrap:wrap;gap:5px}
.chip{border-radius:4px;padding:2px 8px;font-size:11px;font-weight:500}
.chip-tool{background:rgba(56,139,253,.12);color:var(--blue)}
.chip-tag{background:rgba(63,185,80,.1);color:var(--green)}
.chip-hook{background:rgba(210,153,34,.1);color:var(--yellow)}
.install-hint{margin-top:14px;background:var(--surface3);border-radius:6px;padding:8px 14px;font-family:var(--font-mono);font-size:12px;color:var(--muted)}
.install-hint span{color:var(--accent)}
/* Hidden bundle */
.bundle-card.hidden{display:none}
/* Footer */
.footer{text-align:center;color:var(--muted);font-size:12px;padding-top:32px;border-top:1px solid var(--border);margin-top:16px}
</style>
</head>
<body>
<div class="wrapper">
  <div class="header">
    <h1>Claude Code <span>Skills Marketplace</span></h1>
    <p>Discover and install reusable skills, agents, and hooks for Claude Code</p>
    <div class="stats">
      <div class="stat"><div class="stat-val" id="stat-bundles">0</div><div class="stat-lbl">Bundles</div></div>
      <div class="stat"><div class="stat-val" id="stat-skills">0</div><div class="stat-lbl">Skills</div></div>
      <div class="stat"><div class="stat-val" id="stat-shown">0</div><div class="stat-lbl">Shown</div></div>
    </div>
  </div>

  <div class="search-wrap">
    <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
      <path d="M11.742 10.344a6.5 6.5 0 1 0-1.397 1.398h-.001c.03.04.062.078.098.115l3.85 3.85a1 1 0 0 0 1.415-1.414l-3.85-3.85a1.007 1.007 0 0 0-.115-.099zm-5.242 1.656a5.5 5.5 0 1 1 0-11 5.5 5.5 0 0 1 0 11z"/>
    </svg>
    <input id="search" type="text" placeholder="Search skills, bundles, descriptions…" autocomplete="off" spellcheck="false">
  </div>

  <div id="bundles"></div>
  <div class="no-results" id="no-results">No skills match your search.</div>

  <div class="footer">
    Updated <span id="updated-at"></span> &nbsp;·&nbsp;
    <a href="https://github.com/amdmax/claude_marketplace" target="_blank">github.com/amdmax/claude_marketplace</a>
  </div>
</div>

<script>
const DATA = __DATA__;

function esc(s){
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

function chips(arr, cls){
  if(!arr||!arr.length) return '';
  return arr.map(t=>`<span class="chip ${cls}">${esc(t)}</span>`).join('');
}

function buildUI(){
  document.getElementById('stat-bundles').textContent = DATA.total_bundles;
  document.getElementById('stat-skills').textContent = DATA.total_skills;
  document.getElementById('stat-shown').textContent = DATA.total_skills;
  document.getElementById('updated-at').textContent = DATA.generated_at.replace('T',' ').replace('Z',' UTC');

  const container = document.getElementById('bundles');
  DATA.bundles.forEach((bundle, bi) => {
    const card = document.createElement('div');
    card.className = 'bundle-card';
    card.dataset.bi = bi;

    const skillsHtml = bundle.skills.map((sk, si) => {
      const excerpt = sk.description.replace(/\n/g,' ').slice(0,100);
      const toolChips = chips(sk.tools,'chip-tool');
      const tagChips  = chips(sk.tags,'chip-tag');
      const hookChips = chips(sk.hooks,'chip-hook');
      const hasTools  = sk.tools.length>0;
      const hasTags   = sk.tags.length>0;
      const hasHooks  = sk.hooks.length>0;
      const toolRow   = hasTools  ? `<div class="detail-row"><span class="detail-label">Tools</span><div class="chips">${toolChips}</div></div>` : '';
      const tagRow    = hasTags   ? `<div class="detail-row"><span class="detail-label">Tags</span><div class="chips">${tagChips}</div></div>` : '';
      const hookRow   = hasHooks  ? `<div class="detail-row"><span class="detail-label">Hooks</span><div class="chips">${hookChips}</div></div>` : '';
      const authorStr = sk.author ? `<div class="detail-row"><span class="detail-label">Author</span><span style="color:var(--muted);font-size:12px">${esc(sk.author)}</span></div>` : '';
      const installName = sk.name.includes(':') ? sk.name : sk.name;
      return `
      <div class="skill-row" data-si="${si}">
        <div class="skill-summary">
          <span class="skill-name">/${esc(installName)}</span>
          <span class="skill-excerpt">${esc(excerpt)}</span>
          <svg class="skill-chevron" viewBox="0 0 16 16" fill="currentColor"><path d="M6.22 3.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L9.94 8 6.22 4.28a.75.75 0 0 1 0-1.06z"/></svg>
        </div>
        <div class="skill-detail">
          <div class="skill-desc">${esc(sk.description||'No description.')}</div>
          ${toolRow}${tagRow}${hookRow}${authorStr}
          <div class="install-hint">Install: <span>/plugin install</span> then use <span>/${esc(installName)}</span></div>
        </div>
      </div>`;
    }).join('');

    card.innerHTML = `
      <div class="bundle-header">
        <svg class="chevron" viewBox="0 0 16 16" fill="currentColor"><path d="M6.22 3.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L9.94 8 6.22 4.28a.75.75 0 0 1 0-1.06z"/></svg>
        <div class="bundle-meta">
          <div class="bundle-top">
            <span class="bundle-name">${esc(bundle.name)}</span>
            <span class="badge">${bundle.skills.length} skill${bundle.skills.length!==1?'s':''}</span>
          </div>
          <div class="bundle-desc">${esc(bundle.description)}</div>
          <div class="keywords">${bundle.keywords.map(k=>`<span class="kw">${esc(k)}</span>`).join('')}</div>
        </div>
      </div>
      <div class="skills-list">${skillsHtml}</div>`;

    // Bundle expand/collapse
    card.querySelector('.bundle-header').addEventListener('click', ()=>{
      card.classList.toggle('open');
    });

    // Skill expand/collapse
    card.querySelectorAll('.skill-row').forEach(row=>{
      row.querySelector('.skill-summary').addEventListener('click', e=>{
        e.stopPropagation();
        const wasActive = row.classList.contains('active');
        card.querySelectorAll('.skill-row').forEach(r=>r.classList.remove('active'));
        if(!wasActive) row.classList.add('active');
      });
    });

    container.appendChild(card);
  });
}

function search(q){
  q = q.trim().toLowerCase();
  let totalShown = 0;
  document.querySelectorAll('.bundle-card').forEach((card, bi)=>{
    const bundle = DATA.bundles[bi];
    if(!q){
      card.classList.remove('hidden');
      card.querySelectorAll('.skill-row').forEach(r=>r.classList.remove('hidden'));
      totalShown += bundle.skills.length;
      return;
    }
    const bMatch = bundle.name.toLowerCase().includes(q) ||
                   bundle.description.toLowerCase().includes(q) ||
                   bundle.keywords.some(k=>k.toLowerCase().includes(q));
    let skillShown = 0;
    card.querySelectorAll('.skill-row').forEach((row, si)=>{
      const sk = bundle.skills[si];
      const match = bMatch ||
        sk.name.toLowerCase().includes(q) ||
        sk.description.toLowerCase().includes(q) ||
        sk.tags.some(t=>t.toLowerCase().includes(q)) ||
        sk.tools.some(t=>t.toLowerCase().includes(q));
      row.classList.toggle('hidden', !match);
      if(match) skillShown++;
    });
    card.classList.toggle('hidden', skillShown===0);
    if(skillShown>0){
      card.classList.add('open');
      totalShown += skillShown;
    }
  });
  document.getElementById('stat-shown').textContent = totalShown;
  document.getElementById('no-results').style.display = totalShown===0?'block':'none';
}

buildUI();
document.getElementById('search').addEventListener('input', e=>search(e.target.value));
</script>
</body>
</html>"""


def generate(output: Path) -> None:
    data = load_data()
    data_json = json.dumps(data, ensure_ascii=False)
    html = HTML_TEMPLATE.replace("__DATA__", data_json)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(html, encoding="utf-8")
    print(f"Generated: {output}")
    print(f"  {data['total_bundles']} bundles, {data['total_skills']} skills")


def main():
    parser = argparse.ArgumentParser(description="Generate skills discovery HTML page")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                        help=f"Output path (default: {DEFAULT_OUTPUT})")
    args = parser.parse_args()
    generate(args.output)


if __name__ == "__main__":
    main()
