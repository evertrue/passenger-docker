# EverTrue Ruby Docker baseimage

This provides a base image, itself based on `phusion/passenger-ruby22` and its variants, to provide a consistent base for all EverTrue containerized projects.

Primarily, this involves:

* Bootstrapping secrets from Vault into environment variables
* Enabled NGINX if needed and, if so:
    - Setting NGINX’s server config
    - Adding a file listing the env var keys that NGINX should preserve in its environment

## Usage

Add this to the top of your project’s `Dockerfile`:

```
FROM evertrue/passenger-ruby22:0.1.0
```

You will want to have a YAML file as part of your project, `config/image.yml`, that specifies the name of the environment variables you want to set, and the secrets to load them in from in the Vault:

```yaml
vault_paths:
  secret/default/dna:
    EVERTRUE_APP_KEY: evertrue.app_key
    EVERTRUE_AUTH: evertrue.auth
    ANOTHER_ENV_VAR: another_vault_secret_data_key
```

Alternatively, you can just provide an array of env vars, and it will use that as both the key for the Vault data object, and the key for the final env var.

```yaml
vault_paths:
  secret/default/dna:
    - EVERTRUE_APP_KEY
    - EVERTRUE_AUTH
    - ANOTHER_ENV_VAR
```

If you need NGINX, you will want to specify:

```yaml
nginx_enabled: true
```

in your `image.yml`.

Then, build your project’s image.

## Development

The version for this image is set in the `Makefile`, please be sure to rev it before building and pushing new versions of the images this project generates.

To build an individual image, look in the `Makefile` for the corresponding build task.

To build them all:

```bash
$ make all
```

To perform a release:

```bash
$ make release
```
