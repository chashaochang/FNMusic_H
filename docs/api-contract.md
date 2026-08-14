# Feiniu Music API Contract v0

This client implements the public protocol facts observed in the pinned `kuilei0926/FeiNiuMusic` source snapshot `38103622367c3a48db0df8ac48ca2d4974b979f1`. It does not copy that project's UI, assets or player implementation.

## Base protocol

- Prefix: `{baseUrl}/music/api/v1`
- Envelope: `{ code, msg, data }`; only `code == 0` is success
- Authentication: `Cookie: music-token={token}`
- Relay requests additionally carry `mode=relay`
- Login: `POST /user/password-login` with username, SHA-256 password and stable device ID
- There is no observed refresh-token or server logout endpoint

## V1 endpoint allowlist

- Tracks: `track/list`, `track/stream`, `track/metadata`
- Collections: `favorite-track/*`, `play-history/*`, `track/roam-start`, `track/roam-next`
- Catalog: `album/*`, `artist/*`, `genre/list`, catalog detail track lists
- Search: `search/track`, `search/album`, `search/artist`
- Playlists: `playlist/*`, `track/playlist-detail/list`
- Media: `static/cover`, `lyric/list`
- Optional play event: `event/report`; failure never blocks playback

## Error rules

- HTTP, business and parse errors stay distinct.
- Authentication errors may trigger one serialized re-login attempt.
- Read failures are never silently converted into an empty library.
- Server address, credentials, access code and token are redacted from logs.

## Deferred capabilities

Music-library scanning, NAS user management, metadata matching, WebDAV backup, reports, DLNA, downloads and desktop lyrics are outside V1. Settings entries for unavailable server-management capabilities show `功能开发中`.
