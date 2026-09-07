# fixture

## Endpoints

README.md Endpoints table fixture (port drift): the host matches the routed
UI, but the URL hardcodes a stale port :8000 (the removed DR front door's port)
instead of k3d's own load-balancer port :8080, so lab-ui-check must flag the
wrong port.

| UI | URL |
|----|-----|
| Demo | http://demo.127.0.0.1.nip.io:8000 |

## Something else

Not part of the Endpoints section.
