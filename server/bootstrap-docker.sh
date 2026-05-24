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
BUILD_NODE_IMAGE="$NODE_IMAGE"
NGINX_CLIENT_MAX_BODY_SIZE="${BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE:-24m}"
NGINX_SSL_PROTOCOLS="${BLOG_DYNAMIC_NGINX_SSL_PROTOCOLS:-TLSv1.2 TLSv1.3}"
NGINX_SSL_ECDH_CURVE="${BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE:-}"
SSL_CERT_PATH="${BLOG_DYNAMIC_SSL_CERT_PATH:-}"
SSL_KEY_PATH="${BLOG_DYNAMIC_SSL_KEY_PATH:-}"
LETSENCRYPT_EMAIL="${BLOG_DYNAMIC_LETSENCRYPT_EMAIL:-}"
LETSENCRYPT_STAGING="${BLOG_DYNAMIC_LETSENCRYPT_STAGING:-0}"
AUTO_ISSUE_TLS="${BLOG_DYNAMIC_AUTO_ISSUE_TLS:-1}"
REQUIRE_SSL="${BLOG_DYNAMIC_REQUIRE_SSL:-1}"
ACME_WEBROOT="${BLOG_DYNAMIC_ACME_WEBROOT:-/var/www/blog-dynamic-acme}"
GENERATE_SELF_SIGNED_TLS="${BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS:-0}"
SELF_SIGNED_CERT_DIR="${BLOG_DYNAMIC_SELF_SIGNED_CERT_DIR:-/etc/blog-dynamic/tls}"
CLOUDFLARED_ENABLE="${BLOG_DYNAMIC_CLOUDFLARED_ENABLE:-0}"
CLOUDFLARED_TOKEN_FILE="${BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE:-/etc/blog-dynamic-cloudflared.token}"

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

resolve_build_base_image() {
  if docker image inspect "$NODE_IMAGE" >/dev/null 2>&1; then
    BUILD_NODE_IMAGE="$NODE_IMAGE"
    return
  fi

  if [ "$NODE_IMAGE" = "node:22-bookworm-slim" ] && docker image inspect blog-dynamic:local >/dev/null 2>&1; then
    docker image tag blog-dynamic:local blog-dynamic:base >/dev/null 2>&1 || true
    BUILD_NODE_IMAGE="blog-dynamic:base"
    log "Using local blog-dynamic:local image as build base because ${NODE_IMAGE} is not cached locally."
    return
  fi

  BUILD_NODE_IMAGE="$NODE_IMAGE"
}

resolve_ssl_paths() {
  local server_name="${1:-}"
  if [ -n "$SSL_CERT_PATH" ] || [ -n "$SSL_KEY_PATH" ]; then
    [ -n "$SSL_CERT_PATH" ] && [ -n "$SSL_KEY_PATH" ] || fail "Set both BLOG_DYNAMIC_SSL_CERT_PATH and BLOG_DYNAMIC_SSL_KEY_PATH."
    [ -f "$SSL_CERT_PATH" ] && [ -f "$SSL_KEY_PATH" ] || fail "Configured SSL certificate paths do not exist."
    return 0
  fi

  if [ -n "$server_name" ]; then
    local default_cert="/etc/letsencrypt/live/${server_name}/fullchain.pem"
    local default_key="/etc/letsencrypt/live/${server_name}/privkey.pem"
    if [ -f "$default_cert" ] && [ -f "$default_key" ]; then
      SSL_CERT_PATH="$default_cert"
      SSL_KEY_PATH="$default_key"
    fi
  fi
}

ensure_certbot() {
  if command -v certbot >/dev/null 2>&1; then
    return 0
  fi
  log "Installing certbot."
  install_packages certbot
}

