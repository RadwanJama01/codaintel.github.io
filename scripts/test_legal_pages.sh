#!/usr/bin/env bash
#
# Contract test for the store-required legal pages.
#
# Apple App Store and Google Play require a reachable privacy policy URL and a support
# URL; Meta Business verification requires the visible seller name to match the
# registered entity exactly. This script asserts both, plus that the new pages are
# reachable from every public page via a depth-correct footer Legal column.
#
# Usage: scripts/test_legal_pages.sh
# Exits 0 when every assertion holds, 1 otherwise.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
readonly REPO_ROOT="$PWD"

readonly SELLER_NAME='Phoenix Rising Group LLC'
readonly SUPPORT_MAILTO='mailto:radwanjama099@gmail.com'
readonly SITE_ORIGIN='https://www.phoenixrisinggroups.com'
readonly CHROME_REFERENCE='contact.html'
readonly NEW_PAGES=(privacy.html support.html)

# Nav labels every page must expose. Privacy/Support are deliberately absent: the top nav
# is already six items deep, so the legal pages are reached from the footer instead.
readonly REQUIRED_NAV_LABELS=(Home Capabilities Blog Products Contact)

failures=0
checks=0

pass() { checks=$((checks + 1)); printf 'ok   %s\n' "$1"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); printf 'FAIL %s\n' "$1"; }

# assert_ok <description> <exit-status>
assert_ok() {
  if [ "$2" -eq 0 ]; then pass "$1"; else fail "$1"; fi
}

section() { printf '\n== %s ==\n' "$1"; }

# Extract the <footer class="site-footer"> … </footer> block of a page.
footer_of() {
  awk '/<footer class="site-footer">/,/<\/footer>/' "$1"
}

# Extract the footer-brand anchor (brand link text lives here).
footer_brand_of() {
  footer_of "$1" | awk '/<div class="footer-brand">/,/<\/a>/'
}

# Extract the <ul class="site-nav"> … </ul> block of a page.
nav_of() {
  awk '/<ul class="site-nav">/,/<\/ul>/' "$1"
}

# Ordered list of font/stylesheet <link> tags, used for chrome-parity comparison.
font_links_of() {
  grep -E 'fonts\.googleapis\.com|fonts\.gstatic\.com|api\.fontshare\.com' "$1"
}

