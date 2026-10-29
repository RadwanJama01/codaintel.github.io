# TEST_PROOF — company-site rebrand

Test file: [`scripts/test_legal_pages.sh`](scripts/test_legal_pages.sh)

## RED — new test against base `1281298`

Run in a detached worktree at the base commit with only the new test script copied in:

```
FAIL: 42 of 288 checks failed
```

Failures were the retired pages (nav links to blog/products/results, speech-research copy) and
sitemap entries pointing at directories.

## GREEN — this branch

```
PASS: 122/122 checks passed
```

The total is lower than base because the per-page checks now run over 5 public pages instead of 16.

## Visual check

Rendered with headless Chromium at 1440x900 and 390x844 (index, capabilities, contact, support):
no horizontal scroll at phone width. One defect found and fixed: the active Contact button on
`contact.html` rendered black-on-black (`.site-nav a.active` outranked `.site-nav .nav-cta`).