ensure_tls_certificate() {
  local server_name="${1:-}"

  resolve_ssl_paths "$server_name"
  if [ -n "$SSL_CERT_PATH" ] && [ -n "$SSL_KEY_PATH" ] && [ -f "$SSL_CERT_PATH" ] && [ -f "$SSL_KEY_PATH" ]; then
    return 0
  fi

  [ "$AUTO_ISSUE_TLS" = "1" ] || {
    [ "$REQUIRE_SSL" = "1" ] && fail "No TLS certificate found for ${server_name}. Set BLOG_DYNAMIC_SSL_CERT_PATH/BLOG_DYNAMIC_SSL_KEY_PATH or BLOG_DYNAMIC_LETSENCRYPT_EMAIL."
    return 0
  }

  [ -n "$LETSENCRYPT_EMAIL" ] || {
    [ "$REQUIRE_SSL" = "1" ] && fail "No TLS certificate found for ${server_name}. Set BLOG_DYNAMIC_LETSENCRYPT_EMAIL or provide BLOG_DYNAMIC_SSL_CERT_PATH/BLOG_DYNAMIC_SSL_KEY_PATH."
    return 0
  }

  ensure_certbot
  install -d -m 0755 "$ACME_WEBROOT"

  local certbot_args=(
    certonly
    --webroot
    -w "$ACME_WEBROOT"
    -d "$server_name"
    --email "$LETSENCRYPT_EMAIL"
    --agree-tos
    --non-interactive
    --keep-until-expiring
    --rsa-key-size 4096
    --no-eff-email
  )
  if [ "$LETSENCRYPT_STAGING" = "1" ]; then
    certbot_args+=(--staging)
  fi

  log "Requesting TLS certificate for ${server_name}."
  certbot "${certbot_args[@]}"
  resolve_ssl_paths "$server_name"
  [ -n "$SSL_CERT_PATH" ] && [ -n "$SSL_KEY_PATH" ] && [ -f "$SSL_CERT_PATH" ] && [ -f "$SSL_KEY_PATH" ] || fail "TLS certificate request finished but the certificate files were not found."
}

ensure_self_signed_tls_certificate() {
  local server_name="${1:-}"
  [ "$GENERATE_SELF_SIGNED_TLS" = "1" ] || return 1

  command -v openssl >/dev/null 2>&1 || install_packages openssl
  install -d -m 0750 "$SELF_SIGNED_CERT_DIR"

  local cert_path key_path
  cert_path="${SELF_SIGNED_CERT_DIR}/${server_name}.crt"
  key_path="${SELF_SIGNED_CERT_DIR}/${server_name}.key"

  if [ ! -f "$cert_path" ] || [ ! -f "$key_path" ]; then
    log "Generating self-signed origin TLS certificate for ${server_name}."
    openssl req \
      -x509 \
      -newkey rsa:4096 \
      -sha256 \
      -days 825 \
      -nodes \
      -keyout "$key_path" \
      -out "$cert_path" \
      -subj "/CN=${server_name}" \
      -addext "subjectAltName=DNS:${server_name}" >/dev/null 2>&1
    chmod 0644 "$cert_path"
    chmod 0600 "$key_path"
  fi

  SSL_CERT_PATH="$cert_path"
  SSL_KEY_PATH="$key_path"
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

  copy_if_needed() {
    local source="$1"
    local target="$2"
    if [ -f "$target" ] && [ "$source" -ef "$target" ]; then
      return 0
    fi
    install -m 0644 "$source" "$target"
  }

  copy_if_needed "$SOURCE_ROOT/server/index.mjs" "$REPO_DIR/server/index.mjs"
  copy_if_needed "$SOURCE_ROOT/server/Dockerfile" "$REPO_DIR/server/Dockerfile"
  copy_if_needed "$SOURCE_ROOT/server/docker-compose.yml" "$REPO_DIR/server/docker-compose.yml"
}

