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
