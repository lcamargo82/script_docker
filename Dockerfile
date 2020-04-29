FROM php:7.2-apache

RUN apt-get update

# 1. development packges
RUN apt-get install -y \
git \
zip \
curl \
sudo \
unzip \
libicu-dev \
libbz2-dev \
libpng-dev \
libjpeg-dev \
libmcrypt-dev \
libreadline-dev \
libfreetype6-dev \
nodejs npm \
g++

# 2. apache configs + documento root

#Começando com o próprio servidor da Web, a php-apacheimagem por padrão define a raiz do documento como /var/www/html. No entanto, como o laravel index.phpestá dentro /var/www/html/public, precisamos editar a configuração do apache e os sites disponíveis. Também habilitaremos mod_rewritea correspondência de URL e mod_headersa configuração de cabeçalhos de servidor da web.

ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# 3. mod_rewrite for URL rewrite and mod_headers for .htaccess extra headers like Access-Control-Allow-Origin-
RUN a2enmod rewrite headers

# 4. start with base php config, then add extensions
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

RUN docker-php-ext-install \
bz2 \
intl \
iconv \
bcmath \
opcache \
calendar \
mbstring \
pdo_mysql \
zip

# 5. composer

#Passando para a phpconfiguração, começamos usando o comprovado php.inie adicionamos algumas extensões via docker-php-ext-install. A ordem para executar essas tarefas não é importante ( php.ininão será substituída), pois as configurações que carregam cada extensão são mantidas em arquivos separados.
#Pois composer, o que estamos fazendo aqui é buscar o composerbinário localizado na imagem /usr/bin/composerda composer:latestjanela de encaixe. Obviamente, você pode especificar qualquer outra versão que desejar na tag, em vez de latest. Isso faz parte do recurso de criação em vários estágios do docker.

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 6. we need a user with the same UID/GID with host user
# so when we execute CLI commands, all the host file's owenership remains intact
# otherwise command from inside container will create root-owned files and directories

#As etapas finais são opcionais. Como vamos montar o código-fonte do aplicativo do host no contêiner para desenvolvimento, qualquer comando executado na CLI do contêiner não deve afetar a propriedade dos arquivos / pastas do host. Isso é útil para configurações e geradas por php artisan. Aqui estou usando ARGpara permitir que outros membros da equipe definam seus próprios uidque correspondam ao usuário host uid.

ARG uid
RUN useradd -G www-data,root -u $uid -d /home/devuser devuser
RUN mkdir -p /home/devuser/.composer && \
chown -R devuser:devuser /home/devuser
