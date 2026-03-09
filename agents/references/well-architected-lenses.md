# Well-Architected Audit

Apply before producing the implementation brief.

## Scope Check

1. Challenge each proposed file: does it trace directly to an AC? Remove any that don't.
2. Is there a simpler existing service vs introducing a new one?

## Compute Right-Sizing

Match the proposed compute to the workload pattern:

| Workload pattern | Right-size to |
|---|---|
| Runs in seconds, event- or schedule-triggered, infrequent | Lambda |
| Runs minutes–hours, containerised, stateless | ECS Fargate |
| Runs hours+, stateful or needs persistent disk / GPU | EC2 |
| Long-running queue consumer, variable load | ECS Fargate with autoscaling |

## Well-Architected Pillars (one check each — fail = flag to PM)

- **Operational Excellence**: Can this be observed and diagnosed without console access?
- **Security**: Does proposed IAM follow least-privilege? Any new public endpoints?
- **Reliability**: What fails if this component goes down? Is there a retry or fallback?
- **Performance Efficiency**: Is compute class matched to workload duration and frequency?
- **Cost Optimization**: Does an existing stack service already solve this?
- **Sustainability**: Does the design avoid always-on resources for occasional workloads?

If two valid paths differ by >$10/mo estimated cost, escalate to PM for human decision.
