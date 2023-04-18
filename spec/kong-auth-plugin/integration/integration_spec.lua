local helpers = require "spec.helpers"

local PLUGIN_NAME = "kong-auth-plugin"

for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      local cache_route = bp.routes:insert({
        hosts = { "test-cache.com" },
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
          auth_header_name = 'MyAuth',
          auth_server_url="http://pongo-mockserver",
          upstream_server_configuration = {
            forwarded_header_name = "x-authorization"
          }
        },
      }
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = cache_route.id },
        config = {
          auth_header_name = 'MyAuth',
          auth_server_url="http://pongo-mockserver",
          auth_server_configuration = {
            cache_enabled = true
          }
        }
      }

      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled," .. PLUGIN_NAME,
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)


    describe("when authorized", function()
      it("proxies a request if remote server with JWT token", function()
        local r = client:get("/request", {
          headers = {
            host = "test1.com",
            MyAuth = 'secret-header'
          }
        })

        assert.response(r).has.status(200)
        local header_Value = assert.request(r).has.header("x-authorization")
        assert.equal(header_Value, "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c")
      end)
    end)

    describe("when unauthorized", function()
      it("returns 401", function()
        local r = client:get("/", {
          headers = {
            host = "test1.com",
            MyAuth = 'something-else'
          }
        })

        assert.response(r).has.status(401)
      end)
    end)

    describe("when auth server crashes", function()
      it("returns 401", function()
        local r = client:get("/", {
          headers = {
            host = "test1.com",
            MyAuth = 'crash'
          }
        })

        assert.response(r).has.status(401)
      end)
    end)

    describe("when auth server responds with 201", function()
      it("returns 401", function()
        local r = client:get("/", {
          headers = {
            host = "test1.com",
            MyAuth = 'created'
          }
        })

        assert.response(r).has.status(401)
      end)
    end)

    describe("when cache is enabled", function()
      it("does not contact auth server repeatedly", function()
        local response1 = client:get("/", {
          headers = {
            host = "test-cache.com",
            MyAuth = 'cache-check'
          }
        })

        local header1_value = assert.request(response1).has.header("authorization")

        local response2 = client:get("/", {
          headers = {
            host = "test-cache.com",
            MyAuth = 'cache-check'
          }
        })

        local header2_value = assert.request(response2).has.header("authorization")
        assert.equal(header1_value, header2_value)
      end)
    end)

    describe("when cache is disabled", function()
      it("contacts auth server for every request", function()
        local response1 = client:get("/", {
          headers = {
            host = "test1.com",
            MyAuth = 'cache-check'
          }
        })

        local header1_value = assert.request(response1).has.header("x-authorization")

        local response2 = client:get("/", {
          headers = {
            host = "test1.com",
            MyAuth = 'cache-check'
          }
        })

        local header2_value = assert.request(response2).has.header("x-authorization")
        assert.is_not.equal(header1_value, header2_value)
      end)
    end)
  end)

end end
