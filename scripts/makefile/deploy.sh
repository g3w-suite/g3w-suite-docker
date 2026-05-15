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
#      switches nginx.conf to the SSL config and reloads the server.
#      Optionally installs a daily cron job for automatic renewal.
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$ROOT_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Ensure .env exists
#
# If .env is missing we copy the bundled example file so every subsequent
# step has a well-known starting point.
# If .env already exists we ask whether the user wants to reconfigure it,
# making re-runs of `make deploy` safe (answer "N" to just restart).
# ─────────────────────────────────────────────────────────────────────────────
configure_vars=true

if [ ! -f .env ]; then
  echo "📋 .env file not found, copying from .env.example..."
  cp .env.example .env
else
  echo "✅ .env file already exists."
  echo ""
  printf "🔄 Re-initialize setup and reconfigure variables? (y/N): "
  read -r reinit </dev/tty
  if [[ ! "$reinit" =~ ^[Yy]$ ]]; then
    configure_vars=false
  fi
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
if [ "$configure_vars" = true ]; then

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

    # read the value currently saved in .env so we can show it as the default;
    # fall back to empty string if the key does not exist yet
    current=$(grep -E "^${key}=" .env 2>/dev/null | head -1 | cut -d'=' -f2- || true)

    printf "  %-45s [%s]: " "$key" "$current"
    read -r value </dev/tty

    # only update .env when the user actually typed something
    if [ -n "$value" ]; then
      # escape characters that have special meaning in sed's replacement string
      escaped_value=$(printf '%s' "$value" | sed 's/[&/\]/\\&/g')
      sed -i "s|^${key}=.*|${key}=${escaped_value}|" .env
    fi

  done < .env.example

fi # configure_vars

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Ask about HTTPS
#
# When the user opts in we collect the admin e-mail address required by
# certbot for LetsEncrypt notifications and account registration.
# We do NOT touch nginx.conf or run certbot here yet — that happens in
# Step 5, after the containers are already up (certbot needs a running
# nginx to serve the ACME webroot challenge).
# ─────────────────────────────────────────────────────────────────────────────
enable_https=false
admin_email=""

echo ""
printf "🔒 Enable HTTPS with LetsEncrypt? (y/N): "
read -r https_choice </dev/tty

if [[ "$https_choice" =~ ^[Yy]$ ]]; then
  enable_https=true

  # pull the email that is currently set as the nginx $WEBGIS_ADMIN_EMAIL default
  current_email=$(grep -E "^\s+default.*@.*;" config/nginx/nginx.conf \
    | sed "s/.*default \(.*\);.*/\1/" | tr -d ' ' | head -1)
  current_email="${current_email:-info@gis3w.it}"

  printf "  %-45s [%s]: " "WEBGIS_ADMIN_EMAIL (LetsEncrypt)" "$current_email"
  read -r admin_email </dev/tty
  admin_email="${admin_email:-$current_email}"
fi

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
printf "🚀 Start as (prod/dev) [prod]: "
read -r mode </dev/tty
mode="${mode:-prod}"

if [[ "$mode" != "prod" && "$mode" != "dev" ]]; then
  echo "⚠️  Invalid mode '$mode', defaulting to prod."
  mode=prod
fi

