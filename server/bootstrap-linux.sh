#!/usr/bin/env bash
set -Eeuo pipefail

umask 027

log() {
  printf '[blog-dynamic] %s\n' "$*"
}

fail() {
  printf '[blog-dynamic] ERROR: %s\n' "$*" >&2
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
SERVICE_USER="${BLOG_DYNAMIC_SERVICE_USER:-blog}"
REPO_DIR="${BLOG_DYNAMIC_REPO_DIR:-/opt/blog-project}"
NODE_DIR="${BLOG_DYNAMIC_NODE_DIR:-/opt/blog-node}"
NODE_VERSION="${BLOG_DYNAMIC_NODE_VERSION:-22.11.0}"
DATA_DIR="${BLOG_DYNAMIC_DATA_DIR:-/var/lib/blog-dynamic}"
ENV_FILE="${BLOG_DYNAMIC_ENV_FILE:-/etc/blog-dynamic.env}"
BIND_HOST="${BLOG_DYNAMIC_HOST:-127.0.0.1}"
BIND_PORT="${BLOG_DYNAMIC_PORT:-8787}"
DYNAMIC_DOMAIN="${BLOG_DYNAMIC_DOMAIN:-activity.20050619.xyz}"
BLOG_ORIGIN="${BLOG_DYNAMIC_BLOG_ORIGIN:-https://blog.20050619.xyz}"
PUBLIC_BASE_URL="${BLOG_DYNAMIC_PUBLIC_BASE_URL:-https://${DYNAMIC_DOMAIN}}"
ALLOWED_ORIGINS="${BLOG_DYNAMIC_ALLOWED_ORIGINS:-${BLOG_ORIGIN},http://localhost:4321}"
CONFIGURE_NGINX="${BLOG_DYNAMIC_CONFIGURE_NGINX:-1}"
ENABLE_SERVICE="${BLOG_DYNAMIC_ENABLE_SERVICE:-1}"
GENERATE_PASSWORDS="${BLOG_DYNAMIC_GENERATE_PASSWORDS:-0}"
NGINX_CLIENT_MAX_BODY_SIZE="${BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE:-24m}"

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

node_arch() {
  case "$(uname -m)" in
    x86_64 | amd64)
      printf 'x64'
      ;;
    aarch64 | arm64)
      printf 'arm64'
      ;;
    armv7l)
      printf 'armv7l'
      ;;
    *)
      fail "Unsupported CPU architecture for portable Node.js: $(uname -m)"
      ;;
  esac
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

