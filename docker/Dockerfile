#=============================================================================
# Development image
#=============================================================================

ARG CONTAINER_BUILDER_IMAGE="${CONTAINER_BUILDER_IMAGE:-hexpm/elixir:1.18.4-erlang-28.0.1-bullseye-20250630-slim}"
ARG RUNNER_IMAGE="${RUNNER_IMAGE:-debian:bullseye-20250630-slim}"

FROM ${CONTAINER_BUILDER_IMAGE} AS dev

ARG PHX_HOST

ENV \
  USER=my_app \
  HOME=/app \
  APP_ROOT_DIR=/app/app \
  PHX_HOST=${PHX_HOST} \
  MIX_ENV=dev \
  DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get update -y \
  && apt-get install -y --no-install-recommends \
  openssl \
  git \
  ca-certificates \
  curl \
  gnupg \
  inotify-tools \
  iputils-ping \
  build-essential \
  libvips-dev \
  file \
  locales \
  libstdc++6 \
  libncurses5 \
  && rm -rf \
  /var/lib/apt/lists/* \
  /usr/share/doc \
  /usr/share/man \
  && apt-get clean \
  `#################### Setup locale.` \
  && sed -i              \
  '/en_US.UTF-8/s/^# //g' \
  /etc/locale.gen \
  && locale-gen \
  `#################### END Setup locale.` \
  `#################### Create user home and group.` \
  && groupadd $USER \
  && useradd -M -g $USER $USER \
  `#################### END Create user home and group.` \
  `#################### Prep working directory.` \
  && mkdir -p \
  $APP_ROOT_DIR/_build \
  $APP_ROOT_DIR/deps \
  $APP_ROOT_DIR/config \
  $APP_ROOT_DIR/priv \
  `#################### END Prep working directory.`\
  `#################### install hex + rebar` \
  && mix local.hex --force \
  && mix local.rebar --force \
  `#################### END install hex + rebar` \
  `#################### Configure file persmissions.` \
  && chown -R $USER:$USER $HOME \
  `#################### END Configure file persmissions.`

USER my_app

WORKDIR /app/app

ENV \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Copy development script
COPY \
  --chown=my_app:my_app \
  --chmod=777 \
  ./docker/compose.app.dev.sh \
  /usr/local/bin/dev.sh

COPY \
  --chown=my_app:my_app \
  ./mix.exs \
  ./mix.lock \
  ./

COPY \
  --chown=my_app:my_app \
  . \
  .

RUN \
  mix deps.get

CMD ["/bin/bash" , "-c", "mix ash.setup && mix phx.server"]

#=============================================================================
# BUILD IMAGE
#=============================================================================

FROM dev AS builder

ENV \
  MIX_ENV=prod \
  DO_NOT_FORCE_SSL=1

RUN \
  mix do deps.get --only prod + compile \
  && mix assets.deploy \
  && mix release \
  && rm -rf /app/app/_build/prod/rel/my_app/bin/{my_app,migrate,server}.bat \
  && find /app/app/_build/prod/rel/my_app/bin -maxdepth 1 -type f -exec chmod 755 {} +

#=============================================================================
# PRODUCTION IMAGE
#=============================================================================

FROM ${RUNNER_IMAGE} AS prod

ENV \
  MIX_ENV=prod \
  DO_NOT_FORCE_SSL=1

RUN \
  apt-get update -y \
  && apt-get install -y \
  libstdc++6 \
  openssl \
  ca-certificates \
  libncurses5 \
  locales \
  && apt-get clean \
  && rm -f /var/lib/apt/lists/*_* \
  `#################### Setup locale.` \
  && sed -i              \
  '/en_US.UTF-8/s/^# //g' \
  /etc/locale.gen \
  && locale-gen \
  `#################### END Setup locale.` \
  && mkdir -p \
  /app \
  /_app/.ssl_cert \
  && chown -R nobody /app \
  && chown -R nobody /_app

WORKDIR /app

ENV \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Only copy the final release from the build stage
COPY \
  --from=builder \
  --chown=nobody:root \
  /app/app/_build/prod/rel/my_app \
  ./

# Copy the shared config module into the releases since it is referenced by runtime.exs.
COPY \
  --from=builder \
  --chown=nobody:root \
  /app/app/config/shared_config.exs \
  ./releases/0.1.0/

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

CMD ["/bin/bash", "-c", "/app/bin/migrate && /app/bin/server"]
