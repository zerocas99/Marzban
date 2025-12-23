FROM python:3.10-slim

# Установка зависимостей и Xray-core
RUN apt-get update && apt-get install -y curl wget unzip sqlite3 && \
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
    rm -rf /var/lib/apt/lists/*

# Рабочая директория
WORKDIR /app

# Копирование файлов проекта
COPY . .

# Установка Python-зависимостей
RUN pip install --no-cache-dir -r requirements.txt

# Создание директорий для persistent data (будет монтироваться)
RUN mkdir -p /var/lib/marzban /etc/marzban

# Экспонирование портов: 8000 для панели, добавьте порты Xray (например, 443 для inbound)
EXPOSE 8000 443

# Environment variables по умолчанию (переопределим в Choreo)
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8000
ENV XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
ENV XRAY_ASSETS_PATH=/usr/local/share/xray
ENV SQLALCHEMY_DATABASE_URL=sqlite:////var/lib/marzban/marzban.db
ENV SUDO_USERNAME=admin
ENV SUDO_PASSWORD=your_secure_password  # Измените!

# Запуск Marzban (с Xray интеграцией)
CMD ["uvicorn", "app.main:app", "--host", "\( {UVICORN_HOST}", "--port", " \){UVICORN_PORT}"]