echo ""
echo "▶️  Running: make $mode"
make -C "$ROOT_DIR" "$mode"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — HTTPS certificate + nginx switch  (only when HTTPS was requested)
#
# Why this order matters (the chicken-and-egg problem):
#   • nginx's SSL config references certificate files that do not exist yet
#     on a fresh install → nginx would refuse to start if we switched to
#     the HTTPS config before obtaining the certs.
#   • certbot's webroot challenge requires nginx to be serving HTTP traffic
#     on port 8080 so it can answer /.well-known/acme-challenge/ requests.
#
# Solution — four sub-steps (+ optional cron job):
#   A) While nginx is still running with the plain HTTP config, update
#      nginx.conf with the correct hostname / e-mail and run certbot.
#      certbot downloads the TLS parameters and writes the certificate
#      files into shared-volume/certs/letsencrypt/.
#   B) Edit nginx.conf to replace the HTTP include with the HTTPS include
#      (django_ssl).  The HTTPS config keeps an HTTP→HTTPS redirect server
#      block that still serves the ACME challenge path, so future renewals
#      will keep working.
#   C) Switch nginx.conf from the plain HTTP include to the SSL include.
#   D) Call `make renew-ssl` a second time — certbot will renew if needed
#      (harmless if the cert was just issued) and the `docker compose up`
#      at the end of that target restarts nginx so it picks up the new
#      SSL config with the valid certificates.
#   E) Optionally install a daily cron job (`make renew-ssl`) so the
#      certificate is renewed automatically before it expires.
# ─────────────────────────────────────────────────────────────────────────────
if [ "$enable_https" = true ]; then
  echo ""
  echo "🔐 Setting up HTTPS..."

  # read the public hostname that the user configured in .env
  hostname=$(grep -E "^WEBGIS_PUBLIC_HOSTNAME=" .env | head -1 | cut -d'=' -f2- | tr -d " '\"")

  # ── A: patch nginx.conf with correct hostname and email ──────────────────

  # find the current hostname default (non-email line)
  current_hostname=$(grep -E "^\s+default.*;" config/nginx/nginx.conf \
    | grep -v '@' | sed "s/.*default \(.*\);.*/\1/" | tr -d ' ' | head -1)
  current_hostname="${current_hostname:-dev.g3wsuite.it}"
  sed -i "s|  default ${current_hostname};|  default ${hostname};|" config/nginx/nginx.conf

  # find the current email default (line that contains '@')
  current_email_in_conf=$(grep -E "^\s+default.*@.*;" config/nginx/nginx.conf \
    | sed "s/.*default \(.*\);.*/\1/" | tr -d ' ' | head -1)
  current_email_in_conf="${current_email_in_conf:-info@gis3w.it}"
  sed -i "s|  default ${current_email_in_conf};|  default ${admin_email};|" config/nginx/nginx.conf

  echo "🔧 nginx.conf updated (hostname: $hostname, email: $admin_email)"

  # ── B: obtain TLS certificate while nginx is in HTTP mode ────────────────
  #
  # `make renew-ssl` runs scripts/makefile/renew-ssl.sh (downloads recommended
  # TLS parameters from certbot's GitHub, then runs the certbot Docker image
  # using the webroot method) and afterwards restarts nginx via docker compose.
  echo "📜 Requesting LetsEncrypt certificate (nginx still in HTTP mode)..."
  ENV=$mode make -C "$ROOT_DIR" renew-ssl

  # ── C: switch nginx.conf from HTTP-only to HTTPS ─────────────────────────
  #
  # Comment out the plain HTTP include and enable the SSL include.
  # The SSL config (config/nginx/django_ssl) listens on 443 for HTTPS and
  # keeps a redirect server on 8080 so that future certbot renewals can still
  # reach the ACME challenge endpoint.
  sed -i 's|^include /etc/nginx/conf.d/django;|# include /etc/nginx/conf.d/django;             # Remove this line if you want activate https|' config/nginx/nginx.conf
  sed -i 's|^# include /etc/nginx/conf.d/django_ssl;|include /etc/nginx/conf.d/django_ssl;|' config/nginx/nginx.conf
  echo "🔧 nginx.conf switched to HTTPS (django_ssl)."

  # ── D: reload nginx so it picks up the SSL config + valid certificates ───
  echo "🔄 Reloading nginx with HTTPS configuration..."
  ENV=$mode make -C "$ROOT_DIR" renew-ssl

  echo ""
  echo "✅ HTTPS is active at https://$hostname"

  # ── E: offer to install a cron job for automatic certificate renewal ─────
  #
  # We only attempt this when crontab is available on the system.
  # The job runs `make renew-ssl` every night at 03:00; certbot is a no-op
  # when the certificate is still valid (> 30 days), so running daily is safe.
  if command -v crontab &>/dev/null; then
    echo ""
    printf "   ⏰ Add a daily cron job to auto-renew the certificate? (y/N): "
    read -r add_cron </dev/tty
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

