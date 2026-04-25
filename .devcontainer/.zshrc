
# -----------------------------
# コメント文字でエラーを出さずに履歴に残す
# -----------------------------
setopt interactivecomments

# -----------------------------
# 日本語IMEの設定 (ibus)
# -----------------------------
export GTK_IM_MODULE=ibus
export QT_IM_MODULE=ibus
export XMODIFIERS=@im=ibus

# -----------------------------
# 補完（zsh-completions）
# -----------------------------
fpath=(~/.zsh/plugins/zsh-completions/src $fpath)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
autoload -Uz compinit
compinit

# -----------------------------
# Tab 補完の表示・挙動
# -----------------------------
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _approximate _ignored
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# -----------------------------
# プラグイン読み込み
# ※ syntax-highlighting は必ず最後
# -----------------------------
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# -----------------------------
# fzf
# -----------------------------
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# -----------------------------
# zoxide
# -----------------------------
eval "$(zoxide init zsh)"

# -----------------------------
# 便利系オプション
# -----------------------------
setopt auto_cd
setopt auto_pushd
setopt correct
setopt list_packed
setopt no_beep
export LESS="$LESS -R -Q"

# -----------------------------
# 履歴設定
# -----------------------------
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt share_history
setopt hist_ignore_dups
setopt hist_find_no_dups

# プロジェクト単位の履歴切り替え (ファイルが存在する場合のみ)
_update_project_history() {
    local target=".zsh_history_local"
    local dir="$PWD"
    while [[ "$dir" != "/" && -n "$dir" ]]; do
        if [[ -f "$dir/$target" ]]; then
            fc -P 2>/dev/null
            fc -p "$dir/$target"
            return
        fi
        dir="${dir%/*}"
        [[ -z "$dir" ]] && dir="/"
    done
    fc -P 2>/dev/null
}

# 履歴を即保存
setopt inc_append_history

# 履歴ファイルに書き出す際、古い重複を削除して保存
setopt hist_save_no_dups

# 履歴の重複を完全排除
setopt hist_ignore_all_dups

# 余分な空白を削除して記録
setopt hist_reduce_blanks

# スペース始まりは履歴保存しない
setopt hist_ignore_space

# -----------------------------
# 存在しないコマンド（終了ステータス127）を履歴に残さない
# -----------------------------
zshaddhistory() {
    # 127 は "command not found" の標準ステータス
    if [[ $? -eq 127 ]]; then
        return 1 # 履歴に保存しない
    fi
    return 0     # それ以外（成功および127以外のエラー）は保存する
}

# -----------------------------
# 履歴 prefix 検索（入力文字に一致する履歴を↑↓で検索）
# -----------------------------
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search

zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

# -----------------------------
# エイリアス
# -----------------------------
alias ls='ls --color=auto'
#alias ls='ls -G'    #macはこっち

alias ll='ls -alF'
alias df='df -h'
alias cp='cp -i'
alias mv='mv -i'

# -----------------------------
# lf 終了時にディレクトリ移動
# -----------------------------
lfcd() {
  tmp="$(mktemp)"
  command lf -last-dir-path="$tmp" "$@"
  if [ -f "$tmp" ]; then
    dir="$(cat "$tmp")"
    rm -f "$tmp"
    [ -d "$dir" ] && [ "$dir" != "$PWD" ] && cd "$dir"
  fi
}
alias lf="lfcd"

# -----------------------------
# プロンプト
# -----------------------------
autoload -Uz colors && colors
PROMPT="%{${fg[green]}%}%n@%m:%{${fg[blue]}%}%~%{${reset_color}%}%# "
