#!/usr/bin/env ruby

require 'logger'
require 'yaml'
require 'erb'
require 'vault'
require 'aws-sdk-secretsmanager'
require 'json'

# Nicer logging for Docker
log = Logger.new STDOUT

log.info "Starting env-init"

# Load app config from YAML supplied by downstream image
conf = if File.exist? '/home/app/webapp/image.yml'
         log.info "Loading image.yml"
         YAML.load ERB.new(File.read('/home/app/webapp/image.yml')).result
       else
         log.info "Could not find image.yml - skipping setting loading"
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

  awsRegion = ENV['AWS_REGION']
  awsEndpoint = ENV['AWS_SECRETS_ENDPOINT']
  appEnv = ENV['APP_ENV']
  secretsManagerEnv = appEnv =~ /prod/ ? "prod" : "stage"

  log.info 'Starting AWS Secrets env vars init'
  log.info "AWS ECS environment = #{appEnv}"
  log.info "AWS Secrets Manager environment = #{secretsManagerEnv}"
  log.info "AWS Secrets endpoint = #{awsEndpoint}"
  log.info "AWS Region = #{awsRegion}"

  secretsmanager = Aws::SecretsManager::Client.new(
    region: awsRegion,
    endpoint: awsEndpoint
  )

  File.open('/etc/nginx/main.d/env.conf', 'w+') do |f|
    conf['aws_secrets_env'].each do |secrets_path, secret_env_vars|
      begin
        secrets = secretsManagerEnv + '/' + secrets_path

        log.info "Reading from Secrets path #{secrets}"

        aws_secrets = secretsmanager.get_secret_value({
          secret_id: secrets
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

log.info "Finished env-init"
