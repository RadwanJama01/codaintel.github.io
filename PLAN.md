# PLAN — Company-site rebrand

Branch: `site/company-rebrand` (base `main` @ 1281298)

## Goal

The public site pitched Somali/Afar speech research (SASR Eval, ASR blog posts, voice desks).
The people now sent to it are US city halls, Djiboutian freight forwarders (transitaires) and
national institutions. Replace it with a broad company site: what Phoenix Rising Group does,
for which sectors, how it works — without naming research or individual products.

## Scope

1. Rewrite `index.html`, `capabilities.html`, `contact.html` around three sectors
   (local government, trade and logistics, national institutions).
2. Remove retired pages: `blog/`, `products/`, `results.html`, SASR Eval PDF/data, `horn-map.svg`.
3. Top nav: Home · Capabilities · Contact. Legal pages stay footer-only.
4. Replace `css/styles.css` with a lean stylesheet for the remaining pages (drop dead eval/blog/gate
   rules and the duplicated font `@import`); move the legal pages' duplicated inline `<style>` into it.
5. `js/main.js`: drop the eval metric-bar animation (its page is gone).
6. New `assets/og-share.png`; prune `sitemap.xml` to live pages.

## Constraints kept

- Footer seller attribution `Phoenix Rising Group LLC` (brand link + copyright) on every page.
- Privacy and support page bodies unchanged (store-required legal text).
- No claims of customers, adoption, accuracy figures or government endorsement.

## Test

`scripts/test_legal_pages.sh` gains section (j): no public page links a retired page or carries
speech-research terms; every sitemap entry and share-image URL resolves to a file.
