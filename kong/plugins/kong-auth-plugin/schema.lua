local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "kong-auth-plugin"

local function validate_formattable_string(string_format)
  local example_value = "xyz_custom_value"
  local formated_value = string.format(string_format, example_value)
  return string.find(formated_value, example_value)
end

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
          { auth_server_configuration = {
            type = "record",
            fields = {
              { cache_TTL = {
                type = "number",
                default = 0,
                gt = -1
              }},
              { cache_enabled = {
                type = "boolean",
                default = false,
              }},
              { auth_request_header_name = typedefs.header_name {
                default = "Authorization"
              }},
              {auth_request_header_value_format = {
                type = "string",
                default = "Bearer %s"
              }},
              {auth_request_method = typedefs.http_method {
                default = "POST"
              }},
            }
          }},
          { upstream_server_configuration = {
            type = "record",
            fields = {
              { forwarded_header_name = typedefs.header_name {
                default = "Authorization"
              }},
              { forwarded_header_value_format = {
                type = "string",
                default = "Bearer %s"
              }}
            }
          }}
        },
        entity_checks = {
          { custom_entity_check = {
            field_sources = { "auth_server_configuration.auth_request_header_value_format", "upstream_server_configuration.forwarded_header_value_format" },
            fn = function (entity)
              local auth_server_value_format = entity.auth_server_configuration.auth_request_header_value_format
              local forwarded_header_value_format = entity.upstream_server_configuration.forwarded_header_value_format
              if not validate_formattable_string(auth_server_value_format) then
                return nil, "Cannot format secret value with given header: auth_request_header_value_format -- " .. auth_server_value_format
              elseif not validate_formattable_string(forwarded_header_value_format) then
                return nil, "Cannot format secret value with given header: forwarded_header_value_format -- " .. forwarded_header_value_format
              end

              return true
            end,
          }}
        }
      },
    },

  },
}

return schema
