local http = require "resty.http"

local plugin = {
  PRIORITY = 1000,
  VERSION = "0.1",
}


local function authorize_request(auth_endpoint, token)
  token = token or ""
  local httpc = http:new()

  local res, err = httpc:request_uri(auth_endpoint, {
    method = "POST",
    ssl_verify = false,
    headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["Authorization"] = "Bearer " .. token }
  })

  if not res then
    kong.log.err("Could not access auth endpoint: " .. auth_endpoint)
    return kong.response.exit(401)
  end

  if res.status ~= 200 then
    kong.log.err("Auth endpoint " .. auth_endpoint .. " responeded with status: " .. res.status)
    return kong.response.exit(401)
  end

  kong.log("Authentication was successful")
  return true
end

function plugin:access(plugin_conf)
  kong.log.inspect(plugin_conf)   -- check the logs for a pretty-printed config!

  local auth_token = kong.request.get_headers()[plugin_conf.auth_header_name]
  -- if not auth_token then
  --   kong.response.exit(401)
  -- end
  local auth_endpoint = plugin_conf.auth_server_url
  kong.log("Going to hit: " .. auth_endpoint .. " with token: " .. (auth_token or ""))

  authorize_request(auth_endpoint, auth_token)
end

return plugin
