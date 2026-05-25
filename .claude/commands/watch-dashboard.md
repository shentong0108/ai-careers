# /watch-dashboard

Dynamic loop — Claude picks own wake interval based on activity.

## Steps Per Tick

1. **Quick scan**:
   - `gh pr list --label auto-content` — count open PRs
   - newest file in `.claude/logs/` — was anything attempted since last tick?
   - newest file in `docs/dashboard/` — is data fresh?

2. **Decide cadence**:
   | State | Next wake |
   |---|---|
   | PR open + > 24h old | 30 min (nag) |
   | New analytics arrived | 6 h |
   | Quiet (no PR, fresh data) | 24 h |
   | CI failed | 15 min (urgent) |

3. **Use `ScheduleWakeup`** to pick next interval. Pass this same `/watch-dashboard` command in `prompt` field.

4. **Surface one action item only** — don't spam. If nothing actionable, output `nothing to do` and reschedule.

## Boundaries

- Read-only.
- Max 4 wakeups per 24h.
- Stop if user says "stop loop" or `nothing to do` 3 ticks in a row (truly quiet — let user re-trigger).
