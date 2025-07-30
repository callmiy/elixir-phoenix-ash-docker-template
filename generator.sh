#!/usr/bin/env bash
# shellcheck disable=

# claude
# ash_rate_limiter
# ash_oban
# oban_web
installs_list=(
  ash
  ash_postgres
  ash_phoenix
  ash_admin
  ash_archival
  live_debugger
  tidewave
  mix_test_interactive
  ash_authentication
  ash_authentication_phoenix
  opentelemetry_ash
  ash_ai
)
IFS=','
installs="${installs_list[*]}"
unset IFS
app=my_app
dir_path="f"
module=MyApp
mix igniter.new "$dir_path" \
  --install "${installs}" \
  --with phx.new \
  --with-args="--app $app --module $module --binary-id" \
  --yes

cd "$dir_path" || exit 1

mix ash_authentication.add_strategy magic_link \
  --yes

mix phx.gen.release --docker

mix release.init

find ./rel \
  -type f \( -name "*.bat" -o -name "*.bat.eex" \) \
  -delete

# Sync all usage rules to `deps`
mix usage_rules.sync CLAUDE.md \
  --all \
  --inline usage_rules:all \
  --link-to-folder deps \
  --yes

## OR Sync specific rules (ash_postgres) to `my-rules-folder`
mix usage_rules.sync AGENTS.md ash ash_postgres \
  --link-to-folder my-rules-folder

mix ecto.drop

mix ash.setup

## 7220 = port where you access mix phx.server
PORT=7220
claude mcp add \
  --transport stdio \
  tidewave \
  mcp-proxy http://localhost:$PORT/tidewave/mcp

mix ash_authentication.add_strategy password --yes

mix igniter.install ash_ai --yes

mix ash_ai.gen.mcp --yes

mix ash_ai.gen.chat --live --yes
