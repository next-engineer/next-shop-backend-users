#!/usr/bin/env bash
set -e

echo "[BeforeInstall] start"

APP_DIR="/opt/myapp"
SCRIPT_DIR="$APP_DIR/scripts"

# 디렉터리 보장
mkdir -p "$APP_DIR" "$SCRIPT_DIR"
chown -R ec2-user:ec2-user "$APP_DIR"

if ! command -v java >/dev/null 2>&1; then
  echo "[BeforeInstall] installing Amazon Corretto 17..."
  rpm --import https://yum.corretto.aws/corretto.key
  curl -fsSL -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
  yum install -y java-17-amazon-corretto-headless
fi

# 편의 툴(없으면 설치)
for pkg in unzip curl; do
  if ! command -v "$pkg" >/dev/null 2>&1; then
    echo "[BeforeInstall] installing $pkg..."
    if command -v dnf >/dev/null 2>&1; then dnf -y install "$pkg" || true
    elif command -v yum >/dev/null 2>&1; then yum -y install "$pkg" || true
    elif command -v apt-get >/dev/null 2>&1; then apt-get update -y && apt-get install -y "$pkg" || true
    fi
  fi
done

# (다음 단계에서 풀린 스크립트들이 실행 가능하도록) 일단 존재하면 권한 부여
chmod -R 755 "$SCRIPT_DIR" 2>/dev/null || true
echo "[BeforeInstall] done"