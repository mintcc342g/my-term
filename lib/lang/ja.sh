#!/bin/bash
# lib/lang/ja.sh — 日本語メッセージカタログ.
# en.sh / ko.sh と同じキー/関数の集合を定義すること (検証: lib/lang パリティチェック).
# 色は ui.sh の UI_* のみ使用 (source 時点で定義済み).
# 作成基準: 翻訳調・AI っぽさを避け、自然な日本語で書く.

# ── 共通 ────────────────────────────────────────────────────────
L_YES="はい"
L_NO="いいえ"
L_NO_SKIP="いいえ (スキップ)"
L_NO_EXIT="いいえ (終了)"
L_NO_DONE="いいえ (完了)"
L_DONE_ITEM="✓ 完了 (次のステップへ)"
L_UI_HINT="↑↓ 移動 │ Enter 選択"
L_EXIT_ABORTED="インストールを中断して終了します。"

# ── メインメニュー (install.sh) ─────────────────────────────────
L_MENU_TITLE="my-term インストーラー"
L_MENU_INSTALL="インストール"
L_MENU_UPDATE="アップデート"
L_MENU_HUD_CONFIG="HUD 設定"
L_MENU_DELETE="削除 (my-term の設定を削除)"
L_MENU_EXIT="✗ 終了"

# ── ステップのラベル (install.sh ui_confirm_run / ai-tools) ─────
L_STEP_CONVENIENCE="便利ツール (CLI, macOS アプリ, DevOps)"
L_STEP_GIT_SSH="Git SSH キー (マルチアカウント)"
L_STEP_OMZ="Oh-my-zsh + zsh プラグイン"
L_STEP_THEME="シェルテーマ (newro)"
L_STEP_ASDF="asdf + 言語"
L_STEP_PYENV="pyenv"
L_STEP_AI="AI ツール (Claude, OpenCode, Codex)"
L_STEP_OBSIDIAN="Obsidian + vault ツール"

# ── 完了バナー (ui.sh ui_print_completion) ──────────────────────
L_DONE_INSTALL="インストール完了！"
L_DONE_UPDATE="アップデート完了！"
L_DONE_HUDCFG="HUD の設定が完了しました。"
L_DONE_DELETE="my-term の設定を削除しました。"
L_DONE_DELETE_HINT="もう一度設定するには Install を実行してください。"
L_DELETE_CANCELLED="削除をキャンセルしました。"
L_DONE_RESTART_CC="反映するには Claude Code のセッションを再起動してください。"

# 複数色が混ざった案内 (literal ${HOME} は \$ で維持).
lang_done_source_zshrc() {
  printf "  ${UI_YELLOW_BOLD}'source \${HOME}/.zshrc'${UI_RESET} を実行するか、シェルを ${UI_YELLOW_BOLD}再起動${UI_RESET}してください。\n\n"
}

# ── 削除 (ai-tools.sh delete_my_claude) ─────────────────────────
L_DELETE_CONFIRM_TITLE="my-term の設定を削除しますか？ 元に戻せません。"

# 何を削除して何を残すかを示す確認案内. メニューノートとして出力される.
lang_delete_plan() {
  local s="\n"
  s+="   ${UI_RED_BOLD}削除するもの:${UI_RESET}\n"
  s+="     ~/.claude/my-hud, my-hooks, my-collab, my-wiki ${UI_DIM}(自分で変えた HUD テーマ・collab 設定を含む)${UI_RESET}\n"
  s+="     ~/.zshrc, ~/.zprofile, ~/.ssh/config の #-- my-term: ブロック\n"
  s+="     ~/.claude/CLAUDE.md の OPTIONAL 指示ブロック\n"
  s+="     ~/.claude/settings.json の statusLine + my-term フック\n"
  s+="     ~/.claude.json の codex MCP エントリ\n"
  s+="\n"
  s+="   ${UI_GREEN_BOLD}残すもの:${UI_RESET}\n"
  s+="     ~/.claude/memory ${UI_DIM}(保存しておいた記憶)${UI_RESET}\n"
  s+="     SSH キーファイル ~/.ssh/id_* ${UI_DIM}(config ブロックだけ削除)${UI_RESET}\n"
  s+="     settings.json の permissions.deny セキュリティルール\n"
  s+="     brew パッケージ, oh-my-zsh, asdf/pyenv, CLI, IDE, Obsidian\n"
  printf '%s' "$s"
}

# ── 共通エラー案内 ──────────────────────────────────────────────
L_ERR_NO_BREW="Homebrew が見つかりません。先に便利ツールをインストールしてください。"
L_ERR_NO_OMZ="oh-my-zsh が見つかりません。先に oh-my-zsh をインストールしてください。"

