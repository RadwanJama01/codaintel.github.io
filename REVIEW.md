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

---

## Follow-up — soft-fix privacy copy overclaims (PR #15, no merge)

Co-CEO authorized a soft-fix of `privacy.html` §4, §6, §7 to resolve F5 above (the
operational commitments this repo cannot independently verify), against ground truth from
phoenix-engine's `deploy.md` and `engine.env.example`. **Verdict: approved, no merge
(author's self-review).** No CRITICAL/HIGH findings; one wording issue found and fixed
during self-review. This is not Gate 4; Gate 4 privacy independent review is recorded in
the Independent review table under the CI section below.

| Severity | Found | Fixed |
| --- | --- | --- |
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 1 | 1 |
| LOW | 0 | — |

### F6 — MEDIUM — §4's denial sentence contained the literal phrase it was meant to deny

While tightening §4 to deny a present-tense signed-ZDR claim, the first wording ("not a
statement that every provider agreement is **already signed**") embedded the exact phrase
a human skimming the page could misread as the claim itself, inside a negation easy to miss.
Caught by the new contract assertion in `scripts/test_legal_pages.sh` (which uses the same
naive substring match a skimming reader effectively does), not by eye.

**Fixed.** Reworded to "not a claim that it is in place for every provider today" —
semantically identical, with no overlap with the forbidden phrase. Re-verified: 211/211.

### Explicitly checked, no findings

- **§6 retention.** Deletion-certificate language is now scoped ("confirms the active copy
  was removed") and paired with the backup caveat (default 7-day window, matching
  `ENGINE_BACKUP_KEEP_DAYS=7` in ground truth); the 30-day figure is now explicitly scoped to
  account processing, not backups or all data — matches ground-truth rule 1 and rule 2.
- **§4 AI/DPA.** Reads as a gate ("before any real customer file is sent, we require…") with
  an explicit denial that it's already in place for every provider — matches ground-truth
  rule 3. The customs/government-portal denial sentence is untouched.
- **§7 security.** "Customer data is separated by organization" (an isolation claim this repo
  can't verify) is replaced with "customers see their own organization's dossiers and
  reports, not other customers' data" plus "review actions… are logged" — matches
  ground-truth rule 4, no certificate/full-isolation marketing added.
- **`support.html`.** "We process within 30 days" read against the same ground truth; it's
  already an account-processing SLA and doesn't claim backups or all data are gone in 30
  days. Left unchanged — editing it for no reason would be its own risk.
- **Forbidden claims (section g).** No percentage, "accuracy", "pilot", ministry, or
  government-endorsement language introduced by the new wording. Re-verified by the full
  suite run (section (g) still 10/10 green).
- **Scope discipline.** Diff touches only the `<p>` bodies of §4/§6/§7 and the "Last updated"
  date in `privacy.html`, plus the new section (i) in the test script and these three
  evidence files. Footer, nav, chrome, seller name, support email, and `support.html` markup
  are untouched — confirmed by re-running the full 211-assertion suite, not just the new
  section.
- **Secrets/PII.** No secrets, keys, or new PII introduced; the only identifiers are the
  pre-existing support email and the unchanged entity name.
- **Static-only.** Plain prose edits inside existing `<p>` tags; no new markup, scripts, or
  dependencies.

---

## Follow-up — test hardening, two CodeRabbit findings (branch `site/legal-test-hardening`, no merge)

Base `main` @ `90a2f7b` (current `origin/main`, includes PR #15). Reviewed: one script file
(`scripts/test_legal_pages.sh`) and three evidence docs. **No HTML, CSS, or site content
changed.**

**Verdict: approved for PR. No CRITICAL or HIGH findings.**

| Severity | Found | Fixed |
| --- | --- | --- |
| CRITICAL | 0 | — |
| HIGH | 0 | — |
| MEDIUM | 0 | — |
| LOW | 0 | — |

### Code review — `scripts/test_legal_pages.sh`

- **Fix verified correct.** `collect_public_pages()` now enumerates every `*.html` except
  `.git/*` and `google*.html` unconditionally — no footer pre-filter. The new per-page
  assertion `grep -qF '<footer class="site-footer">' "$page"` in section (e) runs before any
  downstream check consumes that page, so a page missing the footer fails there by name, and
  the rename from `footer_pages` to `public_pages` is applied consistently across sections
  (e), (f), and (h) (checked by `grep -n 'footer_pages\|public_pages'
  scripts/test_legal_pages.sh` — no stale references remain).
- **Downstream behavior on a missing footer is still sane.** `footer_of()`,
  `footer_brand_of()`, and the Legal-column extraction in (f) all return empty string for a
  footerless page (`awk` ranges that never match print nothing), which fails the dependent
  assertions individually rather than erroring the script — confirmed by the mutation test
  (9 failures, all naming the mutated page, exit 1, no script crash).
- **No new injection/quoting risk.** The new assertion is a straight `grep -qF` (fixed
  string) against a filename already produced by the existing `find -print0 | sort -z` /
  `IFS= read -r -d ''` pipeline (NUL-delimited, so filenames with spaces or newlines are
  still handled correctly — this was F3 in the original review and remains fixed).
  `SELLER_NAME`/footer markup is still matched with `-F` throughout, so no regex metacharacter
  in page content can alter match semantics.
- **No functional change to sections (a)–(d) and (g)–(i).** Confirmed by diff: the only hunks
  touch the `collect_footer_pages`/`collect_public_pages` function and the three `for page in
  "${footer_pages[@]}"` → `"${public_pages[@]}"` loop headers plus the new assertion loop.
- **Assertion count.** 211 → 228 (+17, one new footer-presence check per public page). All
  211 pre-existing assertions pass unchanged on the branch tip (`TEST_PROOF.md` GREEN run).

### Security review — `scripts/test_legal_pages.sh`

- **No new external input surface.** The script still only reads files already tracked in
  this repo; no network calls, no `eval`, no unsanitized interpolation into a shell command
  (`grep -qF -- "$SELLER_NAME" "$page"` — `--` guards against a page name or constant that
  starts with `-`).
- **No secrets, credentials, or PII touched.** The diff is pure test logic; no change to
  `SUPPORT_MAILTO`, `SELLER_NAME`, or any other constant.
- **Scratch sandboxes used for evidence (`/tmp/bugdemo-sandbox`, `/tmp/mutation-sandbox`,
  `/tmp/red1-sandbox`, `/tmp/red2-sandbox`) were plain `git worktree` copies / `cp -r` copies
  of already-public site content**, created and removed within this session, outside the
  repo's `.git` — no residual state left in the working tree or on `main`.

### Docs review — `TEST_PROOF.md`, `PLAN.md`

- **Fix 2 verified correct.** The RED 1/RED 2 console blocks now show
  `git worktree add --detach … 9c6b1a1`, matching the surrounding prose's long-standing claim
  of that base commit, and both blocks were re-executed for real (not hand-edited transcripts
  — see the `Preparing worktree (detached HEAD 9c6b1a1)` line captured from the actual `git`
  output in each block).
- **Assertion-count consistency.** Every count mentioned in `TEST_PROOF.md` (`202` pre-fix
  bug demo, `228` post-fix RED/GREEN) was taken directly from the `PASS:`/`FAIL:` summary
  line the script itself prints — not computed by hand.
- **No stale cross-references.** `PLAN.md`'s new follow-up section and `TEST_PROOF.md`'s new
  follow-up section cross-link consistently; the historical PR #15 and soft-fix sections above
  them are left intact except for the minimal RED 1/RED 2 command/output correction.

### privacy.html — unchanged, matches `main`'s soft-fix

```console
$ git diff origin/main -- privacy.html
(empty)
```

`privacy.html` on this branch is **byte-identical** to `origin/main` (`90a2f7b`). Confirmed
present, verbatim, in the current file:

- *"purged data can remain in encrypted backups made before the deletion until those backups
  expire — by default within **7 days**"* (backup retention window).
- *"That 30-day figure covers account processing only, not backups"* (30-day scoped to
  account-deletion SLA, not a blanket data-purge claim).
- *"this is a gate we enforce, not a claim that it is in place for every provider today"*
  (no signed ZDR/DPA claimed as current fact).
- *"Access is limited to named accounts. Customers see their own organization's dossiers and
  reports, not other customers' data. Review actions … are logged."* (modest,
  named-account / own-organization / logged-review wording, no blanket isolation guarantee).

No wording was touched in this PR — this section is evidence only, per the task's
instruction not to rewrite privacy copy absent a regression, and none was found.

**@CTO / reviewers — Gate 4 catch-up requested:** please independently review the
`privacy.html` wording quoted above, now live on `main` and unchanged in this PR, before
relying on it for store listings. This PR does not supersede or complete that review.

### Out of scope — deliberately not changed

- `privacy.html` / `support.html` content — evidence-only in this PR.
- `.github/workflows/ci.yml` — left untracked/untouched; CTO owns wiring CI for
  `scripts/test_legal_pages.sh`.
- Deploying or merging. **This PR is for review only — do not merge.**

---

# REVIEW — CI workflow for the legal-pages contract test

Change under review: new file `.github/workflows/ci.yml` (44 lines), branch
`ci/legal-pages-workflow` off `main` @ 90a2f7b. Nothing else is modified except `PLAN.md`
and appended sections in `TEST_PROOF.md` / this file.

Appended rather than rewritten so the Design & Site follow-up merges without conflict.

## Scope check

```console
$ git diff --stat main...HEAD
 .github/workflows/ci.yml |  44 +++++
 PLAN.md                  | ...
 REVIEW.md                | ...
 TEST_PROOF.md            | ...
```

- `privacy.html` / `support.html` wording: **untouched** (zero diff).
- `.github/workflows/static.yml`: **untouched** (zero diff) — Pages deploy unchanged.
- `scripts/test_legal_pages.sh`: **untouched** — the two open CodeRabbit findings (footer
  silent-skip; TEST_PROOF red steps) are left to the Design & Site follow-up, and neither
  was required to make CI run.

## Code review

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | MEDIUM | `actions/checkout` persisted a credential in `.git/config` by default, giving later steps ambient git write access the job never needs. | **Fixed** — `persist-credentials: false`. |
| 2 | MEDIUM | No `timeout-minutes`, so a hung job could hold a runner for the 6-hour default. The job is grep over a few HTML files. | **Fixed** — `timeout-minutes: 5`. |
| 3 | LOW | `actions/checkout@v4` is a mutable major tag, not a pinned commit SHA. | **Accepted, not changed.** `static.yml` pins the same way; diverging in one workflow buys little and costs consistency. A repo-wide move to SHA pinning belongs in its own change. |
| 3b | LOW | The first CI run emitted `Node.js 20 is deprecated ... actions/checkout@v4 ... forced to run on Node.js 24`. | **Accepted, not changed.** `actions/checkout@v5` targets Node 24, but `static.yml` is also on `@v4`; bumping both together is the correct follow-up. Advisory only — the run succeeded. |
| 4 | LOW | `cancel-in-progress: true` also cancels superseded `push`-to-`main` runs. | **Accepted.** The job is test-only — cancelling it cannot interrupt a deploy, and the newest commit on `main` is the one whose result matters. |
| 5 | INFO | `pull_request` has no `branches:` filter, so the check runs on PRs targeting any branch. | **Intended** — the contract should hold on every PR, not just those into `main`. |

Positive observations:

- Least privilege: `permissions: contents: read` at workflow level, so the job's
  `GITHUB_TOKEN` cannot write to the repo, packages, or Pages.
- No deploy surface: no `pages:` or `id-token:` permission, no `environment:`, no
  `actions/deploy-pages` or `upload-pages-artifact` step. Deploying stays solely in
  `static.yml`.
- No `continue-on-error` and no `if:` guard on the test step, so a failure cannot be
  silently skipped — it fails the job and the check.
- Single responsibility and no premature generality: one job, two steps, no matrix, no
  caching, no dependency install. The script is self-contained bash + grep and `cd`s to the
  repo root itself, so a runtime setup step would be dead weight.
- Concurrency group is keyed on both workflow and ref, so unrelated branches do not cancel
  each other.
- Readability: 44 lines, under every file/function size limit; comments explain *why*
  (store requirements, least privilege, no runtime needed) rather than restating the YAML.

## Security review

Checked against the GitHub Actions items in the project security rules:

- **Hardcoded secrets / credentials:** none. `grep -nE "secrets\.|GITHUB_TOKEN|id-token"`
  over `ci.yml` exits 1 — the workflow references no secret and no token, so there is
  nothing for a fork PR to exfiltrate.
- **Token write permissions:** none. `contents: read` only; every other permission scope is
  dropped to `none` by GitHub once the block is declared.
- **Untrusted-input / script injection:** none. No `${{ ... }}` interpolation appears inside
  any `run:` block (`grep -nE '^\s+run:.*\$\{\{'` exits 1), so no PR title, branch name or
  body can be expanded into the shell. The one `run:` line is a static string.
- **Trigger choice:** `pull_request`, not `pull_request_target`. Fork PR code therefore
  executes in the unprivileged context — read-only token, no access to repository secrets.
  This is the correct trigger for a workflow that runs code from the PR's own checkout.
- **Running a script from the checkout:** a fork PR could modify
  `scripts/test_legal_pages.sh` and have the runner execute it. That is inherent to any
  CI that tests PR code, and here the blast radius is bounded to an ephemeral runner with
  a read-only token and no secrets. Accepted risk; no mitigation needed at this trust
  level. (If secrets are ever added to this workflow, that calculus changes and the job
  would need to move behind an approval gate.)
- **Third-party actions:** one, `actions/checkout`, first-party GitHub and the same version
  `static.yml` already trusts. No third-party actions introduced.
- **Supply-chain / egress:** the job installs nothing and makes no network calls beyond the
  checkout itself.

**Verdict: approve (author's self-review).** No CRITICAL or HIGH findings. Both MEDIUM
findings were fixed in this branch before commit; the remaining LOW/INFO items are
documented accepted trade-offs.

This verdict is the **author's own self-review** of the CI workflow PR (#16). It does
**not** clear Gate 4 (independent review). An independent review must be recorded
separately below and must come from someone other than the author of the change.

## Independent review (Gate 4) — recorded separately

| Subject | Reviewer | Where | Result |
| --- | --- | --- | --- |
| Live `privacy.html` soft-fix (Gate 4 catch-up) | CTO (independent of Design & Site authorship) | [PR #17 COMMENT](https://github.com/RadwanJama01/codaintel.github.io/pull/17#pullrequestreview-5642322698) and earlier soft-fix COMMENT | COMMENT, no blockers — ZDR-as-gate, 7-day backups, 30-day = account SLA only |
| CI workflow (`.github/workflows/ci.yml`) in #16 | CodeRabbit bot only before merge | [PR #16 CodeRabbit review](https://github.com/RadwanJama01/codaintel.github.io/pull/16#pullrequestreview-5642307939) | 2 actionable doc findings (this follow-up). **No human independent review of the CI workflow was recorded before #16 merged** — Gate 4 gap called by Co-CEO. |
| Docs-only follow-up that labels the self-review and corrects TEST_PROOF line refs (this PR) | Pending — request CTO independent COMMENT on this PR's tip before merge | this PR | not yet reviewed |

Do not treat the author's self-review above, or CodeRabbit alone, as Gate 4 clearance for
the CI workflow. Human independent review of this docs follow-up (and acknowledgment of
the #16 Gate 4 gap) is still required before merge.

## Verification after fixes

```console
$ python3 -c "yaml.safe_load(...)"
triggers:    ['pull_request', 'push', 'workflow_dispatch'] | push: {'branches': ['main']}
permissions: {'contents': 'read'}
timeout:     5
  step: actions/checkout@v4 | with: {'persist-credentials': False}
  step: bash scripts/test_legal_pages.sh | with: None

$ bash scripts/test_legal_pages.sh | tail -1
PASS: 211/211 checks passed
```

Full red/green evidence, including the mutation test proving the job turns red on a
regression, is in `TEST_PROOF.md`.

---

# REVIEW — Docs follow-up (#16 CodeRabbit findings)

Change under review: docs-only edits to `REVIEW.md` / `TEST_PROOF.md` / `PLAN.md` on
branch `docs/coderabbit-16-followup` off `main` @ 638822e.

## Scope check

- `.github/workflows/ci.yml`: **untouched**
- `scripts/test_legal_pages.sh`: **untouched**
- `privacy.html` / `support.html`: **untouched**
- Diff is evidence docs only

## Code review (author's self-review of this follow-up)

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | MEDIUM (doc) | CI section `Verdict: approve` looked like Gate 4 clearance | **Fixed** — labelled `(author's self-review)`; added Independent review table |
| 2 | LOW (doc) | TEST_PROOF claimed `ci.yml` line 38 for the `run:` step | **Fixed** — prose + transcript now say line **44** |
| 3 | INFO | Soft-fix verdict nearby also read as an independent approve | **Fixed** — labelled `(author's self-review)` and pointed at Gate 4 table |

**Verdict: approve for PR (author's self-review of this docs follow-up).** No CRITICAL or
HIGH findings. This self-review does **not** clear Gate 4 — @CTO please leave an
independent COMMENT on this PR's tip before merge.

## Security review

Docs-only; no workflow, secret, permission, or deploy surface changed. N/A beyond confirming
`git diff` excludes `.github/workflows` and `scripts/`.

## Independent review (Gate 4) — requested

Pending CTO COMMENT on this PR. Prior related independent review already on record:

- Privacy soft-fix Gate 4: [PR #17 CTO COMMENT](https://github.com/RadwanJama01/codaintel.github.io/pull/17#pullrequestreview-5642322698) — no blockers.
