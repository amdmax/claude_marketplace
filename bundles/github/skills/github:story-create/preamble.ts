import { execSync } from 'child_process';

try {
  execSync('gh auth status', { stdio: 'pipe' });
  console.log('## Preamble: Pre-flight Checks');
  console.log('✓ GitHub CLI authenticated');
} catch {
  console.error('## Preamble: Pre-flight Checks');
  console.error('❌ GitHub CLI not authenticated. Run: gh auth login');
  process.exit(1);
}
