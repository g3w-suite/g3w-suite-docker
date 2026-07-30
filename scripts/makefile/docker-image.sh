#!/usr/bin/env bash
#
# docker-image.sh — Build g3w-suite Docker images
#
# Called by: make docker-image              ← interactive wizard
#            make docker-image v=suite:dev  ← non-interactive
#
# Non-interactive usage:
#   $1  = v=<stage>:<tag>  (e.g. suite:dev, deps-ltr:dev, oracle:dev)
#   env = QGIS_DEPS_TAG, QGIS_TAG  (oracle stage only)
#
# Interactive wizard steps:
#   1. Choose image type (stage)
#   2. Choose tag
#   3. Stage-specific options (branch, QGIS channel, MSSQL EULA, Oracle tags)
#   4. Summary + confirmation
#   5. docker build
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$ROOT_DIR"

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────
bold()  { printf '\033[1m%s\033[0m' "$*"; }
cyan()  { printf '\033[36m%s\033[0m' "$*"; }
green() { printf '\033[32m%s\033[0m' "$*"; }
yellow(){ printf '\033[33m%s\033[0m' "$*"; }
red()   { printf '\033[31m%s\033[0m' "$*"; }

hr() { printf '\n%s\n\n' "────────────────────────────────────────────────────────────"; }

prompt() {
  # prompt <label> <default>
  local label="$1" default="$2"
  printf "  %-45s [%s]: " "$label" "$default" >/dev/tty
  read -r _answer </dev/tty
  printf '%s' "${_answer:-$default}"
}

prompt_yn() {
  # prompt_yn <label> <default Y|N>
  local label="$1" default="${2:-N}"
  printf "  %s (y/N): " "$label"
  read -r _answer </dev/tty
  [[ "${_answer:-$default}" =~ ^[Yy]$ ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# NON-INTERACTIVE mode: called with $1 = <stage>:<tag>
# ─────────────────────────────────────────────────────────────────────────────
if [ -n "$1" ]; then
  stage="${1%%:*}"
  tag="${1#*:}"

  case "$stage" in
    suite|deps|deps-ltr|deps-mssql|oracle) ;;
    *)
      echo "$(red "❌ Unknown stage: ${stage}")  Valid: suite, deps, deps-ltr, deps-mssql, oracle"
      exit 1
      ;;
  esac

  # Resolve docker target and image name
  case "$stage" in
    suite)      docker_target="suite"        image="g3wsuite/g3w-suite"             ;;
    deps)       docker_target="deps"         image="g3wsuite/g3w-suite-deps"        ;;
    deps-ltr)   docker_target="deps"         image="g3wsuite/g3w-suite-deps-ltr"    ;;
    deps-mssql) docker_target="deps"         image="g3wsuite/g3w-suite-deps"        ;;
    oracle)     docker_target="qgis-oracle"  image="g3wsuite/g3w-suite-qgis-oracle" ;;
  esac

  extra_args=""
  case "$stage" in
    deps-mssql) extra_args="--build-arg INSTALL_MSSQL=true" ;;
    oracle)
      qgis_deps_tag="${QGIS_DEPS_TAG:-release-3_22}"
      qgis_tag="${QGIS_TAG:-final-3_22_7}"
      extra_args="--build-arg DOCKER_DEPS_TAG=${qgis_deps_tag} --build-arg QGIS_TAG=${qgis_tag}"
      ;;
  esac

  full_image="${image}:${tag}"

  echo ""
  echo "  $(bold '🏗️  G3W-SUITE — Docker image builder')  $(cyan '[non-interactive]')"
  echo ""
  echo "  $(bold 'Image name :') ${full_image}"
  echo "  $(bold 'Stage      :') ${docker_target}"
  [ -n "$extra_args" ] && echo "  $(bold 'Extra args :') ${extra_args}"
  echo ""
  echo "$(bold '🚀 Building image…')"
  echo ""

  # shellcheck disable=SC2086
  docker build --target "${docker_target}" \
    ${extra_args} \
    -t "${full_image}" \
    --no-cache \
    .

  echo ""
  echo "$(green '✅ Image built successfully:') $(bold "${full_image}")"
  echo ""
  exit 0