# ── 必須ツール (required.sh) ────────────────────────────────────
L_REQ_TITLE="必須ツールをインストールしますか？ (Homebrew + jq)"
L_REQ_NOTE="⚠ 必須項目です — 断るとインストーラーがすぐに終了します。"
L_REQ_ALREADY="必須ツール(Homebrew・jq)はすでに入っているので、このステップは飛ばします。"

# ── IDE (ides.sh) ───────────────────────────────────────────────
L_IDE_MENU_TITLE="IDE — インストールする項目を選択"
L_IDE_CMD_HEADER="Antigravity コマンドの設定"
L_IDE_CMD_PROMPT="antigravity の短い起動コマンド名を入力してください (デフォルト: agy)"
L_IDE_INVALID_NAME="名前が正しくありません。デフォルトの agy を使います。"
L_IDE_BINDIR_NOTFOUND="Antigravity の bin ディレクトリが見つかりません。IDE を一度起動してから、このステップをやり直してください。"
L_PROMPT_NAME="名前: "
L_IDE_MORE_TITLE="IDE インストール完了 — 続けますか？"
L_IDE_ANOTHER="別の IDE をインストール"
L_IDE_PROCEED_FMT="次のステップへ (%s)"

# ── asdf (asdf-langs.sh) ────────────────────────────────────────
L_ASDF_MENU_TITLE="asdf — 設定する言語を選択"
# 言語選択メニューに常時表示される赤い警告 (インストール後 .zprofile のコメント解除).
lang_asdf_note() {
  printf '%s' " ${UI_YELLOW_BOLD}[警告]${UI_RESET} ${UI_RED_BOLD}言語をインストールしたあと${UI_RESET}、.zprofile でその言語の環境設定の${UI_RED_BOLD}コメントを外して${UI_RESET}ください。"
}

# ── Git SSH (git-ssh.sh) ────────────────────────────────────────
L_GITSSH_INTRO_TITLE="Git SSH — マルチアカウント設定"
L_GITSSH_CASEA_TITLE="すでに使用中の default キーがあります"
L_GITSSH_CASEB_TITLE="既存の default キーを検出しました — 続けますか？"
L_GITSSH_ANOTHER_TITLE="キーをもう 1 つ作りますか？"
L_GITSSH_ENTER_NEXT="Enter で次のステップへ…"
L_GITSSH_ENTER_DONE="登録を終えたら Enter…"
L_GITSSH_NICK_LABEL="ニックネーム: "
L_GITSSH_INVALID_NICK="ニックネームが正しくありません (a-z, 0-9, _, - のみ)。"
L_GITSSH_KEY_EXISTS="%s にすでにキーがあります。別のニックネームを入力してください。"
L_GITSSH_EMAIL_LABEL="email (キーのコメント): "
L_GITSSH_EMPTY_EMAIL="email を入力してください。"
L_GITSSH_PUBKEY_LABEL="公開鍵:"
L_GITSSH_REGISTER_GH="GitHub Settings → SSH keys に登録してください:"
L_GITSSH_DIR_LABEL="ディレクトリ: "
L_GITSSH_DIR_REQUIRED="ディレクトリは必須です。"
L_GITSSH_VERIFY="検証: cd <登録したディレクトリ> && ssh -T git@github.com"

# 導入の案内 (UI_MENU_NOTE; echo -e 用の literal \n).
lang_gitssh_intro() {
  local s=""
  s+=" ─────────────────────\n"
  s+=" キーを 2 つ以上作るなら、作る前にどの\n"
  s+=" ディレクトリでどのキーを使うか決めておいてください。\n"
  s+="\n"
  s+="   例)  ~/Documents/my    →  id_my    (個人)\n"
  s+="        ~/Documents/works →  id_work  (仕事)\n"
  s+="\n"
  s+=" キーが 2 つ以上あると、ssh は github.com の認証で\n"
  s+=" どのキーを使うか判断できないので、ディレクトリ\n"
  s+=" ごとにキーを割り当てます。\n"
  s+="\n"
  s+=" GitHub の SSH キーを設定しますか？"
  printf '%s' "$s"
}

# Case A の案内 (マネージド default あり).
lang_gitssh_caseA_note() {
  local managed="$1"
  local s=""
  s+=" ─────────────────────\n"
  s+=" このキーをすでに default として使っています。\n"
  s+="    ${managed}\n"
  s+="\n"
  s+=" 新しいキーはディレクトリごとのマッチングで追加します。\n"
  s+="\n"
  s+=" キーを新しく追加しますか？"
  printf '%s' "$s"
}

# Case B の案内 (外部 default あり).
lang_gitssh_caseB_note() {
  local ext="$1"
  local s=""
  s+=" ${UI_DIM}~/.ssh/config にすでに 'Host github.com' の設定があります。${UI_RESET}\n"
  s+=" ${UI_DIM}このキーをそのまま default として使います:${UI_RESET}\n"
  s+="    ${ext}\n"
  s+="\n"
  s+=" ${UI_DIM}さらにキーを登録するなら続けてください。${UI_RESET}"
  printf '%s' "$s"
}

