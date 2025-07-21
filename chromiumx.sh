#!/usr/bin/env bash

echo ""
echo "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
echo "┃     🧠 @admirkhen Chromiumx     ┃"
echo "┃     Browser Farm Script      ┃"
echo "┃     Powered by Saint Khen    ┃"
echo "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
echo ""

# --- System Check ---
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  curl -fsSL https://get.docker.com | bash
  usermod -aG docker $USER
  echo "🔁 Please log out and back in or run: newgrp docker"
  exit
fi

if ! command -v docker-compose &> /dev/null; then
  echo "🔧 Installing Docker Compose..."
  curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

if ! command -v htpasswd &> /dev/null; then
  echo "🔑 Installing apache2-utils for password management..."
  apt update && apt install apache2-utils -y
fi

echo ""
read -p "🌐 How many Chromium browsers do you want to set up? [1-10]: " COUNT

if ! [[ "$COUNT" =~ ^[1-9]$|10 ]]; then
  echo "❌ Invalid input. Enter a number between 1 and 10."
  exit 1
fi

echo ""
echo "🔐 Password protection options:"
echo "1. Same password for all"
echo "2. Different passwords for each"
echo "3. No password"
read -p "Choose [1/2/3]: " PASS_OPTION

mkdir -p chromium_farm && cd chromium_farm
rm -f docker-compose.yml
rm -f .htpasswd

cat <<EOF > docker-compose.yml
services:
EOF

for i in $(seq 1 $COUNT); do
  USER="user$i"

  # Handle password logic
  if [ "$PASS_OPTION" == "1" ] && [ "$i" == "1" ]; then
    read -p "🔑 Enter a common password: " COMMON_PASS
    echo
  fi

  if [ "$PASS_OPTION" == "1" ]; then
    htpasswd -b -c .htpasswd $USER $COMMON_PASS
  elif [ "$PASS_OPTION" == "2" ]; then
    read -p "🔑 Enter password for $USER: " IND_PASS
    echo
    htpasswd -b -c .htpasswd $USER $IND_PASS
  fi

  cat <<EOF >> docker-compose.yml
  chromium_$i:
    image: browserless/chrome
    container_name: chromium_$i
    ports:
      - "$((3000 + i)):3000"
    restart: unless-stopped
EOF

done

# Add Nginx reverse proxy
cat <<EOF >> docker-compose.yml

  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "8085:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./htpasswd:/etc/nginx/.htpasswd:ro
    depends_on:
$(for i in $(seq 1 $COUNT); do echo "      - chromium_$i"; done)
    restart: unless-stopped
EOF

# NGINX config
cat <<EOF > nginx.conf
events {}
http {
    server {
        listen 8085;
        auth_basic "Restricted Access";
EOF

if [ "$PASS_OPTION" != "3" ]; then
  echo '        auth_basic_user_file /etc/nginx/.htpasswd;' >> nginx.conf
fi

for i in $(seq 1 $COUNT); do
  echo "        location /user$i/ {" >> nginx.conf
  echo "            proxy_pass http://chromium_$i:3000/;" >> nginx.conf
  echo "            proxy_set_header Host \$host;" >> nginx.conf
  echo "        }" >> nginx.conf
done

echo "    }" >> nginx.conf
echo "}" >> nginx.conf

# Rename password file if used
if [ "$PASS_OPTION" != "3" ]; then
  mv .htpasswd htpasswd
fi

echo ""
echo "🚀 Starting your Chromium farm..."
docker-compose up -d

echo ""
echo "✅ All done!"
for i in $(seq 1 $COUNT); do
  echo "🧪 Access: http://<your-ip>/user$i/"
done
echo "🌐 Powered by Saint Khen (@admirkhen)"
