local PLUGIN_NAME = "kong-auth-plugin"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema) #unit", function()


  it("accepts proper configuration", function()
    local ok, err = validate({
        auth_server_url = "https://mockbin.org",
        auth_header_name = "MyAuth",
        auth_server_configuration = {
          auth_request_header_name = "Authorization",
          auth_request_header_value_format = "Bearer %s",
          auth_request_method = "POST"
        },
        upstream_server_configuration = {
          forwarded_header_name = "Authorization",
          forwarded_header_value_format = "Bearer %s",
        }
      })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

  it("rejects when auth_request_header_value_format format is incorrect", function()
    local ok, err = validate({
        auth_server_url = "https://mockbin.org",
        auth_server_configuration = {
          auth_request_header_value_format = "Static format with no interpolation",
        },
      })
    assert.is_truthy(err)
    assert.is_falsy(ok)
  end)

  it("rejects when forwarded_header_value_format format is incorrect", function()
    local ok, err = validate({
        auth_server_url = "https://mockbin.org",
        upstream_server_configuration = {
          forwarded_header_value_format = "Static format with no interpolation",
        },
      })
    assert.is_truthy(err)
    assert.is_falsy(ok)
  end)
end)
