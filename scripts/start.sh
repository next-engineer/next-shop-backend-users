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

# 실행권한 보장
chmod 755 "$JAR" || true

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