fi

# ─────────────────────────────────────────────────────────────────────────────
# HEADER
# ─────────────────────────────────────────────────────────────────────────────
clear
clear 2>/dev/null || true
echo ""
echo "  $(bold '🏗️  G3W-SUITE — Docker image builder')"
echo ""
echo "  This wizard will guide you through building one of the available"
echo "  g3w-suite Docker images.  Answer each question or press $(bold Enter) to"
echo "  accept the default value shown in brackets."
hr

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — Choose stage
# ─────────────────────────────────────────────────────────────────────────────
echo "$(bold 'STEP 1 — Choose an image type')"
echo ""
echo "  Available image types:"
echo ""
printf "    $(cyan '1')  %-18s %s\n" "suite"      "Full g3w-suite application image  $(green '← recommended')"
printf "    $(cyan '2')  %-18s %s\n" "deps"       "Ubuntu + QGIS (latest channel)"
printf "    $(cyan '3')  %-18s %s\n" "deps-ltr"   "Ubuntu + QGIS (LTR channel)"
printf "    $(cyan '4')  %-18s %s\n" "deps-mssql" "Ubuntu + QGIS LTR + MS SQL ODBC driver $(yellow '⚠️  EULA')"
printf "    $(cyan '5')  %-18s %s\n" "oracle"     "QGIS Server compiled from source with Oracle support"
echo ""
printf "  Choice [1]: "
read -r stage_choice </dev/tty
stage_choice="${stage_choice:-1}"

case "$stage_choice" in
  1) stage="suite"      ;;
  2) stage="deps"       ;;
  3) stage="deps-ltr"   ;;
  4) stage="deps-mssql" ;;
  5) stage="oracle"     ;;
  *)
    echo ""
    echo "  $(red '❌ Invalid choice.')  Please run the wizard again."
    exit 1
    ;;
esac

hr

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — Tag name
# ─────────────────────────────────────────────────────────────────────────────
echo "$(bold 'STEP 2 — Choose a tag')"
echo ""
echo "  The tag is appended to the image name, e.g. $(cyan 'g3wsuite/g3w-suite:<tag>')."
echo "  Use $(cyan 'dev') for local development builds or a semver such as $(cyan 'v3.8.x') for"
echo "  release images."
echo ""
tag=$(prompt "Tag" "dev")
hr

# ─────────────────────────────────────────────────────────────────────────────
# STEP 3 — Stage-specific options
# ─────────────────────────────────────────────────────────────────────────────
extra_args=""

