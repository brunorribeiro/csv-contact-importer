# ==========================
# Etapa 1: Build dos assets com Node
# ==========================
FROM node:18 AS build
WORKDIR /var/www

# Copiar arquivos de dependências
COPY package*.json ./

# Instalar dependências (inclui devDependencies, necessárias para vite/laravel-vite-plugin)
RUN npm install

# Copiar todo o projeto
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

# Copiar código-fonte do projeto + assets já compilados
COPY --from=build /var/www /var/www

# Instalar dependências PHP (sem dev)
RUN composer install --no-dev --optimize-autoloader

# Definir permissões para storage e bootstrap/cache
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage /var/www/bootstrap/cache

# Porta exposta pelo PHP-FPM
EXPOSE 9000

# Comando padrão (pode ser ajustado dependendo do setup nginx/php-fpm)
CMD ["php-fpm"]
