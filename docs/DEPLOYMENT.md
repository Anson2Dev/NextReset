# Website deployment

## Target and source

- Public site: https://nextreset.tokenpark.org
- Cloudflare Worker: `nextreset`
- Account and custom-domain configuration: `wrangler.jsonc`.
- Entry point: `worker/index.js`; static source: `website/`.
- Use the pinned Wrangler version from `package-lock.json`; do not silently upgrade it.

The Worker serves HTML, CSS, robots, sitemap and a small copy-command script from bundled text modules. `/copy.js` uses JavaScript MIME type but its source is imported as text via the explicit `**/copy.js` rule. Keep this rule when editing Wrangler configuration. CSP allows same-origin resources without inline script execution. There are no data bindings or analytics scripts.

## Normal CLI workflow

```sh
npm ci
npm run dev
npm run check:deploy
npx wrangler whoami
npm run deploy
```

If Wrangler credentials have expired, run `npx wrangler login` interactively on the maintainer's machine. Do not put tokens into the repository. A successful dry run verifies packaging, not authentication or the live deployment.

## Connected Cloudflare API fallback

The September 30, 2026 website updates used the authenticated Cloudflare connector because local Wrangler OAuth had expired. No token was copied out of the connector. To reproduce this route:

1. Build with `npm run check:deploy -- --outdir dist/website-build`.
2. Read the Worker's current settings through `GET /accounts/{account_id}/workers/scripts/nextreset/settings`. Confirm the target and absence of unexpected bindings.
3. Upload the generated `index.js` **and every text module it imports** with multipart `PUT /accounts/{account_id}/workers/scripts/nextreset`. Use `main_module: "index.js"`, JavaScript-module content type for the entry point, and text/plain for imported text modules.
4. Preserve the observed compatibility date, flags, bindings, usage model, logpush, observability, tags and tail consumers. Stop to reconcile any unexpected settings. The existing custom domain needs no DNS change.
5. Check the API success result, then verify the public website. Updating the script deploys it immediately.

Only include files referenced by the current build. Reused output directories can contain stale hashed modules from previous builds. Source maps are not needed for serving this site.

Cloudflare reference: [Multipart upload metadata](https://developers.cloudflare.com/workers/configuration/multipart-upload-metadata/).

## Cache and verification

Responses use a five-minute cache. Bump the CSS/script query versions in `website/index.html` whenever those resources change; the Worker routes using the URL pathname. A page query such as `?v=0.2.2` provides a fresh URL for immediate verification while existing page caches expire.

Check:

- Homepage, stylesheet and copy script return 200 with their correct MIME types; an unknown path returns 404.
- Public release links and Homebrew command match the published release/tap.
- The install command stays centered and readable on desktop and mobile.
- Copy shows success and writes the single-line command; keyboard focus and fallback feedback remain available.
- The site carries the current signing statement, without changing historical release claims.

## Generated files

`node_modules/` and `.build/` are reusable dependency/build caches. `dist/website-*` contains disposable packaging output. Keep source files and lockfiles; remove stale packaging output after deployment. Do not delete active app bundles or unique release records while clearing `dist/`.
