# Educational Patterns

## Overview

Kelly's techniques transform educational content from abstract explanations into engaging narratives. Instead of defining concepts first, create scenarios where learners encounter problems, then reveal underlying principles through the solving process. Learners become characters; technical concepts become discoveries.

**Educational adaptations:**
- **Real-world scenarios** replace abstract introductions (show the problem before the solution)
- **Learner personas** function as characters (Elena debugging, Marcus deploying)
- **Concrete examples** precede abstract principles (specific → universal pattern)
- **Accessible voice** explains technical precision without jargon
- **Practical application** grounds every concept in doing

## Core Pattern: Scenario → Principle → Application

### Step 1: Real-World Scenario
Open with a learner facing a concrete, relatable problem.

**Example (React hooks):**
> When Elena's React component renders for the eighth time in two seconds, she knows something's wrong. She opens the browser console: hundreds of state updates scrolling past, each triggering another re-render, the kind of infinite loop that crashes production sites.

**Why it works:**
- Specific observable problem (eighth render in two seconds)
- Quantified symptoms (hundreds of state updates)
- Stakes established (crashes production)
- Learner can recognize: "I've seen this"

### Step 2: Technical Exploration
Show what's happening under the hood using the specific scenario.

**Example:**
> Elena examines her useEffect hook:
> ```javascript
> useEffect(() => {
>   setCount(count + 1);
> }); // No dependency array
> ```
> The problem is invisible but devastating: no dependency array means this effect runs after every render. Each time it runs, it updates state. Each state update triggers a new render. New render runs the effect again. Infinite.

**Why it works:**
- Shows actual code causing the problem
- Explains mechanism step-by-step
- Uses concrete example (setCount) not abstract placeholder
- Visualizes the loop (render → effect → state update → render)

### Step 3: Underlying Principle
Extract the general rule from the specific case.

**Example:**
> This is React's reactivity model: state changes trigger re-renders. Effects run after renders. If an effect changes state without restrictions, you've created a feedback loop. The dependency array breaks the loop by saying "only run this effect when these specific values change."

**Why it works:**
- Moves from specific (Elena's code) to universal (React's model)
- Explains *why* the pattern exists (feedback loop prevention)
- Introduces technical concept (dependency array) in context
- Still grounded in concrete mental model (feedback loop)

### Step 4: Broader Application
Show how this principle applies beyond the immediate example.

**Example:**
> The pattern appears everywhere in reactive frameworks: Vue's watchers, Angular's change detection, Svelte's reactive statements. Any system where changes trigger updates needs a mechanism to prevent infinite loops. React uses dependency arrays. Vue uses explicit watch targets. The principle is universal: declare what you're watching, or watch everything forever.

**Why it works:**
- Connects to other technologies (broader relevance)
- Establishes universal pattern (reactive frameworks generally)
- Maintains concrete examples (Vue, Angular, Svelte)
- Reinforces learning (same principle, different implementations)

### Step 5: Practical Solution
Return to the original scenario and solve it.

**Example:**
> Elena fixes her code:
> ```javascript
> useEffect(() => {
>   setCount(count + 1);
> }, []); // Empty array: run once on mount
> ```
> The console clears. Renders drop to one. The component is stable. The infinite loop is gone because Elena told React: "Run this effect once, when the component mounts, then never again."

**Why it works:**
- Shows working code, not just explanation
- Quantified improvement (one render vs. eight)
- Explains the specific fix (empty array = run once)
- Closes the loop: problem introduced, problem solved

## Tutorial Writing

### Pattern: Problem → Guided Solution → Understanding

**Structure:**
1. **Present the problem:** Learner faces a specific challenge
2. **Explore together:** Guide through the solution step-by-step
3. **Reveal the why:** Explain underlying principles after showing the how
4. **Apply more broadly:** Show variations and edge cases
5. **Verify understanding:** Provide self-check or practice scenario

### Example Tutorial: "Understanding React's useEffect Dependency Array"

**Section 1: The Problem (Hook)**
> You've written a React component. It works locally. You deploy to production. Within minutes, your server is overwhelmed with API requests, your AWS bill is spiking, and users are reporting frozen browsers. You frantically check the logs and discover your component is making thousands of API calls per second.
>
> This is what happens when useEffect doesn't have a dependency array. Let's understand why, and how to fix it.

**Section 2: The Scenario (Concrete Example)**
> Here's the component that caused the problem:
> ```javascript
> function UserProfile({ userId }) {
>   const [user, setUser] = useState(null);
>
>   useEffect(() => {
>     fetch(`/api/users/${userId}`)
>       .then(res => res.json())
>       .then(data => setUser(data));
>   }); // ← Problem: no dependency array
>
>   return <div>{user?.name}</div>;
> }
> ```
>
> Can you spot the bug? It's subtle but catastrophic.

