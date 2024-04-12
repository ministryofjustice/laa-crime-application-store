FROM ruby:3.3.0-alpine3.19 AS base
LABEL maintainer="Non-standard magistrates' court payment team"

RUN apk update && apk upgrade --no-cache libcrypto3 libssl3 openssl g++ gcc libxslt-dev libxml2

# dependencies required both at runtime and build time
RUN apk add --update \
  build-base \
  postgresql-dev \
  gcompat \
  tzdata \
  yarn

FROM base AS dependencies

# system dependencies required to build some gems
RUN apk add --update \
  git

COPY Gemfile Gemfile.lock .ruby-version ./

RUN bundle config set frozen 'true' && \
  bundle config set without test:development && \
  bundle install --jobs 5 --retry 3

RUN yarn install --frozen-lockfile --ignore-scripts

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
RUN chown -R appuser:appgroup log tmp db
RUN chmod +x run.sh

# Download RDS certificates bundle -- needed for SSL verification
# We set the path to the bundle in the ENV, and use it in `/config/database.yml`
#
ENV RDS_COMBINED_CA_BUNDLE /usr/src/app/config/rds-combined-ca-bundle.pem
ADD https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem $RDS_COMBINED_CA_BUNDLE
RUN chmod +r $RDS_COMBINED_CA_BUNDLE

ARG APP_BRANCH_NAME
ENV APP_BRANCH_NAME ${APP_BRANCH_NAME}

ARG APP_BUILD_DATE
ENV APP_BUILD_DATE ${APP_BUILD_DATE}

ARG APP_BUILD_TAG
ENV APP_BUILD_TAG ${APP_BUILD_TAG}

ARG APP_GIT_COMMIT
ENV APP_GIT_COMMIT ${APP_GIT_COMMIT}

# switch to non-root user
ENV APPUID 1000
USER $APPUID

ENV PORT 3000
EXPOSE $PORT

ENTRYPOINT ["./run.sh"]
