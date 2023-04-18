local http = require "resty.http"

local function unauthorize_request()
  return kong.response.error(401, "Unauhtorized", {
    ["Content-Type"] = "text/plain",
    ["WWW-Authenticate"] = "Basic"
  })
end

local function call_auth_server(auth_configuration, token)
  local httpc = http:new()
  return httpc:request_uri(auth_configuration.endpoint, {
    method = auth_configuration.method,
    ssl_verify = false,
    headers = {
        [auth_configuration.header] = string.format(auth_configuration.header_value_format, token) }
  })
end

local function validate_response(response, endpoint)
  if not response then
    kong.log.err("Could not access auth endpoint: " .. endpoint)
    unauthorize_request()
  elseif response.status ~= 200 then
    kong.log.err("Auth endpoint " .. endpoint .. " responeded with status: " .. response.status)
    unauthorize_request()
  end
end

local function validate_token(token)
  if not token then
    kong.log.err("no auth token provided")
    unauthorize_request()
  end
end

local function authenticate(auth_configuration, token)
  validate_token(token)

  kong.log.notice("Going to access: " .. auth_configuration.endpoint .. " with token: " .. token)
  local res = call_auth_server(auth_configuration, token)

  validate_response(res, auth_configuration.endpoint)
  kong.log.notice("Authentication was successful")
  return true
end

return authenticate