# Pages that render the shared site chrome. The google*.html files are Search Console
# verification stubs with no chrome and are excluded by design.
collect_footer_pages() {
  find . -name '*.html' -not -path './.git/*' -not -name 'google*.html' -print0 \
    | sort -z \
    | while IFS= read -r -d '' page; do
        page=${page#./}
        if grep -q '<footer class="site-footer">' "$page"; then
          printf '%s\n' "$page"
        fi
      done
}

# Depth-relative prefix from a page back to the repo root ("" / "../" / "../../").
prefix_for() {
  local dir
  dir=$(dirname "$1")
  if [ "$dir" = "." ]; then
    printf ''
    return
  fi
  local depth
  depth=$(printf '%s' "$dir" | awk -F/ '{print NF}')
  local i
  for ((i = 0; i < depth; i++)); do printf '../'; done
}

# ---------------------------------------------------------------------------
section '(a) new pages exist at repo root'

for page in "${NEW_PAGES[@]}"; do
  [ -f "$REPO_ROOT/$page" ]
  assert_ok "$page exists at repo root" $?
done

# Everything downstream needs the files present; bail out early with a clear signal.
if [ "$failures" -gt 0 ]; then
  printf '\n%d/%d checks failed (missing pages — remaining assertions skipped)\n' \
    "$failures" "$checks"
  exit 1
fi

# ---------------------------------------------------------------------------
section '(b) seller name, support email, cross-links'

for page in "${NEW_PAGES[@]}"; do
  grep -qF -- "$SELLER_NAME" "$page"
  assert_ok "$page states seller name '$SELLER_NAME'" $?

  grep -qF -- "$SUPPORT_MAILTO" "$page"
  assert_ok "$page links $SUPPORT_MAILTO" $?
done

grep -qF 'href="support.html"' privacy.html
assert_ok "privacy.html links to support.html" $?

grep -qF 'href="privacy.html"' support.html
assert_ok "support.html links to privacy.html" $?

# ---------------------------------------------------------------------------
section '(c) shared chrome parity'

for page in "${NEW_PAGES[@]}"; do
  grep -qF 'href="css/styles.css"' "$page"
  assert_ok "$page loads css/styles.css" $?

  grep -qF 'src="js/main.js"' "$page"
  assert_ok "$page loads js/main.js" $?

  grep -qF '<header class="site-header">' "$page"
  assert_ok "$page has site-header" $?

  grep -qF 'class="menu-toggle"' "$page"
  assert_ok "$page has menu-toggle" $?

  grep -qF '<ul class="site-nav">' "$page"
  assert_ok "$page has site-nav" $?

  for label in "${REQUIRED_NAV_LABELS[@]}"; do
    nav_of "$page" | grep -qF ">$label<"
    assert_ok "$page site-nav offers '$label'" $?
  done

  # Parity with contact.html: SASR Eval is the sixth item on every other page.
  nav_of "$page" | grep -qF 'results.html'
  assert_ok "$page site-nav offers SASR Eval (results.html)" $?

  # The top nav must stay uncrowded — legal pages are footer-only.
  if nav_of "$page" | grep -qE 'privacy\.html|support\.html'; then
    fail "$page site-nav does not link Privacy/Support (keeps top nav uncrowded)"
  else
    pass "$page site-nav does not link Privacy/Support (keeps top nav uncrowded)"
  fi

  # menu-toggle markup must be the contact.html variant, not the draft's 22x22 one.
  diff <(grep -A 1 'class="menu-toggle"' "$CHROME_REFERENCE") \
       <(grep -A 1 'class="menu-toggle"' "$page") >/dev/null 2>&1
  assert_ok "$page menu-toggle markup matches $CHROME_REFERENCE" $?

  diff <(font_links_of "$CHROME_REFERENCE") <(font_links_of "$page") >/dev/null 2>&1
  assert_ok "$page font link tags match $CHROME_REFERENCE in content and order" $?

  grep -qiF 'charset="UTF-8"' "$page"
  assert_ok "$page declares charset UTF-8" $?

  iconv -f UTF-8 -t UTF-8 "$page" >/dev/null 2>&1
  assert_ok "$page is valid UTF-8" $?
done

# ---------------------------------------------------------------------------
section '(d) sitemap.xml'

for page in "${NEW_PAGES[@]}"; do
  grep -qF "$SITE_ORIGIN/$page" sitemap.xml
  assert_ok "sitemap.xml lists $SITE_ORIGIN/$page" $?
done

# ---------------------------------------------------------------------------
footer_pages=()
while IFS= read -r line; do
  footer_pages+=("$line")
done < <(collect_footer_pages)

section "(e) footer seller attribution across ${#footer_pages[@]} public pages"

if [ "${#footer_pages[@]}" -eq 0 ]; then
  fail 'found at least one public page with a site-footer'
else
  pass "found ${#footer_pages[@]} public pages with a site-footer"
fi

for page in "${footer_pages[@]}"; do
  footer_brand_of "$page" | grep -qF -- "$SELLER_NAME"
  assert_ok "$page footer-brand link text reads '$SELLER_NAME'" $?

  footer_of "$page" | grep -F '&copy;' | grep -qF -- "$SELLER_NAME"
  assert_ok "$page &copy; line reads '$SELLER_NAME'" $?

  # No bare "Phoenix Rising" / "Phoenix Rising Group" may survive inside the footer.
  if footer_of "$page" | grep -F 'Phoenix Rising' | grep -vqF -- "$SELLER_NAME"; then
    fail "$page footer has no bare 'Phoenix Rising' without '$SELLER_NAME'"
  else
    pass "$page footer has no bare 'Phoenix Rising' without '$SELLER_NAME'"
  fi
done

# ---------------------------------------------------------------------------
section '(f) footer Legal column with depth-correct, resolvable links'

for page in "${footer_pages[@]}"; do
  footer=$(footer_of "$page")
  prefix=$(prefix_for "$page")
  page_dir=$(dirname "$page")
  legal_column=$(printf '%s\n' "$footer" | awk '/<h4>Legal<\/h4>/,/<\/div>/')

  [ -n "$legal_column" ]
  assert_ok "$page footer has a Legal column" $?

  for target in privacy.html support.html; do
    expected="${prefix}${target}"

    printf '%s\n' "$legal_column" | grep -qF "href=\"$expected\""
    assert_ok "$page Legal column links $target as '$expected'" $?

    # Resolve the href the page actually ships, not the one we expected, so a
    # wrong number of ../ segments fails here as well as on the match above.
    shipped=$(printf '%s\n' "$legal_column" \
      | grep -oE "href=\"[^\"]*${target//./\\.}\"" \
      | head -1 \
      | sed -e 's/^href="//' -e 's/"$//')

    if [ -n "$shipped" ] && [ -f "$REPO_ROOT/$page_dir/$shipped" ]; then
      pass "$page shipped link '$shipped' resolves to an existing file"
    else
      fail "$page shipped link '${shipped:-<missing>}' resolves to an existing file"
    fi
  done
done

# ---------------------------------------------------------------------------
section '(h) LLC confined to footer attribution on pre-existing pages'

for page in "${footer_pages[@]}"; do
  # The two legal pages legitimately carry the entity name in their own <title>
  # and meta tags. Every other page must mention it only as footer attribution:
  # exactly twice, both inside the footer (brand link text + copyright line).
  case "$page" in
    privacy.html | support.html) continue ;;
  esac

  total=$(grep -o 'LLC' "$page" | wc -l)
  in_footer=$(footer_of "$page" | grep -o 'LLC' | wc -l)

  if [ "$total" -eq "$in_footer" ] && [ "$in_footer" -eq 2 ]; then
    pass "$page mentions LLC only as footer attribution (brand + copyright)"
  else
    fail "$page mentions LLC only as footer attribution (brand + copyright) — found $in_footer in footer of $total total, expected 2 of 2"
  fi
