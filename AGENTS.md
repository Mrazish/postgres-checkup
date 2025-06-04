# AGENTS.md - AI Agent Instructions for postgres-checkup

## Описание

Данный документ содержит инструкции для работы ИИ агентов с инструментом postgres-checkup - системой глубокой диагностики PostgreSQL баз данных. postgres-checkup выявляет текущие и потенциальные проблемы производительности, масштабируемости и безопасности БД, предоставляя рекомендации по их устранению.

## Обзор системы

postgres-checkup - это диагностический инструмент для анализа состояния PostgreSQL базы данных. Он:

- Обнаруживает скрытые проблемы, которые могут проявиться в будущем
- Минимально воздействует на наблюдаемую систему
- Не требует установки на целевых серверах
- Создает JSON и Markdown отчеты
- Поддерживает анализ master-replica кластеров

## Системные требования

### Операционная система оператора
- Linux (RHEL/CentOS, Debian/Ubuntu)
- MacOS
- Windows (с ограничениями)

### Обязательные программы на машине оператора
- bash
- psql
- coreutils
- **jq >= 1.5 <= 1.6** (КРИТИЧНО!)
- golang >= 1.8
- awk
- sed

### Опциональные программы (для HTML/PDF отчетов)
- pandoc
- wkhtmltopdf >= 0.12.4

## Настройка окружения

### 1. Развертывание и запуск PostgreSQL

#### Вариант A: Docker (рекомендуется для тестирования)
```bash
# Создать docker-compose.yml или запустить контейнер напрямую
docker run -d \
  --name postgres-test \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:latest
```

#### Вариант B: Нативная установка
**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

**CentOS/RHEL:**
```bash
sudo yum install -y postgresql-server postgresql-contrib
sudo postgresql-setup initdb
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Создание расширения pg_stat_statements

⚠️ **ВАЖНО**: pg_stat_statements должен быть включен в shared_preload_libraries ПЕРЕД запуском PostgreSQL.

#### Для Docker:
```bash
# Остановить контейнер если запущен
docker stop postgres-test

# Запустить с необходимыми параметрами
docker run -d \
  --name postgres-test \
  -e POSTGRES_PASSWORD=postgres \
  -p 5432:5432 \
  -v postgres_data:/var/lib/postgresql/data \
  postgres:latest \
  -c "shared_preload_libraries='pg_stat_statements'" \
  -c "pg_stat_statements.max=10000" \
  -c "pg_stat_statements.track=all"

# Дождаться запуска БД
sleep 10

# Создать расширение
docker exec -it postgres-test psql -U postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
```

#### Для нативной установки:
```bash
# Отредактировать postgresql.conf
sudo nano /etc/postgresql/*/main/postgresql.conf
# Добавить или изменить:
# shared_preload_libraries = 'pg_stat_statements'
# pg_stat_statements.max = 10000
# pg_stat_statements.track = all

# Перезапустить PostgreSQL
sudo systemctl restart postgresql

# Создать расширение
sudo -u postgres psql -c "CREATE EXTENSION IF NOT EXISTS pg_stat_statements;"
```

#### Проверка установки pg_stat_statements:
```sql
-- Проверить что расширение загружено
SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements' AND installed_version IS NOT NULL;

-- Проверить что модуль в shared_preload_libraries
SELECT name, setting FROM pg_settings WHERE name = 'shared_preload_libraries';

-- Проверить работу
SELECT COUNT(*) FROM pg_stat_statements;
```

### 3. Создание пользователя БД и настройка доступа

#### Создание пользователя:
```sql
-- Подключиться как суперпользователь
sudo -u postgres psql

-- Создать пользователя для checkup
CREATE USER checkup_user WITH PASSWORD 'secure_password';

-- Предоставить необходимые права
GRANT CONNECT ON DATABASE postgres TO checkup_user;
GRANT USAGE ON SCHEMA public TO checkup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO checkup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA information_schema TO checkup_user;
GRANT SELECT ON ALL TABLES IN SCHEMA pg_catalog TO checkup_user;

-- Для доступа к статистике
GRANT pg_read_all_stats TO checkup_user;

-- Альтернативно, для полного доступа к мониторингу
ALTER USER checkup_user WITH SUPERUSER;
```

#### Настройка доступа в pg_hba.conf:
```bash
# Отредактировать pg_hba.conf
sudo nano /etc/postgresql/*/main/pg_hba.conf

# Добавить строки для локального и сетевого доступа:
# Локальный доступ через Unix socket
local   all             checkup_user                     md5

# Доступ по IP (замените IP на реальный)
host    all             checkup_user    127.0.0.1/32     md5
host    all             checkup_user    ::1/128          md5

