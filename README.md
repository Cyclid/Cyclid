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

# Test data

## Test User

The test user is configured with the following attributes:

* Username: test
* Email: test@example.com
* Password: aapassword55
* Secret: aasecret55