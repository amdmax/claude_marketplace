# Command: solicit-nfrs

Interactive Q&A to surface non-functional requirements for the current story or feature.

## Workflow

1. Read `WORKSPACE_DIR/active-story.json` if it exists — use story title and ACs as context for targeted questions
2. Ask the user targeted questions across NFR categories (ask each category in turn, wait for responses):

   - **Performance:** What are the latency/throughput targets? Are there SLAs for response time?
   - **Scalability:** What is the expected load? Are there peak traffic events or growth projections?
   - **Security:** What auth mechanisms apply? How sensitive is the data? Any compliance requirements (GDPR, SOC2, HIPAA)?
   - **Availability:** What is the uptime SLA? How should the system handle partial failures?
   - **Observability:** What logging, metrics, and alerting are needed? Any existing observability stack to integrate with?

3. Derive concrete, testable NFRs from the user's responses (e.g., "p95 latency < 200ms under 1000 RPS")
4. Append the derived NFRs to `WORKSPACE_DIR/active-story.json` under the `nfrs` array:
   ```json
   {
     "nfrs": [
       { "id": "NFR-001", "category": "performance", "requirement": "p95 latency < 200ms" }
     ]
   }
   ```
5. Report the full NFR list to the user

## File Boundary

Write only to `WORKSPACE_DIR/active-story.json`.
