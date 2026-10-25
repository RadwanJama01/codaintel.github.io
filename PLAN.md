# PLAN — Store-required privacy & support pages + footer seller attribution

Branch: `site/legal-privacy-support` (base `main` @ 9c6b1a1)
Workflow: ECC loop — PLAN → failing test → implement → passing proof + screenshots → REVIEW → commit/push/PR.

## 1. Goal

Apple App Store and Google Play both require a reachable **privacy policy URL** and a
**support URL** for every listing. Production currently 404s on both. Meta Business
verification additionally needs the visible seller name to match the registered legal
entity exactly.

Therefore:

1. Ship `privacy.html` and `support.html` at the site root, so the store URLs are
   `https://www.phoenixrisinggroups.com/privacy.html` and `.../support.html`.
2. Make the footer seller attribution read exactly **`Phoenix Rising Group LLC`** on every
   public page — both the `footer-brand` link text and the `&copy;` line.
3. Make the two new pages reachable from every page without crowding the top nav.

### Explicit brand-scope rule

`Phoenix Rising Group LLC` is a **seller/legal attribution**, not the display brand. It
goes **only** in:

- the `footer-brand` anchor text, and
- the `&copy; 2026 …` line in `footer-bottom`.

The header brand, hero copy, `<h1>`s, `<title>`s, meta descriptions and Open Graph tags
keep reading `Phoenix Rising Group` (no `LLC`). The new pages' own `<title>`/meta carry
`LLC` because they are legal documents and the drafts already say so.

## 2. Files to add / change

### Added

| Path | Purpose |
| --- | --- |
| `privacy.html` | Privacy policy, adapted from `/workspace/store-assets/legal/privacy.html` |
| `support.html` | Support page, adapted from `/workspace/store-assets/legal/support.html` |
| `scripts/test_legal_pages.sh` | Executable contract test for every requirement below |
| `PLAN.md`, `TEST_PROOF.md`, `REVIEW.md` | ECC evidence |
| `docs/legal-screenshots/privacy-phone.png`, `support-phone.png` | 390×844 renders |

### Changed

| Path | Change |
| --- | --- |
| `index.html`, `contact.html`, `capabilities.html`, `results.html` | footer seller name → `LLC`; add Legal column |
| `blog/index.html`, `products/index.html` | same, `../` link prefix |
| `blog/*/index.html` (5 posts), `products/*/index.html` (4 desks) | same, `../../` link prefix |
| `sitemap.xml` | add the two new URLs |
| `css/styles.css` | `.site-footer .wrap` grid `1.5fr 1fr 1fr` → `1.5fr 1fr 1fr 1fr` for the 4th column |

15 existing public pages carry `site-footer`; with `privacy.html` and `support.html` added
the test runs section (e), (f) and (h) over **17** pages, since the new pages ship the same
footer chrome and should be held to the same contract. `google10b527549df2d462.html` and
`googlee43e9ac03ab14222.html` are Search Console verification stubs with no chrome and are
excluded everywhere.

### Content adaptation from the drafts

Keep the drafts' legal body verbatim in substance (all 12 privacy sections, all support
sections), and keep their `.legal` inline `<style>` block. Replace the drafts' chrome:

- Font/`<link>` tags reordered to match `contact.html` byte-for-byte.
- Header: brand `Phoenix Rising Group`, `menu-toggle` SVG copied from `contact.html`
  (24×24, `stroke-width="2"`, `M3 6h18M3 12h18M3 18h18`) — the drafts shipped a 22×22
  1.5-weight variant that would not match.
- `site-nav`: the six `contact.html` items (Home, Capabilities, Blog, Products, SASR Eval,
  Contact). The drafts' `Privacy` + `Support` nav entries are **removed**.
- Footer: full four-column footer (`footer-brand` + Pages + Resources + Legal) +
  `footer-bottom`, not the drafts' reduced two-column footer.
- Privacy's absolute `https://…/support.html` link becomes relative `support.html` so it
  resolves in local preview as well as production.

## 3. Footer Legal column (preferred over top nav)

Top nav already holds six items and collapses to a hamburger at ≤760px; adding Privacy and
Support would make seven and crowd it. The brief also says to prefer a footer column. So a
new third-level column is inserted **immediately before `<div class="footer-bottom">`** on
every page:

