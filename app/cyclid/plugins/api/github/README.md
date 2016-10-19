Github API plugin
---

This is the Github API plugin for Cyclid. It adds API end points which support Github OAuth authentication and webhook events:

| Verb | Path | Notes |
| --- | --- | --- |
| **GET** | / |Github webhook callback. |
| **GET** | /oauth/request | Start the OAuth authorization process. |
| **GET** | /oauth/callback | The OUth authorization calback. |

# OAuth

Initiate the Github OAuth "Web" flow with a GET to the /oauth/request endpoint. This will cause a redirect to Github where the user can authorise the OAuth request.

When the request has been authorised the user will be redirected back to the /oauth/callback endpoint, which in turn will then redirect to the Cyclid UI.

# Server Configuration

The server-side configuration for this plugin is:

```
    github:
      client_id: <Github OAuth client ID>
      client_secret: <Github OAuth client secret>
      api_url: <This API>
      ui_url: <Cyclid UI instance attached to this API>
```
The `client_id` and `client_secret` can be obtained from Github when you [register Cyclid as an application](https://github.com/settings/applications/new) and should be provided here to enable OAuth authorization flow.

The `api_url` should be the publically resolvable name of the Cyclid API server, and the `ui_url` should be the publically resolvable name of a Cyclid UI server which is configured to use the API server. These URLs are both used to generate appropriate redirects during the OAuth authorization process.

Note that the `api_url` provided must match the "Authorization callback URL" setting you provide to Github when you register Cyclid as an application; this includes both the scheme (http: or https:) and any port number (Cyclid by default uses port 8361). So for example:

```
api_url: https://cyclid.example.com:8361
```

# Plugin configuration

The per-organization plugin configuration is:

```
Individual repository personal OAuth tokens
	None
Organization Github OAuth token: abcdef123456789
```

The individual repository OAuth tokens can be used to provide a privately generated OAuth token for a single repository. OAuth tokens are matched by the repository URL.

The organization OAuth token is the token normally generated via. the normal Github OAuth authorization process. This is the token which will be used by default.

# Webhook events

The plugin currently supports the following webhook events:

* ping
* status
* pull_request
* push

The `ping` and `status` events return immediatly with a 200 response. The `pull_request` and `push` events may cause a new job to be submitted, if a Cyclid job file can be found in the repository which generated the event.