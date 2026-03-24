#!/bin/zsh
# Claude Code SessionStart 훅용 환경 초기화 스크립트.
# .zprofile을 source하여 PATH/환경변수를 확보한 뒤,
# asdf plugin의 precmd 함수들을 직접 호출하여 언어별 환경변수를 설정.
# 최종 결과를 CLAUDE_ENV_FILE에 write하여 이후 모든 Bash 명령에 적용.

[ -z "$CLAUDE_ENV_FILE" ] && exit 0

ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"
[ -f "$ZPROFILE" ] && source "$ZPROFILE"

# 호출 전 환경변수 스냅샷
env_before=$(env | sort)

# asdf plugin의 asdf_update_* precmd 함수들을 모두 호출
# (source된 set-env.zsh 등이 precmd에 등록만 하고 실행은 안 하므로)
for func in ${(k)functions[(I)asdf_update_*]}; do
  $func
done

# 변경된 환경변수를 CLAUDE_ENV_FILE에 write
{
  printf 'export PATH=%q\n' "$PATH"
  comm -13 <(echo "$env_before") <(env | sort) | while IFS='=' read -r key value; do
    [[ "$key" == "PATH" ]] && continue
    printf 'export %s=%q\n' "$key" "$value"
  done
} >> "$CLAUDE_ENV_FILE"