```html
<div>
  <h4>Legal</h4>
  <ul>
    <li><a href="PREFIXprivacy.html">Privacy</a></li>
    <li><a href="PREFIXsupport.html">Support</a></li>
  </ul>
</div>
```

`.site-footer .wrap` goes to four columns above 900px; the existing `max-width: 900px`
rule already collapses the footer to a single column, so no new breakpoint is needed.

## 4. Relative-path rules

The site is served as plain static files, so every link is depth-relative. The two legal
pages live at the root, so `PREFIX` is `../` repeated once per directory level:

| Page tier | Example | `PREFIX` | Legal links |
| --- | --- | --- | --- |
| Root | `index.html`, `contact.html`, `capabilities.html`, `results.html`, `privacy.html`, `support.html` | *(empty)* | `privacy.html`, `support.html` |
| One level | `blog/index.html`, `products/index.html` | `../` | `../privacy.html`, `../support.html` |
| Two levels | `blog/<post>/index.html`, `products/<desk>/index.html` | `../../` | `../../privacy.html`, `../../support.html` |

The test derives `PREFIX` from each file's own directory depth and then checks the link
target **resolves to a real file on disk**, so a wrong number of `../` fails rather than
merely looking plausible.

## 5. Test plan — `scripts/test_legal_pages.sh`

One executable bash script, no dependencies beyond coreutils/grep/awk/iconv. It prints one
`ok`/`FAIL` line per assertion and exits non-zero if any failed. 204 assertions:

- **(a)** `privacy.html` and `support.html` exist at the repo root.
- **(b)** Both contain `Phoenix Rising Group LLC`, `mailto:radwanjama099@gmail.com`, and
  link to each other (`href="support.html"` / `href="privacy.html"`).
- **(c)** Both load `css/styles.css` and `js/main.js`; both carry `site-header`,
  `menu-toggle`, `site-nav`; the nav contains Home, Capabilities, Blog, Products, Contact
  (plus SASR Eval, for parity with `contact.html`); the nav does **not** link Privacy or
  Support; the `menu-toggle` SVG and the font `<link>` sequence match `contact.html`.
- **(d)** `sitemap.xml` contains both `https://www.phoenixrisinggroups.com/privacy.html`
  and `.../support.html`.
- **(e)** For every HTML page with a `site-footer` (excluding `google*.html`): the
  `footer-brand` anchor text and the `&copy;` line both read `Phoenix Rising Group LLC`,
  and **no** line inside the footer says `Phoenix Rising` without the full `Group LLC`
  suffix — so a leftover bare `Phoenix Rising` or `Phoenix Rising Group` fails.
- **(f)** Every such page has a `<h4>Legal</h4>` column whose Privacy and Support links use
  the depth-correct prefix and resolve to existing files.
- **(g)** The new pages contain no accuracy percentage (`\d+%` or the word "accuracy"), no
  `pilot`, and no government/ministry endorsement claim.
- **(h)** On the 15 pre-existing pages, every occurrence of `LLC` lies **inside** the footer
  and there are exactly two of them (brand link + copyright) — so a future edit that leaks
  the entity name into a `<title>`, `<h1>`, meta or `og:*` tag fails the suite. The two legal
  pages are exempt: they legitimately carry `LLC` in their own title and meta.
- Plus: both new pages are valid UTF-8 and declare `charset="UTF-8"`.

The script is run **before** implementing and must fail (recorded in `TEST_PROOF.md`), then
again after, and must pass.

## 6. Visual proof

Serve the repo with `python3 -m http.server` and capture headless Chrome screenshots at
390×844 (phone viewport) of both pages into `docs/legal-screenshots/`, referenced from
`TEST_PROOF.md`.

## 7. Out of scope

- Renaming the hero/product/header brand, `<title>`s, meta or Open Graph copy. Only footer
  seller attribution and copyright change.
- Any product-page or capability copy edits.
- `google*.html` Search Console stubs.
- Adding `products/voicedoc-dnp/` to `sitemap.xml` (pre-existing gap, unrelated).
- Deploying or merging. **The PR is for CTO review only — do not merge, do not deploy.**
- Moving support email off `radwanjama099@gmail.com` (no domain mailbox exists yet).

