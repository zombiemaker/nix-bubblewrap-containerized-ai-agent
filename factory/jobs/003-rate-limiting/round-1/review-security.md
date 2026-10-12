VERDICT: CHANGES

- The per-IP bucket map is never pruned — a spoofed-IP flood grows it without
  bound (memory DoS). Sweep buckets idle > 5m.
- `X-Forwarded-For` is trusted unconditionally, letting clients spoof their
  key and dodge the limit. Only trust it behind a configured proxy.
