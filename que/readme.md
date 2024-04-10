## Que

We use Que to process async jobs. The main python web app adds a job to the que by creating a QueJob with a job_class and `args`.

The Que worker is run with `bundle exec que ./run.rb`
