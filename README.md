# Как установить standalone версию Devprom

## Требования
1. Установленный [Docker](https://docs.docker.com/engine/install/)
2. Установленный Docker плагин [Compose](https://docs.docker.com/compose/install/)

Если вы используете Windows - рекомендуется устанавливать Docker в [WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

## Установка
Команда ниже создаст Volume со всеми необходимыми файлами Devprom ALM

```
docker compose -f standalone_compose.yml up build
```

После окончания процесса вы можете запустить сервис использую команду ниже

```
docker compose -f standalone_compose.yml up alm -d
```

Devprom будет доступен по ссылке http://127.0.0.1:80

## Остановка
```
docker compose -f standalone_compose.yml stop
```

## Удаление
```
docker compose -f standalone_compose.yml rm -f
docker volume rm docker_htdocs
```

## Как посмотреть логи
```
docker compose -f standalone_compose.yml logs alm -f
```