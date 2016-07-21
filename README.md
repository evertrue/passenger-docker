# EverTrue Ruby Docker baseimage

This provides a base image, itself based on the various flavors of [`phusion/passenger-docker`](https://github.com/phusion/passenger-docker), to provide a consistent set of features commonly used in EverTrue Docker-ized apps.

Specifically, those features are:

* Bootstrapping secrets from [Vault](https://vaultproject.io) into environment variables
    - A file listing the env vars for NGINX is generated as well
* Enabling NGINX if desired

## Usage

Three images are built from this project:

* `evertrue/passenger-ruby22`
* `evertrue/passenger-ruby23`
* `evertrue/passenger-full`

Add one of those to top of your project’s `Dockerfile`, specifying a tag:

```
FROM registry.evertrue.com/evertrue/passenger-ruby22:0.2.0
```

### Config

In order to customize the init process, a YAML config file will need to be provided.

Here is an example `image.yml` that enables NGINX and sets up a set of env vars from Vault:

```yaml
nginx_enabled: true
vault_env:
  secret/default/dna:
    EVERTRUE_APP_KEY: evertrue.app_key
    EVERTRUE_AUTH: evertrue.auth
    ANOTHER_ENV_VAR: another_vault_secret_data_key
```

Alternatively, you can just provide an array of env vars, and it will use that as both the key for the Vault data object, and the key for the final env var.

```yaml
vault_env:
  secret/default/dna:
    - EVERTRUE_APP_KEY
    - EVERTRUE_AUTH
    - ANOTHER_ENV_VAR
```

If you omit `nginx_enabled`, it will be left disabled (the default state for the Phusion Passenger images).

Ensure that the `image.yml` is placed at `/home/app/webapp/image.yml`:

```
COPY config/image.yml /home/app/webapp/image.yml
```

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
