#!/bin/bash
# Japanese message catalog.
# Keep the keys and functions in sync across catalogs. Verify with the catalog parity check.
# Use UI_* colors from ui.sh, which defines them before loading this file.
# Use natural Japanese and avoid literal translation.

# Common messages
L_YES="はい"
L_NO="いいえ"
L_NO_SKIP="いいえ (スキップ)"
L_NO_EXIT="いいえ (終了)"
L_NO_DONE="いいえ (完了)"
L_UI_HINT="↑↓ 移動 │ Enter 選択"
L_EXIT_ABORTED="インストールを中断して終了します。"

# Main menu (install.sh)
L_MENU_TITLE="my-term インストーラー"
L_MENU_INSTALL="インストール"
L_MENU_UPDATE="アップデート"
L_MENU_HUD_CONFIG="HUD 設定"
L_MENU_DELETE="削除 (my-term の設定を削除)"
L_MENU_EXIT="✗ 終了"

# Step labels (install.sh and ai-tools.sh)
L_STEP_CONVENIENCE="各種ツール"
L_STEP_GIT_SSH="Git SSH キー (マルチアカウント)"
L_STEP_OMZ="Oh-my-zsh + zsh プラグイン"
L_STEP_THEME="シェルテーマ (newro)"
L_STEP_LANGUAGE_TOOLS="言語バージョン管理ツール"

# Optional tool checkboxes
L_CONVENIENCE_CLI="CLI ツール"
L_CONVENIENCE_APPS="macOS アプリ"
L_CONVENIENCE_DEVOPS="DevOps ツール"
L_CONVENIENCE_MANAGERS="パッケージマネージャー"
L_CONVENIENCE_EDITORS="IDE・エディター"
L_CHECKLIST_HINT="↑↓ 移動 │ ←→ 下部メニュー │ Enter チェック / 実行"
L_CHECKLIST_SKIP="スキップ"
L_CHECKLIST_ALL="すべてインストール"
L_CHECKLIST_EMPTY="ツールを1つ以上選ぶか、スキップを選んでください。"

# Completion banner (ui_print_completion in ui.sh)
L_DONE_INSTALL="インストール完了！"
L_DONE_UPDATE="アップデート完了！"
L_DONE_HUDCFG="HUD の設定が完了しました。"
L_DONE_DELETE="my-term の設定を削除しました。"
L_DONE_DELETE_HINT="もう一度設定するには Install を実行してください。"
L_DELETE_CANCELLED="削除をキャンセルしました。"
L_DONE_RESTART_CC="反映するには Claude Code のセッションを再起動してください。"

# Escape the dollar sign to keep the HOME variable literal in colorized instructions.
lang_done_source_zshrc() {
  printf "  ${UI_YELLOW_BOLD}'source \${HOME}/.zprofile && source \${HOME}/.zshrc'${UI_RESET} を実行するか、シェルを ${UI_YELLOW_BOLD}再起動${UI_RESET}してください。\n\n"
}

# Delete confirmation (delete_ai_tools in ai-tools.sh)
L_DELETE_CONFIRM_TITLE="my-term の設定を削除しますか？ 元に戻せません。"

# List what the installer removes and preserves in the confirmation menu.
lang_delete_plan() {
  local s="\n"
  s+="   ${UI_RED_BOLD}削除するもの:${UI_RESET}\n"
  s+="     ~/.claude/my-hud, my-hooks, my-collab, my-wiki ${UI_DIM}(自分で変えた HUD テーマ・collab 設定を含む)${UI_RESET}\n"
  s+="     ~/.zshrc, ~/.zprofile, ~/.ssh/config の #-- my-term: ブロック\n"
  s+="     ~/.claude/CLAUDE.md の OPTIONAL 指示ブロック\n"
  s+="     Codex AGENTS.md の管理ブロック、my-term の @wk フックとファイル\n"
  s+="     インストール済みエージェントの my-term wk スキル\n"
  s+="     ~/.claude/settings.json の statusLine + my-term フック\n"
  s+="     ~/.claude.json の codex MCP エントリ\n"
  s+="\n"
  s+="   ${UI_GREEN_BOLD}残すもの:${UI_RESET}\n"
  s+="     ~/.claude/memory ${UI_DIM}(保存しておいた記憶)${UI_RESET}\n"
  s+="     SSH キーファイル ~/.ssh/id_* ${UI_DIM}(config ブロックだけ削除)${UI_RESET}\n"
  s+="     settings.json の permissions.deny セキュリティルール\n"
  s+="     アンインストール済みエージェントの設定と保管庫のパス\n"
  s+="     Codex のユーザー権限プロファイルとコマンド拒否ルール\n"
  s+="     brew パッケージ, oh-my-zsh, asdf/pyenv, CLI, IDE, Obsidian\n"
  printf '%s' "$s"
}

# Shared error messages
L_ERR_NO_BREW="Homebrew が見つかりません。先に Homebrew をインストールしてください。"
L_ERR_NO_OMZ="oh-my-zsh が見つかりません。先に oh-my-zsh をインストールしてください。"

# Required tools (required.sh)
L_REQ_TITLE="必須ツールをインストールしますか？ (Homebrew + jq)"
L_REQ_NOTE="⚠ 必須項目です — 断るとインストーラーがすぐに終了します。"
L_REQ_ALREADY="必須ツール(Homebrew・jq)はすでに入っているので、このステップは飛ばします。"

