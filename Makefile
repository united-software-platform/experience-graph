# Управление окружением проекта.
# Состав сервисов описан в docker-compose.yml, переменные подключения — в .env.

COMPOSE ?= docker compose

.DEFAULT_GOAL := up
.PHONY: init up down restart

# Первичная инициализация: каталоги данных, свежие образы, запуск сервисов.
# Каталоги создаются заранее — иначе их создаёт Docker от root и ArangoDB
# не получает прав на запись в том данных.
init:
	mkdir -p data/arangodb data/arangodb-apps data/arangodb-backups
	$(COMPOSE) pull
	$(COMPOSE) up -d

# Запуск сервисов окружения в фоне.
# Сервис claude вынесен в отдельный профиль и здесь не поднимается.
up:
	$(COMPOSE) up -d

# Остановка сервисов и удаление контейнеров; тома данных сохраняются.
down:
	$(COMPOSE) down

# Перезапуск: последовательно down и up.
restart:
	$(MAKE) down
	$(MAKE) up
