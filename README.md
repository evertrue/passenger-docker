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
    EVERTRUE_APP_KEY: EVERTRUE_APP_KEY
    EVERTRUE_AUTH: EVERTRUE_AUTH
    ANOTHER_ENV_VAR: another_vault_secret_data_key
```

Then, build your project’s image.