# Case D 競合画面 (/dev/tty 出力).
lang_gitssh_conflict() {
  local ext="$1" managed="$2"
  echo -e "${UI_BLUE_BOLD} 'Host github.com' の設定が 2 つあります${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config の 'Host github.com' がマネージドブロックの内と外の${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}両方にあります。ssh は最初にマッチした 1 つだけを使うので、${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}どちらか一方が隠れています。${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}  マネージド外 (手書き): ${ext}${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}  マネージド内 (installer): ${managed}${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config を自分で整理してから、もう一度実行してください。${UI_RESET}\n" > /dev/tty
}

# ニックネームの案内画面.
lang_gitssh_nick_help() {
  local has_default="$1"
  echo -e "${UI_BLUE_BOLD} SSH キー — ニックネーム${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}このニックネームがキーのファイル名に使われます (~/.ssh/id_<nickname>)。${UI_RESET}" > /dev/tty
  if [ "$has_default" = "false" ]; then
    echo -e " ${UI_DIM}最初のキーは default として登録するので、ディレクトリは指定しません。${UI_RESET}" > /dev/tty
  else
    echo -e " ${UI_DIM}すでに default キーがあるので、このキーは特定のディレクトリ専用にします。${UI_RESET}" > /dev/tty
    echo -e " ${UI_DIM}このステップでキーを作り、次のステップでそのディレクトリを指定します。${UI_RESET}" > /dev/tty
  fi
  echo -e " ${UI_DIM}${UI_ITALIC}ニックネームを入力せず Enter を押すと、ここで止めて次のステップへ進みます。${UI_RESET}\n" > /dev/tty
}

# ディレクトリの案内画面.
lang_gitssh_dir_help() {
  local nickname="${1:-}"
  echo -e "${UI_BLUE_BOLD} SSH キー — ディレクトリ${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}'${nickname}' キーを使うディレクトリのパス (Tab で補完)。${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}そのパス(と配下)で git を使うと '${nickname}' キーが自動で選ばれます。${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}パスが無ければ自動で作成します。${UI_RESET}\n" > /dev/tty
}

# ── Obsidian (obsidian.sh) ──────────────────────────────────────
L_OBS_STORAGE_TITLE="wiki の保存方式"
L_OBS_STORAGE_LOCAL="ローカル"
L_OBS_CANCELLED="Obsidian wiki の設定をキャンセルしました。"
L_OBS_WIKIPATH_LABEL="wiki パス: "
L_OBS_EMPTY_PATH="wiki パスが空のため、wiki 設定をスキップします。"
L_OBS_PLUGIN_HINT="Claude Code を初めて起動したあと、obsidian-skills プラグインを手動でインストールしてください:"

# wiki パスの案内画面 (storage: 0=ローカル 1=icloud 2=git).
lang_obs_wikipath_help() {
  local storage="$1"
  echo -e "${UI_BLUE_BOLD} wiki パス${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}wiki に使うローカルディレクトリのパスを入力してください (Tab で補完)。${UI_RESET}" > /dev/tty
  case "$storage" in
    0)
      echo -e " ${UI_DIM}  ローカル — どのディレクトリでも大丈夫です。${UI_RESET}\n" > /dev/tty
      ;;
    1)
      echo -e " ${UI_DIM}  iCloud Drive — Obsidian が使う標準の iCloud 保管庫パス:${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}    ~/Library/Mobile Documents/iCloud~md~obsidian/Documents/<vault-name>${UI_RESET}\n" > /dev/tty
      ;;
    2)
      echo -e " ${UI_DIM}  Git — 使うローカル git リポジトリのディレクトリを指定してください。${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}  リポジトリがまだ無くても、パスを指定すれば新しいディレクトリを作成します。${UI_RESET}" > /dev/tty
      echo -e " ${UI_DIM}     例) ~/Documents/my-notes${UI_RESET}\n" > /dev/tty
      ;;
  esac
}

# ── AI ツール (ai-tools.sh) ─────────────────────────────────────
L_AI_MENU_TITLE="AI ツール — インストールする項目を選択"
L_AI_METHOD_TITLE="Claude Code のインストール方法"
L_AI_METHOD_STABLE="Stable (安定版)"
L_AI_METHOD_LATEST="Latest (安定版ではない最新版)"
L_AI_ALIAS_HEADER="Claude alias の設定"
L_AI_ALIAS_PROMPT="claude コマンドの alias を入力してください (デフォルト: c)"
L_AI_ALIAS_LABEL="alias: "
L_AI_INVALID_ALIAS="alias 名が正しくありません。デフォルトの c を使います。"
L_AI_HUD_TITLE="HUD ステータスラインをインストールしますか？"
L_AI_GOFMT_TITLE="Go を検出しました — gofmt フックを Claude に追加しますか？"
