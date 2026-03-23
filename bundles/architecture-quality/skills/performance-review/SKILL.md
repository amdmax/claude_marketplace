---
name: performance-review
description: Detect performance issues and inefficiencies
---

# Performance Review

## Overview

Identifies performance bottlenecks, algorithmic inefficiencies, and resource consumption issues in code. Use this skill before committing to catch O(n²) complexity, N+1 queries, memory leaks, and other performance anti-patterns.

**Focus Areas:** Algorithmic complexity, database efficiency, memory management, network optimization, frontend performance, build/bundle optimization.

## Workflow

### 1. Get Changed Files

```bash
git diff --name-only HEAD
# Or for staged files: git diff --cached --name-only
# Or compare branches: git diff --name-only master...HEAD
```

### 2. Analyze Each File

For each changed file:
1. **Read** the file to understand code structure
2. **Calculate complexity** - count loop nesting depth, recursive calls
3. **Search for patterns** - N+1 queries, synchronous operations, unnecessary allocations
4. **Estimate impact** - based on data size, frequency, criticality

### 3. Report Findings

**Format (matches CI/CD):**

```
🔴 CRITICAL | 🟠 MAJOR | 🟡 MINOR

File: path/to/file.ts
Line(s): 42-45
Problem: [Performance issue description with impact estimation]
Fix: [REQUIRED for CRITICAL/MAJOR] - Optimized code example with expected improvement
```

**Severity Assignment:**

- **🔴 CRITICAL**: O(n²+) complexity on unbounded data, guaranteed performance failure at scale
- **🟠 MAJOR**: Significant inefficiency with measurable impact (N+1 queries, blocking operations, memory leaks)
- **🟡 MINOR**: Optimization opportunities with marginal gains (microoptimizations, readability vs speed)

### 4. Summary

```
Total performance issues: X (CRITICAL: Y, MAJOR: Z, MINOR: W)
Files reviewed: N
Estimated impact: [high/medium/low] - based on code path criticality
Most common issues: [top 3 patterns found]

⚠️ Critical findings will cause performance degradation at scale.
```

## Performance Checklist

### 1. Algorithmic Complexity

#### Nested Loops (O(n²) or worse)

**Pattern Search:**
```
for.*for.*{
while.*while.*{
\.forEach\(.*\.forEach\(
\.map\(.*\.map\(
```

**Check for:**
- [ ] Nested loops over same or related datasets
- [ ] O(n²) complexity with unbounded `n`
- [ ] Triple-nested loops (O(n³))
- [ ] Cartesian products of large datasets

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: O(n²) - finds duplicates inefficiently
function findDuplicates(arr: number[]): number[] {
  const dupes: number[] = [];
  for (let i = 0; i < arr.length; i++) {
    for (let j = i + 1; j < arr.length; j++) {
      if (arr[i] === arr[j]) dupes.push(arr[i]);
    }
  }
  return dupes;
}
// Impact: 10,000 items = 50M comparisons (seconds of delay)