write_environment_file() {
  BIND_HOST="$(env_or_existing_or_default BLOG_DYNAMIC_HOST "$BIND_HOST")"
  BIND_PORT="$(env_or_existing_or_default BLOG_DYNAMIC_PORT "$BIND_PORT")"
  ALLOWED_ORIGINS="$(env_or_existing_or_default BLOG_DYNAMIC_ALLOWED_ORIGINS "$ALLOWED_ORIGINS")"
  DATA_DIR="$(env_or_existing_or_default BLOG_DYNAMIC_DATA_DIR "$DATA_DIR")"
  PUBLIC_BASE_URL="$(env_or_existing_or_default BLOG_DYNAMIC_PUBLIC_BASE_URL "$PUBLIC_BASE_URL")"
  NGINX_CLIENT_MAX_BODY_SIZE="$(env_or_existing_or_default BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE "$NGINX_CLIENT_MAX_BODY_SIZE")"
  NGINX_SSL_PROTOCOLS="$(env_or_existing_or_default BLOG_DYNAMIC_NGINX_SSL_PROTOCOLS "$NGINX_SSL_PROTOCOLS")"
  NGINX_SSL_ECDH_CURVE="$(env_or_existing_or_default BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE "$NGINX_SSL_ECDH_CURVE")"
  ACME_WEBROOT="$(env_or_existing_or_default BLOG_DYNAMIC_ACME_WEBROOT "$ACME_WEBROOT")"
  LETSENCRYPT_EMAIL="$(env_or_existing_or_default BLOG_DYNAMIC_LETSENCRYPT_EMAIL "$LETSENCRYPT_EMAIL")"
  LETSENCRYPT_STAGING="$(env_or_existing_or_default BLOG_DYNAMIC_LETSENCRYPT_STAGING "$LETSENCRYPT_STAGING")"
  AUTO_ISSUE_TLS="$(env_or_existing_or_default BLOG_DYNAMIC_AUTO_ISSUE_TLS "$AUTO_ISSUE_TLS")"
  REQUIRE_SSL="$(env_or_existing_or_default BLOG_DYNAMIC_REQUIRE_SSL "$REQUIRE_SSL")"
  GENERATE_SELF_SIGNED_TLS="$(env_or_existing_or_default BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS "$GENERATE_SELF_SIGNED_TLS")"
  SELF_SIGNED_CERT_DIR="$(env_or_existing_or_default BLOG_DYNAMIC_SELF_SIGNED_CERT_DIR "$SELF_SIGNED_CERT_DIR")"
  SSL_CERT_PATH="$(env_or_existing_or_default BLOG_DYNAMIC_SSL_CERT_PATH "$SSL_CERT_PATH")"
  SSL_KEY_PATH="$(env_or_existing_or_default BLOG_DYNAMIC_SSL_KEY_PATH "$SSL_KEY_PATH")"
  CLOUDFLARED_ENABLE="$(env_or_existing_or_default BLOG_DYNAMIC_CLOUDFLARED_ENABLE "$CLOUDFLARED_ENABLE")"
  CLOUDFLARED_TOKEN_FILE="$(env_or_existing_or_default BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE "$CLOUDFLARED_TOKEN_FILE")"

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
    write_env_line BLOG_DYNAMIC_NGINX_CLIENT_MAX_BODY_SIZE "$NGINX_CLIENT_MAX_BODY_SIZE"
    write_env_line BLOG_DYNAMIC_NGINX_SSL_PROTOCOLS "$NGINX_SSL_PROTOCOLS"
    write_env_line BLOG_DYNAMIC_NGINX_SSL_ECDH_CURVE "$NGINX_SSL_ECDH_CURVE"
    write_env_line BLOG_DYNAMIC_ACME_WEBROOT "$ACME_WEBROOT"
    write_env_line BLOG_DYNAMIC_LETSENCRYPT_EMAIL "$LETSENCRYPT_EMAIL"
    write_env_line BLOG_DYNAMIC_LETSENCRYPT_STAGING "$LETSENCRYPT_STAGING"
    write_env_line BLOG_DYNAMIC_AUTO_ISSUE_TLS "$AUTO_ISSUE_TLS"
    write_env_line BLOG_DYNAMIC_REQUIRE_SSL "$REQUIRE_SSL"
    write_env_line BLOG_DYNAMIC_GENERATE_SELF_SIGNED_TLS "$GENERATE_SELF_SIGNED_TLS"
    write_env_line BLOG_DYNAMIC_SELF_SIGNED_CERT_DIR "$SELF_SIGNED_CERT_DIR"
    write_env_line BLOG_DYNAMIC_SSL_CERT_PATH "$SSL_CERT_PATH"
    write_env_line BLOG_DYNAMIC_SSL_KEY_PATH "$SSL_KEY_PATH"
    write_env_line BLOG_DYNAMIC_CLOUDFLARED_ENABLE "$CLOUDFLARED_ENABLE"
    write_env_line BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE "$CLOUDFLARED_TOKEN_FILE"
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

remove_stale_containers() {
  local ids=""
  compose_cmd down --remove-orphans >/dev/null 2>&1 || true

  ids="$(
    {
      docker ps -a --filter "name=${SERVICE_NAME}" --format "{{.ID}}" || true
      docker ps -a --filter "label=com.docker.compose.service=${SERVICE_NAME}" --format "{{.ID}}" || true
    } | sort -u
  )"

  if [ -n "$ids" ]; then
    log "Removing stale containers matching ${SERVICE_NAME}."
    while IFS= read -r container_id; do
      [ -n "$container_id" ] || continue
      docker rm -f "$container_id" >/dev/null 2>&1 || true
    done <<EOF
$ids
EOF
  fi
}

