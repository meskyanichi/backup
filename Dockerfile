FROM ruby:2.3.3

## 1. Image metadata ##

MAINTAINER Tom de Bruijn, tom@tomdebruijn.com
LABEL version="0.1.0" \
    description="Image for running the backup Rubygem"

## 2. Add operating system packages ##

# Dependencies for developing and running Backup
#  * The Nokogiri gem requires libxml2
#  * The unf_ext gem requires the g++ compiler to build
ENV APP_DEPS bsdtar ca-certificates curl g++ git \
    libxml2 libxslt1.1 libyaml-0-2 openssl \
    libldap2-dev ldap-utils \
    mongodb-clients \
    mysql-client-5.5 libmysqlclient-dev \
    percona-xtrabackup postgresql-client-9.4 redis-tools rsync \
    libsqlite3-dev sqlite3 sudo

RUN apt-get update && apt-get install -y --no-install-recommends $APP_DEPS

## 3. Add custom Linux user account ##

ENV APP_USER app
RUN useradd -d /home/$APP_USER -u 1001 -m $APP_USER && \
    adduser $APP_USER sudo && \
    echo "$APP_USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/app_user && \
    chown -R $APP_USER:$APP_USER /home/$APP_USER

## 4. Set up working directory ##

ENV APP_HOME /usr/src/backup
RUN mkdir $APP_HOME && chown -R $APP_USER:$APP_USER $APP_HOME
WORKDIR $APP_HOME
COPY lib/backup/version.rb $APP_HOME/lib/backup/
COPY backup.gemspec Gemfile* $APP_HOME/
RUN chown -R $APP_USER:$APP_USER $APP_HOME

## 5. Switch to custom user account ##

USER $APP_USER

## 6. Add Ruby gem packages ##

RUN bundle config build.nokogiri --use-system-libraries && bundle install && \
    rm -r $APP_HOME/lib/backup
