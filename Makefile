# Управление окружением проекта.
# Состав сервисов описан в docker-compose.yml, переменные подключения — в .env.

COMPOSE ?= docker compose

# compose интерполирует файл целиком, включая сервис claude, даже когда его профиль
# не поднимается. CLAUDE_PROFILE объявлен там обязательным, поэтому без значения
# падает любая цель, а не только запуск агента. Заглушка удовлетворяет проверку и
# до монтирования каталога аккаунта не доходит: цели этого Makefile сервис claude
# не запускают — для него профиль задаётся явно при вызове docker compose.
# Приоритет сохраняется: значение из окружения или из .env заглушкой не затирается.
CLAUDE_PROFILE ?= $(shell sed -n 's/^CLAUDE_PROFILE=//p' .env 2>/dev/null | tail -n 1)
ifeq ($(strip $(CLAUDE_PROFILE)),)
CLAUDE_PROFILE := _unset
endif
export CLAUDE_PROFILE

.DEFAULT_GOAL := up
.PHONY: init up down restart logs

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

# Логи всех сервисов окружения, включая завершившиеся контейнеры вроде arangodb-init.
# Без цвета и с ограничением хвоста: вывод уходит агенту через раннер целей.
logs:
	$(COMPOSE) logs --no-color --tail=200

# Перезапуск: последовательно down и up.
restart:
	$(MAKE) down
	$(MAKE) up
