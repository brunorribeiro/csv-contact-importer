# ==========================
# Etapa 1: Build dos assets com Node
# ==========================
FROM node:20 AS build
WORKDIR /var/www

# Copiar package.json e lockfile para instalar dependências
COPY package*.json ./

# Instalar dependências exatamente como no lockfile
RUN npm ci

# Copiar o resto do projeto
COPY . .

# Rodar build do Vite
RUN npm run build


# ==========================
# Etapa 2: Laravel com PHP-FPM
# ==========================
FROM php:8.2-fpm

WORKDIR /var/www

# Instalar dependências do sistema e extensões PHP
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpq-dev \
    libzip-dev \
    zip \
    && docker-php-ext-install pdo pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

# Instalar Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Copiar código do projeto e assets já buildados
COPY --from=build /var/www /var/www

# Instalar dependências PHP (sem dev)
RUN composer install --no-dev --optimize-autoloader

# Ajustar permissões
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Expor porta do PHP-FPM
EXPOSE 9000

CMD ["php-fpm"]
