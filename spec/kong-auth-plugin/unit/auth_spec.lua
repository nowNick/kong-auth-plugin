local PLUGIN_NAME = "kong-auth-plugin"

local auth_configuration = {
  endpoint = "localhost",
  method = "POST",
  header = "test",
  header_value_format = "token %s",
}

describe(PLUGIN_NAME .. ": (auth) #unit", function()
  local authenticate
  local http

  setup(function()
    package.loaded['authenticate'] = nil
    package.loaded['resty.http'] = nil

    http = require('resty.http')
    http.new = function(self)
      return {
        request_uri = function() return { status = 200 } end
      }
    end
    authenticate = require "kong.plugins.kong-auth-plugin.auth"
  end)

  teardown(function()
    package.loaded['authenticate'] = nil
    package.loaded['resty.http'] = nil
  end)

  it("rejects authentication when no token", function()
    local jwt, err = authenticate(auth_configuration, nil)
    assert.is_nil(jwt)
    assert.is_truthy(err)
  end)

  it("when config and token", function()
    local jwt, err = authenticate(auth_configuration, 'abc')
    assert.is_truthy(jwt)
    assert.is_nil(err)
  end)
end)
