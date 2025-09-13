#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/myapp"
JAR="$APP_DIR/app.jar"
LOG="$APP_DIR/app.out"
PORT="${SERVER_PORT:-8080}"

echo "[START] launching app.jar (no systemd)"



# 이전 프로세스 종료(있으면)
if pgrep -f "$JAR" >/dev/null 2>&1; then
  echo "[START] stopping previous app.jar..."
  pkill -f "$JAR" || true
  sleep 2
fi

# 환경파일 로드(있을 때만)
if [ -f /etc/myapp.env ]; then
  echo "[START] loading /etc/myapp.env"
  set -a; . /etc/myapp.env; set +a
  PORT="${SERVER_PORT:-$PORT}"
fi

# --- SSM Parameter Store에서 비어있는 값 보강 ---
fetch_ssm_param() {
  local name="$1"
  aws ssm get-parameter --name "$name" --with-decryption \
    --query 'Parameter.Value' --output text 2>/dev/null
}

# 너가 만든 파라미터 경로에 맞게 매핑
declare -A SSM_KEYS=(
  [SPRING_DATASOURCE_URL]="/nextshop/user/db/url"
  [SPRING_DATASOURCE_USERNAME]="/nextshop/user/db/username"
  [SPRING_DATASOURCE_PASSWORD]="/nextshop/user/db/password"  # SecureString 권장
  [JWT_SECRET]="/nextshop/user/jwt_secret"                    # SecureString 권장
)

for VAR in "${!SSM_KEYS[@]}"; do
  if [[ -z "${!VAR:-}" ]]; then
    VAL="$(fetch_ssm_param "${SSM_KEYS[$VAR]}")" || true
    if [[ -n "$VAL" && "$VAL" != "None" ]]; then
      export "$VAR=$VAL"
      echo "[SSM] loaded $VAR from ${SSM_KEYS[$VAR]}"
    else
      echo "[SSM] $VAR not found at ${SSM_KEYS[$VAR]} (skip)"
    fi
  fi
done
# --- end SSM 보강 ---

# 실행권한 보장
chmod 755 "$JAR" || true

cd "$APP_DIR"

# 백그라운드 실행
echo "[START] nohup java -jar ..."
nohup /usr/bin/java \
  -Dserver.port="${PORT}" \
  ${SPRING_PROFILES_ACTIVE:+-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}} \
  ${SPRING_DATASOURCE_URL:+-Dspring.datasource.url="${SPRING_DATASOURCE_URL}"} \
  ${SPRING_DATASOURCE_USERNAME:+-Dspring.datasource.username="${SPRING_DATASOURCE_USERNAME}"} \
  ${SPRING_DATASOURCE_PASSWORD:+-Dspring.datasource.password="${SPRING_DATASOURCE_PASSWORD}"} \
  -jar "$JAR" > "$LOG" 2>&1 &

# 포트 헬스체크(최대 60초)
echo "[HC] waiting for :${PORT}"
for i in $(seq 1 60); do
  if ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${PORT}$"; then
    echo "[HC] listening on ${PORT} (ok)"
    exit 0
  fi
  echo "[HC] not ready ... ${i}/60"
  sleep 1
done

echo "[HC] still not listening after 60s"
echo "[HC] last 100 lines of log:"
tail -n 100 "$LOG" || true
exit 1