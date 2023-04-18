local http = require "resty.http"

local function call_auth_server(auth_configuration, token)
  local httpc = http:new()
  return httpc:request_uri(auth_configuration.endpoint, {
    method = auth_configuration.method,
    ssl_verify = false,
    headers = {
        [auth_configuration.header] = string.format(auth_configuration.header_value_format, token) }
  })
end

local function authenticate(auth_configuration, token)
  if not token then
    return nil, "Auth token not provided"
  end

  local res, err = call_auth_server(auth_configuration, token)

  if not res then
    return nil, err
  elseif res.status ~= 200 then
    return nil, "unauthorized"
  end

  return (res.body or "")
end

return authenticate
