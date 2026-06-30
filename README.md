# launchd-yaml

Declarative macOS LaunchAgent management from a YAML file.

Define your LaunchAgents in YAML, run `launchd-yaml apply`, and the tool handles rendering to plist, deploying, reloading only what changed, and pruning agents that were removed. Unchanged agents are never restarted.

## Requirements

- macOS
- [`yq`](https://github.com/mikefarah/yq) — YAML/JSON processor

## Install

### Homebrew (recommended)

```sh
brew install athal7/tap/launchd-yaml
```

### Manual

```sh
curl -sL https://github.com/athal7/launchd-yaml/releases/latest/download/launchd-yaml -o ~/.local/bin/launchd-yaml
chmod +x ~/.local/bin/launchd-yaml
```

## Usage

```sh
launchd-yaml apply          # deploy changes
launchd-yaml diff           # preview changes without applying
launchd-yaml list           # show managed agents
```

## YAML format

```yaml
launchagents:
  my-daemon:
    Label: com.$USER.my-daemon
    ProgramArguments:
      - /usr/local/bin/my-binary
      - --flag
    RunAtLoad: true
    KeepAlive: true

  my-scheduled-task:
    Label: com.$USER.my-task
    ProgramArguments: [/usr/bin/some-script]
    StartInterval: 900
```

`$HOME` and `$USER` in string values are substituted at render time. YAML integers become plist `<integer>`, booleans become `<true/>`/`<false/>`.

## Config file search

When `--file` is not given, `launchd-yaml` looks for:
1. `./launchd.yaml` (current directory)
2. `~/.config/launchd-yaml/agents.yaml`

## Self-hosting carve-out

If your YAML includes a KeepAlive daemon that hosts the process running `launchd-yaml apply` (e.g. an `opencode-web` server), use `--self-agent <name>` to exempt it from inline bootout. The agent's plist will be updated, but the reload is deferred via `launchctl kickstart -k` so the running process isn't killed mid-apply.

```sh
launchd-yaml apply --self-agent opencode-web
```

## chezmoi integration

Add a `run_onchange_` script that calls `launchd-yaml apply`:

```sh
#!/bin/sh
# launchd.yaml hash: {{ include ".chezmoidata/launchd.yaml" | sha256sum }}
launchd-yaml apply --file "{{ .chezmoi.sourceDir }}/.chezmoidata/launchd.yaml" --self-agent opencode-web
```

## License

MIT
