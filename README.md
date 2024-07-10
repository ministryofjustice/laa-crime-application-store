# laa-crime-application-store

LAA Crime Application Store is a service to provide the ability to store and version crime applications from CRM forms.

* Ruby version
ruby 3.3.4

* Rails version
rails 7.1+

## Getting Started

Clone the repository, and follow these steps in order.
The instructions assume you have [Homebrew](https://brew.sh) installed in your machine, as well as use some ruby version manager, usually [rbenv](https://github.com/rbenv/rbenv). If not, please install all this first.

### Pre-requirements

* `brew bundle`
* `gem install bundler`
* `bundle install`

### Configuration

* Copy `.env.development` to `.env.development.local` and modify with suitable values for your local machine

```
# amend database username to use your local superuser role, typically your personal user
POSTGRES_USERNAME=joe.bloggs
=>
POSTGRES_USERNAME=john.smith
```

After you've defined your DB configuration in the above files, run the following:

* `bin/rails db:prepare` (for the development database)
* `RAILS_ENV=test bin/rails db:prepare` (for the test database)

### Run the app locally

Once all the above is done, you should be able to run the application as follows:

a) `bin/dev` - will run foreman, spawning a rails server and sidekiq worker
b) `rails server` - will only run the rails server, which is fine if you are not wanting to process background jobs.

### Authenticating Requests

When running locally you can switch of authentication for message sending to subscribers by providing the following env var:

```
AUTHENTICATION_REQUIRED=false
```

To authenticate messages sent to subscribers you will need to provide these env vars with values. The values can be retrieved from the relevant namespace's kubernetes secret, named `azure-secret`. *Do no use the production secret's values*

```sh
APP_CLIENT_ID=app-store-application-identifier
ENTRA_CLIENT_SECRET=app-store-application-secret
TENANT_ID=app-store-application-entra-tenant
```

*Note that it is possible to use the pre-production client and tenant IDs*

### Running tests

#### Unit tests

We use rspec for unit/integration testing. This can be run as below:

```shell
bundle exec rspec
```

#### API Tests

API testing can be performed using the Postman tooling. This can be downloaded from [the Postman website](https://www.postman.com/) and a free account created. Once this is done you can import the collections and environments found in the postman folder to begin testing. You will need to get a secret token from Entra ID from the Tenant and Application ID as setup above to be able to authenticate requests.

See [Postman Tests](postman/README.md) for more.

### Running linters

Rubocop can be run as below
```shell
bundle exec rubocop
```

### Metababase

An analytics database user/role is created in the application database which is granted limited permission to access views, not tables, on the database.

This user will be created if migrations are run via an enhancement added to the `db:migrate` task. Note that this will not run on branches because we use
`db:prepare` (which calls `db:schema:load` not `db:migrate`). The user can be created by explicitly calling the rake task `db:config_analytics_user` on a server.

The views are generated and maintained using the [scenic gem's](https://github.com/scenic-views/scenic) idiomatic location, `db/views`. UAT and production have Metabase database RDS instances plus a web UI available. The web UI is used to create database connections to the application/target database using the analytics user. The web UI can then use this connection to generate widgets that can be embedded in parts of the app.

See [Metabase setup for NSCC confluence document](https://dsdmoj.atlassian.net/wiki/x/XABEJAE) for more
