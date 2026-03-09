/**
 * Acceptance Criteria Generator
 *
 * Extracts or generates acceptance criteria from active story.
 * Supports parsing from story body markdown and generation from title + NFRs.
 */

export interface AcceptanceCriterion {
  id: string;
  priority: 'P0' | 'P1' | 'P2';
  description: string;
  type: 'functional' | 'non-functional' | 'constraint';
  source: 'story' | 'nfr' | 'generated';
  keywords: string[];
  implemented: boolean;
  tested: boolean;
  tests: string[];
  coverage: number;
  evidence: {
    implementation: string[];
    tests: string[];
  };
  gap?: string;
}

export interface ActiveStory {
  issueNumber: number;
  title: string;
  body: string;
  url: string;
  nfrs?: {
    performance?: {
      maxResponseTime?: string;
      maxLatency?: string;
      throughput?: string;
    };
    security?: {
      authentication?: string;
      authorization?: string;
      encryption?: string;
    };
    reliability?: {
      availability?: string;
      errorRate?: string;
      recoveryTime?: string;
    };
  };
  context?: {
    relatedCode?: Array<{ path: string }>;
  };
}

const STOP_WORDS = new Set([
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
  'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would', 'should',
  'could', 'may', 'might', 'must', 'can', 'this', 'that', 'these', 'those'
]);

/**
 * Parse acceptance criteria from story body markdown
 */
