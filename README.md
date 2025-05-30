# laa-crime-application-store

LAA Crime Application Store is a service to store and version crime applications from 'Submit a crime form'.

* Ruby version
ruby 3.3.6

* Rails version
rails 7.2+

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

When running locally you can switch off authentication for messages received from clients by providing the following env var:

```
AUTHENTICATION_REQUIRED=false
```

To authenticate messages sent by clients you will need to provide these env vars with values. The values can be retrieved from the relevant namespace's kubernetes secret, named `azure-secret`. *Do no use the production secret's values*

```sh
APP_CLIENT_ID=app-store-application-identifier
TENANT_ID=app-store-application-entra-tenant
```

*Note that it is possible to use the pre-production client and tenant IDs*

### Running tests

#### Unit tests

We use rspec for unit/integration testing. This can be run as below:

```shell
bundle exec rspec
```

#### Integration tests

We have Playwright-driven [end-to-end tests](https://github.com/ministryofjustice/nsm-e2e-test/pulls) that drive the submission
of applications to the app store from 'Submit a crime forms' and assessment of those applications via 'Assess a crime form'. These
tests run on all open PRs of both those services and this repository, as well as pre deployment to all three.

### Running linters

Rubocop can be run as below
```shell
bundle exec rubocop
```

### Metabase

An analytics database user/role is created in the application database which is granted limited permission to access views, not tables, on the database.

This user will be created if migrations are run via an enhancement added to the `db:migrate` task. Note that this will not run on branches because we use
`db:prepare` (which calls `db:schema:load` not `db:migrate`). The user can be created by explicitly calling the rake task `db:config_analytics_user` on a server.

The views are generated and maintained using the [scenic gem's](https://github.com/scenic-views/scenic) idiomatic location, `db/views`. UAT and production have Metabase database RDS instances plus a web UI available. The web UI is used to create database connections to the application/target database using the analytics user. The web UI can then use this connection to generate widgets that can be embedded in parts of the app.

See [Metabase setup for NSCC confluence document](https://dsdmoj.atlassian.net/wiki/x/XABEJAE) for more

### Deployment
The app store is deployed to Cloud Platform, in three different namespaces, one each for dev, UAT and production. Our K8s configuration does
not include an ingress. This is because all requests to the app store from 'Submit a crime form' and 'Assess a crime form' happen via internal
network requests that do not go via the public internet. Therefore they are routed directly to the service, which forwards requests on directly
to the application pods.

#### Security Context
We have a default [k8s security context ](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.30/#securitycontext-v1-core) defined in our _helpers.tpl template file. It sets the following:

- runAsNonRoot - Indicates that the container must run as a non-root user. If true, the Kubelet will validate the image at runtime to ensure that it does not run as UID 0 (root) and fail to start the container if it does. Currently defaults to true, this reduces attack surface
- allowPrivilegeEscalation - AllowPrivilegeEscalation controls whether a process can gain more privileges than its parent process. Currently defaults to false, this limits the level of access for bad actors/destructive processes
- seccompProfile.type - The Secure Computing Mode (Linux kernel feature that limits syscalls that processes can run) options to use by this container. Currenly defaults to RuntimeDefault which is the [widely accepted default profile](https://docs.docker.com/engine/security/seccomp/#significant-syscalls-blocked-by-the-default-profile)
- capabilities - The POSIX capabilities to add/drop when running containers. Currently defaults to drop["ALL"] which means all of these capabilities will be dropped - since this doesn't cause any issues, it's best to keep as is for security reasons until there's a need for change

### Debugging

By default, debugging isn't enabled. This can be changed by setting
`WEB_ENABLE_DEBUGGING=true` in your `.env.development.local` file and
restarting the application.

After doing so, you will be able to connect to the running application
in your editor of choice. If the default selected port is otherwise
occupied by some other service, then also set `WEB_DEBUG_PORT` to some
other value.

## Debugging production data
We are often asked to investigate the state of records in our production environment. To
make it safer to explore, we have a script that pulls an anonymised version (all PII removed) of a record
to UAT. To use it, run the following:

```
./bin/download_anonymised LAA-REFERENCE uat
```

(Note you can also download to your local machine by substituring "local" for "uat" in the above.)

You can then either open up the rails console to explore the data that way:

```
kubectl exec deploy/laa-crime-application-store-app -it -n laa-crime-application-store-uat -- bundle exec rails c
```

or access the record via the UAT caseworker UI (https://uat.assess-crime-forms.service.justice.gov.uk/).

When you are done, clear the record entirely with:

```
./bin/delete_anonymised LAA-REFERENCE uat
```

## Licence

This project is licensed under the [MIT License][mit].

[mit]: LICENCE

Useless code change
