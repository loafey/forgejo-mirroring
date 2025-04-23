# GitHub -> Forgejo Mirroring
Simply mirrors all your GitHub projects to your own forgejo instance!

Create a file called `settings.json` containing the following:
```json
{
    "github": {
        "api": "...",
        "user": "..."
    },
    "forgejo": {
        "url": "...",
        "admin": "...",
        "api": "...",
        "user": "...",
        "mirror_interval": "...",
        "mirror_delay": 200
    }
}
```
where the keys contain the following values:
- `github.api`: the api key to your user on GitHub, needs repo, user, and workflow permissions on read.
- `github.user`: the user name for your GitHub user.
- `forgejo.url`: the url to your Forgejo server.
- `forgejo.admin`: an admin api key to your Forgejo server (might not be needed).
- `forgejo.api`: the api key for the user where you want to mirror the repos. Can be the same as `forgejo.admin`.
- `forgejo.user`: the user where you want to mirror the repos. Needs to match `forgejo.api`.
- `forgejo.mirror_interval`: how often you want your mirror to sync in hours. I recommend "24h".
- `forgejo.mirror_delay`: the delay between mirror requests. Usefull if you don't want all your repos to sync at the same time.

After this file is set up simply run "mirror-repos.sh"