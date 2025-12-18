#!/bin/bash

# ====== CONFIG ======
DOMAIN="example.com"
PROJECT_NAME="flutter_web"
FLUTTER_BUILD_PATH="$HOME/build/web"
NGINX_ROOT="/var/www/$PROJECT_NAME"
EMAIL="admin@example.com"
# ====================

set -e

echo "🚀 Deploy Flutter Web (SAFE MODE)"

# 1️⃣ Update
sudo apt update -y

# 2️⃣ Install Nginx فقط اگر نصب نیست
if ! command -v nginx &> /dev/null; then
  echo "📦 Installing Nginx"
  sudo apt install nginx -y
else
  echo "✅ Nginx already installed"
fi

sudo systemctl enable nginx
sudo systemctl start nginx

# 3️⃣ Install Certbot فقط اگر نصب نیست
if ! command -v certbot &> /dev/null; then
  echo "📦 Installing Certbot"
  sudo apt install certbot python3-certbot-nginx -y
else
  echo "✅ Certbot already installed"
fi

# 4️⃣ Create isolated web directory
sudo mkdir -p $NGINX_ROOT
sudo rm -rf $NGINX_ROOT/*
sudo cp -r $FLUTTER_BUILD_PATH/* $NGINX_ROOT

sudo chown -R www-data:www-data $NGINX_ROOT
sudo chmod -R 755 $NGINX_ROOT

# 5️⃣ Create Nginx config (بدون دست‌زدن به بقیه)
NGINX_CONF="/etc/nginx/sites-available/$PROJECT_NAME"

if [ ! -f "$NGINX_CONF" ]; then
  sudo tee $NGINX_CONF > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    root $NGINX_ROOT;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
else
  echo "⚠️ Nginx config already exists, skipping creation"
fi

# 6️⃣ Enable site (بدون حذف default یا سایت‌های دیگه)
sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/

# 7️⃣ Test & reload
sudo nginx -t
sudo systemctl reload nginx

# 8️⃣ SSL فقط برای همین دامنه
sudo certbot --nginx \
  -d $DOMAIN \
  --non-interactive \
  --agree-tos \
  -m $EMAIL \
  --redirect

sudo systemctl reload nginx

echo "✅ DONE!"
echo "🌐 https://$DOMAIN"
