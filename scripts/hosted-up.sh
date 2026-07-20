#!/usr/bin/env bash
# Bring up the hosted stack (ComfyUI + Caddy [+ Cloudflare tunnel]).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

if [ ! -f .env ]; then
  echo "[info] No .env — copying .env.example"
  cp .env.example .env
  echo "[warn] Edit .env and set HOSTED_BASIC_HASH before exposing publicly."
fi

# shellcheck disable=SC1091
set -a
# shellcheck source=/dev/null
source .env
set +a

if [ -z "${HOSTED_BASIC_HASH:-}" ]; then
  echo "[warn] HOSTED_BASIC_HASH is empty — generating a temporary password..."
  TMP_PASS="$(openssl rand -base64 18 2>/dev/null || head -c 18 /dev/urandom | base64)"
  if command -v docker >/dev/null 2>&1; then
    HASH="$(docker run --rm caddy:2.9-alpine caddy hash-password --plaintext "${TMP_PASS}" 2>/dev/null || true)"
  else
    HASH=""
  fi
  if [ -n "${HASH}" ]; then
    if grep -q '^HOSTED_BASIC_HASH=' .env 2>/dev/null; then
      sed -i.bak "s|^HOSTED_BASIC_HASH=.*|HOSTED_BASIC_HASH=${HASH}|" .env
    else
      echo "HOSTED_BASIC_HASH=${HASH}" >> .env
    fi
    echo "[ok] Temporary basic-auth password (save now): ${TMP_PASS}"
    echo "[ok] User: ${HOSTED_BASIC_USER:-grok}"
  else
    echo "[error] Could not generate hash (need docker for caddy hash-password)."
    echo "        Run: docker run --rm caddy:2.9-alpine caddy hash-password --plaintext 'yourpass'"
    exit 1
  fi
  # re-source
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

mkdir -p hosted/caddy-data hosted/caddy-config

COMPOSE=(docker compose -f docker-compose.yml -f docker-compose.hosted.yml)

if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
  echo "[up] hosted stack + cloudflare tunnel profile"
  "${COMPOSE[@]}" --profile tunnel up -d --build "$@"
else
  echo "[up] hosted stack (caddy + comfyui)"
  "${COMPOSE[@]}" up -d --build "$@"
fi

echo
echo "=== Hosted stack starting ==="
echo "  Local proxy:  https://localhost  (or http://localhost:${HOSTED_HTTP_PORT:-80})"
echo "  Domain:       ${HOSTED_DOMAIN:-localhost}"
echo "  Auth user:    ${HOSTED_BASIC_USER:-grok}"
if [ -n "${CLOUDFLARE_TUNNEL_TOKEN:-}" ]; then
  echo "  Tunnel:       enabled (Cloudflare)"
fi
echo
echo "Logs: docker compose -f docker-compose.yml -f docker-compose.hosted.yml logs -f"
