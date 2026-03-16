/**
 * Test Linker
 *
 * Links acceptance criteria to test files via keyword search and similarity scoring.
 */

import { AcceptanceCriterion } from './ac-generator';

export interface TestMatch {
  filePath: string;
  testName: string;
  similarity: number;
  lineNumber?: number;
}

export interface ACCoverageResult {
  ac: AcceptanceCriterion;
  implementationFiles: string[];
  testFiles: TestMatch[];
  coveragePercent: number;
}

/**
 * Calculate similarity between AC description and test description
 * Uses Jaccard similarity on keyword sets
 */
export function calculateSimilarity(acKeywords: string[], testDescription: string): number {
  const testWords = new Set(
    testDescription
      .toLowerCase()
      .replace(/[^\w\s]/g, ' ')
      .split(/\s+/)
      .filter(w => w.length > 2)
  );

  const acWordSet = new Set(acKeywords.map(k => k.toLowerCase()));

  // Calculate intersection
  const intersection = new Set([...acWordSet].filter(w => testWords.has(w)));

  // Calculate union
  const union = new Set([...acWordSet, ...testWords]);

  if (union.size === 0) return 0;

  // Jaccard similarity
  return intersection.size / union.size;
}

/**
 * Parse test file to extract describe/it blocks
 */
export function extractTestDescriptions(testFileContent: string): Array<{ name: string; line: number }> {
  const tests: Array<{ name: string; line: number }> = [];
  const lines = testFileContent.split('\n');

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];

    // Match: describe('...', ...) or it('...', ...)
    const describeMatch = line.match(/(?:describe|it|test)\s*\(\s*['"`](.+?)['"`]/);
    if (describeMatch) {
      tests.push({
        name: describeMatch[1],
        line: i + 1
      });
    }
  }

  return tests;
}

/**
 * Search codebase for implementation of AC
 */
export async function findImplementation(
  ac: AcceptanceCriterion,
  grepTool: (pattern: string, options?: any) => Promise<string[]>
): Promise<string[]> {
  const implementationFiles = new Set<string>();

  // Search for each keyword
  for (const keyword of ac.keywords.slice(0, 5)) { // Limit to top 5 keywords
    try {
      const results = await grepTool(keyword, {
        output_mode: 'files_with_matches',
        type: 'ts',
        glob: '**/*.ts',
      });

      results.forEach(file => {
        // Exclude test files
        if (!file.includes('__tests__') && !file.includes('.test.ts')) {
          implementationFiles.add(file);
        }
      });
    } catch (error) {
      // Keyword not found, continue
    }
  }

  return Array.from(implementationFiles);
}

/**
 * Search test files for AC coverage
 */
export async function findTestsForAC(
  ac: AcceptanceCriterion,
  grepTool: (pattern: string, options?: any) => Promise<string[]>,
  readTool: (filePath: string) => Promise<string>,
  similarityThreshold: number = 0.7
): Promise<TestMatch[]> {
  const testMatches: TestMatch[] = [];

  // Build search pattern from keywords (regex OR)
  const pattern = ac.keywords.slice(0, 5).join('|');

  try {
    // Search test files
    const testFiles = await grepTool(pattern, {
      output_mode: 'files_with_matches',
      glob: '**/__tests__/**/*.test.ts',
      '-i': true // Case insensitive
    });

    // Analyze each test file
    for (const testFile of testFiles) {
      try {
        const content = await readTool(testFile);
        const testDescriptions = extractTestDescriptions(content);

        // Calculate similarity for each test
        for (const test of testDescriptions) {
          const similarity = calculateSimilarity(ac.keywords, test.name);

          if (similarity >= similarityThreshold) {
            testMatches.push({
              filePath: testFile,
              testName: test.name,
              similarity,
              lineNumber: test.line
            });
          }
        }
      } catch (error) {
        // File read error, skip
        console.error(`⚠️  Could not read ${testFile}`);
      }
    }
  } catch (error) {
    // No test files found
  }

  // Sort by similarity (highest first)
  return testMatches.sort((a, b) => b.similarity - a.similarity);
}

/**
 * Calculate per-AC coverage from Jest coverage report
 */
export function calculateACCoverage(
  implementationFiles: string[],
  coverageData: any
): number {
  if (implementationFiles.length === 0) return 0;

  let totalStatements = 0;
  let coveredStatements = 0;

  for (const file of implementationFiles) {
    const fileCoverage = coverageData[file];
    if (!fileCoverage) continue;

    const statements = fileCoverage.s || {};
    for (const count of Object.values(statements) as number[]) {
      totalStatements++;
      if (count > 0) coveredStatements++;
    }
  }

  if (totalStatements === 0) return 0;

  return Math.round((coveredStatements / totalStatements) * 100);
}

/**
 * Link all ACs to tests and calculate coverage
 */
export async function linkACsToTests(
  acs: AcceptanceCriterion[],
  grepTool: (pattern: string, options?: any) => Promise<string[]>,
  readTool: (filePath: string) => Promise<string>,
  coverageData?: any,
  similarityThreshold: number = 0.7
): Promise<ACCoverageResult[]> {
  const results: ACCoverageResult[] = [];

  for (const ac of acs) {
    console.log(`🔍 Analyzing ${ac.id}: ${ac.description}`);

    // Find implementation
    const implementationFiles = await findImplementation(ac, grepTool);

    // Find tests
    const testMatches = await findTestsForAC(ac, grepTool, readTool, similarityThreshold);

    // Calculate coverage
    const coveragePercent = coverageData
      ? calculateACCoverage(implementationFiles, coverageData)
      : 0;

    // Update AC
    ac.implemented = implementationFiles.length > 0;
    ac.tested = testMatches.length > 0;
    ac.tests = testMatches.map(t => t.filePath);
    ac.coverage = coveragePercent;
    ac.evidence = {
      implementation: implementationFiles,
      tests: testMatches.map(t => `${t.filePath}:${t.lineNumber}`)
    };

    if (!ac.tested) {
      ac.gap = ac.implemented
        ? 'Implementation exists but no tests found'
        : 'Not implemented';
    }

    results.push({
      ac,
      implementationFiles,
      testFiles: testMatches,
      coveragePercent
    });
  }

  return results;
}
