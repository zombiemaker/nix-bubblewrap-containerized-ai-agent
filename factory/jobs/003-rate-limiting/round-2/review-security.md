VERDICT: PASS

Round-1 findings are addressed:
- Idle sweep present and tested (`TestSweep_EvictsIdle`).
- `X-Forwarded-For` gated behind `TRUST_PROXY=1`, default `remoteAddr`,
  covered by `TestMiddleware_ProxyHeaderUntrusted`.
