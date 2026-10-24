# REVIEW — privacy/support pages + footer seller attribution

Branch `site/legal-privacy-support`, base `main` @ `9c6b1a1`.
Reviewed: 2 new pages, 15 rewritten footers, `sitemap.xml`, `css/styles.css`, and
`scripts/test_legal_pages.sh`.

Three passes were run: an automated mechanical audit, an independent code review
(`ecc:code-reviewer`), and an independent security review (`ecc:security-reviewer`). The two
agent reviews were given the diff and the constraints, not my conclusions.

**Verdict: approved for PR. No CRITICAL or HIGH findings. Every actionable finding below is
fixed; the suite grew from 189 to 204 assertions as a result.**

| Severity | Found | Fixed | Deferred (with reason) |
| --- | --- | --- | --- |
| CRITICAL | 0 | — | — |
| HIGH | 0 | — | — |
| MEDIUM | 1 | 1 | 0 |
| LOW | 4 | 3 | 1 (escalated to CTO — not fixable in this repo) |

---

## Findings and resolutions

### F1 — MEDIUM — Test could not catch the core "LLC only in the footer" constraint
*Source: code review.*

The whole brand-scope rule is that `LLC` is a seller attribution, not the display brand: it
belongs in the footer brand link and the copyright line, and nowhere else. Section (e) of the
suite only inspected markup **inside** `<footer class="site-footer">`, so a future edit that
leaked `LLC` into a `<title>`, `<h1>`, `<meta>` or `og:*` tag would have passed green. The
content was compliant at the time — this was a coverage gap, not a live defect.

**Fixed.** Added section (h) to `scripts/test_legal_pages.sh`: for each of the 15
pre-existing pages, the count of `LLC` occurrences in the whole file must equal the count
inside the footer, and must be exactly 2. The two legal pages are explicitly exempt — they
legitimately carry the entity name in their own `<title>` and meta tags.

Verified by mutation: leaking `LLC` into `capabilities.html`'s `og:site_name` now produces

```
FAIL capabilities.html mentions LLC only as footer attribution (brand + copyright) — found 2 in footer of 3 total, expected 2 of 2
```

See mutation 5 in [`TEST_PROOF.md`](TEST_PROOF.md).

### F2 — LOW — `(f)` link-resolution assertion was tautological
*Source: my own mutation testing, before the agent reviews returned.*

Section (f) resolved the **expected** path (`"$page_dir/$prefix$target"`) against the
filesystem rather than the href the page actually ships. Because the expected path is correct
by construction, that assertion could never fail on its own; only the companion string-match
assertion was doing real work.

**Fixed.** Section (f) now scopes to the Legal column, extracts the href the page actually
ships, and resolves *that*. A wrong `../` depth now fails both assertions and the failure
message prints the offending path. Verified by mutation 2 in [`TEST_PROOF.md`](TEST_PROOF.md).

### F3 — LOW — `collect_footer_pages` would mis-split filenames containing whitespace
*Source: security review.*

`find … | while read -r page` splits on `IFS`, so a path with a space or tab would silently
break the loop. No such filename exists in this repo and all paths are developer-controlled,
so this was robustness rather than a security hole.

**Fixed.** Switched to `find -print0 | sort -z | while IFS= read -r -d '' page`. Suite still
green.

### F4 — LOW — Inline links in the legal body were visually indistinguishable from body text
*Source: my own review of the first phone screenshots.*

The site-wide rule is `a { color: var(--ink); text-decoration: none; }`, which reads fine on
nav and card links but makes inline prose links invisible. On a support page whose entire
purpose is to route a store reviewer to `radwanjama099@gmail.com` and to the privacy policy,
an unclickable-looking link is a real defect — and a WCAG 1.4.1 problem, since nothing but
position distinguished the link.

**Fixed.** Reused the site's own established prose-link idiom (`.research-footnote a` and
`.eval-note a` in `css/styles.css`) inside the `.legal` scope, rather than inventing a new
treatment:

```css
.legal a { font-weight: 500; text-decoration: underline; text-decoration-color: var(--line); }
.legal a:hover { color: var(--ink); text-decoration-color: var(--ink); }
```

The screenshots in [`TEST_PROOF.md`](TEST_PROOF.md) are the post-fix renders.

### F5 — LOW — Privacy policy makes operational commitments this repo cannot verify
*Source: security review. **Not fixed here — escalated to the CTO.***

`privacy.html` commits to things that live in backend systems outside this repository:
30-day account-deletion processing, deletion certificates, per-organization data isolation,
audit logs of who confirmed findings, and zero-retention (or equivalent) agreements with AI
providers before any real customer file is sent.

These came from the approved draft and are the right commitments for a store listing, but a
static-site PR cannot prove they are operationally true. **Changing the text is a business
decision, not an engineering one**, so I have left the wording exactly as drafted and raised
it instead. This is called out in the PR body as a sign-off item.

---

## Explicitly checked, no findings

