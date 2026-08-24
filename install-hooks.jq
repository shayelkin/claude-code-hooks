#!/bin/sh --
# \
exec jq -Mf --arg dir "$(cd "$(dirname "$0")" && pwd)" "$0" "$@"
# jq code follows:

def hasCommand(cmd): any(.[]?; .type == "command" and .command == cmd);

def addHookGroup(event; matcher; cmd):
  (.hooks[event] // []) as $groups |
  ($groups | map(select(.matcher == matcher))) as $matching |
  if ($matching | length) == 0 then
    .hooks[event] = ($groups + [{matcher: matcher, hooks: [{type:"command", command: cmd}]}])
  elif ($matching[0].hooks | hasCommand(cmd)) then
    .
  else
    .hooks[event] = ($groups | map(
      if .matcher == matcher then .hooks += [{type:"command", command: cmd}] else . end
    ))
  end;

addHookGroup("PostToolUse"; "Edit|MutliEdit|Write"; "\($dir)/edit-hook.sh")
| addHookGroup("PreToolUse"; "Bash"; "\($dir)/bash-pretool-hook.jq")
| .statusLine = {type: "command", command: "\($dir)/statusline.jq"}