---

## Follow-up — soft-fix privacy copy overclaims (PR #15, no merge)

Co-CEO authorized a **soft-fix only** of `privacy.html` before merge, to correct three
operational commitments the review (F5 above) flagged as unverifiable from this repo.
Ground truth: copies of `deploy.md` and `engine.env.example` from phoenix-engine, placed at
`/tmp/privacy-softfix/` for this pass.

1. **Retention/deletion (§6).** `engine retention purge` deletes a dossier and issues a
   certificate, but the purged dossier still exists in backups taken before the purge until
   those backups expire — default `ENGINE_BACKUP_KEEP_DAYS=7`. The old copy promised a
   deletion certificate with no backup caveat. Fix: state that a certificate confirms the
   active copy only, and that backup purge follows the backup-retention window (7 days by
   default). Keep the 30-day figure, but scope it explicitly to account-processing, not to
   backups or all data.
2. **AI / ZDR (§4).** `ENGINE_READER_DPA_CONFIRMED` gates whether real customer files reach
   the reader; that confirmation is not yet in place for every provider. The old copy already
   used "we require…" framing but did not clearly deny that the requirement is already met
   everywhere. Fix: keep the gate framing, add an explicit denial that it is a claim the
   agreement is already in place for every provider today. Demo/synthetic-data wording and the
   customs/government denial sentence are unchanged.
3. **Security (§7).** "Customer data is separated by organization" implies a tenant-isolation
   guarantee this repo cannot verify. Fix: restate as the modest, verifiable claim — named
   accounts, customers see only their own organization's data, review actions are logged.
4. **`support.html`.** Checked the "We process within 30 days" account-deletion line against
   the same ground truth — it already reads as an account-processing SLA and does not imply
   backups or all data are purged in 30 days. No change needed.

Out of scope for this pass: everything else in section 7 above, plus merging and deploying —
deploy remains with the CTO after merge, and this pass does not merge PR #15.

Test plan: extend `scripts/test_legal_pages.sh` with a new section (i) — assertions that the
backup-retention window is stated, that the ZDR/DPA requirement reads as a gate (not a
present-tense signed fact), and that the organization-isolation claim stays modest. Written
red against the pre-fix copy, then green after the edit (see `TEST_PROOF.md`).

---

## Follow-up — test hardening, two open CodeRabbit findings (branch `site/legal-test-hardening`, no merge)

