#!/usr/bin/env bash
#
# Contract test for the 404 page and the redirects covering the pages PR #19 retired.
#
# Twelve URLs that used to be live now have nothing behind them. Two hosts serve this repo
# and they need different answers: Vercel (production) takes 308 redirects from
# vercel.json, GitHub Pages has no redirect configuration and needs a stub file sitting at
# each retired path. This asserts both, plus that anything still falling through lands on a
# branded 404 rather than the host's default.
#
# scripts/redirect_map.txt is the single source of truth for which path goes where.
#
# Usage: scripts/test_redirects.sh
# Exits 0 when every assertion holds, 1 otherwise, 2 when the repo is unreadable.

set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
readonly REPO_ROOT="$PWD"

readonly MAP_FILE='scripts/redirect_map.txt'
readonly VERCEL_HELPER='scripts/vercel_redirects.py'
readonly VERCEL_CONFIG='vercel.json'
readonly NOT_FOUND_PAGE='404.html'
readonly SITEMAP='sitemap.xml'

readonly SELLER_NAME='Phoenix Rising Group LLC'
readonly SITE_ORIGIN='https://www.phoenixrisinggroups.com'
readonly REQUIRED_NAV_LABELS=(Home Capabilities Contact)

# Sources vercel.json must carry literally. The two wildcards would cover the bare paths on
# their own, but naming all five means a wildcard behaving differently from this test's
# model still leaves the top-level URLs redirected by an exact rule.
readonly REQUIRED_SOURCES=(/products '/products/:path*' /blog '/blog/:path*' /results.html)

# Retired-content terms, same set scripts/test_legal_pages.sh applies to public pages. The
# stubs are excluded from that scan, so they are checked here instead.
readonly RETIRED_CONTENT='\bASR\b|SASR|speech recognition|Somali|Afar'
readonly RETIRED_PATHS='results\.html|/blog|/products'

failures=0
checks=0

pass() { checks=$((checks + 1)); printf 'ok   %s\n' "$1"; }
fail() { checks=$((checks + 1)); failures=$((failures + 1)); printf 'FAIL %s\n' "$1"; }

# assert_ok <description> <exit-status>
assert_ok() {
  if [ "$2" -eq 0 ]; then pass "$1"; else fail "$1"; fi
}

# assert_absent <description> <extended-regex> <file> — passes when the pattern is NOT found.
assert_absent() {
  if grep -qiE "$2" "$3"; then fail "$1"; else pass "$1"; fi
}

section() { printf '\n== %s ==\n' "$1"; }

# Repo file a destination URL path resolves to ("/" -> index.html, "/x/" -> x/index.html).
file_for_url() {
  case "$1" in
    */) printf '%sindex.html' "${1#/}" ;;
    /*) printf '%s' "${1#/}" ;;
    *)  return 1 ;;
  esac
}

# URL forms a retired file path used to answer on. A directory index served three:
# bare, trailing-slash and the explicit file.
url_forms_for() {
  local path=$1
  if [ "${path##*/}" = 'index.html' ]; then
    local dir=${path%/index.html}
    printf '/%s\n/%s/\n/%s\n' "$dir" "$dir" "$path"
    return
  fi
  printf '/%s\n' "$path"
}

# Extract the <footer class="site-footer"> … </footer> block of a page.
footer_of() {
  awk '/<footer class="site-footer">/,/<\/footer>/' "$1"
}

# Extract the <ul class="site-nav"> … </ul> block of a page.
nav_of() {
  awk '/<ul class="site-nav">/,/<\/ul>/' "$1"
}

# ---------------------------------------------------------------------------
# Load the map. Everything downstream is driven by it, so a missing or empty map is fatal
# rather than a failed assertion — there would be nothing left to assert.
retired_paths=()
retired_targets=()

if [ ! -f "$MAP_FILE" ]; then
  printf 'FAIL %s is missing; nothing to check\n' "$MAP_FILE"
  exit 2
