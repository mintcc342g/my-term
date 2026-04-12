#!/bin/bash
# installers/asdf-langs.sh — asdf language setup (Golang, Java)
# source'd by install.sh — uses shared log functions and variables

install_asdf_langs() {
  log_start "Starting programming language setup…\n"

  ask_asdf_config() {
    local lang="$1"
    local __varname="$2"
    local answer

    read -r -p "Would you like to configure ${lang} with asdf? (y/N) " answer
    printf -v "$__varname" '%s' "$answer"
  }

  print_env_uncomment_warning() {
    local lang="$1"

    echo
    log_done "${lang} configuration for asdf has been added to .zprofile."
    echo
    echo "${YELLOW_BOLD}[WARNING]${RESET} ${RED_BOLD}After installing ${lang}${RESET}, please ${RED_BOLD}uncomment${RESET} the ${lang} environment configuration in your ${RED_BOLD}.zprofile.${RESET}"
    echo
  }

  ZPROFILE="${ZDOTDIR:-$HOME}/.zprofile"

  # Golang 설정
  ask_asdf_config "Golang" install_golang
  case "$install_golang" in
    [yY])
      asdf plugin add golang https://github.com/kennyp/asdf-golang.git
      printf '\n# asdf Golang 환경 설정\n#. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/golang/set-env.zsh\n' >> "${ZPROFILE}"
      print_env_uncomment_warning "Golang"
      ;;
    *)
      log_fail "Skipping Golang configuration for asdf.\n"
      ;;
  esac

  # Java 설정
  ask_asdf_config "Java" install_java
  case "$install_java" in
    [yY])
      asdf plugin add java https://github.com/halcyon/asdf-java.git
      printf '\n# asdf Java 환경 설정\n#. ${ASDF_DATA_DIR:-$HOME/.asdf}/plugins/java/set-java-home.zsh\n' >> "${ZPROFILE}"
      print_env_uncomment_warning "Java"
      ;;
    *)
      log_fail "Skipping Java configuration for asdf.\n"
      ;;
  esac

  # Export for gofmt hook in claude installer
  export install_golang
}
