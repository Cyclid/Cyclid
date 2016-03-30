Cyclid
======

# Getting started
```
$ rbenv install 2.3.0
$ bundle install --path vendor/bundle
$ bundle exec rake db:migrate
$ bundle exec test/db-loader.rb
```
Cyclid requires a Redis server for Sidekiq; you can either run a Redis server on your local machine or run `bundle exec rake redis` to start one.

You can start Cyclid under Webrick with `bundle exec rake rackup`, and then start Sidekiq with `bundle exec rake sidekiq`, or you can run both under Gaurd with `bundle exec rake guard`.

You can use curl or wget with HTTP Basic authentication, or the `test/hmac-test.rb` command for GET's using HMAC authentication.

# Testing

RSpec tests are included. Run `bundle exec rake spec` to run the tests and generate a coverage report into the `coverage` directory. The tests do not affect any databases and external API calls are mocked.

The Cyclid source code is also expected to pass Rubocop; run `bundle exec rake rubocop` to lint the code.

# Documentation

Cyclid uses YARD to generate documentation for both the Ruby API (internal Modules, Classes & Methods) and the REST API. Run `bundle exec rake doc` to generate both sets of documentation. The Ruby documentation is placed in the `doc/api` directory, and the REST API documentation is placed in the `doc/rest` directory.

## Test data

The `test/db-loader.rb` script creates two users ('admin' and 'test'), and two organizations ('admins' and 'test).

### Users

An admin (Super Admin) user is configured with the following attributes:

* Username: admin
* Email: admin@example.com
* Password: password
* Secret: aasecret55

A test user is configured with the following attributes:

* Username: test
* Email: test@example.com
* Password: aapassword55
* Secret: aasecret55

### Organizations

Two Organizations are created:

* admins
* test

The admin user is a member of admins, and the test user is a member of test.
