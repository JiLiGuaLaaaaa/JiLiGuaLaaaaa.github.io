#!/usr/bin/env bash
set -Eeuo pipefail

umask 027

log() {
  printf '[blog-dynamic-docker] %s\n' "$*"
}

fail() {
  printf '[blog-dynamic-docker] ERROR: %s\n' "$*" >&2
  exit 1
}

if [ "$(id -u)" -ne 0 ]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  fi
  fail "Run this script as root or install sudo."
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SERVICE_NAME="${BLOG_DYNAMIC_SERVICE_NAME:-blog-dynamic}"
REPO_DIR="${BLOG_DYNAMIC_REPO_DIR:-/opt/blog-project}"
DATA_DIR="${BLOG_DYNAMIC_DATA_DIR:-/var/lib/blog-dynamic}"
ENV_FILE="${BLOG_DYNAMIC_ENV_FILE:-/etc/blog-dynamic.env}"
BIND_HOST="${BLOG_DYNAMIC_HOST:-0.0.0.0}"
BIND_PORT="${BLOG_DYNAMIC_PORT:-8787}"
CONTAINER_PORT="${BLOG_DYNAMIC_CONTAINER_PORT:-8787}"
DYNAMIC_DOMAIN="${BLOG_DYNAMIC_DOMAIN:-activity.20050619.xyz}"
BLOG_ORIGIN="${BLOG_DYNAMIC_BLOG_ORIGIN:-https://blog.20050619.xyz}"
PUBLIC_BASE_URL="${BLOG_DYNAMIC_PUBLIC_BASE_URL:-https://${DYNAMIC_DOMAIN}}"
ALLOWED_ORIGINS="${BLOG_DYNAMIC_ALLOWED_ORIGINS:-${BLOG_ORIGIN},http://localhost:4321}"
CONFIGURE_NGINX="${BLOG_DYNAMIC_CONFIGURE_NGINX:-1}"
GENERATE_PASSWORDS="${BLOG_DYNAMIC_GENERATE_PASSWORDS:-0}"
INSTALL_DOCKER="${BLOG_DYNAMIC_INSTALL_DOCKER:-1}"
NODE_IMAGE="${BLOG_DYNAMIC_NODE_IMAGE:-node:22-bookworm-slim}"

strip_url_host() {
  local value="$1"
  value="${value#http://}"
  value="${value#https://}"
  value="${value%%/*}"
  printf '%s' "$value"
}

