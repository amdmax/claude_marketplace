#!/usr/bin/env node
/**
 * validate-action.ts - Validate GitHub Actions composite action files
 * Exit codes: 0 = valid, 2 = invalid (blocks write)
 */

import * as fs from 'fs';
import * as yaml from 'yaml';

interface ValidationConfig {
  validation: {
    syntax_check: boolean;
    require_shell: boolean;
    require_descriptions: boolean;
    warn_checkout: boolean;
  };
}

interface CompositeAction {
  name?: string;
  description?: string;
  inputs?: Record<string, { description?: string; required?: boolean; default?: string }>;
  outputs?: Record<string, { description?: string; value?: string }>;
  runs?: {
    using?: string;
    steps?: Array<{
      name?: string;
      uses?: string;
      run?: string;
      shell?: string;
      with?: Record<string, unknown>;
      env?: Record<string, unknown>;
      if?: string;
      id?: string;
      'working-directory'?: string;
    }>;
  };
}

const VALID_SHELLS = ['bash', 'sh', 'pwsh', 'python', 'cmd'];

function loadConfig(scriptDir: string): ValidationConfig {
  const configPath = `${scriptDir}/config.yaml`;
  try {
    const configContent = fs.readFileSync(configPath, 'utf8');
    return yaml.parse(configContent) as ValidationConfig;
  } catch {
    // Default config if file not found
    return {
      validation: {
        syntax_check: true,
        require_shell: true,
        require_descriptions: true,
        warn_checkout: true,
      },
    };
  }
}

function validateAction(actionFile: string, config: ValidationConfig): { valid: boolean; errors: string[]; warnings: string[] } {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check file exists
  if (!fs.existsSync(actionFile)) {
    errors.push(`File not found: ${actionFile}`);
    return { valid: false, errors, warnings };
  }

  let action: CompositeAction;

  // Check 1: Valid YAML syntax
  try {
    const content = fs.readFileSync(actionFile, 'utf8');
    action = yaml.parse(content) as CompositeAction;
  } catch (error) {
    if (config.validation.syntax_check) {
      errors.push(`Invalid YAML syntax: ${error instanceof Error ? error.message : String(error)}`);
    }
    return { valid: false, errors, warnings };
  }

  // Check 2: Required top-level fields
  const requiredFields: Array<keyof CompositeAction> = ['name', 'description', 'runs'];
  for (const field of requiredFields) {
    if (!action[field]) {
      errors.push(`Missing required field: ${field}`);
    }
  }

  // Check 3: runs.using must be "composite"
  if (action.runs?.using !== 'composite') {
    errors.push(`runs.using must be 'composite', found: ${action.runs?.using || 'undefined'}`);
  }

  // Check 4: All run steps must have shell specified
  if (config.validation.require_shell && action.runs?.steps) {
    const stepsWithoutShell = action.runs.steps
      .filter(step => step.run && !step.shell)
      .map(step => step.name || '(unnamed step)');

    if (stepsWithoutShell.length > 0) {
      errors.push('Found run: steps without shell: bash');
      errors.push(`  Steps missing shell:\n${stepsWithoutShell.map(s => `    - ${s}`).join('\n')}`);
    }
  }

  // Check 5: Inputs should have descriptions
  if (config.validation.require_descriptions && action.inputs) {
    const inputsWithoutDesc = Object.entries(action.inputs)
      .filter(([, input]) => !input.description)
      .map(([name]) => name);

    if (inputsWithoutDesc.length > 0) {
      warnings.push(`Inputs missing descriptions:\n${inputsWithoutDesc.map(s => `    - ${s}`).join('\n')}`);
    }
  }

  // Check 6: Warn if action includes checkout
  if (config.validation.warn_checkout && action.runs?.steps) {
    const hasCheckout = action.runs.steps.some(
      step => step.uses && step.uses.includes('checkout')
    );

    if (hasCheckout) {
      warnings.push("Composite action includes actions/checkout (caller's responsibility)");
    }
  }

  // Check 7: Validate shell values
  if (action.runs?.steps) {
    const invalidShells = action.runs.steps
      .filter(step => step.shell && !VALID_SHELLS.includes(step.shell))
      .map(step => step.shell);

    if (invalidShells.length > 0) {
      errors.push(`Invalid shell values: ${invalidShells.join(', ')} (must be one of: ${VALID_SHELLS.join(', ')})`);
    }
  }

  return {
    valid: errors.length === 0,
    errors,
    warnings,
  };
}

function main() {
  const actionFile = process.argv[2];

  if (!actionFile) {
    console.error('❌ Usage: validate-action.ts <action.yml>');
    process.exit(2);
  }

  const scriptDir = __dirname;
  const config = loadConfig(scriptDir);

  console.log(`🔍 Validating: ${actionFile}`);

  const result = validateAction(actionFile, config);

  // Print warnings
  if (result.warnings.length > 0) {
    result.warnings.forEach(warning => console.log(`⚠️  Warning: ${warning}`));
  }

  // Print errors
  if (result.errors.length > 0) {
    result.errors.forEach(error => console.log(`❌ ${error}`));
    console.log('');
    console.log(`❌ Action validation failed with ${result.errors.length} error(s)`);
    console.log('');
    console.log('Common fixes:');
    console.log("  - Add 'shell: bash' to all run: steps");
    console.log('  - Ensure name, description, and runs.using are present');
    console.log("  - Set runs.using to 'composite'");
    console.log('  - Add descriptions to all inputs');
    process.exit(2);
  }

  console.log('✓ Action validation passed');
  process.exit(0);
}

main();
