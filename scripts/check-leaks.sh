#!/usr/bin/env bash
# Stops things that must not be published: secrets, private addresses and
# whatever the maintainer lists as their own (domains, SSIDs, ...).
#
#   scripts/check-leaks.sh --staged   what is about to be committed (the pre-commit hook)
#   scripts/check-leaks.sh --all      every tracked file (CI)
#
# Two kinds of checks:
# - generic, in this file: vault data, private keys, AWS key ids, passwords
#   in URLs, literal passwords/tokens, private IPv4 addresses other than the
#   example range 192.168.1.0/24
# - private, from a file that is NOT in this repository (it would itself
#   publish what it lists): one extended regex per line, # for comments.
#   $PI_SETUP_LEAK_PATTERNS, else ../pi-setup/pub-leak-patterns.txt. The
#   commit's author and committer identity are checked against it too.
#
# A line that has to stay as it is can end with "leak-ok" (in a comment).
set -u

mode=${1:---staged}
root=$(git rev-parse --show-toplevel) || exit 2
cd "$root" || exit 2
patterns=${PI_SETUP_LEAK_PATTERNS:-$root/../pi-setup/pub-leak-patterns.txt}

# name|regex
generic=(
  'Ansible Vault data|\$ANSIBLE_VAULT|!vault'
  'private key|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'AWS access key id|(AKIA|ASIA)[0-9A-Z]{16}'
  'password in a URL|[a-z][a-z0-9+.-]*://[^/[:space:]:@]+:[^/[:space:]@]+@'
  'literal secret|^[[:space:]-]*[A-Za-z0-9_]*(password|passwd|secret|token|psk|api_key)[A-Za-z0-9_]*:[[:space:]]*[^[:space:]#"'"'"'{|>]'
  'literal secret|^[[:space:]-]*[A-Za-z0-9_]*(password|passwd|secret|token|psk|api_key)[A-Za-z0-9_]*:[[:space:]]*["'"'"'][^"'"'"'{]'
  'private IPv4 address|(^|[^0-9.])(10\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])|192\.168\.([02-9]|[1-9][0-9]+))\.[0-9]{1,3}\.?[0-9]*'
)

private=()
if [ -f "$patterns" ]; then
  while IFS= read -r p; do
    case "$p" in ''|'#'*) continue ;; esac
    private+=("private pattern|$p")
  done < "$patterns"
else
  echo "check-leaks: no private pattern file ($patterns) - generic checks only" >&2
fi

case "$mode" in
  --staged) files=$(git diff --cached --name-only --diff-filter=ACMR) ;;
  --all) files=$(git ls-files) ;;
  *) echo "usage: $0 [--staged|--all]" >&2; exit 2 ;;
esac

# The checker and its own documentation name the patterns on purpose
skip_re='^(scripts/check-leaks\.sh|LICENSE)$'

content() {
  if [ "$mode" = --staged ]; then git show ":$1" 2>/dev/null; else cat -- "$1"; fi
}

found=0
report() {   # name file lines...
  local name=$1 file=$2
  shift 2
  # Line numbers and the key only: never print what was found
  local IFS=,
  echo "check-leaks: $name in $file (line $*)" >&2
  found=1
}

while IFS= read -r f; do
  [ -n "$f" ] || continue
  [[ $f =~ $skip_re ]] && continue
  # Binary files are not looked into
  if ! content "$f" | grep -Iq . 2>/dev/null; then continue; fi
  for entry in "${generic[@]}" "${private[@]}"; do
    name=${entry%%|*}
    re=${entry#*|}
    lines=$(content "$f" | grep -nEi -- "$re" | grep -v 'leak-ok' | cut -d: -f1 | tr '\n' ' ')
    [ -n "$lines" ] && report "$name" "$f" $lines
  done
done <<< "$files"

# Whoever the commit is recorded as is published with it
if [ "$mode" = --staged ] && [ ${#private[@]} -gt 0 ]; then
  for who in GIT_AUTHOR_IDENT GIT_COMMITTER_IDENT; do
    ident=$(git var "$who" 2>/dev/null | sed -E 's/ [0-9]+ [+-][0-9]{4}$//')
    for entry in "${private[@]}"; do
      if printf '%s\n' "$ident" | grep -qEi -- "${entry#*|}"; then
        echo "check-leaks: the commit's ${who%_IDENT} (name or e-mail) matches a private pattern - set a public one with git config user.email" >&2
        found=1
      fi
    done
  done
fi

if [ $found -ne 0 ]; then
  echo "check-leaks: not committed. Fix the lines above, or end a line that is fine with a \"leak-ok\" comment." >&2
  exit 1
fi
exit 0
