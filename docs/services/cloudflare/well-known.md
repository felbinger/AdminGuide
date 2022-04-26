# .well-known

This Cloudflare worker provides the following routes for all sites that are routed through Cloudflare.

- `/robots.txt` - denies all, only applied if the actual service doesn't provide anything
- `/.well-known/security.txt` - always
- `/.well-known/matrix/server` - default disabled - matrix federation endpoint
- `/.well-known/matrix/client` - default disabled - matrix client endpoint

## Getting started

1. Create a fork of [`git@github.com:MarcelCoding/.well-known.git`](https://github.com/MarcelCoding/.well-known).
2. Create a GitHub Actions secret named `CF_API_TOKEN`, which should contain a Cloudflare access token, with the scope of the DNS zone and the ability to manage workers.
3. In the `wrangler.toml` update the `routes`, `zone_id` and `account_id` according to your zone and CloudFlare account.
4. Update `config.ts` according to your zone.
5. Because of your changes to GitHub the worker should be automatically deployed using GitHub Actions.

## Matrix

1. Uncomment `main.ts` line 8-9.
2. Add imports:
   ```typescript
   import {onlyRootDomain} from "./utils";
   import {matrixClient, matrixServer} from "./matrix";
   ```
