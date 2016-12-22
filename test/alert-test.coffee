assert = require 'cassert'
_ = require 'lodash'

describe "pimatic", ->

  config =
    settings:
      debug: true
      logLevel: "debug"
      httpServer:
        enabled: true
        port: 8080
      httpsServer: {}
      database:
        client: "sqlite3"
        connection: {
          filename: ':memory:'
        }
    plugins: [
      {
        plugin: "alert",
        active: true,
        debug: true
      }
    ]
    devices: []
    rules: []
    users: [
      {
        username: "admin",
        password: "admin",
        role: "admin"
      }
    ],
    roles: [
      {
        name: "admin",
        permissions: {
          pages: "write",
          rules: "write",
          variables: "write",
          messages: "write",
          events: "write",
          devices: "write",
          groups: "write",
          plugins: "write",
          updates: "write",
          database: "write",
          config: "write",
          controlDevices: true,
          restart: true
        }
      }
    ],
    variables: []

  fs = require 'fs'
  os = require 'os'
  configFile = "#{os.tmpdir()}/pimatic-test-config.json"

  framework = null
  env = null

  before ->
    fs.writeFileSync configFile, JSON.stringify(config)
    process.env.PIMATIC_CONFIG = configFile
    startup = require('../startup')
    env = startup.env
    startup.startup()
      .then( (fw) ->
        framework = fw
        env.logger.info("Startup completed ...")
    ).catch( (err) -> env.logger.error(err))

  after ->
    fs.unlinkSync configFile

  deviceConfig = null

  describe 'startup', ->

    it "httpServer should run", (done)->
      http = require 'http'
      http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
        done()
      ).on "error", (e) ->
        throw e

    it "httpServer should ask for password", (done)->
      http = require 'http'
      http.get("http://localhost:#{config.settings.httpServer.port}", (res) ->
        assert res.statusCode is 401 # is Unauthorized
        done()
      ).on "error", (e) ->
        throw e

  describe 'plugin', ->

    it 'should be installed', ->

      assert framework.pluginManager.isInstalled('pimatic-alert')