# Для SSH доступа с удаленных машин
host    all             checkup_user    0.0.0.0/0        md5
```

#### Настройка postgresql.conf для сетевого доступа:
```bash
sudo nano /etc/postgresql/*/main/postgresql.conf

# Разрешить соединения
listen_addresses = '*'  # или конкретные IP
port = 5432

# Перезапустить PostgreSQL
sudo systemctl restart postgresql
```

### 4. Сборка pghrep

```bash
# Перейти в директорию postgres-checkup
cd postgres-checkup

# Собрать pghrep
cd ./pghrep
make install main
cd ..

# Проверить что pghrep собран
ls -la ./pghrep/bin/
```

### 5. Проверка версии jq

⚠️ **КРИТИЧНО**: jq должен быть версии 1.5-1.6, более новые версии НЕ поддерживаются!

```bash
# Проверить версию
jq --version

# Если версия > 1.6, установить правильную версию
# Ubuntu/Debian:
sudo apt-get remove jq
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
chmod +x jq-linux64
sudo mv jq-linux64 /usr/local/bin/jq

# Проверить что опция --argfile доступна (если нужна)
jq --help | grep argfile
```

### 6. Проверка подключения к БД

#### Через Unix socket:
```bash
# Тест подключения локально
psql -U checkup_user -d postgres -c "SELECT version();"

# Если требуется пароль
PGPASSWORD=secure_password psql -U checkup_user -d postgres -c "SELECT version();"
```

#### Через TCP/IP (127.0.0.1):
```bash
# Тест подключения по сети
psql -h 127.0.0.1 -p 5432 -U checkup_user -d postgres -c "SELECT version();"

# С паролем
PGPASSWORD=secure_password psql -h 127.0.0.1 -p 5432 -U checkup_user -d postgres -c "SELECT version();"
```

#### Через SSH (для удаленного доступа):
```bash
# Тест SSH подключения
ssh username@remote_host "psql -U checkup_user -d postgres -c 'SELECT version();'"
```

## Запуск тестов

### ⚠️ ВАЖНО: Использовать только команду `checkup`

**НЕ ИСПОЛЬЗОВАТЬ** `run_tests` - используйте только `checkup` с строковыми параметрами!

### Базовый запуск:
```bash
# Локальное подключение
./checkup -h localhost -p 5432 --username checkup_user --dbname postgres --project test_project -e 1

# Удаленное подключение
./checkup -h remote_host -p 5432 --username checkup_user --dbname postgres --project prod_project -e 1

# SSH подключение
./checkup --ssh-hostname remote_host --username checkup_user --dbname postgres --project prod_project -e 1
```

### Параметры команды checkup:
- `-h, --hostname` - хост для подключения
- `-p, --port` - порт PostgreSQL
- `--username` - имя пользователя БД
- `--dbname` - имя базы данных
- `--project` - имя проекта (для организации отчетов)
- `-e, --epoch` - номер эпохи (итерации проверки)
- `--ssh-hostname` - принудительное использование SSH
- `--pg-hostname` - принудительное использование psql

### Расширенный анализ (два снимка для K003):
```bash
DISTANCE="1800"  # 30 минут между снимками

# Первый снимок
./checkup -h localhost --username checkup_user --dbname postgres --project prod1 -e 1 --file resources/checks/K000_query_analysis.sh

# Ожидание
sleep "$DISTANCE"

# Второй снимок (полный анализ)
./checkup -h localhost --username checkup_user --dbname postgres --project prod1 -e 1
```

### Анализ кластера (master + replicas):
```bash
# Для каждого узла кластера
for host in master.local replica1.local replica2.local; do
  ./checkup -h "$host" --username checkup_user --dbname postgres --project cluster_prod -e 1
done
```

## Результаты и отчеты

После выполнения создаются директории:
```
./artifacts/project_name/json_reports/epoch_timestamp/
./artifacts/project_name/md_reports/epoch_timestamp/
```

Основной отчет: `./artifacts/project_name/md_reports/epoch_timestamp/Full_report.md`

## Использование с Docker

```bash
# Базовый запуск в Docker
docker run --rm \
  --name postgres-checkup \
  --env PGPASSWORD="secure_password" \
  --volume $(pwd)/artifacts:/artifacts \
  postgresai/postgres-checkup:latest \
  ./checkup \
  --hostname your_host \
  --port 5432 \
  --username checkup_user \
  --dbname postgres \
  --project docker_test \
  --epoch "$(date +'%Y%m%d')001"
```

## Типичные проблемы и решения

### 1. jq: Unknown option --argfile
- Обновить jq до версии 1.6 или понизить с версии 1.7+

### 2. Нет доступа к pg_stat_statements
- Проверить что модуль добавлен в shared_preload_libraries
- Перезапустить PostgreSQL
- Создать расширение: `CREATE EXTENSION pg_stat_statements;`

### 3. Ошибки подключения
- Проверить pg_hba.conf
- Проверить postgresql.conf (listen_addresses)
- Проверить пароль и права пользователя

### 4. SSH ошибки
- Настроить ключи SSH
- Проверить доступность хоста
- Использовать --pg-hostname для прямого подключения

## Архитектура отчетов

Каждый отчет содержит три секции:
1. **Observations** - автоматически собранные данные
2. **Conclusions** - выводы на понятном языке  
3. **Recommendations** - рекомендации по устранению проблем

## Режимы работы

- `collect` - только сбор данных
- `process` - только генерация отчетов
- `upload` - загрузка на платформу Postgres.ai
- `run` - сбор и обработка (по умолчанию)

## Примеры использования для ИИ агентов

### Автоматическая диагностика:
```bash
# Запуск полной диагностики
export PGPASSWORD="secure_password"
./checkup -h production_db --username checkup_user --dbname postgres --project auto_check -e $(date +%Y%m%d)

# Анализ результатов
cat ./artifacts/auto_check/md_reports/*/Full_report.md
```

### Мониторинг кластера:
```bash
# Скрипт для регулярного мониторинга
#!/bin/bash
HOSTS="master.db replica1.db replica2.db"
PROJECT="cluster_monitoring"
EPOCH=$(date +%Y%m%d_%H)

for host in $HOSTS; do
  ./checkup -h "$host" --username checkup_user --dbname postgres --project "$PROJECT" -e "$EPOCH"
done
```

Данный документ предоставляет полную инструкцию для настройки и использования postgres-checkup ИИ агентами.