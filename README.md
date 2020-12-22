# k8s-deployment

Universal deployment script for Kubernetes applications.

Usage

```text/plain
Usage: ./deploy.sh [--help|-h] [service...] [--app=<app>] [--force]
   --app=<app>       - app to deploy
   --context=<tname> - defined config context
   --force           - force rebuild, even if no files are updated
   --help | -h       - print this help message and exit
```

This script will search the following places for app files, and will use the first one it finds:

1. `${DEPLOY_HOME}/apps/<app-name>`, if `${DEPLOY_HOME}` is defined,
1. `./apps/<app-name>`,
1. `~/.deploy/apps/<app-name>`, and
1. `/etc/deploy/apps/<app-name>`.

In all cases, app files are really shell scripts, but the `.sh` extension is optional.

For contexts, the list is the same, replacing `app` with `context`.

The `--force` is only necessary for remote builds; this script cannot detect changes when building locally.

## Deployment process

Deployments using this script follow the following general steps:

1. Loads app and context files,
1. If context requires it, copy files and `k8s-deployment` onto another machine,
1. Build Docker image,
1. Tag and upload image to registry,
1. Restart deployment, and
1. If app is configured for it, await deployment restart.

This script will search the following places for app files, and will use the first one it finds:

1. `${DEPLOY_HOME}/apps/<app-name>`, if `${DEPLOY_HOME}` is defined,
1. `~/.deploy/apps/<app-name>`,
1. `/etc/deploy/apps/<app-name>`, and
1. `./apps/<app-name>`.

In all cases, app files are really shell scripts, but the `.sh` extension is optional.

For contexts, the list is the same, replacing `app` with `context`.

## Apps and Contexts

An example app file is in [/apps/example_app.sh] and an example context is in [/contexts/example_context.sh]
