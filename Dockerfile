ARG PYTHON_VERSION=3.12

FROM python:$PYTHON_VERSION-slim AS build

ENV PYTHONUNBUFFERED=1

WORKDIR /code

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential curl unzip gcc python3-dev libpq-dev \
    && curl -L https://github.com/Gozargah/Marzban-scripts/raw/master/install_latest_xray.sh | bash \
    && rm -rf /var/lib/apt/lists/*

COPY ./requirements.txt /code/
RUN python3 -m pip install --upgrade pip setuptools \
    && pip install --no-cache-dir --upgrade -r /code/requirements.txt

FROM python:$PYTHON_VERSION-slim

ENV PYTHON_LIB_PATH=/usr/local/lib/python${PYTHON_VERSION%.*}/site-packages
WORKDIR /code

RUN rm -rf $PYTHON_LIB_PATH/*

COPY --from=build $PYTHON_LIB_PATH $PYTHON_LIB_PATH
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/share/xray /usr/local/share/xray

# Директории для данных (используем external DB для persistence в Choreo free tier)
RUN mkdir -p /var/lib/marzban /etc/marzban

COPY . /code

RUN ln -s /code/marzban-cli.py /usr/bin/marzban-cli \
    && chmod +x /usr/bin/marzban-cli \
    && marzban-cli completion install --shell bash

# Экспонирование портов: 8000 для панели, 443 для Xray (example inbound; адаптируйте под вашу конфигурацию)
EXPOSE 8000 443

# Environment variables по умолчанию (переопределите в Choreo environment variables или .env)
ENV UVICORN_HOST=0.0.0.0
ENV UVICORN_PORT=8000
ENV XRAY_EXECUTABLE_PATH=/usr/local/bin/xray
ENV XRAY_ASSETS_PATH=/usr/local/share/xray
# ENV SQLALCHEMY_DATABASE_URL=postgresql://your_user:your_pass@your_host:5432/your_db  # Укажите в Choreo secrets для external DB (например, Supabase PostgreSQL)
# ENV XRAY_JSON=/etc/marzban/xray_config.json
# ENV XRAY_SUBSCRIPTION_URL_PREFIX=https://your-choreo-domain

# Non-root user для Choreo security requirements (UID в диапазоне 10000-20000)
USER 10001

# Запуск: Миграции БД + запуск приложения (адаптировано для Uvicorn; env vars переопределим)
CMD ["bash", "-c", "alembic upgrade head; uvicorn app.main:app --host ${UVICORN_HOST} --port ${UVICORN_PORT}"]
