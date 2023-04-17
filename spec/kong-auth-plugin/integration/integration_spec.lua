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
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {
          auth_header_name = 'MyAuth',
          auth_server_url="http://pongo-mockserver"
        },
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
      it("proxies a request if remote server returns 200", function()
        local r = client:get("/", {
          headers = {
            host = "test1.com",
            MyAuth = 'secret-header'
          }
        })

        assert.response(r).has.status(200)
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

  end)

end end
