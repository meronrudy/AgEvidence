FROM ruby:3.4.10-slim AS base

WORKDIR /rails

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT=development:test

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libpq5 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

RUN SECRET_KEY_BASE_DUMMY=1 \
    DATABASE_URL=postgres://postgres:postgres@localhost:5432/agevidence \
    RAILS_ALLOWED_HOSTS=example.com \
    bundle exec rails assets:precompile

FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /rails /rails

EXPOSE 3000

ENTRYPOINT ["sh", "bin/docker-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
