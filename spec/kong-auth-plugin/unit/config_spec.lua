local PLUGIN_NAME = "kong-auth-plugin"


-- helper function to validate data against a schema
local validate do
  local validate_entity = require("spec.helpers").validate_plugin_config_schema
  local plugin_schema = require("kong.plugins."..PLUGIN_NAME..".schema")

  function validate(data)
    return validate_entity(data, plugin_schema)
  end
end


describe(PLUGIN_NAME .. ": (schema)", function()


  it("accepts distinct request_header and response_header", function()
    local ok, err = validate({
        auth_server_url = "https://mockbin.org",
        auth_header_name = "MyAuth",
      })
    assert.is_nil(err)
    assert.is_truthy(ok)
  end)

end)