fi

while read -r path target _rest; do
  case "$path" in '' | '#'*) continue ;; esac
  retired_paths+=("$path")
  retired_targets+=("$target")
done < "$MAP_FILE"

if [ "${#retired_paths[@]}" -eq 0 ]; then
  printf 'FAIL %s lists no retired paths; nothing to check\n' "$MAP_FILE"
  exit 2
fi

# ---------------------------------------------------------------------------
section "(a) $NOT_FOUND_PAGE is a branded page, not a host default"

[ -f "$NOT_FOUND_PAGE" ]
assert_ok "$NOT_FOUND_PAGE exists at repo root" $?

if [ -f "$NOT_FOUND_PAGE" ]; then
  grep -qF '<header class="site-header">' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE has the site header" $?

  grep -qF '<ul class="site-nav">' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE has the site nav" $?

  for label in "${REQUIRED_NAV_LABELS[@]}"; do
    nav_of "$NOT_FOUND_PAGE" | grep -qF ">$label<"
    assert_ok "$NOT_FOUND_PAGE site-nav offers '$label'" $?
  done

  grep -qF '<footer class="site-footer">' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE has the site footer" $?

  footer_of "$NOT_FOUND_PAGE" | grep -qF -- "$SELLER_NAME"
  assert_ok "$NOT_FOUND_PAGE footer states '$SELLER_NAME'" $?

  # Vercel serves this page for any unmatched URL, including deep ones, so a relative
  # href would resolve against the missing path. Every link has to be root-absolute.
  grep -qF 'href="/"' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE links home as '/'" $?

  grep -qF 'href="/contact.html"' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE links '/contact.html'" $?

  grep -qF 'href="/css/styles.css"' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE loads '/css/styles.css'" $?

  if grep -oE 'href="[^"]+"' "$NOT_FOUND_PAGE" \
    | grep -vE 'href="(/|#|mailto:|https://)' | grep -q .; then
    fail "$NOT_FOUND_PAGE uses only root-absolute, anchor, mailto or https links"
  else
    pass "$NOT_FOUND_PAGE uses only root-absolute, anchor, mailto or https links"
  fi

  grep -qiF 'charset="UTF-8"' "$NOT_FOUND_PAGE"
  assert_ok "$NOT_FOUND_PAGE declares charset UTF-8" $?

  iconv -f UTF-8 -t UTF-8 "$NOT_FOUND_PAGE" >/dev/null 2>&1
  assert_ok "$NOT_FOUND_PAGE is valid UTF-8" $?

  # Same copy constraints the rest of the site is held to.
  assert_absent "$NOT_FOUND_PAGE makes no numeric percentage claim" \
    '[0-9]+(\.[0-9]+)?[[:space:]]*%' "$NOT_FOUND_PAGE"
  assert_absent "$NOT_FOUND_PAGE makes no accuracy claim" \
    '\baccurac(y|ies)\b|\baccurate\b' "$NOT_FOUND_PAGE"
  assert_absent "$NOT_FOUND_PAGE does not use the word 'pilot'" \
    '\bpilots?\b|\bpiloting\b|\bpiloted\b' "$NOT_FOUND_PAGE"
  assert_absent "$NOT_FOUND_PAGE claims no ministry involvement" \
    '\b(ministry|ministries|ministerial)\b' "$NOT_FOUND_PAGE"
  assert_absent "$NOT_FOUND_PAGE claims no government endorsement" \
    '(endorsed|approved|certified|adopted|authorized|accredited)[[:space:]]+by[[:space:]]+(the[[:space:]]+)?(government|ministry|state|customs)|government[[:space:]]+(endorsement|approval|partner|certification|adoption)' \
    "$NOT_FOUND_PAGE"
  assert_absent "$NOT_FOUND_PAGE claims nothing about being AI-made" \
    '\b(ai|claude|chatgpt|gpt|llm)[-[:space:]]?(generated|written|authored|built|made|assisted)\b|\b(generated|written|authored|built|made)[[:space:]]+(by|with)[[:space:]]+(an?[[:space:]]+)?(ai|claude|chatgpt|gpt|llm)\b' \
    "$NOT_FOUND_PAGE"
  assert_absent "$NOT_FOUND_PAGE carries no speech-research content" \
    "$RETIRED_CONTENT" "$NOT_FOUND_PAGE"

  # A 404 that offers the visitor another dead URL is worse than one that offers nothing.
  if grep -oE 'href="[^"]+"' "$NOT_FOUND_PAGE" | grep -qE "$RETIRED_PATHS"; then
    fail "$NOT_FOUND_PAGE links none of the retired paths"
  else
    pass "$NOT_FOUND_PAGE links none of the retired paths"
  fi
