#!/bin/sh --
# \
exec jq -Mf --raw-output "$0" "$@"
# jq code follows:

if .tool_input.command | test("(^|[;&| ])(?<!uv )(?<!uv run )(python[23]?(\\.[0-9]+)?|pip[23]?)( |$)|\\.venv/bin/") then
  "Blocked: use uv run/uv pip, not python/pip/.venv directly.\n" | halt_error(2)
end
