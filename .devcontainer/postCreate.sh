#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"  # /workspaces/g3w-suite-docker
ADMIN_DIR="$(cd "${REPO_DIR}/.." && pwd)/g3w-admin"          # /workspaces/g3w-admin

# ---------------------------------------------------------------------------
# 1. Create .env from template (skip if already present)
# ---------------------------------------------------------------------------
if [ ! -f "${REPO_DIR}/.env" ]; then
  echo "[devcontainer] Copying .env.example → .env"
  cp "${REPO_DIR}/.env.example" "${REPO_DIR}/.env"
fi

# ---------------------------------------------------------------------------
# 2. Patch WEBGIS_PUBLIC_HOSTNAME for Codespaces
#    The dev-server listens on port 8000; Codespaces exposes it at:
#    https://${CODESPACE_NAME}-8000.app.github.dev
# ---------------------------------------------------------------------------
if [ -n "${CODESPACE_NAME:-}" ]; then
  HOSTNAME="${CODESPACE_NAME}-8000.app.github.dev"
  echo "[devcontainer] Setting WEBGIS_PUBLIC_HOSTNAME=${HOSTNAME}"
  sed -i "s|^WEBGIS_PUBLIC_HOSTNAME=.*|WEBGIS_PUBLIC_HOSTNAME=${HOSTNAME}|" "${REPO_DIR}/.env"
fi

# ---------------------------------------------------------------------------
# 3. Clone g3w-admin (required by CODE_VOLUME=../g3w-admin:/code in .env.dev)
# ---------------------------------------------------------------------------
if [ ! -d "${ADMIN_DIR}/.git" ]; then
  echo "[devcontainer] Cloning g3w-suite/g3w-admin into ${ADMIN_DIR} …"
  git clone --depth=1 https://github.com/g3w-suite/g3w-admin.git "${ADMIN_DIR}"
else
  echo "[devcontainer] g3w-admin already present at ${ADMIN_DIR}, skipping clone"
fi

# ---------------------------------------------------------------------------
# 4. Start the full Docker Compose stack in DEV mode
#    .env.dev sets: DEV_MODE=True, DEV_SERVER=1, CODE_VOLUME, SCRIPTS_VOLUME …
# ---------------------------------------------------------------------------
echo "[devcontainer] Starting Docker Compose stack (ENV=dev) …"
make -C "${REPO_DIR}" reload ENV=dev

echo "[devcontainer] Done. Application will be available on port 8000 once g3w-suite finishes its first-run setup (this may take several minutes)."