fi

# ---------------------------------------------------------------------------
section "(b) $VERCEL_CONFIG redirect rules"

[ -f "$VERCEL_HELPER" ]
assert_ok "$VERCEL_HELPER exists" $?

rules=''
rules_readable=1
if [ -f "$VERCEL_CONFIG" ] && [ -f "$VERCEL_HELPER" ]; then
  rules=$(python3 "$VERCEL_HELPER" list "$VERCEL_CONFIG" 2>&1)
  rules_readable=$?
fi

[ -f "$VERCEL_CONFIG" ]
assert_ok "$VERCEL_CONFIG exists" $?

if [ "$rules_readable" -eq 0 ]; then
  pass "$VERCEL_CONFIG parses with a well-formed \"redirects\" array"
else
  fail "$VERCEL_CONFIG parses with a well-formed \"redirects\" array — ${rules:-helper missing}"
  rules=''
fi

if [ -n "$rules" ]; then
  pass "$VERCEL_CONFIG declares at least one redirect"
else
  fail "$VERCEL_CONFIG declares at least one redirect"
fi

for source in "${REQUIRED_SOURCES[@]}"; do
  rule=$(printf '%s\n' "$rules" | awk -F'\t' -v s="$source" '$1 == s {print; exit}')

  if [ -n "$rule" ]; then
    pass "$VERCEL_CONFIG has a rule for source '$source'"
  else
    fail "$VERCEL_CONFIG has a rule for source '$source'"
    continue
  fi

  [ "$(printf '%s' "$rule" | cut -f3)" = 'true' ]
  assert_ok "rule '$source' is permanent (308)" $?
done

