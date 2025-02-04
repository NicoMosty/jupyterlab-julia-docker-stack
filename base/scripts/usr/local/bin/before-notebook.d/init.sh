#!/bin/bash
# Copyright (c) 2020 b-data GmbH.
# Distributed under the terms of the MIT License.

set -e

# Set defaults for environment variables in case they are undefined
LANG=${LANG:=en_US.UTF-8}
TZ=${TZ:=Etc/UTC}

if [ "$(id -u)" == 0 ] ; then
  # Update timezone if needed
  if [ "$TZ" != "Etc/UTC" ]; then
    echo "Setting TZ to $TZ"
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
      && echo $TZ > /etc/timezone
  fi

  # Add/Update locale if needed
  if [ ! -z "$LANGS" ]; then
    for i in $LANGS; do
      sed -i "s/# $i/$i/g" /etc/locale.gen
    done
  fi
  if [ "$LANG" != "en_US.UTF-8" ]; then
    sed -i "s/# $LANG/$LANG/g" /etc/locale.gen
  fi
  if [[ "$LANG" != "en_US.UTF-8" || ! -z "$LANGS" ]]; then
    locale-gen
  fi
  if [ "$LANG" != "en_US.UTF-8" ]; then
    echo "Setting LANG to $LANG"
    update-locale --reset LANG=$LANG
  fi

  # Install user-specific startup files for Julia and IJulia
  su $NB_USER -c "mkdir -p .julia/config"
  if [[ ! -f ".julia/config/startup_ijulia.jl" ]]; then
    su $NB_USER -c "cp -a /var/backups/skel/.julia/config/startup_ijulia.jl \
      .julia/config/startup_ijulia.jl"
  fi
  if [[ ! -f ".julia/config/startup.jl" ]]; then
    su $NB_USER -c "cp -a /var/backups/skel/.julia/config/startup.jl \
      .julia/config/startup.jl"
  fi

  # Update code-server settings
  su $NB_USER -c "mv .local/share/code-server/User/settings.json \
    .local/share/code-server/User/settings.json.bak"
  su $NB_USER -c "sed -i ':a;N;\$!ba;s/,\n\}/\n}/g' \
    .local/share/code-server/User/settings.json.bak"
  su $NB_USER -c "jq -s '.[0] * .[1]' \
    /var/backups/skel/.local/share/code-server/User/settings.json \
    .local/share/code-server/User/settings.json.bak > \
    .local/share/code-server/User/settings.json"
else
  # Warn if the user wants to change the timezone but hasn't started the
  # container as root.
  if [ "$TZ" != "Etc/UTC" ]; then
    echo "WARNING: Setting TZ to $TZ but /etc/localtime and /etc/timezone remain unchanged!"
  fi

  # Warn if the user wants to change the locale but hasn't started the
  # container as root.
  if [[ ! -z "$LANGS" ]]; then
    echo "WARNING: Container must be started as root to add locale(s)!"
  fi
  if [[ "$LANG" != "en_US.UTF-8" ]]; then
    echo "WARNING: Container must be started as root to update locale!"
    echo "Resetting LANG to en_US.UTF-8"
    LANG=en_US.UTF-8
  fi

  # Install user-specific startup files for Julia and IJulia
  mkdir -p .julia/config
  if [[ ! -f ".julia/config/startup_ijulia.jl" ]]; then
    cp -a /var/backups/skel/.julia/config/startup_ijulia.jl \
      .julia/config/startup_ijulia.jl
  fi
  if [[ ! -f ".julia/config/startup.jl" ]]; then
    cp -a /var/backups/skel/.julia/config/startup.jl \
      .julia/config/startup.jl
  fi

  # Update code-server settings
  mv .local/share/code-server/User/settings.json \
    .local/share/code-server/User/settings.json.bak
  sed -i ':a;N;$!ba;s/,\n\}/\n}/g' \
    .local/share/code-server/User/settings.json.bak
  jq -s '.[0] * .[1]' \
    /var/backups/skel/.local/share/code-server/User/settings.json \
    .local/share/code-server/User/settings.json.bak > \
    .local/share/code-server/User/settings.json
fi

# Remove old .zcompdump files
rm -f .zcompdump*
