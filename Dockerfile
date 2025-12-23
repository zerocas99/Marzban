FROM python:3.12-slim

# Установка зависимостей, Xray и ассетов
RUN apt-get update && apt-get install -y curl wget unzip sqlite3 && \
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
    mkdir -p /usr/local/share/xray && \
    curl -L https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o /usr/local/share/xray/geoip.dat && \
    curl -L https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o /usr/local/share/xray/geosite.dat && \
    rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копирование файлов проекта
COPY . .

# Установка Python-зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Директории для данных (используем external DB для persistence в Choreo free tier)
RUN mkdir -p /var/lib/marzban /etc/marzban

# Экспонирование портов: 8000 для панели, 443 для Xray (example inbound; адаптируйте под вашу конфигурацию)
EXPOSE 8000 443

# Environment variables по умолчанию (переопределите в Choreo environment variables или .env)
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8000
ENV XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
ENV XRAY_ASSETS_PATH=/usr/local/share/xray
# ENV SQLALCHEMY_DATABASE_URL=mysql://your_user:your_pass@your_host/your_db  # Укажите в Choreo secrets для external DB
# ENV XRAY_JSON=/etc/marzban/xray_config.json
# ENV XRAY_SUBSCRIPTION_URL_PREFIX=https://your-choreo-domain

# Запуск Marzban с Uvicorn (env vars можно переопределить при запуске)
CMD ["uvicorn", "app.main:app", "--host", "\( {UVICORN_HOST}", "--port", " \){UVICORN_PORT}"]
