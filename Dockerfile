# ====================================================
# Dockerfile - Backend API (PHP + Apache + MySQL Client)
# Scrum Management App
# ====================================================

FROM php:8.2-apache

# Install dependensi sistem dan ekstensi PHP
RUN apt-get update && apt-get install -y \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd pdo pdo_mysql mysqli \
    && a2enmod rewrite headers \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Konfigurasi Apache - AllowOverride
RUN sed -i 's/AllowOverride None/AllowOverride All/g' /etc/apache2/apache2.conf

# Tambahkan konfigurasi CORS untuk REST API
RUN echo '<IfModule mod_headers.c>\n\
    Header set Access-Control-Allow-Origin "*"\n\
    Header set Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS"\n\
    Header set Access-Control-Allow-Headers "Content-Type, Authorization"\n\
</IfModule>' > /etc/apache2/conf-available/cors.conf \
    && a2enconf cors

# Copy source code backend
COPY project_ppl/ /var/www/html/project_ppl/

# Buat file .htaccess untuk clean URLs
RUN echo 'RewriteEngine On\nRewriteCond %{REQUEST_FILENAME} !-f\nRewriteCond %{REQUEST_FILENAME} !-d\nRewriteRule ^(.*)$ index.php [QSA,L]' \
    > /var/www/html/project_ppl/.htaccess

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost/project_ppl/get_projects.php || exit 1

EXPOSE 80

CMD ["apache2-foreground"]
