# Управление окружением проекта.
# Состав сервисов описан в docker-compose.yml, переменные подключения — в .env.

COMPOSE ?= docker compose

# Профиль аккаунта Claude нужен только цели claude-shell. Значение берётся из
# окружения, иначе из .env — экспорт не нужен: compose читает .env сам, а
# переменную окружения наследует и так. Остальным целям профиль безразличен:
# в docker-compose.yml у него есть безопасное значение по умолчанию.
CLAUDE_PROFILE ?= $(shell sed -n 's/^CLAUDE_PROFILE=//p' .env 2>/dev/null | tail -n 1)

.DEFAULT_GOAL := up
.PHONY: init up down restart logs claude-shell

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

# Вход в контейнер агента. Профиль обязателен именно здесь: он определяет, какой
# каталог аккаунта смонтируется в контейнер. Без проверки агент молча получил бы
# пустой профиль __no_profile__ из docker-compose.yml и потребовал бы новый вход.
# В белый список раннера цель не добавляется: она интерактивная и повесила бы его.
claude-shell:
	@test -n "$(CLAUDE_PROFILE)" || { \
		echo "Не задан CLAUDE_PROFILE — укажите профиль аккаунта:" >&2; \
		echo "  CLAUDE_PROFILE=<профиль> make claude-shell" >&2; \
		echo "или добавьте строку CLAUDE_PROFILE=<профиль> в .env" >&2; \
		exit 1; \
	}
	$(COMPOSE) --profile claude run --rm claude bash
