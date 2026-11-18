#!/bin/sh
set -eu

hook="$(cd "$(dirname "$0")" && pwd)/../bash-pretool-hook.jq"
failures=0
nl='
'

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

decision() {
  extra=${2-}
  [ -n "$extra" ] || extra='{}'
  jq -cn --arg c "$1" --argjson x "$extra" '{tool_input: ({command: $c} + $x)}' | "$hook" 2>/dev/null |
    jq -r '.hookSpecificOutput.permissionDecision // "none"'
}

expect() {
  got=$(decision "$2" "${3-}")
  [ "$got" = "$1" ] || fail "expected [$1] got [$got] for [$2] ${3-}"
}

for sub in checks diff view; do
  expect allow "gh pr $sub"
  expect allow "gh pr $sub 123"
  expect allow "gh pr $sub 123 --json title,body"
  expect allow "gh -R owner/repo pr $sub 1"
  expect allow "gh --repo owner/repo pr $sub 1"
  expect allow "gh -R github.example.com/owner/repo pr $sub 1"
  expect allow "gh -R my-org/my.repo_2 pr $sub 1"
  expect allow "  gh pr $sub 1  "
  expect allow "gh pr $sub --jq \"a b\""
  expect allow "gh pr $sub 1" '{"dangerouslyDisableSandbox": false}'
  expect ask "gh pr $sub 1" '{"dangerouslyDisableSandbox": true}'
  expect ask "gh pr $sub 1" '{"dangerouslyDisableSandbox": "true"}'
  expect ask "gh pr ${sub}x"
  expect ask "GH pr $sub 1"
  expect ask "gh pr $sub 1; rm -rf x"
  expect ask "gh pr $sub 1 && rm -rf x"
  expect ask "gh pr $sub 1 | sh"
  expect ask "gh pr $sub \$(rm x)"
  expect ask "gh pr $sub \`rm x\`"
  expect ask "gh pr $sub 1 > out"
  expect ask "gh pr $sub 1${nl}rm x"
  expect ask "rm x${nl}gh pr $sub 1"
  expect ask "FOO=1 gh pr $sub 1"
  expect ask "env gh pr $sub 1"
  expect ask "sh -c 'gh pr $sub 1'"
  expect ask "cd x && gh pr $sub 1"
  expect ask "gh pr $sub 1 \\${nl}rm x"
  expect ask "gh -R owner pr $sub 1"
  expect ask "gh -R a/b/c/d pr $sub 1"
  expect ask "gh -R 'owner/repo' pr $sub 1"
  expect ask "gh -R ~/repo pr $sub 1"
  expect ask "gh -R https://github.com/o/r pr $sub 1"
done

for sub in checkout edit merge close comment ready review create reopen lock unlock update-branch revert; do
  expect ask "gh pr $sub"
  expect ask "gh pr $sub 1"
  expect ask "gh -R owner/repo pr $sub 1"
  expect ask "gh pr view 1; gh pr $sub 1"
  expect ask "gh pr view 1 && gh pr $sub 1"
  expect ask "sh -c 'gh pr $sub 1'"
  expect ask "gh pr view 1${nl}gh pr $sub 1"
done

expect ask "gh -R 'https://github.com/o/r# pr view x' pr merge 1 --squash"
expect ask "gh --repo \"https://github.com/o/r?a= pr diff x\" pr close 1"
expect ask "gh -R {o/r,pr,merge,--squash,--body} pr view"
expect ask "gh -R * pr view"
expect ask "gh -R o/r? pr view"
expect ask "gh -R o/[r] pr view"
expect ask "GH pr merge 1 --squash"
expect ask "Gh pr merge 1"
expect ask "/opt/homebrew/bin/GH pr merge 1"
expect ask "=gh pr merge 1"
expect ask "g''h pr merge 1"
expect ask "g\"\"h pr merge 1"
expect ask 'g\h pr merge 1'
expect ask "g\\${nl}h pr merge 1"
expect ask "gh p''r merge 1"
expect ask 'gh p\r merge 1'
expect ask "gh -R 'https://github.com/o/r#;' pr merge 1 --squash"
expect ask "gh -R 'https://github.com/o/r#|' pr merge 1 --squash"
expect ask "gh -R 'https://github.com/o/r#&' pr merge 1 --squash"
expect ask "echo pr merge 1 --squash | xargs gh"
expect ask 'x=pr; gh $x merge 1'
expect ask 'gh $(printf p)r merge 1'
expect ask "gh api -X PUT repos/o/r/pulls/1/merge"
expect ask "gh alias set mg 'p''r merge'"
expect ask "gh mg 1"
expect ask "gh co 1"
expect ask "gh pr edit 1 --body-file ~/.ssh/id_ed25519"
expect ask "gh pr checkout 1 --force"
expect ask "gh pr"
expect ask "gh pr "
expect ask "gh -R owner/repo pr"
expect ask "gh --repo=owner/repo pr view 1"
expect ask "gh -R 'a b/c' pr view 1"
expect ask "gh -R \$(x) pr view 1"
expect ask "gh issue list"
expect none "ls"
expect none "git status"
expect none "echo hi > ghost"
expect none "cat high.txt"
expect "" "python3 x.py"
expect "" "git add ."

[ "$failures" -eq 0 ] || exit 1
echo PASS
