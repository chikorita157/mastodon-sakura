# Setting up a dev environment

## Prerequisites

Mastodon development requires the following:

- Ruby 3.0
- Ruby gems:
  - `bundler`
  - `irb`
  - `foreman`
- NodeJS v18 (LTS)
- NPM packages:
  - `yarn`
- Postgres
- Redis

### macOS

First, make sure you have Homebrew installed. Follow the instructions at [brew.sh](https://brew.sh).

Run the following to install all necessary packages:
```
brew install ruby@3.0 foreman node yarn postgresql redis
```

Ruby 3.0 is **keg-only** by default. Follow the instructions in the **Caveat** to add it to your path.

### Linux

We will assume that you know how to locate the correct packages for your distro. That said, some distros package `bundler` and `irb` separately. Make sure that you also install these.

On Arch, you will need:
- `ruby`
- `ruby-bundler`
- `ruby-irb`
- `ruby-foreman`
- `redis`
- `postgresql`
- `yarn-berry`
- `gmp`
- `libidn`

### Windows

Unfortunately, none of the authors use Windows. Contributions welcome!

## Database

In the root of this repository, go through the following script:
```sh
# Create a folder for local data
mkdir -p data

# Set up a local database
pg_ctl -D data/postgres initdb -o '-U mastodon --auth-host=trust'

# Use the data/postgres folder for the DB connection unix socket
#
# If you don't know what that means, it's just a way for Mastodon to communicate
# with a database on the same machine efficiently.
#
# See: https://manpages.ubuntu.com/manpages/jammy/man7/unix.7.html
echo 'unix_socket_directories = .' >> data/postgres/postgresql.conf

# Start the database
pg_ctl -D data/postgres start --silent
```

To later connect to the DB, you can run:
```sh
psql -h localhost -U mastodon -d mastodon_dev
```

## Redis

In the root of this repository, run the following:
```sh
# Create a folder for redis data
mkdir -p data/redis

# Start Redis
redis-server ./redis-dev.conf

# [Optional] Stop Redis
# kill "$(cat ./data/redis/redis-dev.pid)"
```

## Ruby

```sh
export RAILS_ENV=development

# Bundle installs all Ruby gems globally by default, which might cause problems.
bundle config set --local path 'vendor/bundle'

# [Apple Silicon] If using macOS on Apple Silicon, run the following:
# bundle config build.idn-ruby -- --with-idn-dir="$(brew --prefix libidn)"

# Install dependencies using bundle (Ruby) and yarn (JS)
bundle install
yarn install

# Setup the database using the pre-defined Rake task
#
# Rake is a command runner for Ruby projects. The `bundle exec` ensures that
# we use the version of Rake that this project requires.
bundle exec rake db:setup

# [Optional] If that fails, run the following and try again:
# bundle exec rake db:reset
```

## Running Mastodon

1. Run `export RAILS_ENV=development NODE_ENV=development`.
    - Put these in your shell's .rc, or a script you can source if you want to skip this step in the future.
2. Run `bundle exec rake assets:precompile`.
    - If this explodes, complaining about `Hash`, you'll need to `export NODE_OPTIONS=--openssl-legacy-provider`.
    - After doing this, you will need to run `bundle exec rake assets:clobber` and then re-run `bundle exec rake assets:precompile`.
3. Run `foreman start`

# Updates/Troubleshooting

No known issues currently, somehow.

# Need Help?

If the above instructions don't work, please contact @rin.system on discord, or @tammy@social.treehouse.systems.


## Migrating back to glitch-soc

### DB Migrations

A DB Migration has been provided for your convenience to new mastodon-style quotes.
It **cannot** be performed live and requires the instance to be OFFLINE!

**WARNING**: Set `SKIP_POST_DEPLOYMENT_MIGRATIONS` to a non-empty value to skip dropping the legacy quote structure!
```sh
export SKIP_POST_DEPLOYMENT_MIGRATIONS=true
bundle exec rake db:migrate
```