read_existing_env() {
  local key="$1"
  [ -f "$ENV_FILE" ] || return 1
  awk -F= -v key="$key" '
    $1 == key {
      sub(/^[^=]*=/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      if ($0 ~ /^".*"$/) {
        sub(/^"/, "")
        sub(/"$/, "")
        gsub(/\\"/, "\"")
        gsub(/\\\\/, "\\")
      }
      print
      exit
    }
  ' "$ENV_FILE"
}

env_or_existing_or_default() {
  local key="$1"
  local fallback="$2"
  local env_value="${!key-}"
  local existing_value=""
  if [ -n "$env_value" ]; then
    printf '%s' "$env_value"
    return
  fi
  existing_value="$(read_existing_env "$key" || true)"
  if [ -n "$existing_value" ]; then
    printf '%s' "$existing_value"
    return
  fi
  printf '%s' "$fallback"
}

generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
    return
  fi
  od -An -N32 -tx1 /dev/urandom | tr -d ' \n'
  printf '\n'
}

secret_or_existing_or_generate() {
  local key="$1"
  local env_value="${!key-}"
  local existing_value=""

  if [ -n "$env_value" ]; then
    printf '%s' "$env_value"
    return
  fi

  existing_value="$(read_existing_env "$key" || true)"
  if [ -n "$existing_value" ]; then
    printf '%s' "$existing_value"
    return
  fi

  generate_secret
}

secret_or_existing_or_prompt() {
  local key="$1"
  local label="$2"
  local env_value="${!key-}"
  local existing_value=""
  local value=""

  if [ -n "$env_value" ]; then
    printf '%s' "$env_value"
    return
  fi

  existing_value="$(read_existing_env "$key" || true)"
  if [ -n "$existing_value" ]; then
    printf '%s' "$existing_value"
    return
  fi

  if [ "$GENERATE_PASSWORDS" = "1" ]; then
    generate_secret
    return
  fi

  if [ -t 0 ]; then
    read -r -s -p "$label: " value
    printf '\n' >&2
    [ -n "$value" ] || fail "$key cannot be empty."
    printf '%s' "$value"
    return
  fi

  fail "Set $key or run interactively. To generate one automatically, set BLOG_DYNAMIC_GENERATE_PASSWORDS=1."
}

write_env_line() {
  local key="$1"
  local value="$2"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '%s="%s"\n' "$key" "$value"
}

repair_apt_if_needed() {
  command -v apt-get >/dev/null 2>&1 || return 0
  export DEBIAN_FRONTEND=noninteractive
  if command -v dpkg >/dev/null 2>&1; then
    dpkg --configure -a || true
  fi
  apt-get -f install -y || true
}

install_packages() {
  [ "$#" -gt 0 ] || return 0
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    repair_apt_if_needed
    apt-get update
    apt-get install -y --no-install-recommends "$@"
    return
  fi
  if command -v dnf >/dev/null 2>&1; then
    dnf install -y "$@"
    return
  fi
  if command -v yum >/dev/null 2>&1; then
    yum install -y "$@"
    return
  fi
  if command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm "$@"
    return
  fi
  fail "No supported package manager found. Install missing packages manually: $*"
}

ensure_docker() {
  if [ "$INSTALL_DOCKER" != "1" ]; then
    command -v docker >/dev/null 2>&1 || fail "Docker is not installed."
    docker compose version >/dev/null 2>&1 || fail "Docker Compose plugin is not installed."
    return
  fi

  if ! command -v docker >/dev/null 2>&1; then
    log "Installing Docker."
    if command -v apt-get >/dev/null 2>&1; then
      install_packages docker.io
    elif command -v dnf >/dev/null 2>&1; then
      install_packages docker
    elif command -v yum >/dev/null 2>&1; then
      install_packages docker
    elif command -v pacman >/dev/null 2>&1; then
      install_packages docker
    fi
  fi

  if ! docker compose version >/dev/null 2>&1; then
    log "Installing Docker Compose plugin."
    if command -v apt-get >/dev/null 2>&1; then
      if apt-cache show docker-compose-plugin >/dev/null 2>&1; then
        install_packages docker-compose-plugin
      else
        install_packages docker-compose
      fi
    elif command -v dnf >/dev/null 2>&1; then
      install_packages docker-compose-plugin || true
      docker compose version >/dev/null 2>&1 || install_packages docker-compose
    elif command -v yum >/dev/null 2>&1; then
      install_packages docker-compose-plugin || true
      docker compose version >/dev/null 2>&1 || install_packages docker-compose
    elif command -v pacman >/dev/null 2>&1; then
      install_packages docker-compose
    fi
  fi

  command -v docker >/dev/null 2>&1 || fail "Docker installation failed."
  if ! docker compose version >/dev/null 2>&1; then
    command -v docker-compose >/dev/null 2>&1 || fail "Docker Compose installation failed."
  fi
}

ensure_prerequisites() {
  local packages=()
  command -v curl >/dev/null 2>&1 || packages+=("curl")
  command -v nginx >/dev/null 2>&1 || packages+=("nginx")
  if [ "${#packages[@]}" -gt 0 ]; then
    log "Installing missing packages: ${packages[*]}"
    install_packages "${packages[@]}"
  fi
  ensure_docker
}

ensure_dirs() {
  install -d -m 0755 "$REPO_DIR"
  install -d -m 0755 "$REPO_DIR/server"
  install -d -m 0750 "$DATA_DIR"
}

install_source() {
  [ -f "$SOURCE_ROOT/server/index.mjs" ] || fail "Cannot find server/index.mjs beside this script."
  [ -f "$SOURCE_ROOT/server/Dockerfile" ] || fail "Cannot find server/Dockerfile beside this script."
  [ -f "$SOURCE_ROOT/server/docker-compose.yml" ] || fail "Cannot find server/docker-compose.yml beside this script."
  install -m 0644 "$SOURCE_ROOT/server/index.mjs" "$REPO_DIR/server/index.mjs"
  install -m 0644 "$SOURCE_ROOT/server/Dockerfile" "$REPO_DIR/server/Dockerfile"
  install -m 0644 "$SOURCE_ROOT/server/docker-compose.yml" "$REPO_DIR/server/docker-compose.yml"
}

write_environment_file() {
  BIND_HOST="$(env_or_existing_or_default BLOG_DYNAMIC_HOST "$BIND_HOST")"
  BIND_PORT="$(env_or_existing_or_default BLOG_DYNAMIC_PORT "$BIND_PORT")"
  ALLOWED_ORIGINS="$(env_or_existing_or_default BLOG_DYNAMIC_ALLOWED_ORIGINS "$ALLOWED_ORIGINS")"
  DATA_DIR="$(env_or_existing_or_default BLOG_DYNAMIC_DATA_DIR "$DATA_DIR")"
  PUBLIC_BASE_URL="$(env_or_existing_or_default BLOG_DYNAMIC_PUBLIC_BASE_URL "$PUBLIC_BASE_URL")"

  local admin_token post_password diary_password temp_file
  admin_token="$(secret_or_existing_or_generate BLOG_DYNAMIC_ADMIN_TOKEN)"
  post_password="$(secret_or_existing_or_prompt BLOG_DYNAMIC_POST_PASSWORD "Dynamic publish password")"
  diary_password="$(secret_or_existing_or_prompt BLOG_DYNAMIC_DIARY_PASSWORD "Diary password")"

  temp_file="$(mktemp)"
  {
    write_env_line BLOG_DYNAMIC_HOST "$BIND_HOST"
    write_env_line BLOG_DYNAMIC_PORT "$CONTAINER_PORT"
    write_env_line BLOG_DYNAMIC_ALLOWED_ORIGINS "$ALLOWED_ORIGINS"
    write_env_line BLOG_DYNAMIC_ADMIN_TOKEN "$admin_token"
    write_env_line BLOG_DYNAMIC_POST_PASSWORD "$post_password"
    write_env_line BLOG_DYNAMIC_DIARY_PASSWORD "$diary_password"
    write_env_line BLOG_DYNAMIC_DATA_DIR "$DATA_DIR"
    write_env_line BLOG_DYNAMIC_NODE_IMAGE "$NODE_IMAGE"
    write_env_line BLOG_DYNAMIC_PUBLIC_BASE_URL "$PUBLIC_BASE_URL"
  } >"$temp_file"

  install -m 0600 -o root -g root "$temp_file" "$ENV_FILE"
  rm -f "$temp_file"
  DYNAMIC_DOMAIN="$(strip_url_host "$PUBLIC_BASE_URL")"
}

compose_cmd() {
  if docker compose version >/dev/null 2>&1; then
    docker compose "$@"
    return
  fi
  docker-compose "$@"
}

start_container() {
  systemctl enable --now docker >/dev/null 2>&1 || true
  cd "$REPO_DIR/server"
  export BLOG_DYNAMIC_NODE_IMAGE="$NODE_IMAGE"
  compose_cmd up -d --build
}

write_nginx_config() {
  [ "$CONFIGURE_NGINX" = "1" ] || return 0

  local server_name target link
  server_name="$(strip_url_host "${BLOG_DYNAMIC_NGINX_SERVER_NAME:-$DYNAMIC_DOMAIN}")"
  [ -n "$server_name" ] || fail "BLOG_DYNAMIC_DOMAIN cannot be empty when nginx is enabled."

  if [ -d /etc/nginx/sites-available ] && [ -d /etc/nginx/sites-enabled ]; then
    target="/etc/nginx/sites-available/${SERVICE_NAME}.conf"
    link="/etc/nginx/sites-enabled/${SERVICE_NAME}.conf"
  else
    install -d -m 0755 /etc/nginx/conf.d
    target="/etc/nginx/conf.d/${SERVICE_NAME}.conf"
    link=""
  fi

  cat >"$target" <<EOF
server {
    listen 80;
    server_name ${server_name};

    client_max_body_size 1m;

    location / {
        proxy_pass http://127.0.0.1:${BIND_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

  if [ -n "$link" ]; then
    ln -sfn "$target" "$link"
  fi

  nginx -t
  systemctl enable --now nginx >/dev/null 2>&1 || true
  systemctl reload nginx >/dev/null 2>&1 || true
}

verify_service() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "http://127.0.0.1:${BIND_PORT}/health" >/dev/null
  fi
}

main() {
  log "Preparing Docker deployment."
  ensure_prerequisites
  write_environment_file
  ensure_dirs
  install_source
  start_container
  write_nginx_config
  verify_service
  log "Dynamic service container is running locally on http://127.0.0.1:${BIND_PORT}"
  log "Public API base should be ${PUBLIC_BASE_URL}"
  log "Set GitHub Actions Variable PUBLIC_DYNAMIC_API_BASE to ${PUBLIC_BASE_URL}"
  log "Environment file: ${ENV_FILE}"
  log "Data directory: ${DATA_DIR}"
}

main "$@"