**Section 3: The Mechanism (What's Happening)**
> Let's trace what happens when this component renders:
>
> 1. Component renders with userId prop
> 2. useEffect runs (it runs after every render by default)
> 3. Effect fetches data and calls setUser
> 4. State update triggers a new render
> 5. useEffect runs again (it runs after every render)
> 6. Effect fetches data and calls setUser again
> 7. State update triggers another render
> 8. **→ Infinite loop**
>
> Every render triggers the effect. Every effect triggers a render. The cycle never ends.

**Section 4: The Principle (Why This Happens)**
> React's reactivity model is built on a simple idea: when state changes, re-render to reflect the new state. Effects run after renders to synchronize with external systems (APIs, DOM, subscriptions).
>
> But if your effect changes state, and state changes trigger renders, and renders trigger effects... you need a way to say "only run this effect when specific values change." That's the dependency array.

**Section 5: The Solution (How to Fix)**
> Add a dependency array listing what the effect depends on:
> ```javascript
> useEffect(() => {
>   fetch(`/api/users/${userId}`)
>     .then(res => res.json())
>     .then(data => setUser(data));
> }, [userId]); // ← Only re-run when userId changes
> ```
>
> Now the effect runs:
> - Once when the component mounts
> - Again only when userId changes
> - Not on every render caused by setUser
>
> The loop is broken because setUser no longer triggers the effect.

**Section 6: Edge Cases & Variations**
> **Empty dependency array `[]`:** Run once on mount, never again
> ```javascript
> useEffect(() => {
>   console.log('Component mounted');
> }, []);
> ```
>
> **No dependency array:** Run after every render (dangerous!)
> ```javascript
> useEffect(() => {
>   console.log('Every render'); // ← Usually wrong
> });
> ```
>
> **Multiple dependencies:** Run when any dependency changes
> ```javascript
> useEffect(() => {
>   fetchData(userId, filter);
> }, [userId, filter]);
> ```

**Section 7: Self-Check**
> **Scenario:** You have a component that fetches data when a search term changes. Which dependency array is correct?
>
> ```javascript
> function SearchResults({ query }) {
>   const [results, setResults] = useState([]);
>
>   useEffect(() => {
>     searchAPI(query).then(setResults);
>   }, /* what goes here? */);
> }
> ```
>
> A) `[]` (run once)
> B) `[query]` (run when query changes)
> C) `[results]` (run when results change)
> D) No array (run every render)
>
> **Answer:** B. You want to re-fetch when query changes, not on every render or just once.

## Concept Explainer Writing

### Pattern: Analogy → Technical Detail → Application

**Structure:**
1. **Familiar analogy:** Compare new concept to something known
2. **Introduce technical concept:** Name and define the actual technology
3. **Show how it works:** Concrete example with code
4. **Explain trade-offs:** When to use, when not to use
5. **Practice application:** Realistic scenario to apply knowledge

### Example Explainer: "What Is API Rate Limiting?"

**Analogy (Grounding in Familiar)**
> Imagine a bakery that makes fresh croissants every morning. They can bake a hundred per hour. If two hundred people show up wanting croissants, everyone waits. If a thousand people show up, the bakery is overwhelmed—staff can't keep up, ovens run constantly, quality drops, and eventually the whole operation shuts down.
>
> API rate limiting is your bakery's "Sorry, we can only serve 100 customers per hour" policy.

**Technical Introduction**
> Rate limiting controls how many requests a client can make to your API in a given time period. Common limits:
> - 100 requests per minute per user
> - 1,000 requests per hour per IP address
> - 10,000 requests per day per API key
>
> Exceed the limit, and the API returns HTTP 429: "Too Many Requests."

**How It Works (Concrete Example)**
> Here's a simple rate limiter using a token bucket algorithm:
> ```javascript
> class RateLimiter {
>   constructor(maxRequests, windowMs) {
>     this.maxRequests = maxRequests; // e.g., 100
>     this.windowMs = windowMs;       // e.g., 60000 (1 minute)
>     this.requests = new Map();      // Track requests by client
>   }
>
>   allowRequest(clientId) {
>     const now = Date.now();
>     const clientRequests = this.requests.get(clientId) || [];
>
>     // Remove requests outside the time window
>     const recentRequests = clientRequests.filter(
>       timestamp => now - timestamp < this.windowMs
>     );
>
>     // Check if under limit
>     if (recentRequests.length < this.maxRequests) {
>       recentRequests.push(now);
>       this.requests.set(clientId, recentRequests);
>       return true; // Allow
>     }
>
>     return false; // Deny (rate limited)
>   }
> }
> ```