install_packages() {
  [ "$#" -gt 0 ] || return 0
  if command -v apt-get >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    if command -v dpkg >/dev/null 2>&1; then
      dpkg --configure -a || true
    fi
    apt-get -f install -y || true
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

ensure_node_runtime() {
  local node_bin node_major
  node_bin="${BLOG_DYNAMIC_NODE_BIN:-$(command -v node || true)}"
  if [ -n "$node_bin" ]; then
    node_major="$("$node_bin" -p "Number(process.versions.node.split('.')[0])" 2>/dev/null || printf '0')"
    if [ "$node_major" -ge 18 ]; then
      NODE_BIN="$node_bin"
      return
    fi
  fi

  if [ -x "${NODE_DIR}/bin/node" ]; then
    node_major="$("${NODE_DIR}/bin/node" -p "Number(process.versions.node.split('.')[0])" 2>/dev/null || printf '0')"
    if [ "$node_major" -ge 18 ]; then
      NODE_BIN="${NODE_DIR}/bin/node"
      return
    fi
  fi

  if command -v curl >/dev/null 2>&1; then
    local arch versioned_dir temp_archive
    arch="$(node_arch)"
    versioned_dir="${NODE_DIR}/node-v${NODE_VERSION}-linux-${arch}"
    temp_archive="/tmp/node-v${NODE_VERSION}-linux-${arch}.tar.xz"

    if [ ! -x "${versioned_dir}/bin/node" ]; then
      log "Installing portable Node.js ${NODE_VERSION} to ${NODE_DIR}."
      install -d -m 0755 "$NODE_DIR"
      if curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${arch}.tar.xz" -o "$temp_archive"; then
        if tar -xJf "$temp_archive" -C "$NODE_DIR"; then
          :
        fi
        rm -f "$temp_archive"
      fi
    fi

    if [ -x "${versioned_dir}/bin/node" ]; then
      node_major="$("${versioned_dir}/bin/node" -p "Number(process.versions.node.split('.')[0])" 2>/dev/null || printf '0')"
      if [ "$node_major" -ge 18 ]; then
        ln -sfn "$versioned_dir" "${NODE_DIR}/current"
        NODE_BIN="${versioned_dir}/bin/node"
        return
      fi
    fi
  fi

  if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y --no-install-recommends nodejs || true
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y nodejs || true
  elif command -v yum >/dev/null 2>&1; then
    yum install -y nodejs || true
  elif command -v pacman >/dev/null 2>&1; then
    pacman -Sy --noconfirm nodejs npm || true
  fi

  node_bin="${BLOG_DYNAMIC_NODE_BIN:-$(command -v node || true)}"
  if [ -n "$node_bin" ]; then
    node_major="$("$node_bin" -p "Number(process.versions.node.split('.')[0])" 2>/dev/null || printf '0')"
    if [ "$node_major" -ge 18 ]; then
      NODE_BIN="$node_bin"
      return
    fi
  fi

  fail "Node.js 18+ is required. Install Node.js manually and rerun this script."
}

ensure_prerequisites() {
  command -v systemctl >/dev/null 2>&1 || fail "systemd is required for this bootstrap script."

  local packages=()
  command -v curl >/dev/null 2>&1 || packages+=("curl")
  command -v nginx >/dev/null 2>&1 || packages+=("nginx")

  if [ "${#packages[@]}" -gt 0 ]; then
    log "Installing missing packages: ${packages[*]}"
    install_packages "${packages[@]}"
  fi

  ensure_node_runtime
}

ensure_user_and_dirs() {
  if ! id "$SERVICE_USER" >/dev/null 2>&1; then
    local nologin_shell
    nologin_shell="$(command -v nologin || printf '/usr/sbin/nologin')"
    useradd --system --home-dir "$DATA_DIR" --shell "$nologin_shell" "$SERVICE_USER"
  fi

  install -d -m 0755 "$REPO_DIR"
  install -d -m 0755 "$REPO_DIR/server"
  SERVICE_GROUP="$(id -gn "$SERVICE_USER")"
  install -d -m 0750 -o "$SERVICE_USER" -g "$SERVICE_GROUP" "$DATA_DIR"
}

install_source() {
  [ -f "$SOURCE_ROOT/server/index.mjs" ] || fail "Cannot find server/index.mjs beside this script."
  if [ ! -f "$REPO_DIR/server/index.mjs" ] || ! [ "$SOURCE_ROOT/server/index.mjs" -ef "$REPO_DIR/server/index.mjs" ]; then
    install -m 0644 "$SOURCE_ROOT/server/index.mjs" "$REPO_DIR/server/index.mjs"
  fi
}

write_environment_file() {
  BIND_HOST="$(env_or_existing_or_default BLOG_DYNAMIC_HOST "$BIND_HOST")"
  BIND_PORT="$(env_or_existing_or_default BLOG_DYNAMIC_PORT "$BIND_PORT")"
  ALLOWED_ORIGINS="$(env_or_existing_or_default BLOG_DYNAMIC_ALLOWED_ORIGINS "$ALLOWED_ORIGINS")"
  DATA_DIR="$(env_or_existing_or_default BLOG_DYNAMIC_DATA_DIR "$DATA_DIR")"
  PUBLIC_BASE_URL="$(env_or_existing_or_default BLOG_DYNAMIC_PUBLIC_BASE_URL "$PUBLIC_BASE_URL")"
  NGINX_CLIENT_MAX_BODY_SIZE="$(env_or_existing_or_default BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE "$NGINX_CLIENT_MAX_BODY_SIZE")"

  local admin_token post_password diary_password temp_file
  admin_token="$(secret_or_existing_or_generate BLOG_DYNAMIC_ADMIN_TOKEN)"
  post_password="$(secret_or_existing_or_prompt BLOG_DYNAMIC_POST_PASSWORD "Dynamic publish password")"
  diary_password="$(secret_or_existing_or_prompt BLOG_DYNAMIC_DIARY_PASSWORD "Diary password")"

  temp_file="$(mktemp)"
  {
    write_env_line BLOG_DYNAMIC_HOST "$BIND_HOST"
    write_env_line BLOG_DYNAMIC_PORT "$BIND_PORT"
    write_env_line BLOG_DYNAMIC_ALLOWED_ORIGINS "$ALLOWED_ORIGINS"
    write_env_line BLOG_DYNAMIC_ADMIN_TOKEN "$admin_token"
    write_env_line BLOG_DYNAMIC_POST_PASSWORD "$post_password"
    write_env_line BLOG_DYNAMIC_DIARY_PASSWORD "$diary_password"
    write_env_line BLOG_DYNAMIC_DATA_DIR "$DATA_DIR"
    write_env_line BLOG_DYNAMIC_PUBLIC_BASE_URL "$PUBLIC_BASE_URL"
    write_env_line BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE "$NGINX_CLIENT_MAX_BODY_SIZE"
  } >"$temp_file"

  install -m 0600 -o root -g root "$temp_file" "$ENV_FILE"
  rm -f "$temp_file"
  DYNAMIC_DOMAIN="$(strip_url_host "$PUBLIC_BASE_URL")"
}

write_systemd_unit() {
  local unit_file="/etc/systemd/system/${SERVICE_NAME}.service"
  cat >"$unit_file" <<EOF
[Unit]
Description=Blog Dynamic Service
After=network.target

[Service]
Type=simple
WorkingDirectory=${REPO_DIR}
EnvironmentFile=${ENV_FILE}
ExecStart=${NODE_BIN} ${REPO_DIR}/server/index.mjs
Restart=on-failure
RestartSec=5
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${DATA_DIR}

[Install]
WantedBy=multi-user.target
EOF
  chmod 0644 "$unit_file"
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

    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE};

    location / {
        proxy_pass http://${BIND_HOST}:${BIND_PORT};
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
}

restart_services() {
  systemctl daemon-reload
  if [ "$ENABLE_SERVICE" = "1" ]; then
    systemctl enable --now "$SERVICE_NAME"
    systemctl restart "$SERVICE_NAME"
  fi
  if [ "$CONFIGURE_NGINX" = "1" ]; then
    systemctl enable --now nginx
    systemctl reload nginx
  fi
}

verify_service() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsS "http://${BIND_HOST}:${BIND_PORT}/health" >/dev/null
  fi
}

main() {
  log "Preparing portable Linux deployment."
  ensure_prerequisites
  write_environment_file
  ensure_user_and_dirs
  install_source
  write_systemd_unit
  write_nginx_config
  restart_services
  verify_service
  log "Dynamic service is running locally on http://${BIND_HOST}:${BIND_PORT}"
  log "Public API base should be ${PUBLIC_BASE_URL}"
  log "Set GitHub Actions Variable PUBLIC_DYNAMIC_API_BASE to ${PUBLIC_BASE_URL}"
  log "Environment file: ${ENV_FILE}"
  log "Data directory: ${DATA_DIR}"
}

main "$@"
