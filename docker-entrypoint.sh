#!/bin/sh
set -e

# The app persists its state as JSON files in the project root.
# Symlink each of them (plus the logs dir) into /data so a single
# volume mount survives container rebuilds.
DATA_DIR="${DATA_DIR:-/data}"

# Volumes are mounted owned by root. When started as root, fix ownership
# of the data dir, then re-exec this script as the unprivileged node user.
if [ "$(id -u)" = "0" ]; then
  mkdir -p "$DATA_DIR"
  chown -R node:node "$DATA_DIR"
  exec su-exec node "$0" "$@"
fi

mkdir -p "$DATA_DIR/logs"

for f in keypair.json device.json ecdh-keypair.json \
         tracked-payments.json webhook-retries.json webhooks.json; do
  # Migrate a file baked into the image (or left over) into the volume once
  if [ -f "/app/$f" ] && [ ! -L "/app/$f" ] && [ ! -e "$DATA_DIR/$f" ]; then
    mv "/app/$f" "$DATA_DIR/$f"
  fi
  rm -f "/app/$f"
  ln -s "$DATA_DIR/$f" "/app/$f"
done

rm -rf /app/logs
ln -sfn "$DATA_DIR/logs" /app/logs

exec "$@"
