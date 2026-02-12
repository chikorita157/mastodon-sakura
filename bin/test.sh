#!/bin/bash

set -eux

export NODE_ENV=production
export RAILS_ENV=production

bundle exec rake assets:clobber
bundle exec rake assets:precompile

export RAILS_ENV=test
bundle exec rake spec