# ── IDE (ides.sh) ───────────────────────────────────────────────
L_IDE_CMD_HEADER="Antigravity コマンドの設定"
L_IDE_CMD_PROMPT="antigravity の短い起動コマンド名を入力してください (デフォルト: agy)"
L_IDE_INVALID_NAME="名前が正しくありません。デフォルトの agy を使います。"
L_IDE_BINDIR_NOTFOUND="Antigravity の bin ディレクトリが見つかりません。IDE を一度起動してから、このステップをやり直してください。"
L_PROMPT_NAME="名前: "

# ── asdf (asdf-langs.sh) ────────────────────────────────────────
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
L_GITSSH_HOST_LABEL="ホスト [github.com]: "
L_GITSSH_INVALID_HOST="github.com のようなホスト名を入力してください。"
L_GITSSH_REGISTER_HOST="%s のアカウントに公開鍵を登録してください。"
L_GITSSH_NICK_LABEL="ニックネーム: "
L_GITSSH_INVALID_NICK="ニックネームが正しくありません (a-z, 0-9, _, - のみ)。"
L_GITSSH_KEY_EXISTS="%s にすでにキーがあります。別のニックネームを入力してください。"
L_GITSSH_EMAIL_LABEL="email (キーのコメント): "
L_GITSSH_EMPTY_EMAIL="email を入力してください。"
L_GITSSH_PUBKEY_LABEL="公開鍵:"
L_GITSSH_REGISTER_GH="GitHub Settings → SSH keys に登録してください:"
L_GITSSH_DIR_LABEL="ディレクトリ: "
L_GITSSH_DIR_REQUIRED="ディレクトリは必須です。"
L_GITSSH_VERIFY="検証: cd <登録したディレクトリ> && ssh -T git@%s"

# Introductory menu note. Use literal \n for echo -e.
lang_gitssh_intro() {
  local s=""
  s+=" ─────────────────────\n"
  s+=" キーを 2 つ以上作るなら、作る前にどの\n"
  s+=" ディレクトリでどのキーを使うか決めておいてください。\n"
  s+="\n"
  s+="   例)  ~/Documents/my    →  id_my    (個人)\n"
  s+="        ~/Documents/works →  id_work  (仕事)\n"
  s+="\n"
  s+=" キーが 2 つ以上あると、ssh は 同じホストの認証で\n"
  s+=" どのキーを使うか判断できないので、ディレクトリ\n"
  s+=" ごとにキーを割り当てます。\n"
  s+="\n"
  s+=" Git の SSH キーを設定しますか？"
  printf '%s' "$s"
}

# Case A note for an existing managed default.
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

# Case B note for an existing external default.
lang_gitssh_caseB_note() {
  local ext="$1" host="$2"
  local s=""
  s+=" ${UI_DIM}~/.ssh/config にすでに 'Host ${host}' の設定があります。${UI_RESET}\n"
  s+=" ${UI_DIM}このキーをそのまま default として使います:${UI_RESET}\n"
  s+="    ${ext}\n"
  s+="\n"
  s+=" ${UI_DIM}さらにキーを登録するなら続けてください。${UI_RESET}"
  printf '%s' "$s"
}

# Case D conflict screen, displayed through /dev/tty.
lang_gitssh_conflict() {
  local ext="$1" managed="$2" host="$3"
  echo -e "${UI_BLUE_BOLD} 'Host ${host}' の設定が 2 つあります${UI_RESET}" > /dev/tty
  echo -e " ─────────────────────" > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config の 'Host ${host}' がマネージドブロックの内と外の${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}両方にあります。ssh は最初にマッチした 1 つだけを使うので、${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}どちらか一方が隠れています。${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}  マネージド外 (手書き): ${ext}${UI_RESET}" > /dev/tty
  echo -e " ${UI_DIM}  マネージド内 (installer): ${managed}${UI_RESET}" > /dev/tty
  echo > /dev/tty
  echo -e " ${UI_DIM}~/.ssh/config を自分で整理してから、もう一度実行してください。${UI_RESET}\n" > /dev/tty
}

# Nickname prompt.
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

# Directory prompt.
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

# Vault path instructions. Storage values are 0 for local, 1 for iCloud, and 2 for Git.
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

# AI tools (ai-tools.sh)
L_AI_MENU_TITLE="AI ツール"
L_AI_AGENTS_CATEGORY="AI コーディングエージェント"
L_AI_MULTIPLEXERS_CATEGORY="ターミナルマルチプレクサ"
L_AI_KNOWLEDGE_CATEGORY="ナレッジ管理"
L_AI_METHOD_TITLE="Claude Code のインストール方法"
L_AI_METHOD_STABLE="Stable (安定版)"
L_AI_METHOD_LATEST="Latest (安定版ではない最新版)"
L_AI_ALIAS_HEADER="%s alias の設定"
L_AI_ALIAS_PROMPT="%s コマンドの alias を入力してください (デフォルト: %s)"
L_AI_ALIAS_LABEL="alias: "
L_AI_INVALID_ALIAS="alias 名が正しくありません。デフォルトの %s を使います。"
L_AI_HUD_TITLE="HUD ステータスラインをインストールしますか？"
L_AI_GOFMT_TITLE="Go を検出しました — gofmt フックを Claude に追加しますか？"
