#!/usr/bin/env node

/**
 * Pre-tool-use hook: Block gh pr merge commands
 *
 * This hook prevents Claude from automatically merging pull requests.
 * PRs should be merged manually after review.
 */

import * as fs from 'fs';

interface ToolCall {
  tool: string;
  parameters?: {
    command?: string;
    [key: string]: any;
  };
}

async function main(): Promise<void> {
  try {
    // Read tool call from stdin
    const input = fs.readFileSync(0, 'utf-8');
    const toolCall: ToolCall = JSON.parse(input);

    // Block gh pr merge commands
    if (
      toolCall.tool === 'Bash' &&
      toolCall.parameters?.command?.includes('gh pr merge')
    ) {
      console.error('❌ Blocked: gh pr merge commands are disabled');
      console.error('Please merge pull requests manually after code review');
      process.exit(1);
    }

    // Block git push to master/main
    if (toolCall.tool === 'Bash' && toolCall.parameters?.command) {
      const command = toolCall.parameters.command;
      if (command.match(/git\s+push/) && command.match(/\s+(origin\s+)?(master|main)/)) {
        console.error('❌ Blocked: Direct push to master/main is not allowed');
        console.error('');
        console.error('Policy: ALL changes must go through pull requests. No exceptions.');
        console.error('');
        console.error('To fix:');
        console.error('  1. Create a feature branch: git checkout -b feature/my-change');
        console.error('  2. Push the feature branch: git push -u origin feature/my-change');
        console.error('  3. Create a PR with: /mr');
        process.exit(1);
      }
    }

    // Allow all other tool calls
    process.exit(0);
  } catch (error) {
    // If there's an error parsing, allow the tool call to proceed
    console.error('Hook error:', error);
    process.exit(0);
  }
}

main();
