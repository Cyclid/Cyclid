Cyclid
======
# Authentication
There are three authentication schemes currently supported:

1. HTTP Basic
2. HMAC request signing
3. API token

## HTTP Basic

HTTP Basic is self explanitory and works with any standard HTTP client (E.g. curl).

## HMAC

The HMAC scheme uses a shared secret (The `User.secret` data) to generate an HMAC from the request, with an optional nonce. The header format is:

```
Authorization: HMAC [user]:[hmac]
X-HMAC-Nonce: [nonce]
```

An HMAC capable client is implemented in `test/hmac-test.rb`

## API Token

The API token based scheme is wildly insecure as it is but might be extended in the future for use by simple non-sensitive clients which can't support HMAC signing (E.g. scripts which call `curl` or `wget`). The header format is:

```
Authorization: Token [user]:[token]
```
Currently, the 'token' is just the `User.secret` data sent in plain text (hence why it is wildely insecure!)

# Getting started
```
$ rbenv install 2.3.0
$ bundle install --path vendor/bundle
$ bundle exec rake db:migrate
$ bundle exec test/db-loader.rb
```
Then start Webrick with either `bundle exec rake rackup` or `bundle exec rake guard`.

You can use curl or wget with HTTP Basic authentication, or the `test/hmac-test.rb` command for GET's using HMAC authentication.

## Examples
```
$ curl -v -X GET -u admin http://localhost:9292/organizations
Enter host password for user 'admin':
*   Trying ::1...
* connect to ::1 port 9292 failed: Connection refused
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9292 (#0)
* Server auth using Basic with user 'admin'
> GET /organizations HTTP/1.1
> Host: localhost:9292
> Authorization: Basic YWRtaW46cGFzc3dvcmQ=
> User-Agent: curl/7.43.0
> Accept: */*
>
< HTTP/1.1 200 OK
< Content-Type: application/json
< Content-Length: 179
< X-Content-Type-Options: nosniff
< Server: WEBrick/1.3.1 (Ruby/2.0.0/2015-04-13)
< Date: Mon, 15 Feb 2016 17:23:47 GMT
< Connection: Keep-Alive
<
* Connection #0 to host localhost left intact
[{"id":1,"name":"admins","owner_email":"admins@example.com"},{"id":2,"name":"test","owner_email":"test@example.com"}]
```

```
$ bundle exec test/hmac-test.rb -u test -s aasecret55 /users/test
opening connection to localhost:9292...
opened
<- "GET /users/test HTTP/1.1\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nHost: localhost:9292\r\nAuthorization: HMAC test:9b4c32035b941ab8ef6ee336ea4f1dc669700402\r\nX-Hmac-Nonce: 81dbb2ab305c1175cc23138072f3f517\r\nDate: Mon, 15 Feb 2016 17:24:57 GMT\r\nConnection: close\r\n\r\n"
-> "HTTP/1.1 200 OK \r\n"
-> "Content-Type: application/json\r\n"
-> "Content-Length: 88\r\n"
-> "X-Content-Type-Options: nosniff\r\n"
-> "Server: WEBrick/1.3.1 (Ruby/2.0.0/2015-04-13)\r\n"
-> "Date: Mon, 15 Feb 2016 17:24:57 GMT\r\n"
-> "Connection: close\r\n"
-> "\r\n"
reading 88 bytes...
-> "{\"id\":2,\"username\":\"test\",\"email\":\"test@example.com\",\"organizations\":[\"test\"]}"
read 88 bytes
Conn close
{"id":2,"username":"test","email":"test@example.com","organizations":["test"]}
```

# Test data

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