Branch: `site/legal-test-hardening` (base `main` @ `90a2f7b`, i.e. current `origin/main`,
which already includes PR #15).

### 1. Goal

PR #15 squash-merged to `main` as `90a2f7b`. Two CodeRabbit findings were left open:

1. **Silent footer skip.** `collect_footer_pages` in `scripts/test_legal_pages.sh` only
   collected pages that **already** had `<footer class="site-footer">`, so a public page
   missing its footer entirely was silently dropped from every downstream check instead of
   failing the suite.
2. **Stale red-repro commands.** `TEST_PROOF.md`'s RED 1/RED 2 console blocks showed
   `git worktree add --detach … HEAD`, contradicting the surrounding prose, which always
   claimed base `9c6b1a1`.

This follow-up fixes both, with real red→green evidence, and does **not** touch
`privacy.html`/`support.html` wording, add CI, or merge anything.

### 2. Files touched

| Path | Change |
| --- | --- |
| `scripts/test_legal_pages.sh` | `collect_footer_pages` → `collect_public_pages` (no footer pre-filter); new per-page footer-presence assertion in section (e); sections (e)/(f)/(h) now iterate the full public-page set instead of a "already has footer" subset |
| `TEST_PROOF.md` | RED 1/RED 2 commands corrected to `9c6b1a1`, re-run for real with current script; new "Follow-up — test hardening" section with bug demo, mutation RED/GREEN, and a red→green summary table |
| `PLAN.md` | this section |
| `REVIEW.md` | new follow-up review section |

Explicitly **not** touched: `privacy.html`, `support.html`, any other page content,
`sitemap.xml`, `css/styles.css`, and `.github/workflows/ci.yml` (CTO's CI job stays out of
scope for this PR).

### 3. Test plan

1. Demonstrate the pre-fix bug on the current `main` tip (`90a2f7b`) in a scratch worktree:
   strip one page's footer, show the unfixed script still reports `PASS`.
2. Fix the script as described above.
3. Mutation-prove the fix: strip a different page's footer in a scratch copy of the fixed
   tree, confirm the suite `FAIL`s and names that page; restore, confirm green again.
4. Re-run the historical RED 1/RED 2 reproductions in worktrees genuinely checked out at
   `9c6b1a1`, with the current (fixed) script copied in; record real console output.
5. Full suite GREEN on the branch tip.

All evidence lives in `TEST_PROOF.md`; assertion count grows from 211 to 228 (17 new
footer-presence checks), with zero regressions in the pre-existing 211.

### 4. Out of scope

- Any wording change to `privacy.html` or `support.html`. The Gate 4 catch-up in this PR is
  **evidence that the soft-fix wording is unchanged and matches `main`**, not a rewrite —
  confirmed by `git diff origin/main -- privacy.html` being empty.
- Adding `.github/workflows/ci.yml` — CTO owns wiring CI for this script.
- Deploying or merging. **This PR is for review only.**

---

# PLAN — CI workflow that runs the legal-pages contract test

Branch: `ci/legal-pages-workflow` (base `main` @ 90a2f7b)
Workflow: ECC loop — PLAN → failing test (absence of CI) → implement → passing proof → REVIEW → commit/push/PR.

## 1. Goal

`scripts/test_legal_pages.sh` is the contract test for the store-required privacy/support
pages and the footer seller attribution. It passes on `main` today, but nothing runs it
automatically — a future edit to `privacy.html`, `support.html` or any footer could break
an App Store / Play Store / Meta verification requirement and no check would object.

Add a GitHub Actions workflow that executes the script on every pull request, every push
to `main`, and on manual dispatch.

## 2. The gap being proven (red)

The failing test for this change is the *absence* of CI, not a failing assertion: the
script itself passes 211/211 on `main` and must stay that way. Red proof is that
`.github/workflows/` holds only the Pages deploy and no workflow references the script.
Captured in `TEST_PROOF.md` before the workflow is added.

## 3. Change

One new file, `.github/workflows/ci.yml`:

- `on:` `pull_request`, `push` to `main`, `workflow_dispatch`
- `permissions: contents: read` at workflow level — least privilege; it publishes nothing
- `concurrency` keyed on workflow + ref with `cancel-in-progress: true`
- one job `legal-pages` on `ubuntu-latest`: `actions/checkout@v4`, then
  `bash scripts/test_legal_pages.sh`

The script is self-contained (bash + grep, `cd`s to the repo root itself), so no runtime
setup, dependency install or cache step is needed.

## 4. Non-goals

- **No Pages deploy.** `.github/workflows/static.yml` is untouched; the new workflow has no
  `pages:` / `id-token:` permission and no deploy step.
- **No wording changes** to `privacy.html` / `support.html`.
- **No fixes** for the two open CodeRabbit findings (footer silent-skip; TEST_PROOF red
  steps) — Design & Site owns those as a separate follow-up on
  `site/legal-test-hardening`. This branch therefore *appends* its proof/review sections
  to `TEST_PROOF.md` / `REVIEW.md` instead of rewriting them, so that follow-up merges
  cleanly.
- **No branch protection / required-check configuration** — the repo owner's call, in
  GitHub settings, after this merges.
- **No merge.** PR opened for review only.

## 5. Verification

1. Red: `ls .github/workflows/` and `grep -rn test_legal_pages .github/` → no match.
2. Green: `bash scripts/test_legal_pages.sh` → exit 0, 211/211.
3. `ci.yml` parses as YAML with the intended triggers, permissions and steps.
4. `git diff main...HEAD -- .github/workflows/static.yml` → empty.
5. After push, Actions runs `ci.yml` on the PR; the run shows in the PR checks tab.

## 6. Risks

Low — additive file that cannot affect the deployed site, since Pages still deploys solely
from `static.yml` on `main`. If a later change breaks the contract this job goes red; that
is the intent, so it must not be skipped or made `continue-on-error`.