# Every destination must be a page that exists here, and must not bounce off-site or
# into itself.
while IFS=$'\t' read -r source destination _permanent; do
  [ -z "$source" ] && continue

  case "$destination" in
    /*) pass "rule '$source' destination '$destination' stays on this site" ;;
    *)  fail "rule '$source' destination '$destination' stays on this site" ;;
  esac

  if [ "$source" = "$destination" ]; then
    fail "rule '$source' does not redirect to itself"
  else
    pass "rule '$source' does not redirect to itself"
  fi

  target_file=$(file_for_url "$destination")
  if [ -n "$target_file" ] && [ -f "$REPO_ROOT/$target_file" ]; then
    pass "rule '$source' destination '$destination' resolves to $target_file"
  else
    fail "rule '$source' destination '$destination' resolves to an existing page"
  fi
done <<< "$rules"

# ---------------------------------------------------------------------------
section "(c) every retired URL is covered by a rule, in every form it was served"

urls=()
expected=()
for index in "${!retired_paths[@]}"; do
  while IFS= read -r url; do
    urls+=("$url")
    expected+=("${retired_targets[$index]}")
  done < <(url_forms_for "${retired_paths[$index]}")
done

matches=''
if [ -f "$VERCEL_CONFIG" ] && [ -f "$VERCEL_HELPER" ] && [ "$rules_readable" -eq 0 ]; then
  matches=$(python3 "$VERCEL_HELPER" match "$VERCEL_CONFIG" "${urls[@]}" 2>/dev/null)
fi

for index in "${!urls[@]}"; do
  url=${urls[$index]}
  want=${expected[$index]}
  got=$(printf '%s\n' "$matches" | awk -F'\t' -v u="$url" '$1 == u {print $2; exit}')

  if [ "$got" = "$want" ]; then
    pass "$url redirects to $want"
  else
    fail "$url redirects to $want — matched '${got:-<no rule>}'"
  fi
done

# ---------------------------------------------------------------------------
section '(d) GitHub Pages fallback stubs at every retired path'

for index in "${!retired_paths[@]}"; do
  stub=${retired_paths[$index]}
  target=${retired_targets[$index]}
  canonical="$SITE_ORIGIN$target"

  [ -f "$stub" ]
  assert_ok "$stub exists as a redirect stub" $?
  [ -f "$stub" ] || continue

  grep -qF "<meta http-equiv=\"refresh\" content=\"0; url=$target\"" "$stub"
  assert_ok "$stub refreshes to '$target'" $?

  grep -qF "<link rel=\"canonical\" href=\"$canonical\"" "$stub"
  assert_ok "$stub declares canonical '$canonical'" $?

  grep -qE '<meta name="robots" content="[^"]*noindex' "$stub"
  assert_ok "$stub is noindex" $?

  grep -qF "<a href=\"$target\"" "$stub"
  assert_ok "$stub shows a visible link to '$target'" $?

  target_file=$(file_for_url "$target")
  [ -n "$target_file" ] && [ -f "$REPO_ROOT/$target_file" ]
  assert_ok "$stub target '$target' resolves to an existing page" $?

  iconv -f UTF-8 -t UTF-8 "$stub" >/dev/null 2>&1
  assert_ok "$stub is valid UTF-8" $?

  assert_absent "$stub carries no speech-research content" "$RETIRED_CONTENT" "$stub"
done

# ---------------------------------------------------------------------------
section '(e) stubs stay out of the index and cannot hide a real page'

# scripts/test_legal_pages.sh skips the mapped paths when checking seller attribution. That
# exemption is only safe if nothing else can claim it, so: every meta-refresh file in the
# repo must be one of the mapped stubs.
while IFS= read -r page; do
  page=${page#./}
  is_mapped=1
  for stub in "${retired_paths[@]}"; do
    [ "$page" = "$stub" ] && is_mapped=0 && break
  done
  assert_ok "meta-refresh page '$page' is a mapped redirect stub" "$is_mapped"
done < <(grep -rliE '<meta[[:space:]]+http-equiv="refresh"' --include='*.html' . 2>/dev/null | sort)

for stub in "${retired_paths[@]}"; do
  if grep -qF "$SITE_ORIGIN/$stub" "$SITEMAP"; then
    fail "$SITEMAP does not list the redirect stub $stub"
  else
    pass "$SITEMAP does not list the redirect stub $stub"
  fi
done

for index in "${!urls[@]}"; do
  if grep -qF "<loc>$SITE_ORIGIN${urls[$index]}</loc>" "$SITEMAP"; then
    fail "$SITEMAP does not list the retired URL ${urls[$index]}"
  else
    pass "$SITEMAP does not list the retired URL ${urls[$index]}"
  fi
done

if grep -qF "$SITE_ORIGIN/$NOT_FOUND_PAGE" "$SITEMAP"; then
  fail "$SITEMAP does not list $NOT_FOUND_PAGE"
else
  pass "$SITEMAP does not list $NOT_FOUND_PAGE"
fi

# ---------------------------------------------------------------------------
printf '\n'
if [ "$failures" -eq 0 ]; then
  printf 'PASS: %d/%d checks passed\n' "$checks" "$checks"
  exit 0
fi
printf 'FAIL: %d of %d checks failed\n' "$failures" "$checks"
exit 1
