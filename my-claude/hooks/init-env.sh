#!/bin/zsh
# Initialize the environment for the Claude Code SessionStart hook.
# Source .zprofile for PATH and environment variables.
# Run asdf plugin precmd functions to initialize language environments.
# Write the resulting exports to CLAUDE_ENV_FILE for subsequent Bash commands.

[ -z "$CLAUDE_ENV_FILE" ] && exit 0

ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
if [ -f "$ZPROFILE" ] && [ ! -L "$ZPROFILE" ]; then
  source "$ZPROFILE"
fi

# Snapshot the environment before running the plugin functions.
env_before=$(env | sort)

# Run all asdf_update_* precmd functions.
# Sourcing set-env.zsh registers these functions without running them.
for func in ${(k)functions[(I)asdf_update_*]}; do
  $func
done

# Write changed, allowlisted environment variables to CLAUDE_ENV_FILE.
ALLOWED_VARS='^(PATH|GOROOT|GOPATH|JAVA_HOME|ASDF_.*|PYENV_.*|RUBY_.*|NVM_.*|VOLTA_.*|SDKMAN_.*|CARGO_HOME|RUSTUP_HOME|BREW_PREFIX|HOMEBREW_.*)$'
{
  printf 'export PATH=%q\n' "$PATH"
  comm -13 <(echo "$env_before") <(env | sort) | while IFS='=' read -r key value; do
    [[ "$key" == "PATH" ]] && continue
    [[ "$key" =~ $ALLOWED_VARS ]] || continue
    printf 'export %s=%q\n' "$key" "$value"
  done
} >> "$CLAUDE_ENV_FILE"
