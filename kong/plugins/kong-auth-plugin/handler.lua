local http = require "resty.http"

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


local function authorize_request(auth_configuration, token)
  kong.log.notice("Going to access: " .. auth_configuration.endpoint .. " with token: " .. token)

  local httpc = http:new()
  local res, err = httpc:request_uri(auth_configuration.endpoint, {
    method = auth_configuration.method,
    ssl_verify = false,
    headers = {
        [auth_configuration.header] = string.format(auth_configuration.header_value_format, token) }
  })

  if not res then
    kong.log.err("Could not access auth endpoint: " .. auth_configuration.endpoint)
    return kong.response.exit(401)
  end

  if res.status ~= 200 then
    kong.log.err("Auth endpoint " .. auth_configuration.endpoint .. " responeded with status: " .. res.status)
    return kong.response.exit(401)
  end

  kong.log.notice("Authentication was successful")
  return true
end

function plugin:access(plugin_conf)
  kong.log.inspect(plugin_conf)   -- check the logs for a pretty-printed config!

  local auth_token = kong.request.get_headers()[plugin_conf.auth_header_name]
  if not auth_token then
    kong.log.error("no auth token provided")
    kong.response.exit(401)
  end

  local auth_server_config = transform_auth_server_config(plugin_conf)
  authorize_request(auth_server_config, auth_token)
end

return plugin
