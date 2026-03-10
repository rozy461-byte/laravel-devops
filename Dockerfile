# --- Stage 1: Dependencies ---
FROM composer:2.7 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

# --- Stage 2: Runtime ---
FROM php:8.4-fpm-alpine

# Arguments for UID/GID to match host user if needed
ARG user=laravel
ARG uid=1000

# Install system dependencies & PHP extensions for Postgres
RUN apk add --no-cache \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    curl \
    shadow

RUN docker-php-ext-install pdo_pgsql pgsql zip bcmath

# Copy Composer from the official image
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create a non-root system user
RUN useradd -G www-data,root -u $uid -d /home/$user $user
RUN mkdir -p /home/$user/.composer && \
    chown -R $user:$user /home/$user

# Set working directory
WORKDIR /var/www

# Copy application code
COPY . .
# Copy vendor from Stage 1
COPY --from=vendor /app/vendor ./vendor

# Set permissions for Laravel
RUN chown -R $user:www-data /var/www/storage /var/www/bootstrap/cache

# Switch to non-root user
# Install netcat (nc) so the entrypoint script can check the DB port
RUN apk add --no-cache netcat-openbsd

# Copy the entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh

# Make sure it's executable
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the working directory
WORKDIR /var/www

# Switch to our non-root user
USER $user

EXPOSE 9000

# ENTRYPOINT runs the script first
ENTRYPOINT ["entrypoint.sh"]

# CMD is passed as "$@" to the entrypoint script
CMD ["php-fpm"]
