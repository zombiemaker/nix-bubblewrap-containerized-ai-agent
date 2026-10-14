# Spec: Rate limiting on the public API

## Problem

The public API has no per-client request cap, so a single misbehaving client
can exhaust the service and starve everyone else.

## Acceptance criteria

1. A token-bucket limiter (10 req/s, burst 20) keyed by client IP is applied
   as HTTP middleware.
2. Requests over the limit get `429 Too Many Requests` with a `Retry-After: 1`
   header.
3. The limiter is per-client: one saturated client does not throttle others.
4. `go test ./...` passes, including table-driven tests for refill, burst,
   and per-client isolation.

## Out of scope

- Distributed/redis-backed limiting (single process only)
- Per-API-key quotas (later job)
