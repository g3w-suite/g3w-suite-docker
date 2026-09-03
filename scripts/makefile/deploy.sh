#!/usr/bin/env bash
#
# deploy.sh — Interactive setup wizard for g3w-suite-docker
#
# Called by: make deploy
#
# What this script does:
#   1. Ensures a .env file exists (copies .env.example if missing)
#   2. Optionally walks the user through each environment variable
#   3. Optionally asks whether to enable HTTPS via LetsEncrypt (certbot)
#   4. Asks whether to start in production or development mode
#      and starts all Docker containers via `make prod|dev`
#   5. If HTTPS was requested: obtains the TLS certificate while nginx
#      is still running in HTTP mode (certbot webroot challenge), then
#      switches WEBGIS_SSL in .env to enable HTTPS and reloads the server.
#      Optionally installs a daily cron job for automatic renewal.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$ROOT_DIR"

set_env_value() {
  local safe_val=$(printf '%s' "$2" | sed 's/[&/\\]/\\&/g')
  if grep -q "^$1=" .env; then
    sed -i "s|^$1=.*|$1=${safe_val}|" .env
  else
    echo "$1=$2" >> .env
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Ensure .env exists
#
# If .env is missing we copy the bundled example file so every subsequent
# step has a well-known starting point.
# If .env already exists we ask whether the user wants to reconfigure it,
# making re-runs of `make deploy` safe (answer "N" to just restart).
# ─────────────────────────────────────────────────────────────────────────────

if [ ! -f .env ]; then
  echo "📋 .env file not found, copying from .env.example..."
  cp .env.example .env
  init_env="y"  # always configure on first run
else
  echo "✅ .env file already exists."
  echo ""
  read -p "🔄 Re-initialize setup and reconfigure variables? (y/N): " init_env
fi

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Configure environment variables interactively
#
# We iterate over every KEY=value line defined in .env.example (the canonical
# list of supported variables).  For each key we:
#   • show the value currently stored in .env between brackets
#   • let the user type a new value, or press Enter to keep the existing one
#
# Comment lines and blank lines in .env.example are skipped.
# Inline comments on the same line as a variable (e.g. KEY=val # hint) are
# stripped before extracting the key name.
# ─────────────────────────────────────────────────────────────────────────────
if [ "${init_env,,}" == "y" ]; then

  echo ""
  echo "📝 Configure your environment variables (press Enter to keep the current value):"
  echo ""

  while IFS= read -r line || [ -n "$line" ]; do

    # skip pure-comment lines (lines whose first non-space char is '#')
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    # skip blank lines
    [[ -z "${line//[[:space:]]/}" ]] && continue

    # strip any trailing inline comment (e.g. KEY=value # explanation)
    # then extract just the KEY part (everything before the first '=')
    stripped=$(echo "$line" | sed 's/[[:space:]]*#.*//')
    key=$(echo "$stripped" | cut -d'=' -f1 | tr -d '[:space:]')
    [ -z "$key" ] && continue

    # WEBGIS_SSL is managed explicitly in Step 3.
    [ "$key" = "WEBGIS_SSL" ] && continue

    # read the value currently saved in .env so we can show it as the default;
    # fall back to empty string if the key does not exist yet
    current=$(grep -E "^${key}=" .env 2>/dev/null | head -1 | cut -d'=' -f2- || true)

    printf "  %-45s [%s]: " "$key" "$current"
    read -r value </dev/tty

    # only update .env when the user actually typed something
    [ -n "$value" ] && set_env_value "$key" "$value"

  done < .env.example

fi # init_env

# Read .env once after the interactive variable configuration.
set -a
source .env
set +a

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Ask about HTTPS and sync .env values
#
# SSL mode is controlled only through `.env`:
#   WEBGIS_SSL=""     -> HTTP config (`conf/django`)
#   WEBGIS_SSL="_ssl" -> HTTPS config (`conf/django_ssl`)
#
# WEBGIS_SSL is not asked in Step 2; we ask it once here.
# If enabled, we keep WEBGIS_SSL empty for first setup, obtain the
# certificate in HTTP mode, then switch WEBGIS_SSL to `_ssl` and reload.
# ─────────────────────────────────────────────────────────────────────────────

echo ""
read -p "🔒 Enable HTTPS with LetsEncrypt? (y/N): " https_choice

ssl_cert="${WEBGIS_DOCKER_SHARED_VOLUME}/certs/letsencrypt/live/${WEBGIS_PUBLIC_HOSTNAME}/fullchain.pem"
init_https=$([[ "${https_choice,,}" == "y" && ! -f "$ssl_cert" ]] && echo true || echo false)
# Bootstrap certbot in HTTP mode, then switch to SSL later.
# If cert already exists (re-run), start directly in SSL mode; if not yet obtained, keep HTTP mode.
# If HTTPS was not requested at all, stay in HTTP mode.
set_env_value "WEBGIS_SSL" "$([[ "${https_choice,,}" == "y" && -f "$ssl_cert" ]] && echo "_ssl" || echo "")"


# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Choose startup mode and start all containers
#
# "prod"  → standard production setup (no source-code mount, no live-reload)
# "dev"   → development setup: mounts G3WSUITE_LOCAL_CODE_PATH into the
#           container and enables Django's auto-reloader
#
# `make prod|dev` ultimately calls `make reload` which runs:
#   docker compose up -d --force-recreate --remove-orphans
# ─────────────────────────────────────────────────────────────────────────────
echo ""
read -p "🚀 Start as (prod/dev) [prod]: " mode
[[ "$mode" == "dev" ]] || mode="prod"

echo ""
echo "▶️  Running: make $mode"
make -C "$ROOT_DIR" "$mode"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — HTTPS certificate + env switch  (only when HTTPS was requested)
#
# No nginx config files are edited here.
# Flow: HTTP bootstrap -> certbot -> WEBGIS_SSL=_ssl -> reload.
# ─────────────────────────────────────────────────────────────────────────────
if [ "$init_https" = true ]; then
  echo ""
  echo "🔐 Setting up HTTPS..."

  # A) Obtain certificates while nginx is in HTTP mode.
  echo "📜 Requesting LetsEncrypt certificate (nginx still in HTTP mode)..."
  ENV=$mode make -C "$ROOT_DIR" renew-ssl

  # B) Switch to HTTPS profile and reload.
  set_env_value "WEBGIS_SSL" "_ssl"
  echo "🔄 Reloading containers with WEBGIS_SSL=_ssl ..."
  make -C "$ROOT_DIR" "$mode"

  echo ""
  echo "✅ HTTPS is active at https://$WEBGIS_PUBLIC_HOSTNAME"

  # C) Optionally install daily renew cron.
  if command -v crontab &>/dev/null; then
    echo ""
    read -p "   ⏰ Add a daily cron job to auto-renew the certificate? (y/N): " add_cron
    if [[ "$add_cron" =~ ^[Yy]$ ]]; then
      cron_cmd="0 3 * * * make -C \"$ROOT_DIR\" renew-ssl >> \"$ROOT_DIR/shared-volume/var/renew-ssl.log\" 2>&1"
      # append only if the exact line is not already present
      ( crontab -l 2>/dev/null | grep -qF "$cron_cmd" ) \
        || ( crontab -l 2>/dev/null; echo "$cron_cmd" ) | crontab -
      echo "   ✅ Cron job added: $cron_cmd"
    else
      echo "   ℹ️  To add it manually later (sudo crontab -e):"
      echo "      0 3 * * * make -C \"$ROOT_DIR\" renew-ssl"
    fi
  else
    echo ""
    echo "   ℹ️  crontab not found. To auto-renew certificates, schedule this command manually:"
    echo "      0 3 * * * make -C \"$ROOT_DIR\" renew-ssl"
  fi
fi

