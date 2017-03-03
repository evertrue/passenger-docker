#!/usr/bin/env ruby

require 'logger'
require 'yaml'
require 'erb'
require 'vault'

class EnvInit
  # Nicer logging for Docker
  def log
    @log ||= Logger.new STDOUT
  end

  def validate_environment!
    %w(VAULT_TOKEN VAULT_ADDR).each do |env_var|
      fail "Environment variable #{env_var} is required but not defined" unless ENV[env_var]
      fail "Environment variable #{env_var} needs a value but is empty" if ENV[env_var].empty?
    end
  end

  # Load app config from YAML supplied by downstream image
  def conf
    @conf ||= begin
      return {} unless File.exist? '/home/app/webapp/image.yml'
      YAML.load ERB.new(File.read('/home/app/webapp/image.yml')).result
    end
  end

  def seed_vault_store(vault_path)
    Vault.with_retries(Vault::HTTPError) do
      log.info "Loading VAULT_SEED_DATA: #{ENV['VAULT_SEED_DATA']}"
      Vault.logical.write vault_path, ENV['VAULT_SEED_DATA']
    end
  end

  def retrieve_vault_secrets
    File.open('/etc/nginx/main.d/env.conf', 'w+') do |f|
      conf['vault_env'].each do |vault_path, vault_env_vars|
        begin
          seed_vault_store vault_path if ENV['VAULT_SEED_DATA']

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
              fail 'Vault env vars must be specified as an array or hash'
            end
          end

          log.info 'Populating NGINX env var keys'
          # Whitelist of values that do not come from Vault, but should
          # be preserved in NGINX's environment
          %w(
            CHEF_ENV
            VAULT_TOKEN
            VAULT_ADDR
          ).each { |env_var_name| f.puts "env #{env_var_name};" }
          vault_env_vars.each { |env_var_name| f.puts "env #{env_var_name};" }
        rescue => e
          raise e, "ERROR: Failed to read secrets from Vault: #{e.message}"
        end
      end
    end
  end

  def self.run
    if conf['vault_env']
      validate_environment!

      log.info 'Starting Vault env vars init'
      log.info "Copying secrets from #{ENV['VAULT_ADDR']}"
      log.info "VAULT_TOKEN=#{ENV['VAULT_TOKEN'].gsub(/./, '*')}"

      retrieve_vault_secrets

      log.info Dir['/etc/container_environment/*']
      log.info 'Finished Vault env vars init'
    end

    return unless conf['nginx_enabled']

    log.info 'Enabling NGINX'
    File.delete '/etc/service/nginx/down'
  end
end
