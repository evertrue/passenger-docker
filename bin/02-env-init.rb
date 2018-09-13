#!/usr/bin/env ruby

require 'logger'
require 'yaml'
require 'erb'
require 'vault'
require 'aws-sdk-secretsmanager'
require 'json'

# Nicer logging for Docker
log = Logger.new STDOUT

# Load app config from YAML supplied by downstream image
conf = if File.exist? '/home/app/webapp/image.yml'
         YAML.load ERB.new(File.read('/home/app/webapp/image.yml')).result
       else
         {}
       end

# ------------------------------------------------------------------------------------
# Load Vault settings
# ------------------------------------------------------------------------------------

unless conf['vault_env'].to_h.empty?
  log.info 'Starting Vault env vars init'

  log.info "Copying secrets from #{ENV['VAULT_ADDR']}"
  vault_token_obfuscated = ENV['VAULT_TOKEN'].gsub(/./, '*')
  log.info "VAULT_TOKEN=#{vault_token_obfuscated}"

  File.open('/etc/nginx/main.d/env.conf', 'w+') do |f|
    conf['vault_env'].each do |vault_path, vault_env_vars|
      begin
        Vault.with_retries(Vault::HTTPError) do
          log.info "Reading from Vault path #{vault_path}"
          vault_secrets = Vault.logical.read vault_path

          if vault_env_vars.is_a? Hash
            vault_env_vars.each do |env_var_name, vault_key_name|
              File.write(
                "/etc/container_environment/#{env_var_name}",
                vault_secrets.data[vault_key_name.to_sym]
              )
            end
          elsif vault_env_vars.is_a? Array
            vault_env_vars.each do |env_var|
              File.write(
                "/etc/container_environment/#{env_var}",
                vault_secrets.data[env_var.to_sym]
              )
            end
          else
            raise 'Vault env vars must be specified as an array or hash'
          end
        end

        log.info 'Populating NGINX env var keys'
        # Whitelist of values that do not come from Vault, but should
        # be preserved in NGINX’s environment
        %w(
          CHEF_ENV
          VAULT_TOKEN
          VAULT_ADDR
        ).each { |env_var_name| f.puts "env #{env_var_name};" }
        vault_env_vars.each { |env_var_name| f.puts "env #{env_var_name};" }
      rescue => e
        abort "\nFAILED TO READ SECRETS FROM VAULT!\n\n#{e}"
      end
    end
  end

  log.info Dir['/etc/container_environment/*']
  log.info 'Finished Vault env vars init'
end

# ------------------------------------------------------------------------------------
# Load AWS Secrets Manager settings
# ------------------------------------------------------------------------------------

unless conf['aws_secrets_env'].to_h.empty?

  # TODO: Move AWS_SECRETS_* values to env vars
  # TODO: Prefix secrets_path with stage/prod depending on environment

  AWS_SECRETS_REGION = "us-east-1"
  AWS_SECRETS_ENDPOINT = "https://secretsmanager.us-east-1.amazonaws.com"

  log.info 'Starting AWS Secrets env vars init'
  log.info "Connecting to secrets client #{AWS_SECRETS_ENDPOINT}"

  secretsmanager = Aws::SecretsManager::Client.new(
    region: AWS_SECRETS_REGION,
    endpoint: AWS_SECRETS_ENDPOINT
  )

  File.open('/etc/nginx/main.d/env.conf', 'w+') do |f|
    conf['aws_secrets_env'].each do |secrets_path, secret_env_vars|
      begin
        log.info "Reading from Secrets path #{secrets_path}"

        aws_secrets = secretsmanager.get_secret_value({
          secret_id: secrets_path
        })

        if secret_env_vars.is_a? Array
          # Parse the JSON secrets string that returns from the secret path
          secretHash = JSON.parse(aws_secrets.secret_string)

          secret_env_vars.each do |env_var|
              File.write(
                "/etc/container_environment/#{env_var}",
                secretHash[env_var]
              )
            end
        else
          raise 'AWS Secrets env vars must be specified as an array'
        end

        log.info 'Populating NGINX env var keys'

        # Whitelist of values that do not come from Secrets Manager, but should
        # be preserved in NGINX’s environment
        %w(
          CHEF_ENV
        ).each { |env_var_name| f.puts "env #{env_var_name};" }

        secret_env_vars.each { |env_var_name| f.puts "env #{env_var_name};" }
      rescue => e
        abort "\nFAILED TO READ SECRETS FROM AWS Secrets Manager!\n\n#{e}"
      end
    end
  end

  log.info Dir['/etc/container_environment/*']
  log.info 'Finished AWS Secrets env vars init'
end

if conf['nginx_enabled']
  log.info 'Enabling NGINX'
  File.delete '/etc/service/nginx/down'
end