export function parseACsFromStory(story: ActiveStory): AcceptanceCriterion[] {
  const acs: AcceptanceCriterion[] = [];

  if (!story.body.includes('Acceptance Criteria')) {
    return acs;
  }

  const lines = story.body.split('\n');
  let inAcSection = false;
  let currentPriority: 'P0' | 'P1' | 'P2' = 'P0';

  for (const line of lines) {
    // Detect AC section start
    if (line.match(/##\s*Acceptance Criteria/i)) {
      inAcSection = true;
      continue;
    }

    // End of section
    if (inAcSection && line.match(/^##\s+/)) {
      break;
    }

    if (!inAcSection) continue;

    // Detect priority headers
    if (line.match(/Must Have.*\(P0\)/i) || line.match(/\*\*P0\*\*/)) {
      currentPriority = 'P0';
      continue;
    }
    if (line.match(/Should Have.*\(P1\)/i) || line.match(/\*\*P1\*\*/)) {
      currentPriority = 'P1';
      continue;
    }
    if (line.match(/Could Have.*\(P2\)/i) || line.match(/\*\*P2\*\*/)) {
      currentPriority = 'P2';
      continue;
    }

    // Parse checklist items: - [ ] description
    const match = line.match(/^[-*]\s+\[[ x]\]\s+(.+)/);
    if (match) {
      const description = match[1].trim();
      acs.push({
        id: `AC-${String(acs.length + 1).padStart(3, '0')}`,
        priority: currentPriority,
        description,
        type: inferACType(description),
        source: 'story',
        keywords: extractKeywords(description),
        implemented: false,
        tested: false,
        tests: [],
        coverage: 0,
        evidence: {
          implementation: [],
          tests: []
        }
      });
    }
  }

  return acs;
}

/**
 * Generate acceptance criteria from story metadata when not in body
 */
export function generateACsFromStory(story: ActiveStory): AcceptanceCriterion[] {
  const acs: AcceptanceCriterion[] = [];

  // Generate functional AC from title
  const functionalAC: AcceptanceCriterion = {
    id: `AC-${String(acs.length + 1).padStart(3, '0')}`,
    priority: 'P0',
    description: `${story.title} works correctly`,
    type: 'functional',
    source: 'generated',
    keywords: extractKeywords(story.title),
    implemented: false,
    tested: false,
    tests: [],
    coverage: 0,
    evidence: {
      implementation: [],
      tests: []
    }
  };
  acs.push(functionalAC);

  return acs;
}

/**
 * Generate NFR-based acceptance criteria
 */
export function generateNFRACs(nfrs?: ActiveStory['nfrs']): AcceptanceCriterion[] {
  const acs: AcceptanceCriterion[] = [];

  if (!nfrs) return acs;

  // Performance ACs
  if (nfrs.performance?.maxResponseTime) {
    acs.push({
      id: '', // Will be assigned by caller
      priority: 'P0',
      description: `Response time < ${nfrs.performance.maxResponseTime}`,
      type: 'non-functional',
      source: 'nfr',
      keywords: ['response', 'time', 'performance', 'latency'],
      implemented: false,
      tested: false,
      tests: [],
      coverage: 0,
      evidence: {
        implementation: [],
        tests: []
      }
    });
  }

  if (nfrs.performance?.throughput) {
    acs.push({
      id: '',
      priority: 'P1',
      description: `System handles ${nfrs.performance.throughput} requests`,
      type: 'non-functional',
      source: 'nfr',
      keywords: ['throughput', 'requests', 'performance', 'load'],
      implemented: false,
      tested: false,
      tests: [],
      coverage: 0,
      evidence: {
        implementation: [],
        tests: []
      }
    });
  }

  // Security ACs
  if (nfrs.security?.authentication) {
    acs.push({
      id: '',
      priority: 'P0',
      description: `Authentication via ${nfrs.security.authentication}`,
      type: 'non-functional',
      source: 'nfr',
      keywords: ['authentication', 'auth', 'security'],
      implemented: false,
      tested: false,
      tests: [],
      coverage: 0,
      evidence: {
        implementation: [],
        tests: []
      }
    });
  }

  if (nfrs.security?.authorization) {
    acs.push({
      id: '',
      priority: 'P0',
      description: `Authorization checks ${nfrs.security.authorization}`,
      type: 'non-functional',
      source: 'nfr',
      keywords: ['authorization', 'auth', 'permissions', 'security'],
      implemented: false,
      tested: false,
      tests: [],
      coverage: 0,
      evidence: {
        implementation: [],
        tests: []
      }
    });
  }

  // Reliability ACs
  if (nfrs.reliability?.availability) {
    acs.push({
      id: '',
      priority: 'P1',
      description: `Availability ${nfrs.reliability.availability}`,
      type: 'non-functional',
      source: 'nfr',
      keywords: ['availability', 'uptime', 'reliability'],
      implemented: false,
      tested: false,
      tests: [],
      coverage: 0,
      evidence: {
        implementation: [],
        tests: []
      }
    });
  }

  if (nfrs.reliability?.errorRate) {
    acs.push({
      id: '',
      priority: 'P1',
      description: `Error rate < ${nfrs.reliability.errorRate}`,
      type: 'non-functional',
      source: 'nfr',
      keywords: ['error', 'rate', 'reliability', 'failure'],
      implemented: false,
      tested: false,
      tests: [],
      coverage: 0,
      evidence: {
        implementation: [],
        tests: []
      }
    });
  }

  return acs;
}

/**
 * Extract searchable keywords from AC description
 */
export function extractKeywords(description: string): string[] {
  // Remove punctuation and convert to lowercase
  const cleaned = description.toLowerCase().replace(/[^\w\s]/g, ' ');

  // Split into words
  const words = cleaned.split(/\s+/).filter(w => w.length > 0);

  // Remove stop words and duplicates
  const keywords = [...new Set(words.filter(w => !STOP_WORDS.has(w)))];

  // Include camelCase and snake_case variants
  const expanded: string[] = [];
  for (const keyword of keywords) {
    expanded.push(keyword);

    // Add camelCase variant
    if (keyword.includes('_')) {
      const camel = keyword.split('_')
        .map((part, i) => i === 0 ? part : part.charAt(0).toUpperCase() + part.slice(1))
        .join('');
      expanded.push(camel);
    }
  }

  return [...new Set(expanded)];
}

/**
 * Infer AC type from description
 */
export function inferACType(description: string): 'functional' | 'non-functional' | 'constraint' {
  const lower = description.toLowerCase();

  // Non-functional indicators
  const nfrKeywords = [
    'response time', 'latency', 'performance', 'throughput',
    'availability', 'uptime', 'reliability',
    'authentication', 'authorization', 'security', 'encryption',
    'error rate', 'recovery'
  ];

  if (nfrKeywords.some(kw => lower.includes(kw))) {
    return 'non-functional';
  }

  // Constraint indicators
  const constraintKeywords = [
    'must not', 'cannot', 'should not',
    'limit', 'maximum', 'minimum',
    'constraint', 'restriction'
  ];

  if (constraintKeywords.some(kw => lower.includes(kw))) {
    return 'constraint';
  }

  // Default to functional
  return 'functional';
}

/**
 * Extract and generate all acceptance criteria for a story
 */
export function extractAcceptanceCriteria(story: ActiveStory): AcceptanceCriterion[] {
  let acs: AcceptanceCriterion[] = [];

  // Try parsing from story body
  const parsedACs = parseACsFromStory(story);
  if (parsedACs.length > 0) {
    acs = parsedACs;
    console.log(`✓ Extracted ${acs.length} ACs from story`);
  } else {
    // Generate if missing
    console.log('📝 Generating ACs from story + NFRs...');
    acs = generateACsFromStory(story);
  }

  // Augment with NFRs (always)
  const nfrACs = generateNFRACs(story.nfrs);

  // Assign IDs to NFR ACs
  const allACs = [...acs, ...nfrACs];
  return allACs.map((ac, i) => ({
    ...ac,
    id: `AC-${String(i + 1).padStart(3, '0')}`
  }));
}