case "$stage" in

  # ── suite ─────────────────────────────────────────────────────────────────
  suite)
    echo "$(bold 'STEP 3 — G3W-SUITE branch')"
    echo ""
    echo "  The $(cyan 'G3W_SUITE_BRANCH') build argument controls which branch of"
    echo "  $(cyan 'https://github.com/g3w-suite/g3w-admin') is cloned inside the image."
    echo ""
    branch=$(prompt "G3W_SUITE_BRANCH" "dev")
    if [ "$branch" != "dev" ]; then
      extra_args="--build-arg G3W_SUITE_BRANCH=${branch}"
    fi
    ;;

  # ── deps / deps-ltr ───────────────────────────────────────────────────────
  deps)
    echo "$(bold 'STEP 3 — QGIS channel')"
    echo ""
    echo "  Choose the QGIS apt channel:"
    echo ""
    printf "    $(cyan '1')  ubuntu      Latest QGIS release\n"
    printf "    $(cyan '2')  ubuntu-ltr  Long-Term Release (LTR) $(green '← recommended')\n"
    echo ""
    printf "  Choice [1]: "
    read -r qgis_choice </dev/tty
    qgis_choice="${qgis_choice:-1}"
    case "$qgis_choice" in
      2) qgis_channel="ubuntu-ltr" ;;
      *) qgis_channel="ubuntu"     ;;
    esac
    extra_args="--build-arg QGIS_CHANNEL=${qgis_channel}"
    ;;

  deps-ltr)
    # deps-ltr always uses ubuntu-ltr — nothing more to ask
    echo "$(bold 'STEP 3 — No extra options')"
    echo ""
    echo "  The LTR deps image always uses the $(cyan 'ubuntu-ltr') QGIS channel."
    ;;

  # ── deps-mssql ────────────────────────────────────────────────────────────
  deps-mssql)
    echo "$(bold 'STEP 3 — Microsoft SQL Server ODBC driver')"
    echo ""
    echo "  $(yellow '⚠️  License notice:')"
    echo "  By enabling the MS SQL ODBC driver you accept the"
    echo "  $(cyan 'Microsoft END USER LICENSE AGREEMENT')."
    echo "  See: https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server"
    echo ""
    if prompt_yn "I accept the Microsoft EULA and want to install the ODBC driver"; then
      extra_args="--build-arg INSTALL_MSSQL=true"
    else
      echo ""
      echo "  $(red 'EULA not accepted — aborting.')"
      exit 1
    fi
    ;;

  # ── oracle ────────────────────────────────────────────────────────────────
  oracle)
    echo "$(bold 'STEP 3 — Oracle / QGIS build options')"
    echo ""
    echo "  The Oracle image compiles QGIS from source.  You need to specify:"
    echo ""
    echo "  • $(cyan 'QGIS_DEPS_TAG') — the qgis3-build-deps image tag to use as base"
    echo "    (e.g. $(cyan 'release-3_22'))"
    echo "  • $(cyan 'QGIS_TAG')      — the QGIS git tag to check out and compile"
    echo "    (e.g. $(cyan 'final-3_22_7'))"
    echo ""
    qgis_deps_tag=$(prompt "QGIS_DEPS_TAG" "release-3_22")
    qgis_tag=$(prompt "QGIS_TAG"      "final-3_22_7")
    extra_args="--build-arg DOCKER_DEPS_TAG=${qgis_deps_tag} --build-arg QGIS_TAG=${qgis_tag}"
    ;;

esac

hr

# ─────────────────────────────────────────────────────────────────────────────
# Resolve docker target and image name (mirrors Makefile logic)
# ─────────────────────────────────────────────────────────────────────────────
case "$stage" in
  suite)      docker_target="suite"        image="g3wsuite/g3w-suite"             ;;
  deps)       docker_target="deps"         image="g3wsuite/g3w-suite-deps"        ;;
  deps-ltr)   docker_target="deps"         image="g3wsuite/g3w-suite-deps-ltr"    ;;
  deps-mssql) docker_target="deps"         image="g3wsuite/g3w-suite-deps"        ;;
  oracle)     docker_target="qgis-oracle"  image="g3wsuite/g3w-suite-qgis-oracle" ;;
esac

full_image="${image}:${tag}"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 4 — Summary and confirmation
# ─────────────────────────────────────────────────────────────────────────────
echo "$(bold 'STEP 4 — Review and confirm')"
echo ""
echo "  The following command will be executed:"
echo ""
echo "  $(cyan "docker build --target ${docker_target} ${extra_args} -t ${full_image} --no-cache .")"
echo ""
echo "  $(bold 'Image name :') ${full_image}"
echo "  $(bold 'Stage      :') ${docker_target}"
[ -n "$extra_args" ] && echo "  $(bold 'Extra args :') ${extra_args}"
echo ""

if ! prompt_yn "$(bold '▶️  Start the build now?')" "Y"; then
  echo ""
  echo "  Aborted."
  exit 0
fi

hr

# ─────────────────────────────────────────────────────────────────────────────
# STEP 5 — Build
# ─────────────────────────────────────────────────────────────────────────────
echo "$(bold '🚀 Building image…')"
echo ""

# shellcheck disable=SC2086
docker build --target "${docker_target}" \
  ${extra_args} \
  -t "${full_image}" \
  --no-cache \
  .

echo ""
echo "$(green '✅ Image built successfully:') $(bold "${full_image}")"
echo ""
echo "  Run the container with:"
echo ""

case "$stage" in
  suite|deps|deps-ltr|deps-mssql)
    echo "  $(cyan "make reload")   (after setting the image in your .env)"
    ;;
  oracle)
    echo "  $(cyan "make run-oracle QGIS_TAG=${qgis_tag:-final-3_22_7}")"
    ;;
esac

echo ""