#!/usr/bin/env ruby

require 'logger'
require 'yaml'
require 'erb'
require 'vault'

# Nicer logging for Docker
log = Logger.new STDOUT

# Load app config from YAML supplied by downstream image
conf = YAML.load ERB.new(File.read('/home/app/webapp/image.yml')).result

log.info 'Starting Vault env vars init'

log.info "Copy secrets from #{ENV['VAULT_ADDR']}"
vault_token_obfuscated = ENV['VAULT_TOKEN'].gsub(/./, '*')
log.info "VAULT_TOKEN=#{vault_token_obfuscated}"

conf['vault_paths'].each do |vault_path, vault_env_vars|
  begin
    Vault.with_retries(Vault::HTTPError) do
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
  rescue => e
    abort "\nFAILED TO READ SECRETS FROM VAULT!\n\n#{e}"
  end
end

log.info Dir['/etc/container_environment']
log.info 'Finished Vault env vars init'

# TODO generate /etc/nginx/main.d/env.conf
# TODO run `rm -f /etc/service/nginx/down`
