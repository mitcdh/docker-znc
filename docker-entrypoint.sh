#! /usr/bin/env bash

# Options.
DATADIR="/znc-data"

PUID=${PUID:-1000}
PGID=${PGID:-1000}

# Create a group for our gid if required
if [ ! $(getent group znc) ]; then
	echo "creating znc group for gid ${PGID}"
	groupadd --gid ${PGID} --non-unique znc >/dev/null 2>&1
fi

# Create a user for our uid if required
if [ ! $(getent passwd znc) ]; then
	echo "creating znc group for uid ${PUID}"
	useradd --gid ${PGID} --non-unique --comment "ZNC Bouncer Daemon" \
	 --home-dir "${DATADIR}" --create-home \
	 --uid ${PUID} znc >/dev/null 2>&1

	echo "taking ownership of /znc-data for znc"
	chown ${PUID}:${PGID} "${DATADIR}"
fi

# Build modules from source.
if [ -d "${DATADIR}/modules" ]; then
  # Store current directory.
  cwd="$(pwd)"

  # Find module sources.
  modules=$(find "${DATADIR}/modules" -name "*.cpp")

  # Build modules.
  for module in $modules; do
    echo "Building module $module..."
    cd "$(dirname "$module")"
    znc-buildmod "$module"
  done

  # Go back to original directory.
  cd "$cwd"
fi

# Create default config if it doesn't exist
if [ ! -f "${DATADIR}/configs/znc.conf" ]; then
  echo "Creating a default configuration..."
  mkdir -p "${DATADIR}/configs"
  cp /znc.conf.default "${DATADIR}/configs/znc.conf"
fi

# Make sure $DATADIR is owned by znc user. This effects ownership of the
# mounted directory on the host machine too.
echo "Setting necessary permissions..."
chown -R znc:znc "$DATADIR"

# Start ZNC.
echo "Starting ZNC..."
exec sudo -u znc znc --foreground --datadir="$DATADIR" $@
