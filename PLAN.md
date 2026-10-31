# PLAN — 404 page and redirects for the pages PR #19 retired

Branch: `site/pr19-followup-404-redirects` (base `main` @ b111203, the merge of PR #19)

## Why

PR #19 rebranded the site and deleted twelve pages. They had been live and linked
externally, so every one of those URLs now answers 404 with whatever default page the
host supplies. Two hosts serve this repo:

- **Vercel** is production (`curl -sI https://www.phoenixrisinggroups.com` reports
  `server: Vercel`). It can issue real `308` redirects from `vercel.json`.
- **GitHub Pages** (`.github/workflows/static.yml`) still deploys the same tree. Pages
  serves static files only — it has no redirect configuration — so the same URLs need
  on-disk stub files there.

Neither host currently has a branded 404 page either.

## Scope

1. `404.html` — a real page in the site's own chrome, for URLs no rule covers.
2. `vercel.json` — a `redirects` block, `permanent: true` (HTTP 308), for the retired paths.
3. Twelve redirect stubs on disk at the exact deleted paths, for the GitHub Pages fallback.
4. `scripts/test_redirects.sh` — contract test for all three, written before the code.
5. `.github/workflows/ci.yml` — run that test beside the legal-pages test.

Out of scope: pushing, merging, deploying, `TEST_PROOF.md`, any wording in `support.html`,
and the share image or its fonts.

## Why this PR is ~1,300 lines

The diff against `main` is 37 files, +1,313 / -60 (`git diff --shortstat origin/main...HEAD`
at `ff53024`), of which 14 files are PNG screenshots counting as binary (0 lines) and only
about 405 lines are shipped site code.

| Category | Files | Lines (+/-) |
|---|---|---|
| Shipped site: `404.html` | 1 | +108 |
| Shipped site: 12 GitHub Pages redirect stubs (`blog/*`, `products/*`, `results.html`, 24 lines each) | 12 | +288 |
| Shipped site: `vercel.json` redirects | 1 | +9 / -2 |
| **Shipped site subtotal** | 14 | **+405 / -2** |
| Tests: `scripts/test_redirects.sh` | 1 | +364 |
| Tests: `scripts/vercel_redirects.py` (checks vercel.json against the map) | 1 | +120 |
| Tests: `scripts/redirect_map.txt` (single source of truth) | 1 | +24 |
| Tests: `scripts/test_legal_pages.sh` | 1 | +41 / -4 |
| **Tests subtotal** | 4 | **+549 / -4** |
| Evidence docs: PLAN.md, REVIEW.md, TEST_PROOF.md (before this section) | 3 | +340 / -52 |
| CI: `.github/workflows/ci.yml` | 1 | +17 / -2 |
| `.gitignore` | 1 | +2 |
| Screenshots `docs/pr19-followup/*.png` (390px before/after) | 14 | binary |

About 70% of the added lines are tests and evidence documents, not site code. It was not
split because the 404 page, the redirects and their test are one contract: shipping the
test first leaves CI red, shipping the redirects without the test leaves them unguarded,
and holding the redirects back leaves the twelve URLs deleted by #19 returning 404 in
production. This section itself adds about 30 lines to PLAN.md.

## Redirect map

Source of truth is `scripts/redirect_map.txt` (`<deleted file path> <destination>`), read by
both test scripts so the map is stated once. Destinations are the closest live page:

| Deleted path | URL it served | Destination | Why that destination |
|---|---|---|---|
| `products/index.html` | `/products` | `/capabilities.html` | The product index is now the capabilities page. |
| `products/emploi-assist/index.html` | `/products/emploi-assist` | `/capabilities.html` | Named products are retired; capabilities is the nearest surviving description of the work. |
| `products/horn-transcribe/index.html` | `/products/horn-transcribe` | `/capabilities.html` | as above |
| `products/transport/index.html` | `/products/transport` | `/capabilities.html` | as above |
| `products/voicedoc-dnp/index.html` | `/products/voicedoc-dnp` | `/capabilities.html` | as above |
| `results.html` | `/results.html` | `/capabilities.html` | Benchmark results are retired; capabilities is what replaced that part of the site. |
| `blog/index.html` | `/blog` | `/` | No blog survives and no single page inherits it, so the home page is the honest landing spot. |
| `blog/afar-language-speech-recognition/index.html` | `/blog/afar-language-speech-recognition` | `/` | as above |
| `blog/djiboutian-somali-dialect-asr/index.html` | `/blog/djiboutian-somali-dialect-asr` | `/` | as above |
| `blog/horn-of-africa-language-technology-gap/index.html` | `/blog/horn-of-africa-language-technology-gap` | `/` | as above |
| `blog/sasr-eval-somali-asr-benchmark/index.html` | `/blog/sasr-eval-somali-asr-benchmark` | `/` | as above |
| `blog/why-commercial-asr-fails-on-somali/index.html` | `/blog/why-commercial-asr-fails-on-somali` | `/` | as above |

Blog posts deliberately do **not** point at `/capabilities.html`: they were research
writing, capabilities is a sales page, and sending a reader of a retired article straight
into a pitch is worse than sending them to the front door.

`vercel.json` carries five rules rather than twelve, because two of them are wildcards:

```
/products        -> /capabilities.html
/products/:path* -> /capabilities.html
/blog            -> /
/blog/:path*     -> /
/results.html    -> /capabilities.html
```

`:path*` matches zero or more segments, so `/blog/:path*` covers `/blog/`,
`/blog/<slug>`, `/blog/<slug>/` and `/blog/<slug>/index.html` alike. The test does not
trust that claim: it re-implements the match and asserts every retired URL form, in every
trailing-slash variant, is matched by some rule whose destination is a file that exists.

## 404 page

`404.html` reuses the exact header and footer markup of `index.html` and the same
stylesheet, so it looks like the site rather than like the host.

One deliberate difference: **every link in `404.html` is root-absolute** (`/`,
`/capabilities.html`, `/contact.html`, `/css/styles.css`). Vercel serves `404.html` for
*any* unmatched URL, including deep ones, and a relative `href="index.html"` on a 404
served at `/a/b/c` resolves to `/a/b/index.html`. Absolute links are the only ones that
work from every depth.

Copy constraints, same as the rest of the site: plain English, no "pilot", no accuracy or
percentage figures, no ministry or government endorsement, no claim about how the page or
the software was made.

## GitHub Pages stubs

Each deleted path gets a small HTML file carrying:

- `<meta http-equiv="refresh" content="0; url=…">` — the redirect itself;
- `<link rel="canonical" …>` — so the destination, not the stub, keeps the ranking;
- `<meta name="robots" content="noindex, follow">` — the stub must never be indexed;
- a visible link to the destination, for anyone whose browser blocks meta refresh.

A meta refresh is a weaker signal than a 308 and search engines treat it as a soft
redirect. That is accepted: on Vercel the stubs are unreachable (a redirect rule fires
first), so they only ever act as the Pages fallback.

### One change to `scripts/test_legal_pages.sh`

That script's `collect_public_pages` globs every `*.html` and then requires the full site
footer, seller attribution and a depth-correct Legal column on each. The stubs trip it for
a reason unrelated to what it guards: a page that bounces in zero seconds is not a page a
customer reads the seller name on, and giving twelve throwaway files the full 40-line
footer would render chrome and then yank it away. So:

- the stub paths listed in `scripts/redirect_map.txt` are excluded from that scan, and
  `test_redirects.sh` asserts in exchange that **no file outside that map carries a meta
  refresh** — so the exclusion cannot be used to smuggle a real page past the footer check;
- `404.html` stays in the scan — it is a page people genuinely land on, so the seller
  attribution still matters — but `prefix_for` learns that its links are root-absolute.

Stubs and `404.html` are kept out of `sitemap.xml`; the test asserts that too.

## Test plan

`scripts/test_redirects.sh`, written and run red before any implementation:

- **(a)** `404.html` exists, has `site-header` / `site-nav` / `site-footer`, offers the
  Home · Capabilities · Contact nav, states `Phoenix Rising Group LLC` in the footer,
  links `/` and `/contact.html`, loads the shared CSS, and carries none of the forbidden
  claims.
- **(b)** `vercel.json` parses, has a `redirects` array, carries each of the five named
  sources with `permanent: true`, every destination resolves to a file in the repo, and no
  rule redirects off-site or into a loop.
- **(c)** every retired URL form (`/x`, `/x/`, `/x/index.html`) is matched by some rule.
- **(d)** every path in the map has a stub with refresh, canonical, noindex and a visible
  link, all three pointing at the same destination, which exists.
- **(e)** no file outside the map carries a meta refresh; no stub and no `404.html` appears
  in `sitemap.xml`.

Output is `ok`/`FAIL` per check with a `PASS: n/n` or `FAIL: x of n` summary, exit 1 on any
failure. `scripts/test_legal_pages.sh` must stay green throughout.

## Risks

| Risk | Handling |
|---|---|
| Vercel's `:path*` matching differs from what the test models, so a URL silently 404s in production. | The test models the documented `path-to-regexp` semantics and checks every trailing-slash form. The literal five sources are asserted separately, so a wildcard behaving unexpectedly still leaves `/products`, `/blog` and `/results.html` covered by exact rules. Residual risk is a deep blog URL — verifiable only against a real deployment, which this PR does not do. |
| Excluding stubs from the legal-pages scan weakens it. | Compensating assertion: any meta-refresh file not in the map fails the redirect test. |
| A stub's destination is later renamed, leaving a redirect into a 404. | Both the stub target and every `vercel.json` destination are resolved against the filesystem on every CI run. |
| `308` is permanent and cached hard by browsers. | Destinations are the stable top-level pages (`/`, `/capabilities.html`), not deep links likely to move. |
| Redirecting retired research URLs to `/` loses the inbound link's context. | Accepted: the content is gone, and a soft landing on the front door beats a 404. |
