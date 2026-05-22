# Error Handling

## No Active Story

**Detection:**
```bash
STORY_FILE="$CLAUDE_PROJECT_DIR/$AGENT_DOCS_DIR/active-story.yaml"
if [ ! -f "$STORY_FILE" ]; then
  echo "❌ No active story found. Run /fetch-story first."
  exit 1
fi
```

## Active Story Already Has NFRs

**Detection:**
```javascript
if (story.nfrs && Object.keys(story.nfrs).length > 0) {
  // NFRs already exist
}
```

**Warning:**
```
⚠️  NFRs already exist for this story

Options:
  [1] Keep existing NFRs (cancel)
  [2] Re-collect NFRs (overwrite existing)
  [3] View full existing NFRs
```

## File Write Failed

**Detection:**
```javascript
try {
  fs.writeFileSync('$AGENT_DOCS_DIR/active-story.yaml', ...);
} catch (error) {
  console.error('❌ Failed to save NFRs:', error.message);
}
```

**Message:**
```
❌ Failed to save NFRs to $AGENT_DOCS_DIR/active-story.yaml

Possible causes: file permissions, disk full, file locked.
Check permissions and try again.
```
