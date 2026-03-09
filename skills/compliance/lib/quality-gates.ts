/**
 * Quality Gates
 *
 * Enforces quality standards before commits and PRs.
 */

import { AcceptanceCriterion } from './ac-generator';

export interface QualityGateConfig {
  p0_threshold: number;
  p1_threshold: number;
  p2_threshold: number;
  block_commit_on_p0_gaps: boolean;
  block_pr_on_p1_gaps: boolean;
}

export interface QualityGateResult {
  passed: boolean;
  p0Passed: boolean;
  p0Gaps: AcceptanceCriterion[];
  p1Gaps: AcceptanceCriterion[];
  p2Gaps: AcceptanceCriterion[];
  summary: {
    total: number;
    tested: number;
    p0Total: number;
    p0Met: number;
    p1Total: number;
    p1Met: number;
    p2Total: number;
    p2Met: number;
  };
  blockers: string[];
  warnings: string[];
}

/**
 * Validate P0 acceptance criteria coverage
 */
export function validateP0Coverage(
  acs: AcceptanceCriterion[],
  config: QualityGateConfig
): QualityGateResult {
  const p0ACs = acs.filter(ac => ac.priority === 'P0');
  const p1ACs = acs.filter(ac => ac.priority === 'P1');
  const p2ACs = acs.filter(ac => ac.priority === 'P2');

  const p0Tested = p0ACs.filter(ac => ac.tested);
  const p1Tested = p1ACs.filter(ac => ac.tested);
  const p2Tested = p2ACs.filter(ac => ac.tested);

  const p0Coverage = p0ACs.length > 0 ? (p0Tested.length / p0ACs.length) * 100 : 100;
  const p1Coverage = p1ACs.length > 0 ? (p1Tested.length / p1ACs.length) * 100 : 100;
  const p2Coverage = p2ACs.length > 0 ? (p2Tested.length / p2ACs.length) * 100 : 100;

  const p0Passed = p0Coverage >= config.p0_threshold;
  const p1Passed = p1Coverage >= config.p1_threshold;
  const p2Passed = p2Coverage >= config.p2_threshold;

  const p0Gaps = p0ACs.filter(ac => !ac.tested);
  const p1Gaps = p1ACs.filter(ac => !ac.tested);
  const p2Gaps = p2ACs.filter(ac => !ac.tested);

  const blockers: string[] = [];
  const warnings: string[] = [];

  // P0 blockers
  if (!p0Passed && config.block_commit_on_p0_gaps) {
    blockers.push(
      `P0 coverage: ${Math.round(p0Coverage)}% (${p0Tested.length}/${p0ACs.length} tested, requires ${config.p0_threshold}%)`
    );
    p0Gaps.forEach(ac => {
      blockers.push(`  - ${ac.id}: ${ac.description}`);
    });
  }

  // P1 warnings
  if (!p1Passed && config.block_pr_on_p1_gaps && p1ACs.length > 0) {
    warnings.push(
      `P1 coverage: ${Math.round(p1Coverage)}% (${p1Tested.length}/${p1ACs.length} tested, recommends ${config.p1_threshold}%)`
    );
  }

  // P2 info
  if (!p2Passed && p2ACs.length > 0) {
    warnings.push(
      `P2 coverage: ${Math.round(p2Coverage)}% (${p2Tested.length}/${p2ACs.length} tested, recommends ${config.p2_threshold}%)`
    );
  }

  const totalTested = acs.filter(ac => ac.tested).length;

  return {
    passed: p0Passed,
    p0Passed,
    p0Gaps,
    p1Gaps,
    p2Gaps,
    summary: {
      total: acs.length,
      tested: totalTested,
      p0Total: p0ACs.length,
      p0Met: p0Tested.length,
      p1Total: p1ACs.length,
      p1Met: p1Tested.length,
      p2Total: p2ACs.length,
      p2Met: p2Tested.length
    },
    blockers,
    warnings
  };
}

/**
 * Generate quality gate report
 */
export function generateGateReport(result: QualityGateResult): string {
  const lines: string[] = [];

  lines.push('# Quality Gate Report\n');

  // Summary
  lines.push('## Summary\n');
  lines.push(`**Status:** ${result.passed ? '✅ PASSED' : '❌ BLOCKED'}\n`);
  lines.push(`- Total ACs: ${result.summary.total}`);
  lines.push(`- Tested: ${result.summary.tested}/${result.summary.total} (${Math.round((result.summary.tested / result.summary.total) * 100)}%)`);
  lines.push(`- P0: ${result.summary.p0Met}/${result.summary.p0Total} tested`);
  lines.push(`- P1: ${result.summary.p1Met}/${result.summary.p1Total} tested`);
  lines.push(`- P2: ${result.summary.p2Met}/${result.summary.p2Total} tested\n`);

  // Blockers
  if (result.blockers.length > 0) {
    lines.push('## ❌ Blockers\n');
    lines.push('The following issues must be resolved before committing:\n');
    result.blockers.forEach(blocker => {
      lines.push(blocker);
    });
    lines.push('');
  }

  // Warnings
  if (result.warnings.length > 0) {
    lines.push('## ⚠️  Warnings\n');
    result.warnings.forEach(warning => {
      lines.push(warning);
    });
    lines.push('');
  }

  // P0 Gaps detail
  if (result.p0Gaps.length > 0) {
    lines.push('## P0 Gaps\n');
    result.p0Gaps.forEach(ac => {
      lines.push(`### ${ac.id}: ${ac.description}\n`);
      lines.push(`- **Type:** ${ac.type}`);
      lines.push(`- **Source:** ${ac.source}`);
      lines.push(`- **Gap:** ${ac.gap || 'Not tested'}\n`);

      if (ac.evidence.implementation.length > 0) {
        lines.push('**Implementation:**');
        ac.evidence.implementation.forEach(impl => {
          lines.push(`  - ${impl}`);
        });
        lines.push('');
      } else {
        lines.push('**Implementation:** Not found\n');
      }
    });
  }

  return lines.join('\n');
}

/**
 * Block commit if quality gates fail
 */
export function blockCommit(result: QualityGateResult, generatedStubs: string[]): never {
  console.error('❌ Commit blocked: P0 acceptance criteria not fully tested\n');

  console.log('Missing tests for:');
  result.p0Gaps.forEach(ac => {
    console.log(`  - ${ac.id}: ${ac.description}`);
  });

  if (generatedStubs.length > 0) {
    console.log('\nGenerated test stubs:');
    generatedStubs.forEach(stub => {
      console.log(`  - ${stub}`);
    });
  }

  console.log('\nImplement tests and run /commit again.');

  process.exit(1);
}

/**
 * Display compliance summary (non-blocking)
 */
export function displayComplianceSummary(result: QualityGateResult): void {
  if (result.passed) {
    console.log(`✓ Compliance: ${result.summary.tested}/${result.summary.total} ACs tested`);

    if (result.warnings.length > 0) {
      console.log('\n⚠️  Warnings:');
      result.warnings.forEach(warning => {
        console.log(`  ${warning}`);
      });
    }
  } else {
    console.log(`⚠️  Compliance: ${result.summary.tested}/${result.summary.total} ACs tested`);
    console.log(`   P0: ${result.summary.p0Met}/${result.summary.p0Total} (${result.blockers.length} gaps)`);
  }
}
