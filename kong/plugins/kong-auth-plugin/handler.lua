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

local function transform_upstream_config(plugin_conf)
  return {
    header = plugin_conf.upstream_server_configuration.forwarded_header_name,
    header_value_format = plugin_conf.upstream_server_configuration.forwarded_header_value_format,
  }
end

local function unauthorize_request()
  return kong.response.error(401, "Unauhtorized", {
    ["Content-Type"] = "text/plain",
    ["WWW-Authenticate"] = "Basic"
  })
end

local function set_upstream_jwt(upstream_config, jwt)
  local formatted_jwt = string.format(upstream_config.header_value_format, jwt)
  kong.service.request.set_header(upstream_config.header, formatted_jwt)
end

function plugin:access(plugin_conf)
  kong.log.inspect(plugin_conf)

  local auth_server_config = transform_auth_server_config(plugin_conf)
  local upstream_config = transform_upstream_config(plugin_conf)
  local cache_enabled = plugin_conf.auth_server_configuration.cache_enabled
  local cache_TTL = plugin_conf.auth_server_configuration.cache_TTL

  local auth_token = kong.request.get_headers()[plugin_conf.auth_header_name]

  kong.log.debug("Authorizing with " .. (auth_token or ""))

  local jwt
  local err
  if cache_enabled then
    local cache_key = (kong.client.get_forwarded_ip() or kong.client.get_ip() .. "--" .. auth_token)
    jwt, err = kong.cache:get(cache_key, {ttl = cache_TTL}, authenticate, auth_server_config, auth_token)
  else
    jwt, err = authenticate(auth_server_config, auth_token)
  end

  if not jwt then
    kong.log.info("Rejecting request because: " .. err)
    unauthorize_request()
  else
    kong.log.debug("Authorization successful!")
    set_upstream_jwt(upstream_config, jwt)
  end
end

return plugin
