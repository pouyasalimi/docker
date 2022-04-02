FROM php:8.1-fpm

MAINTAINER PouyaSalimi <pouya.s@gmail.com>

ENV TZ=UTC
ARG NODE_VERSION=16

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    pkg-config \
    libssl-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    g++ \
    libicu-dev \
    libxml2-dev \
    git \
    curl \
    nano \
    htop \
    unzip \
    ffmpeg \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    zlib1g-dev \
    libmagickwand-dev --no-install-recommends \
    libzip-dev \
    libonig-dev \
    procps \
    locales \
    tesseract-ocr-fas \
    libmemcached-dev \
    supervisor \
    && curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-configure intl \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install intl \
    && docker-php-ext-install zip \
    && docker-php-ext-install soap \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install opcache \
    && docker-php-ext-install bcmath \
    && docker-php-ext-install pcntl \
    && docker-php-ext-install sockets \
    && pecl install apcu \
    && pecl install -o -f redis \
    && rm -rf /tmp/pear \
    && pecl install mongodb \
    && echo "extension=mongodb.so" > /usr/local/etc/php/conf.d/ext-mongodb.ini \
    && pecl install memcached \
    && echo "extension=memcached.so" > /usr/local/etc/php/conf.d/memcached.ini \
    && docker-php-ext-enable redis \
    && docker-php-ext-enable apcu \
    && docker-php-ext-install pdo \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install exif \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    && docker-php-ext-install fileinfo

COPY ./docker/runtimes/php/8.1/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./docker/runtimes/php/8.1/scheduler /var/run/scheduler
COPY ./composer.lock ./composer.json /var/www/html/

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && echo pt_BR.UTF-8 UTF-8 > /etc/locale.gen && locale-gen \
    && sed -i 's/www/www/g' /usr/local/etc/php-fpm.d/www.conf \
    && groupadd --force -g 1000 www \
    && useradd -ms /bin/bash --no-user-group -g www -u 1000 www

WORKDIR /var/www/html

COPY ./ /var/www/html
COPY --chown=www:www ./ /var/www/html

RUN chmod 777 /run && chmod gu+rw /var/run && chmod 775 /var/run/scheduler

USER www

EXPOSE 9000

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]