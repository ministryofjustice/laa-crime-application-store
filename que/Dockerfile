FROM ruby:3.3.0-alpine3.19 AS base
LABEL maintainer="LAA crime forms team"

# TODO: still needed?
# temp fix to security issue in base image: ruby:3.2.2-alpine3.18
RUN apk update && apk upgrade --no-cache libcrypto3 libssl3

# dependencies required both at runtime and build time
RUN apk add --update \
  build-base \
  postgresql-dev \
  gcompat \
  tzdata

FROM base AS dependencies

# system dependencies required to build some gems
RUN apk add --update \
  git

COPY Gemfile Gemfile.lock .ruby-version ./

RUN bundle config set frozen 'true' && \
  bundle config set without test:development && \
  bundle config build.nokogiri --use-system-libraries && \
  bundle install --jobs 5 --retry 3

FROM base

# add non-root user and group with alpine first available uid, 1000

RUN addgroup -g 1000 -S appgroup && \
  adduser -u 1000 -S appuser -G appgroup

# create some required directories
RUN mkdir -p /usr/src/app && \
  mkdir -p /usr/src/app/log && \
  mkdir -p /usr/src/app/tmp && \
  mkdir -p /usr/src/app/tmp/pids

WORKDIR /usr/src/app

# copy over gems from the dependencies stage
COPY --from=dependencies /usr/local/bundle/ /usr/local/bundle/

# copy over the remaning files and code
COPY . .

# non-root user should own these directories
RUN chown -R appuser:appgroup /usr/src/app
RUN chown -R appuser:appgroup log tmp
RUN chmod +x run.sh

# Download RDS certificates bundle -- needed for SSL verification
# We set the path to the bundle in the ENV, and use it in `/config/database.yml`
#
ENV RDS_COMBINED_CA_BUNDLE /usr/src/app/config/rds-combined-ca-bundle.pem
ADD https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem $RDS_COMBINED_CA_BUNDLE
RUN chmod +r $RDS_COMBINED_CA_BUNDLE

# switch to non-root user
ENV APPUID 1000
USER $APPUID


ENTRYPOINT ["./run.sh"]
