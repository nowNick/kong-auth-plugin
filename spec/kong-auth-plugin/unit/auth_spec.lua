local PLUGIN_NAME = "kong-auth-plugin"

local kong_wrapper = {
  log = {
    error = function (msg) print(msg) end,
    notice = function (msg) print(msg) end
  },
  response = {
    exit = function (code) error(code) end,
    error = function (code) error(code) end
  }
}

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
    _G.kong = mock(kong_wrapper)
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
    http = nil
    authenticate = nil
  end)

  it("rejects authentication when no token", function()
    assert.has.errors(function() authenticate(auth_configuration, nil) end, 401)
  end)

  it("when config and token", function()
    assert.is_truthy(authenticate(auth_configuration, 'abc'))
  end)
end)
