#!/usr/bin/env bash

cwd=$(jq -r '.cwd')

# When changing golang code: go vet
if echo \"$CLAUDE_TOOL_INPUT\" | grep -q '\\.go\"'; then
    cd "$cwd" && go vet ./...
fi
