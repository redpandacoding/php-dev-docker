FROM centos:7
MAINTAINER 'Jordan Wamser <jwamser@redpandacoding.com>'
#ARG DEV='prod'
#ARG FPM_PORT=9000
#ENV APP_ENV=${DEV}

# build centos commands
RUN yum update -y && \
    yum install -y epel-release

# add remi repo bundles
RUN yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm && \
    yum install -y yum-utils && \
    yum-config-manager --enable remi-php72 && \
    yum -y update

### START INSTALL MSSQL ###
RUN curl https://packages.microsoft.com/config/rhel/7/prod.repo > /etc/yum.repos.d/mssql-release.repo

RUN ACCEPT_EULA=Y yum install -y msodbcsql unixODBC-devel
### FINISHED MSSQL INSTALL

### DEV > START INSTALL XDEBUG ###
RUN if [ "${APP_ENV}" != "prod" ]; then \
          yum install -y php-xdebug; \
       fi
### DEV > FINISH INSTALL XDEBUG ###

# install php and needed php modules && sqlsrv
RUN yum install -y php \
 php-zip \
 php-xml \
 php-cli \
 php-bcmath \
 php-dba \
 php-gd \
 php-intl \
 php-mbstring \
 php-mysql \
 php-pdo \
 php-soap \
 php-pecl-apcu \
 php-pecl-imagick \
 php-opcache \
 php-process \
 php-sqlsrv

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '544e09ee996cdf60ece3804abc52599c22b1f40f4323403c44d44fdfdd586475ca9813a858088ffbc1f233e9b180f061') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && mv composer-setup.php /usr/bin/composer \
    && php -r "unlink('composer-setup.php');"

RUN useradd -M -d /opt/app -s /bin/false nginx \
    && mkdir /opt/sites
RUN chown -R -v root:nginx /var/lib/php && chown -R -v root:nginx /opt/sites

#COPY ./php-fpm.conf /etc/php-fpm.conf
#COPY ./www.conf /etc/php-fpm.d/www.conf
COPY ./ini/. /etc/.

EXPOSE 80

RUN yum clean all

CMD ["php", "-v"]

#CMD php-fpm