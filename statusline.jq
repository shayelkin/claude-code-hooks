#!/bin/sh --
# \
exec jq -Mf --raw-output --argjson cols "${COLUMNS:-0}" "$0" "$@"
# jq code follows:

def trim_left(s; avail):
  if avail == null or (s | length) <= avail then s
  elif avail <= 1 then "…"
  else "…" + s[-(avail - 1):]
  end;

def rep(s; n): if n <= 0 then "" else s * n end;

# 12-char bar with braille dot (0-8) sub-cell resolution for input percent 0..100.
def bar(p):
  (p * 12 / 100) as $scaled |
    ($scaled | floor) as $full |
      ((($scaled - $full) * 8) | floor) as $partial |
        (12 - $full - (if $partial > 0 then 1 else 0 end)) as $empty |
          (rep("⣿"; $full) +
            ["", "⡀", "⣀", "⣄", "⣤", "⣦", "⣶", "⣷"][$partial] +
            rep(" "; $empty)) as $b |
          if p > 90 then "[31m" + $b + "[0m" else $b end;

(.model.display_name
  + " · Ctx: \(bar(if .context_window.current_usage then
              .context_window.current_usage as $usage |
                (.context_window.current_usage.input_tokens +
                  .context_window.current_usage.cache_creation_input_tokens +
                  .context_window.current_usage.cache_read_input_tokens) as $tokens |
                  $tokens * 100 / .context_window.context_window_size
            else
              0
            end))"
  + if .rate_limits.five_hour then
      " · 5h: \(bar(.rate_limits.five_hour.used_percentage))"
    else
      ""
    end
  + if .rate_limits.seven_day then
      " · 7d: \(bar(.rate_limits.seven_day.used_percentage))"
    else
      ""
    end
  + if .cost.total_cost_usd then
      " · $\(.cost.total_cost_usd * 1000 | round / 1000)"
    else
      ""
    end
  + " · ") as $pre |
  (if $cols > 0 then
      $cols - 4 - ($pre | gsub("\u001b\\[[0-9;]*m"; "") | length)
   else
       null
   end) as $avail |
   $pre + (.workspace.current_dir | tostring | trim_left(.; $avail))
