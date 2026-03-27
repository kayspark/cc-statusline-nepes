#!/bin/bash
# Claude Code status line — nepes colorscheme
# Input: JSON via stdin

input=$(cat)

# --- fields from JSON ---
cwd=$(echo "$input"      | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input"    | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
cost=$(echo "$input"     | jq -r '.cost.total_cost_usd // empty')
vim_mode=$(echo "$input" | jq -r '.vim.mode // empty')

# --- nepes dark palette (24-bit truecolor) ---
c_blue="\033[38;2;92;140;255m"      # #5C8CFF sapphire
c_green="\033[38;2;61;220;132m"     # #3DDC84 mint
c_orange="\033[38;2;254;164;19m"    # #FEA413
c_red="\033[38;2;255;92;92m"        # #FF5C5C
c_cyan="\033[38;2;58;155;165m"      # #3A9BA5
c_magenta="\033[38;2;162;116;195m"  # #A274C3
c_yellow="\033[38;2;232;197;90m"    # #E8C55A
c_dim="\033[38;2;138;145;153m"      # #8A9199 slate-brown
c_fg="\033[38;2;220;216;212m"       # #DCD8D4
c_reset="\033[0m"

# --- display path: shorten $HOME to ~ ---
case "$cwd" in
    "$HOME"*) display_path="~${cwd#"$HOME"}" ;;
    *) display_path="$cwd" ;;
esac

# --- git branch + worktree ---
branch=""
worktree=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$(git -C "$cwd" -c core.hooksPath=/dev/null symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$cwd" rev-parse --short HEAD 2>/dev/null)
    gitdir=$(git -C "$cwd" rev-parse --git-dir 2>/dev/null)
    commondir=$(git -C "$cwd" rev-parse --git-common-dir 2>/dev/null)
    if [ -n "$gitdir" ] && [ -n "$commondir" ] && [ "$gitdir" != "$commondir" ]; then
        worktree=" wt"
    fi
fi

# --- context remaining (color by threshold) ---
ctx_part=""
if [ -n "$remaining" ]; then
    pct=$(printf "%.0f" "$remaining")
    if [ "$pct" -le 10 ]; then
        ctx_part=" ${c_red}${pct}%${c_reset}"
    elif [ "$pct" -le 30 ]; then
        ctx_part=" ${c_yellow}${pct}%${c_reset}"
    else
        ctx_part=" ${c_green}${pct}%${c_reset}"
    fi
fi

# --- cost ---
cost_part=""
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
    cost_part=" ${c_dim}\$${cost}${c_reset}"
fi

# --- vim mode ---
vim_part=""
if [ -n "$vim_mode" ]; then
    if [ "$vim_mode" = "NORMAL" ]; then
        vim_part="${c_blue}N${c_reset} "
    else
        vim_part="${c_green}I${c_reset} "
    fi
fi

# --- assemble ---
out="${vim_part}"
out="${out}${c_cyan}${display_path}${c_reset}"
if [ -n "$branch" ]; then
    out="${out} ${c_magenta}${branch}${worktree}${c_reset}"
fi
out="${out} ${c_dim}[${c_reset}${c_orange}${model}${c_reset}${c_dim}]${c_reset}"
out="${out}${ctx_part}${cost_part}"

printf "%b" "$out"
