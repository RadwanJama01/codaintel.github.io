#!/usr/bin/env python3
"""Read the "redirects" block of vercel.json for scripts/test_redirects.sh.

Bash cannot parse JSON safely, and the test must not need jq, so this is the one helper
the redirect contract test leans on. It stays deliberately small and makes no decisions:
it reports what the config says and whether a URL would match, and the bash script does
all of the asserting.

Subcommands:

  list  <config>             one "source<TAB>destination<TAB>permanent" line per rule, in
                             config order. "permanent" is printed as JSON (true/false/null)
                             so a missing key is distinguishable from an explicit false.

  match <config> <url>...    one "url<TAB>destination" line per argument, using the first
                             rule that matches; destination is "-" when no rule matches.

`match` re-implements the subset of Vercel's path-to-regexp syntax this site uses: literal
segments, plus a trailing ":name*" wildcard standing for zero or more segments. A trailing
slash is optional on every match, which is how Vercel treats it. Anything outside that
subset is rejected loudly rather than guessed at, so an unsupported source in vercel.json
fails the test instead of silently matching nothing.

Exit status: 0 on success, 2 on a malformed config or bad usage.
"""

import json
import re
import sys

WILDCARD_SEGMENT = re.compile(r':[A-Za-z0-9_]+\*$')


def load_rules(config_path):
    """Return the redirect rules of a vercel.json, raising ValueError if malformed."""
    with open(config_path, encoding='utf-8') as handle:
        config = json.load(handle)

    if not isinstance(config, dict):
        raise ValueError('vercel.json must contain a JSON object')

    rules = config.get('redirects', [])
    if not isinstance(rules, list):
        raise ValueError('"redirects" must be an array')

    for index, rule in enumerate(rules):
        if not isinstance(rule, dict):
            raise ValueError(f'redirects[{index}] must be an object')
        for key in ('source', 'destination'):
            if not isinstance(rule.get(key), str) or not rule[key]:
                raise ValueError(f'redirects[{index}] needs a non-empty string "{key}"')
        if not rule['source'].startswith('/'):
            raise ValueError(f'redirects[{index}] source must start with "/"')

    return rules


def pattern_for(source):
    """Translate a redirect source into an anchored regex."""
    segments = [segment for segment in source.split('/') if segment]
    pieces = []

    for index, segment in enumerate(segments):
        if WILDCARD_SEGMENT.fullmatch(segment) is None:
            if ':' in segment or '*' in segment or '(' in segment:
                raise ValueError(
                    f'{source!r}: unsupported pattern segment {segment!r}; this helper '
                    'handles literal segments and a trailing ":name*" only'
                )
            pieces.append('/' + re.escape(segment))
            continue
        if index != len(segments) - 1:
            raise ValueError(f'{source!r}: ":name*" is only supported as the last segment')
        pieces.append('(?:/.*)?')

    return re.compile('^' + (''.join(pieces) or '/') + '/?$')


def destination_for(rules, url):
    """Destination of the first rule matching url, or "-" when none does."""
    for rule in rules:
        if pattern_for(rule['source']).match(url):
            return rule['destination']
    return '-'


def main(argv):
    if len(argv) < 3:
        print(__doc__, file=sys.stderr)
        return 2

    command, config_path, arguments = argv[1], argv[2], argv[3:]

    try:
        rules = load_rules(config_path)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f'{config_path}: {error}', file=sys.stderr)
        return 2

    try:
        if command == 'list':
            for rule in rules:
                permanent = json.dumps(rule.get('permanent'))
                print(f"{rule['source']}\t{rule['destination']}\t{permanent}")
            return 0

        if command == 'match':
            for url in arguments:
                print(f'{url}\t{destination_for(rules, url)}')
            return 0
    except ValueError as error:
        print(f'{config_path}: {error}', file=sys.stderr)
        return 2

    print(f'unknown subcommand: {command}', file=sys.stderr)
    return 2


if __name__ == '__main__':
    sys.exit(main(sys.argv))
