#!/bin/bash
# shellcheck disable=

set -o errexit
set -o pipefail
set -o noclobber

_has_internet() {
  ping -q -c 1 -W 1 8.8.8.8 >/dev/null
}

_raise_on_no_env() {
  local _required_envs=(
    PROJECT_TAG
    RELEASE_COOKIE
  )

  for _env_name in "${_required_envs[@]}"; do
    printf -v _env_val "%q" "${!_env_name}"

    if [ "${_env_val}" == "''" ]; then
      echo -e "'${_env_name}' environment variable is missing"
      exit 1
    fi
  done
}

_get-hostname() {
  if [ "$(uname)" = 'Linux' ]; then
    hostname -i
  elif [ -z "$APP_HOSTNAME" ]; then
    echo "APP_HOSTNAME environment variable is required."
    exit 1
  else
    echo -n "$APP_HOSTNAME"
  fi
}

_main_node_name() {
  _raise_on_no_env
  echo -n "${PROJECT_TAG}@$(_get-hostname)"
}

diex() {
  _raise_on_no_env

  local _node
  _node="${PROJECT_TAG}_$(date +'%s')"

  PHX_SERVER="" \
  OTEL_EXPORTER_BACKEND="" \
    iex \
    --hidden \
    --name "${_node}@$(_get-hostname)" \
    --remsh "$(_main_node_name)" \
    --cookie "${RELEASE_COOKIE}" \
    -S \
    mix
}

serve() {
  _raise_on_no_env

  if _has_internet; then
    mix deps.get
  fi

  mix ash.setup

  elixir \
    --name "$(_main_node_name)" \
    --cookie "${RELEASE_COOKIE}" \
    -S mix phx.server
}

t() {
  : "Run elixir tests"

  PHX_SERVER='' \
  OTEL_EXPORTER_BACKEND="" \
    DO_NOT_FORCE_SSL=1 \
    mix test.interactive "${@}"
}

"$@"
