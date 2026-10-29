# REVIEW — company-site rebrand

Branch `site/company-rebrand`, base `main` @ `1281298`.

| Check | Result |
| --- | --- |
| Contract test | 122/122 pass |
| Stale links to removed pages/assets | none (`grep` for blog/, products/, results.html, horn-map, sasr) |
| LLC only in footer on non-legal pages | pass (section h) |
| Claims of customers, accuracy, government adoption | none |
| Dead CSS/JS | removed; stylesheet rewritten for the 5 remaining pages |

## Open items for the owner

- `support.html` says Phoenix Rising examiners review each Phoenix Check result. The product model
  is that the customer's own clerks review. Legal text left unchanged here; needs a decision.
- `assets/og-share.png` was rendered without the brand fonts (font CDNs unreachable from the build
  sandbox), so it uses system serif/sans. Re-render with Instrument Serif before relying on link previews.
- French version of the site for Djiboutian visitors is not in this PR.
