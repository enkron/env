#!/usr/bin/env bash
# Claude Code status line.
# Reads session JSON on stdin and prints one line with model, cwd, git branch,
# context-window usage (with threshold colors), session cost and duration,
# lines changed, rate limits, prompt-cache health, and reasoning effort.
# Field reference: https://code.claude.com/docs/en/statusline

input=$(cat)

RED=$'\033[31m'
GREEN=$'\033[32m'
YELLOW=$'\033[33m'
BLUE=$'\033[34m'
MAGENTA=$'\033[35m'
CYAN=$'\033[36m'
GREY=$'\033[90m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

MODEL=$(jq -r    '.model.display_name // "claude"'                <<<"$input")
DIR=$(jq -r      '.workspace.current_dir // ""'                   <<<"$input")
PCT=$(jq -r      '.context_window.used_percentage // 0'           <<<"$input" | cut -d. -f1)
CTX_SIZE=$(jq -r '.context_window.context_window_size // 200000'  <<<"$input")
# Input-only sum matches how used_percentage is computed (see docs).
CTX_USED=$(jq -r '(.context_window.current_usage // {})
                  | ((.input_tokens // 0)
                   + (.cache_creation_input_tokens // 0)
                   + (.cache_read_input_tokens // 0))' <<<"$input")
COST=$(jq -r     '.cost.total_cost_usd // 0'                      <<<"$input")
FIVE_H=$(jq -r   '.rate_limits.five_hour.used_percentage // empty' <<<"$input")
WEEK=$(jq -r     '.rate_limits.seven_day.used_percentage // empty' <<<"$input")
STYLE=$(jq -r    '.output_style.name // empty'                    <<<"$input")
WORKTREE=$(jq -r '.workspace.git_worktree // empty'               <<<"$input")
DURATION_MS=$(jq -r    '.cost.total_duration_ms // 0'             <<<"$input")
LINES_ADDED=$(jq -r    '.cost.total_lines_added // 0'             <<<"$input")
LINES_REMOVED=$(jq -r  '.cost.total_lines_removed // 0'           <<<"$input")
CACHE_WARM=$(jq -r     '.prompt_cache.warm // empty'              <<<"$input")
CACHE_HIT_RAW=$(jq -r  '.prompt_cache.hit_ratio // empty'         <<<"$input")
EFFORT=$(jq -r         '.effort.level // empty'                   <<<"$input")

DIR_LABEL="${DIR##*/}"
BRANCH=$(git -C "$DIR" branch --show-current 2>/dev/null || true)

if   [ "$PCT" -ge 90 ]; then BAR_COLOR="$RED"
elif [ "$PCT" -ge 70 ]; then BAR_COLOR="$YELLOW"
else                         BAR_COLOR="$GREEN"
fi

BAR_WIDTH=10
FILLED=$((PCT * BAR_WIDTH / 100))
(( FILLED > BAR_WIDTH )) && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
(( FILLED > 0 )) && { printf -v F "%${FILLED}s" ''; BAR="${F// /▓}"; }
(( EMPTY  > 0 )) && { printf -v E "%${EMPTY}s"  ''; BAR="${BAR}${E// /░}"; }

human_tokens() {
    awk -v n="$1" 'BEGIN {
        if (n >= 1000000)      { v = n/1000000; printf (v == int(v) ? "%dM" : "%.1fM"), v }
        else if (n >= 1000)    { printf "%dk", n/1000 }
        else                   { printf "%d",  n }
    }'
}
CTX_USED_H=$(human_tokens "$CTX_USED")
CTX_SIZE_H=$(human_tokens "$CTX_SIZE")

COST_FMT=$(printf '$%.2f' "$COST")

DURATION_SEC=$((DURATION_MS / 1000))
DURATION_FMT=$(printf '%dm%02ds' $((DURATION_SEC / 60)) $((DURATION_SEC % 60)))

LIMITS=""
[ -n "$FIVE_H" ] && LIMITS=$(printf '5h:%.0f%%' "$FIVE_H")
[ -n "$WEEK"   ] && LIMITS="${LIMITS:+$LIMITS }$(printf '7d:%.0f%%' "$WEEK")"

STYLE_TAG=""
[ -n "$STYLE" ] && [ "$STYLE" != "default" ] && STYLE_TAG=" ${MAGENTA}${STYLE}${RESET}"

WT_TAG=""
[ -n "$WORKTREE" ] && WT_TAG=" ${GREY}wt:${RESET}${MAGENTA}${WORKTREE}${RESET}"

LINES_TAG=""
if [ "$LINES_ADDED" -gt 0 ] || [ "$LINES_REMOVED" -gt 0 ]; then
    LINES_TAG=" ${GREEN}+${LINES_ADDED}${RESET}${GREY}/${RESET}${RED}-${LINES_REMOVED}${RESET}"
fi

CACHE_TAG=""
if [ -n "$CACHE_HIT_RAW" ]; then
    CACHE_HIT_PCT=$(awk -v r="$CACHE_HIT_RAW" 'BEGIN { printf "%.0f", r * 100 }')
    CACHE_COLOR="$YELLOW"
    [ "$CACHE_WARM" = "true" ] && CACHE_COLOR="$GREEN"
    CACHE_TAG=" ${CACHE_COLOR}cache:${CACHE_HIT_PCT}%${RESET}"
fi

EFFORT_TAG=""
[ -n "$EFFORT" ] && EFFORT_TAG=" ${MAGENTA}${EFFORT}${RESET}"

LINE="${RED}»${RESET} ${CYAN}${MODEL}${RESET} ${BOLD}${DIR_LABEL}${RESET}"
[ -n "$BRANCH" ] && LINE="${LINE} ${GREY}(${RESET}${BLUE}${BRANCH}${RESET}${GREY})${RESET}"
LINE="${LINE}${WT_TAG} ${BAR_COLOR}${BAR}${RESET} ${PCT}% ${GREY}${CTX_USED_H}/${CTX_SIZE_H}${RESET}"
LINE="${LINE} ${YELLOW}${COST_FMT}${RESET} ${GREY}${DURATION_FMT}${RESET}${LINES_TAG}"
[ -n "$LIMITS" ] && LINE="${LINE} ${GREY}${LIMITS}${RESET}"
LINE="${LINE}${CACHE_TAG}${STYLE_TAG}${EFFORT_TAG}"

printf '%b\n' "$LINE"
