#!/bin/bash

clear
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃     🧠 @admirkhen Chromiumx     ┃"
echo "┃     Browser Farm Script      ┃"
echo "┃     Powered by Saint Khen    ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

# Default values
NUM_CONTAINERS=1
MAX_CONTAINERS=10

# Ask how many browsers to run
read -p "🌐 How many Chromium browsers do you want to set up? [1-$MAX_CONTAINERS]: " NUM_CONTAINERS
NUM_CONTAINERS=${NUM_CONTAINERS:-1}
if [ "$NUM_CONTAINERS" -gt "$MAX_CONTAINERS" ]; then
  echo "❌ Max allowed is $MAX_CONTAINERS"
  exit 1
fi

# Ask password preference
echo "🔐 Password protection options:"
echo "1. Same password for all"
echo "2. Different passwords for each"
echo "3. No password"
read -p "Choose [1/2/3]: " PASS_CHOICE

# Prepare folders
rm -rf chromium_farm && mkdir -p chromium_farm/nginx/conf.d
cd chromium_farm
touch nginx/htpasswd

# Create docker-compose.yml
cat <<EOF > docker-compose.yml
version: "3"
services:
EOF

# Loop to create browser containers
for i in $(seq 1 "$NUM_CONTAINERS"); do
  # Find available port
  PORT=0
  BASE_PORT=$((3000 + i))
  while true; do
    ss -tuln | grep -q ":$BASE_PORT" || { PORT=$BASE_PORT; break; }
    BASE_PORT=$((BASE_PORT + 1))
  done

  USERNAME="user$i"
  CONTAINER_NAME="chromium_$i"
  VNC_PASS=""

  if [ "$PASS_CHOICE" = "1" ] && [ "$i" = "1" ]; then
    read -p "🔑 Enter the password for all users: " COMMON_PASS
  fi

  if [ "$PASS_CHOICE" = "1" ]; then
    VNC_PASS="$COMMON_PASS"
  elif [ "$PASS_CHOICE" = "2" ]; then
    read -p "🔑 Enter password for $USERNAME: " VNC_PASS
  fi

  # Add password to htpasswd if needed
  if [ "$PASS_CHOICE" != "3" ]; then
    htpasswd -bB nginx/htpasswd $USERNAME $VNC_PASS
  fi

  cat <<EOF >> docker-compose.yml
  $CONTAINER_NAME:
    image: browserless/chrome
    container_name: $CONTAINER_NAME
    ports:
      - "$PORT:5800"
    environment:
      - VNC_PASSWORD=$VNC_PASS
    restart: unless-stopped
EOF

done

# NGINX reverse proxy config
cat <<EOF > nginx/conf.d/chromium.conf
server {
    listen 80;
    server_name _;

EOF

for i in $(seq 1 "$NUM_CONTAINERS"); do
  USERNAME="user$i"
  PORT=$(docker-compose config | grep "chromium_$i" -A 5 | grep -oP '\d+(?=:5800)')

  cat <<EOL >> nginx/conf.d/chromium.conf
    location /$USERNAME/ {
        proxy_pass http://localhost:$PORT/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
EOL

  if [ "$PASS_CHOICE" != "3" ]; then
    echo "        auth_basic \"Restricted\";" >> nginx/conf.d/chromium.conf
    echo "        auth_basic_user_file /etc/nginx/.htpasswd;" >> nginx/conf.d/chromium.conf
  fi

  echo "    }" >> nginx/conf.d/chromium.conf
done

echo "}" >> nginx/conf.d/chromium.conf

# Add NGINX to docker-compose
cat <<EOF >> docker-compose.yml

  nginx:
    image: nginx:alpine
    container_name: nginx_proxy
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/htpasswd:/etc/nginx/.htpasswd
    ports:
      - "80:80"
    depends_on:
EOF

for i in $(seq 1 "$NUM_CONTAINERS"); do
  echo "      - chromium_$i" >> docker-compose.yml
done

echo "    restart: unless-stopped" >> docker-compose.yml

# Auto-start the farm
echo ""
echo "🚀 Starting your Chromium farm..."
docker-compose up -d

echo ""
echo "✅ All done!"
echo "🧪 Access each browser at: http://<your-ip>/user1/, /user2/, etc."
echo "🌐 Powered by Saint Khen (@admirkhen)"
