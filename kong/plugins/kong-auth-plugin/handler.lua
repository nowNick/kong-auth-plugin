local authenticate = require "kong.plugins.kong-auth-plugin.auth"

local plugin = {
  PRIORITY = 1000,
  VERSION = "0.1",
}

local function transform_auth_server_config(plugin_conf)
  return {
    endpoint = plugin_conf.auth_server_url,
    method = plugin_conf.auth_server_configuration.auth_request_method,
    header = plugin_conf.auth_server_configuration.auth_request_header_name,
    header_value_format = plugin_conf.auth_server_configuration.auth_request_header_value_format,
  }
end

function plugin:access(plugin_conf)
  kong.log.inspect(plugin_conf)

  local auth_server_config = transform_auth_server_config(plugin_conf)
  local auth_token = kong.request.get_headers()[plugin_conf.auth_header_name]
  authenticate(auth_server_config, auth_token)
end

return plugin
