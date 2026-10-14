# Build: 003-rate-limiting

Branch: `factory/003-rate-limiting`

## What was built

- `ratelimit/bucket.go` — token bucket (rate, burst, `Allow(now)`), no globals.
- `ratelimit/middleware.go` — `Middleware(next)` keyed by `remoteAddr` IP;
  returns 429 + `Retry-After: 1` when the bucket is empty.
- `ratelimit/bucket_test.go` — table-driven tests.

## Acceptance criteria

1. Bucket + middleware wired in `server.go` — `ratelimit.Middleware`.
2. 429 + `Retry-After` — `TestMiddleware_OverLimit` asserts both.
3. Per-client — `TestMiddleware_PerClientIsolation` saturates one IP, checks
   a second IP still passes.
4. `go test ./...` — `ok x-opencode-web/ratelimit 0.014s` (7 tests).

## Round 2

Security round-1 flagged: bucket map grows forever and trusts
`X-Forwarded-For` blindly.

- Added idle eviction (buckets unused > 5m are swept on each middleware call).
- `X-Forwarded-For` is only trusted when `TRUST_PROXY=1`; default stays
  `remoteAddr`.
- New tests: `TestSweep_EvictsIdle`, `TestMiddleware_ProxyHeaderUntrusted`.
- `go test ./...` — `ok x-opencode-web/ratelimit 0.016s` (9 tests).