### Relative paths
Every footer Legal link on all 17 pages resolves to a real file. Depth tiers behave as
specified: root → `privacy.html`; `blog/index.html` and `products/index.html` → `../`;
`blog/*/index.html` and `products/*/index.html` → `../../`. Asserted in the suite (which
resolves the shipped href, per F2) and re-verified independently:

```console
$ # every local href/src on the new pages, and every footer Legal link site-wide
all local hrefs/srcs on the new pages resolve
all footer Legal links on all pages resolve to real files
```

### Brand scope — `LLC` confined to footer attribution
```console
$ # LLC outside the footer on any of the 15 pre-existing pages
none — LLC confined to footers on all 15 pre-existing pages
```
Headers, heroes, `<h1>`s, `<title>`s, meta and Open Graph tags are untouched on all 15 pages.
Confirmed structurally too: the complete diff of tracked HTML files contains nothing but
footer brand lines, copyright lines, and Legal-column markup — no hunk reaches any other
region of any file.

### Top nav not crowded
Neither new page links Privacy or Support from `site-nav`; both ship the same six items as
`contact.html` (Home, Capabilities, Blog, Products, SASR Eval, Contact). No existing page's
nav was modified. Asserted in section (c) and verified by mutation 3.

### Secrets and PII
No API keys, tokens, passwords or private-key material in any changed or new file. The only
personal data present is the deliberate, pre-existing `radwanjama099@gmail.com` and the
LinkedIn profile URL — both already on every other page of the site. The three PNGs under
`docs/legal-screenshots/` are headless renders of public pages; strings-scanned and visually
inspected, nothing sensitive captured.

### UTF-8 and French content
Every `.html`, `.css` and `.xml` file in the repo passes `iconv -f UTF-8 -t UTF-8`; no U+FFFD
replacement characters anywhere. The three files carrying French text
(`index.html`, `products/index.html`, `products/transport/index.html`) have an accented-
character count byte-identical to `HEAD`, so the footer rewrite disturbed nothing. The curly
quotes and em dashes in the legal body render correctly in the phone screenshots.

### Forbidden claims
No accuracy percentage, no the word "accuracy", no "pilot", no ministry reference, and no
government-endorsement phrasing on either new page. Asserted in section (g) and verified by
mutation 4. The one surviving mention of government — *"We do not submit Phoenix Check
dossiers to customs systems, carriers, or government portals on your behalf"* — is a denial
of a capability, the opposite of an endorsement claim, and is kept deliberately.

### HTML well-formedness and chrome parity
`privacy.html` and `support.html` parse with zero tag-balance or nesting errors
(`html.parser`). Their font `<link>` sequence and `menu-toggle` SVG are byte-identical to
`contact.html` — asserted by `diff` in section (c), so drift fails the suite rather than
needing a human to spot it.

### CSS grid change
`.site-footer .wrap` went from `1.5fr 1fr 1fr` to `1.5fr 1fr 1fr 1fr` (`css/styles.css:1337`)
to seat the fourth column. The pre-existing `@media (max-width: 900px)` rule at
`css/styles.css:1789` already collapses the footer to `grid-template-columns: 1fr`, so no new
breakpoint was needed and narrow viewports are unaffected. Verified visually at both 1280px
and 390px — see the footer renders in [`TEST_PROOF.md`](TEST_PROOF.md).

### sitemap.xml
Both URLs added in the same entry shape as their siblings (`changefreq: yearly`,
`priority: 0.5`, matching `contact.html`'s entry). File parses as well-formed XML.

### Outbound links and injection surface
No `target="_blank"` without `rel="noopener"`. No inline `<script>` block, no `javascript:`
URL, no `on*=` event-handler attribute on either new page — the only script reference is the
shared, unmodified `js/main.js`.

### Static-only
Plain HTML and CSS. The one inline `<style>` block per legal page follows the existing
one-off page-styling pattern already used elsewhere on the site. No framework, no build step,
no new dependency.

---

## Note on review hygiene

The code-review agent reported that one of its sandbox commands failed to `cd` into a
non-existent directory and ran a `sed` in the real working tree instead. I did not take that
report at face value. Repo integrity was re-verified independently afterwards: the diff stat
is unchanged at 146 insertions / 31 deletions across the same 17 files, every hunk line is a
footer brand, copyright or Legal-column line, `index.html`'s header brand is untouched, and
the suite is green at 204/204. **No corruption occurred.**

---

## Out of scope — deliberately not changed

- Hero, product, header-brand, `<title>`, meta and Open Graph copy on existing pages.
- `google*.html` Search Console stubs (no chrome, excluded from the suite by design).
- `products/voicedoc-dnp/` missing from `sitemap.xml` — a pre-existing gap, unrelated to this
  change, left for a separate PR rather than smuggled in here.
- The support email staying `radwanjama099@gmail.com` until a domain mailbox exists.
- Deploying or merging. **This PR is for CTO review only.**
