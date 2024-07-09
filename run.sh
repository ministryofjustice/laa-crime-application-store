#!/bin/sh
cd /usr/src/app

bundle exec bin/rails db:preparation:run_with_retry && bundle exec pumactl -F config/puma.rb start
