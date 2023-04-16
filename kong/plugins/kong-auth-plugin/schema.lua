local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "kong-auth-plugin"


local schema = {
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part of the plugin schema
        type = "record",
        fields = {
          -- a standard defined field (typedef), with some customizations
          { auth_header_name = typedefs.header_name {
              required = true,
              default = "MyAuth" } },
          { auth_server_url =  {
              type="string",
              required = true } },
        },
      },
    },
  },
}

return schema
