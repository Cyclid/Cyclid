Cyclid
======

# Getting started
```
$ rbenv install 2.3.0
$ bundle install --path vendor/bundle
$ bundle exec rake db:migrate
$ bundle exec test/db-loader.rb
```
Then start Webrick with either `bundle exec rake rackup` or `bundle exec rake guard`.

You can use curl or wget with HTTP Basic authentication, or the `test/hmac-test.rb` command for GET's using HMAC authentication.

# Test data

The `test/db-loader.rb` script creates two users ('admin' and 'test'), and two organizations ('admins' and 'test).

## Test Users

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

## Test Organizations

Two Organizations are created:

* admins
* test

The admin user is a member of admins, and the test user is a member of test.
