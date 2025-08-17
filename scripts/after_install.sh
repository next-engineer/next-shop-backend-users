#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/myapp"
JAR_PATH="$APP_DIR/app.jar"

# CodeDeploy가 app.jar를 이미 복사했는지 확인
if [ ! -f "$JAR_PATH" ]; then
  echo "ERROR: app.jar not found in $APP_DIR"
  exit 1
fi

chown ec2-user:ec2-user "$JAR_PATH"
chmod 755 "$JAR_PATH"

# 환경파일이 이미 있는 경우, ec2-user가 읽을 수 있게만
if [ -f /etc/myapp.env ]; then
  chgrp ec2-user /etc/myapp.env || true
  chmod 640 /etc/myapp.env || true
fi

# 로그 디렉토리
mkdir -p "$APP_DIR/logs"
chown -R ec2-user:ec2-user "$APP_DIR"