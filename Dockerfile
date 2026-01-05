# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.3.6
FROM ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Instalacja zależności systemowych
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      curl \
      git \
      libpq-dev \
      libvips \
      libyaml-dev \
      pkg-config \
      postgresql-client && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ENV zmienne
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="test" \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3 \
    RAILS_ENV=development \
    RAILS_LOG_TO_STDOUT=true

# Kopiowanie Gemfile
COPY Gemfile Gemfile.lock ./

# Instalacja gemów
RUN bundle install && \
    rm -rf ~/.bundle "${BUNDLE_PATH}"/ruby/*/cache

# Kopiowanie całej aplikacji
COPY . .

# Upewnij się, że manifest.js istnieje
RUN mkdir -p app/assets/config && \
    if [ ! -f app/assets/config/manifest.js ]; then \
      echo '//= link_tree ../images' > app/assets/config/manifest.js && \
      echo '//= link_directory ../stylesheets .css' >> app/assets/config/manifest.js && \
      echo '//= link_directory ../javascripts .js' >> app/assets/config/manifest.js; \
    fi

# Tworzenie użytkownika i katalogów
RUN groupadd --system rails && \
    useradd --system --gid rails --home /rails --shell /bin/bash rails && \
    mkdir -p tmp/pids tmp/cache tmp/sockets log public/assets public/packs storage && \
    touch log/development.log && \
    chown -R rails:rails tmp log public storage

USER rails:rails

EXPOSE 3000

ENTRYPOINT ["/rails/bin/docker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]