done

# ---------------------------------------------------------------------------
section '(g) forbidden claims absent from the new pages'

for page in "${NEW_PAGES[@]}"; do
  if grep -qE '[0-9]+(\.[0-9]+)?[[:space:]]*%' "$page"; then
    fail "$page makes no numeric percentage claim"
  else
    pass "$page makes no numeric percentage claim"
  fi

  if grep -qiE '\baccurac(y|ies)\b|\baccurate\b' "$page"; then
    fail "$page makes no accuracy claim"
  else
    pass "$page makes no accuracy claim"
  fi

  if grep -qiE '\bpilots?\b|\bpiloting\b|\bpiloted\b' "$page"; then
    fail "$page does not use the word 'pilot'"
  else
    pass "$page does not use the word 'pilot'"
  fi

  if grep -qiE '\b(ministry|ministries|ministerial)\b' "$page"; then
    fail "$page claims no ministry involvement"
  else
    pass "$page claims no ministry involvement"
  fi

  if grep -qiE '(endorsed|approved|certified|adopted|authorized|accredited)[[:space:]]+by[[:space:]]+(the[[:space:]]+)?(government|ministry|state|customs)|government[[:space:]]+(endorsement|approval|partner|certification|adoption)' "$page"; then
    fail "$page claims no government endorsement"
  else
    pass "$page claims no government endorsement"
  fi
done

# ---------------------------------------------------------------------------
section '(i) soft-fix: retention, AI/DPA, and security claims stay accurate'

grep -qiF 'backups' privacy.html
assert_ok 'privacy.html retention section mentions backups' $?

grep -qiF '7 days' privacy.html
assert_ok 'privacy.html states the backup retention window (7 days)' $?

if grep -qiE 'we have (a )?signed|already signed|is signed' privacy.html; then
  fail 'privacy.html does not claim a signed zero-retention/DPA agreement as current fact'
else
  pass 'privacy.html does not claim a signed zero-retention/DPA agreement as current fact'
fi

grep -qiF 'before any real customer file' privacy.html
assert_ok 'privacy.html frames the ZDR/DPA requirement as a gate before real customer files' $?

if grep -qiF 'separated by organization' privacy.html; then
  fail 'privacy.html does not claim blanket organization-separated isolation'
else
  pass 'privacy.html does not claim blanket organization-separated isolation'
fi

grep -qiF 'own organization' privacy.html
assert_ok "privacy.html states the modest claim: customers see their own organization's data" $?

if grep -qiE 'guarantee(d)?[[:space:]]+(a[[:space:]]+)?deletion certificate|always issue a deletion certificate' privacy.html; then
  fail 'privacy.html does not promise deletion certificates as an unconditional guarantee'
else
  pass 'privacy.html does not promise deletion certificates as an unconditional guarantee'
fi

# ---------------------------------------------------------------------------
printf '\n'
if [ "$failures" -eq 0 ]; then
  printf 'PASS: %d/%d checks passed\n' "$checks" "$checks"
  exit 0
fi
printf 'FAIL: %d of %d checks failed\n' "$failures" "$checks"
exit 1