ensure_cloudflared_token_file() {
  [ "$CLOUDFLARED_ENABLE" = "1" ] || return 0
  [ -f "$CLOUDFLARED_TOKEN_FILE" ] || fail "Cloudflare Tunnel is enabled but ${CLOUDFLARED_TOKEN_FILE} does not exist."
  [ -s "$CLOUDFLARED_TOKEN_FILE" ] || fail "Cloudflare Tunnel token file is empty: ${CLOUDFLARED_TOKEN_FILE}."
  chmod 0600 "$CLOUDFLARED_TOKEN_FILE" 2>/dev/null || true
}

start_container() {
  local compose_args
  systemctl enable --now docker >/dev/null 2>&1 || true
  cd "$REPO_DIR/server"
  resolve_build_base_image
  ensure_cloudflared_token_file
  export BLOG_DYNAMIC_NODE_IMAGE="$BUILD_NODE_IMAGE"
  export BLOG_DYNAMIC_CLOUDFLARED_TOKEN_FILE="$CLOUDFLARED_TOKEN_FILE"

  if [ "$CLOUDFLARED_ENABLE" = "1" ]; then
    compose_args=(--profile tunnel up -d --build)
  else
    compose_args=(up -d --build)
  fi

  if compose_cmd "${compose_args[@]}"; then
    return
  fi

  log "Compose recreate failed; removing stale container and retrying."
  remove_stale_containers
  compose_cmd "${compose_args[@]}"
}

render_nginx_config() {
  local target="$1"
  local server_name="$2"
  local proxy_target="$3"
  local include_ssl="${4:-0}"

  cat >"$target" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${server_name};

    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE};

    location ^~ /.well-known/acme-challenge/ {
        root ${ACME_WEBROOT};
        default_type text/plain;
        try_files \$uri =404;
    }

    location / {
        proxy_pass http://${proxy_target};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

  if [ "$include_ssl" = "1" ]; then
    cat >>"$target" <<EOF

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    listen 2053 ssl http2;
    listen [::]:2053 ssl http2;
    listen 2083 ssl http2;
    listen [::]:2083 ssl http2;
    listen 2087 ssl http2;
    listen [::]:2087 ssl http2;
    listen 2096 ssl http2;
    listen [::]:2096 ssl http2;
    listen 8443 ssl http2;
    listen [::]:8443 ssl http2;
    server_name ${server_name};

    ssl_certificate ${SSL_CERT_PATH};
    ssl_certificate_key ${SSL_KEY_PATH};
    ssl_protocols ${NGINX_SSL_PROTOCOLS};
EOF
    if [ -n "$NGINX_SSL_ECDH_CURVE" ]; then
      cat >>"$target" <<EOF
    ssl_ecdh_curve ${NGINX_SSL_ECDH_CURVE};
EOF
    fi
    cat >>"$target" <<EOF
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE};

    location / {
        proxy_pass http://${proxy_target};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
  fi
}

