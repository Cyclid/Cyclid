Cyclid
======
# Documentation

See http://docs.cyclid.io/en/latest/ for full documentation, including [installation instructions](http://docs.cyclid.io/en/latest/server.html#installation).

# Developement

Cyclid is an Open Source project and we welcome contributions. These instructions will help you get your development environment set up to develop & test Cyclid.

## Getting started
```
$ rbenv install 2.3.1
$ bundle install --path vendor/bundle
$ bundle exec rake db:migrate
$ CYCLID_CONFIG=config/development bundle exec bin/cyclid-db-init
```
Cyclid requires a Redis server for Sidekiq; you can either run a Redis server on your local machine or run `bundle exec rake redis` to start one.

You can start Cyclid under Webrick with `bundle exec rake rackup`, and then start Sidekiq with `bundle exec rake sidekiq`, or you can run both under Guard with `bundle exec rake guard`.

The Cyclid development server will run on localhost port 8361, which is the standard Cyclid API port.

`cyclid-db-init` will create sqlite3 database and the initial `admin` user and `admins` group. You'll need to make a note of the HMAC secret that is automatically generated & printed so that you can configure the Cyclid client to connect to your development server.

## Testing

RSpec tests are included. Run `bundle exec rake spec` to run the tests and generate a coverage report into the `coverage` directory. The tests do not affect any databases and external API calls are mocked.

The Cyclid source code is also expected to pass Rubocop; run `bundle exec rake rubocop` to lint the code.

## Documentation

Cyclid uses YARD to generate documentation for both the Ruby API (internal Modules, Classes & Methods) and the REST API. Run `bundle exec rake doc` to generate both sets of documentation. The Ruby documentation is placed in the `doc/api` directory, and the REST API documentation is placed in the `doc/rest` directory.

User documentation is hosted on [Read the Docs](https://readthedocs.org). The source can be found in the [Cyclid-docs](https://github.com/Cyclid/Cyclid-docs) repository.