// FIX: O(n) using Set
function findDuplicates(arr: number[]): number[] {
  const seen = new Set<number>();
  const dupes = new Set<number>();
  for (const item of arr) {
    if (seen.has(item)) dupes.add(item);
    seen.add(item);
  }
  return Array.from(dupes);
}
// Impact: 10,000 items = 10K operations (milliseconds)
```

#### Linear Search in Loops

**Pattern Search:**
```
for.*\.find\(
for.*\.filter\(
for.*\.includes\(
while.*\.indexOf\(
```

**Check for:**
- [ ] `.find()`, `.includes()`, `.indexOf()` inside loops
- [ ] Repeated linear searches that could use Map/Set
- [ ] Array operations inside hot paths

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: O(n*m) - linear search per item
function filterByIds(items: Item[], allowedIds: number[]): Item[] {
  return items.filter(item => allowedIds.includes(item.id)); // O(n*m)
}

// FIX: O(n+m) using Set for O(1) lookup
function filterByIds(items: Item[], allowedIds: number[]): Item[] {
  const idSet = new Set(allowedIds); // O(m)
  return items.filter(item => idSet.has(item.id)); // O(n)
}
```

#### Recursive Inefficiency

**Pattern Search:**
```
function.*\(.*\).*{.*return.*\1\(
const.*=.*\(.*\).*=>.*\1\(
```

**Check for:**
- [ ] Recursive functions without memoization (Fibonacci, tree traversal)
- [ ] Exponential complexity (O(2ⁿ))
- [ ] Stack overflow risk with deep recursion
- [ ] Missing tail call optimization

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: O(2ⁿ) - exponential complexity
function fibonacci(n: number): number {
  if (n <= 1) return n;
  return fibonacci(n - 1) + fibonacci(n - 2); // Recalculates same values
}
// Impact: fib(40) = 2+ seconds, fib(50) = minutes

// FIX: O(n) with memoization
const fibMemo = new Map<number, number>();
function fibonacci(n: number): number {
  if (n <= 1) return n;
  if (fibMemo.has(n)) return fibMemo.get(n)!;
  const result = fibonacci(n - 1) + fibonacci(n - 2);
  fibMemo.set(n, result);
  return result;
}
// Impact: fib(50) = milliseconds
```

### 2. Database Performance

#### N+1 Query Problem

**Pattern Search:**
```
for.*await.*\.findOne\(
\.map\(async.*=>.*\.query\(
for.*db\.(get|select|find)\(
```

**Check for:**
- [ ] Database queries inside loops
- [ ] Fetching related records one-by-one
- [ ] Sequential async operations that could be parallel
- [ ] Missing eager loading / joins

**🔴 CRITICAL Example:**
```typescript
// VULNERABLE: N+1 queries - 1 query + N queries for comments
async function getPostsWithComments(userId: number) {
  const posts = await db.posts.findMany({ where: { userId } }); // 1 query
  for (const post of posts) {
    post.comments = await db.comments.findMany({ // N queries!
      where: { postId: post.id }
    });
  }
  return posts;
}
// Impact: 100 posts = 101 database round-trips

// FIX: Use JOIN or eager loading
async function getPostsWithComments(userId: number) {
  return db.posts.findMany({
    where: { userId },
    include: { comments: true } // Single query with JOIN
  });
}
// Impact: 100 posts = 1 database round-trip
```

#### Missing Indexes

**Check for:**
- [ ] `WHERE` clauses on unindexed columns
- [ ] Joins without foreign key indexes
- [ ] Sorting large result sets without index
- [ ] Full table scans in queries

**🟠 MAJOR Pattern:**
```sql
-- If you see queries like this in migrations:
SELECT * FROM users WHERE email = ?
-- But no index:
CREATE INDEX idx_users_email ON users(email);
```

#### Inefficient Queries

**Check for:**
- [ ] `SELECT *` when only few columns needed
- [ ] Missing pagination (`LIMIT` clause)
- [ ] Fetching then filtering in application code (should be `WHERE`)
- [ ] Multiple queries that could be combined

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Fetching all columns and filtering in memory
const allUsers = await db.users.findMany(); // Gets ALL users with ALL fields
const activeUsers = allUsers.filter(u => u.status === 'active');

// FIX: Query only what you need
const activeUsers = await db.users.findMany({
  where: { status: 'active' },
  select: { id: true, name: true, email: true } // Only needed fields
});
```

### 3. Memory Management

#### Memory Leaks

**Pattern Search:**
```
setInterval\(.*(?!clearInterval)
addEventListener\(.*(?!removeEventListener)
new.*Observer\(.*(?!disconnect)
\.subscribe\(.*(?!unsubscribe)
```

**Check for:**
- [ ] Event listeners not cleaned up
- [ ] Intervals/timeouts not cleared
- [ ] Observers not disconnected
- [ ] Large objects held in closures
- [ ] Circular references preventing GC

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Memory leak - interval never cleared
class DataPoller {
  start() {
    setInterval(() => {
      this.fetchData(); // `this` keeps object alive forever
    }, 5000);
  }
}

// FIX: Store interval ID and clean up
class DataPoller {
  private intervalId?: NodeJS.Timeout;

  start() {
    this.intervalId = setInterval(() => {
      this.fetchData();
    }, 5000);
  }

  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = undefined;
    }
  }
}
```

#### Unnecessary Memory Allocation

**Pattern Search:**
```
\.map\(\.\.\.filter\(
\.filter\(\.\.\.map\(
new Array\(\)\.fill\(
\[\.\.\.arr\]\.sort\(
```

**Check for:**
- [ ] Chained array operations creating intermediate arrays
- [ ] Copying large arrays unnecessarily
- [ ] String concatenation in loops (use array join)
- [ ] Creating objects in hot paths

**🟡 MINOR Example:**
```typescript
// INEFFICIENT: Creates 3 intermediate arrays
const result = users
  .filter(u => u.active)      // Array 1
  .map(u => u.email)          // Array 2
  .filter(e => e.includes('@company.com')); // Array 3

// BETTER: Single pass with reduce
const result = users.reduce((acc, u) => {
  if (u.active && u.email.includes('@company.com')) {
    acc.push(u.email);
  }
  return acc;
}, [] as string[]);

// Or for large datasets, use generator
function* filterEmails(users: User[]) {
  for (const u of users) {
    if (u.active && u.email.includes('@company.com')) {
      yield u.email;
    }
  }
}
```

### 4. Network Performance

#### Excessive API Calls

**Pattern Search:**
```
for.*fetch\(
for.*axios\.(get|post)
\.map\(.*=>.*fetch\(
```

**Check for:**
- [ ] API calls inside loops (use batch endpoints)
- [ ] Sequential fetches that could be parallel
- [ ] Missing request caching
- [ ] Polling when WebSockets/SSE more appropriate

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Sequential API calls (N * latency)
async function getUserDetails(userIds: number[]) {
  const users = [];
  for (const id of userIds) {
    const user = await fetch(`/api/users/${id}`).then(r => r.json()); // 100ms each
    users.push(user);
  }
  return users;
}
// Impact: 10 users = 1+ seconds

// FIX: Parallel requests or batch API
async function getUserDetails(userIds: number[]) {
  // Option 1: Parallel (if no batch endpoint)
  const promises = userIds.map(id =>
    fetch(`/api/users/${id}`).then(r => r.json())
  );
  return Promise.all(promises); // 100ms total

  // Option 2: Batch endpoint (best)
  return fetch('/api/users/batch', {
    method: 'POST',
    body: JSON.stringify({ ids: userIds })
  }).then(r => r.json()); // Single request
}
```

#### Large Payload Transfer

**Check for:**
- [ ] Sending entire objects when only IDs needed
- [ ] Missing response compression (gzip/brotli)
- [ ] Large JSON responses without pagination
- [ ] Unnecessary data in API responses

**🟡 MINOR Example:**
```typescript
// INEFFICIENT: Sending 100KB+ per request
res.json({
  user: { /* full user object with 50 fields */ },
  posts: posts.map(p => ({ /* full post objects */ })),
  metadata: { /* large metadata */ }
});

// BETTER: Send only required data
res.json({
  user: { id: user.id, name: user.name, avatar: user.avatar },
  posts: posts.map(p => ({ id: p.id, title: p.title, excerpt: p.excerpt })),
  // Omit metadata or fetch separately when needed
});
```

#### Missing Caching

**Check for:**
- [ ] Repeated identical API calls
- [ ] No `Cache-Control` headers
- [ ] Computing same expensive result multiple times
- [ ] Missing memoization for pure functions

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Recomputes on every request
app.get('/api/stats', (req, res) => {
  const stats = calculateExpensiveStats(); // 500ms computation
  res.json(stats);
});

// FIX: Cache with TTL
import NodeCache from 'node-cache';
const cache = new NodeCache({ stdTTL: 300 }); // 5 min TTL

app.get('/api/stats', (req, res) => {
  let stats = cache.get('stats');
  if (!stats) {
    stats = calculateExpensiveStats();
    cache.set('stats', stats);
  }
  res.set('Cache-Control', 'public, max-age=300');
  res.json(stats);
});
```

### 5. Frontend Performance

#### Blocking Synchronous Operations

**Pattern Search:**
```
localStorage\.getItem.*JSON\.parse
fs\.readFileSync
require\(.*\.json
document\.write\(
```

**Check for:**
- [ ] Synchronous file I/O on main thread
- [ ] Large `localStorage` reads without async wrapper
- [ ] Blocking DOM operations
- [ ] Synchronous XHR (deprecated)

#### Missing Lazy Loading

**Check for:**
- [ ] All components loaded upfront (no code splitting)
- [ ] Images loaded eagerly (missing `loading="lazy"`)
- [ ] Large libraries imported but not immediately used
- [ ] Heavy computations on page load

**🟡 MINOR Example:**
```typescript
// INEFFICIENT: Loads Chart.js even if charts not rendered
import Chart from 'chart.js/auto';

// BETTER: Dynamic import when needed
async function renderChart(data: ChartData) {
  const { Chart } = await import('chart.js/auto');
  // Use Chart...
}
```

#### Inefficient Re-renders (React/Vue)

**Check for:**
- [ ] Missing `React.memo()` or `useMemo()`
- [ ] Creating functions/objects in render (new reference each time)
- [ ] Unnecessary state updates triggering cascading re-renders
- [ ] Large lists without virtualization

**🟠 MAJOR Example:**
```typescript
// VULNERABLE: Re-creates handler on every render
function UserList({ users }: Props) {
  return users.map(user => (
    <UserCard
      key={user.id}
      user={user}
      onDelete={() => deleteUser(user.id)} // New function every render!
    />
  ));
}

// FIX: Memoize handler or use stable reference
function UserList({ users }: Props) {
  const handleDelete = useCallback((id: number) => {
    deleteUser(id);
  }, []);

  return users.map(user => (
    <UserCard
      key={user.id}
      user={user}
      onDelete={handleDelete} // Stable reference
    />
  ));
}
```

### 6. Build/Bundle Performance

#### Large Bundle Size

**Check for:**
- [ ] Missing tree-shaking (importing entire library)
- [ ] Duplicate dependencies in bundle
- [ ] Source maps included in production
- [ ] Unoptimized images/assets

**🟡 MINOR Example:**
```typescript
// INEFFICIENT: Imports entire lodash (70KB+)
import _ from 'lodash';
_.debounce(fn, 300);

// BETTER: Import only what you need
import debounce from 'lodash/debounce'; // ~2KB
```

#### Slow Build/Development

**Check for:**
- [ ] No build caching
- [ ] Unnecessary transpilation (modern browsers support ES6+)
- [ ] Rebuilding entire app on small changes
- [ ] Missing incremental builds

## Language-Specific Patterns

### TypeScript/JavaScript

**Inefficient:**
```typescript
// Blocking sync operation
const data = JSON.parse(fs.readFileSync('large.json', 'utf8'));

// Array methods instead of loops for large datasets
const sum = largeArray.reduce((a, b) => a + b, 0); // Slower than for loop
```

**Efficient:**
```typescript
// Non-blocking async
const data = JSON.parse(await fs.promises.readFile('large.json', 'utf8'));

// Traditional loop for hot paths
let sum = 0;
for (let i = 0; i < largeArray.length; i++) {
  sum += largeArray[i];
}
```

### Python

**Inefficient:**
```python
# String concatenation in loop
result = ""
for item in items:
    result += str(item)  # O(n²) - creates new string each time

# List instead of generator
squares = [x*x for x in range(1000000)]  # Allocates 1M items in memory
```

**Efficient:**
```python
# Join list
result = "".join(str(item) for item in items)  # O(n)

# Generator for lazy evaluation
squares = (x*x for x in range(1000000))  # Yields on-demand
```

### Markdown/Static Site Generation

**Check for:**
- [ ] Large unoptimized images (>500KB)
- [ ] Missing image lazy loading
- [ ] All pages built on every change (missing incremental build)
- [ ] Expensive markdown processing not cached

## Examples of Common Findings

### Example 1: O(n²) Nested Loop (🔴 CRITICAL)

```
File: src/utils/matching.ts
Line(s): 15-21
Problem: O(n²) complexity finding matches between two arrays. With 1,000 items per array, performs 1,000,000 comparisons causing multi-second delays.
Fix: Use Map for O(n) lookup:
  const map = new Map(arr2.map(x => [x.id, x]));
  return arr1.filter(x => map.has(x.id));
Expected improvement: 1000x faster (1000ms -> 1ms)
```

### Example 2: N+1 Database Queries (🔴 CRITICAL)

```
File: src/api/posts.ts
Line(s): 45-50
Problem: Fetches comments for each post individually, resulting in 1+N database queries. With 50 posts, makes 51 round-trips (~500ms latency).
Fix: Use eager loading with JOIN:
  posts = await db.posts.findMany({ include: { comments: true } });
Expected improvement: 50x fewer queries (500ms -> 10ms)
```

### Example 3: Memory Leak - Uncleaned Interval (🟠 MAJOR)

```
File: src/services/poller.ts
Line(s): 23-27
Problem: setInterval never cleared, keeping objects in memory indefinitely. Causes memory growth of ~10MB/hour in long-running processes.
Fix: Store and clear interval:
  this.intervalId = setInterval(...);
  cleanup: clearInterval(this.intervalId);
```

### Example 4: Sequential API Calls (🟠 MAJOR)

```
File: src/components/Dashboard.tsx
Line(s): 67-72
Problem: Fetches 5 resources sequentially (200ms each = 1 second total load time). User sees blank screen during fetch.
Fix: Use Promise.all for parallel requests:
  const [users, posts, stats, logs, alerts] = await Promise.all([
    fetch('/api/users'), fetch('/api/posts'), ...
  ]);
Expected improvement: 5x faster (1000ms -> 200ms)
```

### Example 5: Missing Memoization (🟡 MINOR)

```
File: src/utils/calculations.ts
Line(s): 89-95
Problem: Expensive calculation (50ms) runs on every component render even with same inputs, causing UI lag.
Fix: Add memoization:
  import { memoize } from 'lodash';
  export const calculate = memoize((input) => { /* expensive logic */ });
```

## Summary Metrics

After analysis, provide:

1. **Complexity Score**: Count of algorithms with problematic complexity (O(n²+))
2. **Database Efficiency**: Number of N+1 patterns and missing indexes
3. **Memory Health**: Event listeners without cleanup, unnecessary allocations
4. **Network Efficiency**: Sequential requests, missing caching opportunities
5. **Bundle Impact**: Estimated KB added/removed from production bundle

## References

- **CLAUDE.md** - Project build and performance standards
- **Big O Cheat Sheet** - https://www.bigocheatsheet.com/
- **Web Performance Working Group** - https://www.w3.org/webperf/
- **Database Performance Guide** - https://use-the-index-luke.com/
- **React Performance Optimization** - https://react.dev/learn/render-and-commit
