#!/usr/bin/env bash

WHITE='\033[1;37m'
NC='\033[0m'
GREEN='\033[1;32m'
RED='\033[1;31m'

UNAMEOUT="$(uname -s)"
# Verify operating system is supported...
case "${UNAMEOUT}" in
    Linux*)             MACHINE=linux;;
    Darwin*)            MACHINE=mac;;
    *)                  MACHINE="UNKNOWN"
esac

if [ "$MACHINE" == "UNKNOWN" ]; then
    echo "Unsupported operating system [$(uname -s)]. Laravel Sail supports macOS, Linux, and Windows (WSL2)." >&2

    exit 1
fi

cd "$(dirname "${BASH_SOURCE[0]}")" || exit

# Determine if Docker-compose is currently up...
PSRESULT="$(docker-compose ps -q)"

if docker-compose ps | grep 'Exit'; then
	echo -e "${WHITE}Shutting down old Docker processes...${NC}" >&2
	docker-compose down >/dev/null 2>&1
	EXEC="no"
elif [ -n "$PSRESULT" ]; then
	EXEC="yes"
else
	EXEC="no"
fi

# Function that outputs Docker is not running...
function docker_is_not_running() {
	echo -e "${WHITE}Docker is not running.${NC}" >&2
	echo "" >&2
	echo -e "${WHITE}You may run Docker using the following commands:${NC} './docker/app up' or './docker/app up -d'" >&2
	exit 1
}

#Function that run phpqa
function docker_php_qa() {
	if [ "$MACHINE" != 'Linux' ]; then
		echo "Unsupported operating system [$(uname -s)]. Laravel Docker supports macOS, Linux" >&2
		exit 1
	fi

	docker run --rm -i -v "$(pwd):/$DOCKER_BASE_NAME" -v "$(pwd)/storage/tmp-phpqa:/tmp" -w /$BASE_NAME jakzal/phpqa:php7.4-alpine "$@"
}

if [ $# -gt 0 ]; then

	#cp "./bin/pre-commit" .git/hooks/pre-commit
    #chmod 700 .git/hooks/pre-commit

	cp -f ".env.local" ".env"
	cp -f "../.env.local" "../.env"

	# Source the ".env" file so Laravel's environment variables are available...
	set -o allexport
	source ".env" && source "../.env"
	set +o allexport

	# Proxy PHP commands to the "php" binary on the application container...
	if [ "$1" == "php" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				-u www \
				"${DOCKER_BASE_NAME}-laravel" \
				php "$@"
		else
			docker_is_not_running
		fi

	# Proxy Composer commands to the "composer" binary on the application container...
	elif [ "$1" == "composer" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				-u www \
				"${DOCKER_BASE_NAME}-laravel" \
				composer "$@"
		else
			docker_is_not_running
		fi

	# Proxy Artisan commands to the "artisan" binary on the application container...
	elif [ "$1" == "artisan" ] || [ "$1" == "art" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				-u www \
				"${DOCKER_BASE_NAME}-laravel" \
				php artisan "$@"
		else
			docker_is_not_running
		fi

	# Proxy the "test" command to the "php artisan test" Artisan command...
	elif [ "$1" == "test" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				-u www \
				"${DOCKER_BASE_NAME}-laravel" \
				php artisan test "$@"
		else
			docker_is_not_running
		fi

	# Initiate a MySQL CLI terminal session within the "mysql" container...
	elif [ "$1" == "mariadb" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				"${DOCKER_BASE_NAME}-mariadb" \
				bash -c 'MYSQL_PWD=${MYSQL_PASSWORD} mysql -u ${MYSQL_USER} ${MYSQL_DATABASE}'
		else
			docker_is_not_running
		fi

	# Initiate a Bash shell within the application container...
	elif [ "$1" == "shell" ] || [ "$1" == "bash" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				-u www \
				"${DOCKER_BASE_NAME}-laravel" \
				bash
		else
			docker_is_not_running
		fi

	# Initiate a root user Bash shell within the application container...
	elif [ "$1" == "root-shell" ] || [ "$1" == "root-bash" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -it \
				-u root \
				"${DOCKER_BASE_NAME}-laravel" \
				bash
		else
			docker_is_not_running
		fi

	# Run laravel linter
	elif [ "$1" == "linter" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker exec -i \
				-u www \
				"${DOCKER_BASE_NAME}-laravel" \
				php artisan check:all #https://github.com/imanghafoori1/laravel-microscope
		else
			docker_is_not_running
		fi

	# Run Phpmetrics
	elif [ "$1" == "phpmetrics" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			docker_php_qa \
				phpmetrics \
				--report-html=./storage/tmp-phpqa/metrics \
				--exclude=vendor,tests,storage,public,docker,bootstrap \
				./
		else
			docker_is_not_running
		fi

	# Kill existing docker containers
	elif [ "$1" == "kill" ]; then
		shift 1

		if [ "$EXEC" == "yes" ]; then
			# shellcheck disable=SC2046
			docker kill $(docker ps -q)
		else
			docker_is_not_running
		fi
	else
		docker-compose --profile "${DOCKER_ENV}" "$@"
	fi
else
	docker-compose ps
fi
