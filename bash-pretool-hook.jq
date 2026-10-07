#!/bin/sh --
# \
exec jq -Mf --raw-output "$0" "$@"
# jq code follows:

if .tool_input.command | test("(^|[;&| ])(?<!uv )(?<!uv run )(python[23]?(\\.[0-9]+)?|pip[23]?)( |$)|\\.venv/bin/") then
  "Blocked: use uv run/uv pip, not python/pip/.venv directly.\n" | halt_error(2)
end
|
def add_re: "git( +-C +[^ ;&|]+)? +add( |$)";

if .tool_input.command | test("(xargs|\\sfor\\s|^for\\s|while\\s).*" + add_re) then
  "Blocked: git add file list must not come from xargs/loops; name each path explicitly.\n" | halt_error(2)
end
|
if [.tool_input.command | match(add_re + "[^;&]*"; "g").string]
   | any(test("\\$\\(|`|(^|[^|])\\|([^|]|$)|\\*|\\s--(all|update|patch)(\\s|$)|\\s-[a-zA-Z]*[Aup][a-zA-Z]*(\\s|$)|\\s\\.(\\s|$)")) then
  "Blocked: name each path explicitly (git add path/a path/b), only files you changed for this task. No command substitution, pipes, globs, -A/-u/-p, or bare dot.\n" | halt_error(2)
end
