# REVIEW — 404 page and PR #19 redirects

Branch: `site/pr19-followup-404-redirects` (base `main` @ b111203)
Reviewed: 2026-10-29, before any commit of the implementation.

Scope of the diff reviewed: `404.html`, the `redirects` block in `vercel.json`, twelve
meta-refresh stubs at the paths PR #19 deleted, `scripts/test_redirects.sh`,
`scripts/vercel_redirects.py`, `scripts/redirect_map.txt`, `.gitignore`, and edits to
`scripts/test_legal_pages.sh` and `.github/workflows/ci.yml`.

Two independent passes were run against the working tree — a code-quality review and a
security review — in addition to the author's own pass. Both suites were green before and
after every change recorded here.

## Verdict

| Severity | Count | Outcome |
|---|---|---|
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 0 | — |
| LOW | 2 | both fixed |
| Informational | 3 | recorded, no change made |

## Security findings

### Open redirect — not reachable

The thing worth worrying about in a redirect change is a destination that an attacker can
steer. None exists here. Every destination in `vercel.json` is a hardcoded literal:

```json
{ "source": "/products/:path*", "destination": "/capabilities.html", "permanent": true }
```

The wildcard capture `:path` is never referenced in the destination, so there is no field
for `//evil.com`, `/\evil.com`, or a `https:` prefix to land in. A Vercel redirect can only
forward a captured segment if the destination string names it, and none of the five do.
The same holds for the stubs: each `meta http-equiv="refresh"`, `link rel="canonical"` and
visible `<a href>` is a fixed string written from `scripts/redirect_map.txt` at authoring
time, never derived from the request. There is no query-string, hash or
`window.location`-driven redirect anywhere in `js/main.js`.

`scripts/test_redirects.sh` locks this in: every rule's destination must start with `/`,
must not equal its own source, and must resolve to a file that exists in the repo.

### XSS — no sink

No inline `<script>`, no `innerHTML`, no `document.write`, nothing reflected. `js/main.js`
only queries static selectors and is null-guarded, so loading it on `404.html` — which has
a nav but no `form.contact`, `.index` or `.principles` — is a silent no-op rather than an
error. The one place user text reaches a URL (the contact form's `mailto:` builder) runs
every field through `encodeURIComponent`, and that code is untouched by this change.

### Header and information leakage — nothing new

`vercel.json` adds no headers and no environment exposure. The stubs do restate retired
project names in their directory paths (`/products/voicedoc-dnp/`,
`/blog/djiboutian-somali-dialect-asr/`). Those paths were live and indexed until PR #19, so
any inbound link already reveals them; the stub confirms a page used to be there and
nothing more. The only email address on the new pages is the one already published in the
existing footer.

### Indexing

Every stub and `404.html` carries `<meta name="robots" content="noindex, follow">`, none
are listed in `sitemap.xml`, and the test asserts both. `robots.txt` keeps its blanket
`Allow: /`, which is correct and deliberate: a `Disallow` would stop crawlers fetching the
stubs at all, so they would never see the `noindex` and could still index the URL from an
external link. `follow` rather than `nofollow` lets the retired page's link equity pass
through to the live destination, which is the point of the canonical.

### CI

`permissions: contents: read` is unchanged and already minimal. The new step is a bare
`run: bash scripts/test_redirects.sh` with no `${{ }}` interpolation into the shell, so
there is no script-injection path via a branch name or PR title.

### Test tooling

`scripts/vercel_redirects.py` does `json.load` on a repo-local path and regex-matches; no
`eval`, no `exec`, no `subprocess`, no shell-out. `pattern_for()` runs `re.escape()` over
literal segments and rejects anything outside its supported grammar instead of guessing.
In `scripts/test_redirects.sh` every expansion is quoted, `set -uo pipefail` is on, and the
URL list is passed to Python as separate argv entries rather than a concatenated string, so
shell metacharacters in `redirect_map.txt` could not be injected even if someone put them
there.

## Code-quality findings and fixes

### LOW — `vercel.json` existence was used before it was asserted — FIXED

`scripts/test_redirects.sh` guarded the Python call on `[ -f "$VERCEL_CONFIG" ]` and then
re-asserted the same condition afterwards, so the "exists" check read as a duplicate and
the ordering was backwards.

Fixed: both existence checks now run first and capture their status into `helper_present`
and `config_present`, which the guard reuses. The second guard, in the URL-matching
section, dropped its redundant `-f` tests and now keys off `rules_readable` alone.

### LOW — the two scripts guarded an empty redirect map differently — FIXED (comment)

`scripts/test_redirects.sh` exits 2 when `redirect_map.txt` lists nothing; the loader in
`scripts/test_legal_pages.sh` did not. The asymmetry is correct rather than a bug — an
empty map there means nothing is excluded, so every stub falls back into the public-page
scan and fails loudly on its missing footer, which is the safe direction — but nothing said
so. Fixed by recording the reasoning in a comment at the loader.

## Informational — recorded, no change made

1. **No Content-Security-Policy anywhere on the site.** Pre-existing, not introduced here,
   and with no injection sink on a static site it buys little today. Worth doing as its own
   change, ideally as a Vercel `headers` block next to the new `redirects`.
2. **PR #19 also deleted eight non-HTML files** that this change does not redirect:
   `docs/SASR_Eval.pdf`, four `docs/data/sasr_eval*` files, `assets/horn-map.svg` and
   `products/assets/gate.js`. They now land on the new branded 404 instead of a host
   default, which is an improvement but not a redirect. `docs/SASR_Eval.pdf` is the one
   worth adding to the map if it was ever cited externally — a paper URL is exactly the
   kind of link that outlives its page. Left out because the brief scoped the map to the
   deleted pages.
3. **The CI job keeps the name `legal-pages` / "Legal pages contract test"** even though it
   now runs two scripts. Branch protection matches a required status check by name, so
   renaming it would make the required check never report and block every PR.
   `gh api repos/.../branches/main/protection` returns 403 with the available token, so the
   safe choice was to leave the name alone and comment why. Rename once someone with the
   right scope confirms no protection rule references it.

## Verification

Mutation testing, each mutation reverted and the revert confirmed:

| Mutation | Expected | Observed |
|---|---|---|
| Delete `/blog/:path*` from `vercel.json` | deep blog URLs stop matching | `FAIL: 17 of 236` |
| Corrupt `vercel.json` into invalid JSON | parse failure named, not silently skipped | `FAIL … Expecting value: line 1 column 18`, plus every source check |
| Point a stub's meta refresh at the wrong target | that one stub fails | 1 check failed |
| Remove a path from `redirect_map.txt` | both scripts object | `test_legal_pages.sh` 9 failures (stub re-enters the scan, no footer) **and** `test_redirects.sh` fails "meta-refresh page is a mapped redirect stub" |
| Feed the Python helper malformed configs: non-array `redirects`, missing `destination`, source without a leading `/`, a bare `:id` segment, a non-trailing `:id*` | loud rejection | exit 2 with a specific message in every case; no silent wrong match |

The fourth row is the one that matters most: it shows the stub exclusion added to
`test_legal_pages.sh` cannot be used to hide a real page, because dropping a path from the
map makes *both* suites fail rather than quietly widening the exemption.

Final state, after the two LOW fixes:

```
scripts/test_redirects.sh      PASS: 240/240 checks passed   exit 0
scripts/test_legal_pages.sh    PASS: 134/134 checks passed   exit 0
```

For contrast, the first run of `scripts/test_redirects.sh` — written before any of the
implementation existed — reported `FAIL: 53 of 103 checks failed`, exit 1.