**Trade-offs**
> **When to use:**
> - Protect against accidental runaway scripts (dev forgets to remove a polling loop)
> - Prevent malicious overload (DDoS, scraping, brute force)
> - Ensure fair resource distribution (one user can't starve others)
>
> **When it's not enough:**
> - Distributed attacks (limit per IP doesn't help if attacker uses thousands of IPs)
> - Legitimate traffic spikes (product launch, viral content)
> - Bursty usage patterns (batch processing needs more flexibility)

**Practice Application**
> **Scenario:** You're building a weather API. Which rate limit makes sense?
>
> A) 10 requests per second per user
> B) 100 requests per minute per user
> C) 1,000 requests per hour per user
> D) Unlimited
>
> **Answer:** B or C, depending on use case. Weather doesn't change every second (A is overkill). Legitimate apps might check weather every 5-10 minutes. 100/minute or 1,000/hour allows normal usage while preventing abuse.

## Learner Persona Technique

Instead of abstract "users" or "developers," create recurring personas learners can identify with:

**Elena:** The debugging detective
- Encounters runtime errors, performance issues, unexpected behavior
- Use for: troubleshooting, debugging, investigating problems

**Marcus:** The deployer/implementer
- Builds features, integrates systems, makes architectural decisions
- Use for: implementation tutorials, feature guides, design patterns

**Sarah:** The learner/newcomer
- Encounters concepts for the first time, asks "why" questions
- Use for: foundational explanations, first-principles teaching

**Example using personas:**
> Elena sees eight renders in two seconds and investigates the useEffect. Marcus implements a rate limiter to protect the production API. Sarah learns why React re-renders components when state changes.

## Educational Content Checklist

### Opening
- [ ] **Concrete problem:** Opens with specific, observable issue, not abstract concept?
- [ ] **Learner perspective:** Shows someone encountering the problem (Elena, Marcus, Sarah)?
- [ ] **Stakes established:** Clear why this matters (crashes, costs, confusion)?

### Explanation
- [ ] **Specific before universal:** Shows concrete example before general principle?
- [ ] **Code examples:** Includes actual code, not pseudocode or placeholders?
- [ ] **Step-by-step:** Breaks complex processes into sequential steps?
- [ ] **Accessible voice:** Technical precision without unnecessary jargon?

### Application
- [ ] **Practical grounding:** Returns to solving the original problem?
- [ ] **Broader context:** Shows how principle applies more widely?
- [ ] **Self-check:** Provides way for learners to verify understanding?

### Voice
- [ ] **Conversational:** Reads like explaining to a friend, not academic lecture?
- [ ] **Concrete:** Uses specific numbers, names, observable details?
- [ ] **Empathetic:** Acknowledges common struggles ("We've all been here")?

## Common Educational Writing Mistakes

### ❌ Mistake 1: Abstract Introduction

**Weak:**
> API rate limiting is an important concept in modern web development. It involves controlling the number of requests made to an API to ensure system stability and fair resource allocation.

**Fix (Kelly's approach):**
> At 2:47 AM, Sarah's phone buzzes with an alert: her startup's API just received 10,000 requests in three seconds. She watches the server logs scroll past—same endpoint, same pattern, over and over. By the time she kills the runaway script, her monthly AWS bill has jumped $800.
>
> This is what happens without rate limiting.

### ❌ Mistake 2: Code Without Context

**Weak:**
> Here's how to implement rate limiting:
> ```javascript
> if (requests > limit) return 429;
> ```

**Fix:**
> Elena needs to protect her weather API. Users should be able to check weather every few minutes, but not spam the endpoint. She implements a rate limiter:
> ```javascript
> const limiter = new RateLimiter(100, 60000); // 100 requests per minute
>
> if (!limiter.allowRequest(userId)) {
>   return res.status(429).json({ error: 'Too many requests' });
> }
> ```
> Now each user gets 100 requests per minute—enough for normal usage, not enough for abuse.

### ❌ Mistake 3: No Practical Application

**Weak:**
> The dependency array controls when useEffect runs. It's important to use it correctly.

**Fix:**
> Elena's infinite rendering loop happens because she forgot the dependency array. The fix:
> ```javascript
> useEffect(() => {
>   fetchData(userId);
> }, [userId]); // ← Only re-run when userId changes
> ```
> Now the effect runs when userId changes, not on every render. Problem solved.

---

**Related references:**
- `hooks-library.md` - Educational hook examples (scenario-based openings)
- `voice-guide.md` - Accessible expertise voice
- `flow-patterns.md` - Educational-specific flow (scenario → principle → application)
- `examples-library.md` - Educational before/after transformations
