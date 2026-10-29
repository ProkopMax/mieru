YOUR_BRIDGE_PASSWORD openssl rand -base64 24

docker compose up -d --build

docker exec mita-exit mita status
mita server status is "RUNNING"