write_nginx_config() {
  [ "$CONFIGURE_NGINX" = "1" ] || return 0

  local server_name target link proxy_target have_ssl
  server_name="$(strip_url_host "${BLOG_DYNAMIC_NGINX_SERVER_NAME:-$DYNAMIC_DOMAIN}")"
  [ -n "$server_name" ] || fail "BLOG_DYNAMIC_DOMAIN cannot be empty when nginx is enabled."
  proxy_target="127.0.0.1:${BIND_PORT}"
  resolve_ssl_paths "$server_name"

  if [ -d /etc/nginx/sites-available ] && [ -d /etc/nginx/sites-enabled ]; then
    target="/etc/nginx/sites-available/${SERVICE_NAME}.conf"
    link="/etc/nginx/sites-enabled/${SERVICE_NAME}.conf"
  else
    install -d -m 0755 /etc/nginx/conf.d
    target="/etc/nginx/conf.d/${SERVICE_NAME}.conf"
    link=""
  fi

  have_ssl=0
  if [ -n "$SSL_CERT_PATH" ] && [ -n "$SSL_KEY_PATH" ] && [ -f "$SSL_CERT_PATH" ] && [ -f "$SSL_KEY_PATH" ]; then
    have_ssl=1
  elif [ "$GENERATE_SELF_SIGNED_TLS" = "1" ]; then
    ensure_self_signed_tls_certificate "$server_name"
    have_ssl=1
  elif [ "$AUTO_ISSUE_TLS" = "1" ] && [ -n "$LETSENCRYPT_EMAIL" ]; then
    render_nginx_config "$target" "$server_name" "$proxy_target" 0
    if [ -n "$link" ]; then
      ln -sfn "$target" "$link"
    fi
    nginx -t
    systemctl enable --now nginx >/dev/null 2>&1 || true
    systemctl reload nginx >/dev/null 2>&1 || true
    ensure_tls_certificate "$server_name"
    have_ssl=1
  elif [ "$REQUIRE_SSL" = "1" ]; then
    fail "No TLS certificate found for ${server_name}. Set BLOG_DYNAMIC_LETSENCRYPT_EMAIL or BLOG_DYNAMIC_SSL_CERT_PATH/BLOG_DYNAMIC_SSL_KEY_PATH."
  fi

  render_nginx_config "$target" "$server_name" "$proxy_target" "$have_ssl"
  if [ -n "$link" ]; then
    ln -sfn "$target" "$link"
  fi

  nginx -t
  systemctl enable --now nginx >/dev/null 2>&1 || true
  systemctl reload nginx >/dev/null 2>&1 || true

  if [ "$have_ssl" = "1" ]; then
    log "HTTPS enabled for ${server_name} using ${SSL_CERT_PATH}."
  else
    log "No TLS certificate found for ${server_name}; writing HTTP-only nginx config."
  fi
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
  if [ "$CLOUDFLARED_ENABLE" = "1" ]; then
    log "Cloudflare Tunnel container is enabled and uses token file ${CLOUDFLARED_TOKEN_FILE}."
  fi
  log "Public API base should be ${PUBLIC_BASE_URL}"
  log "Set GitHub Actions Variable PUBLIC_DYNAMIC_API_BASE to ${PUBLIC_BASE_URL}"
  log "Environment file: ${ENV_FILE}"
  log "Data directory: ${DATA_DIR}"
}

main "$@"
