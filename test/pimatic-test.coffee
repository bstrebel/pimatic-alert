assert = require "cassert"

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
    plugins: []
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

  before ->
    fs.writeFileSync configFile, JSON.stringify(config)
    process.env.PIMATIC_CONFIG = configFile

  after ->
    fs.unlinkSync configFile

  framework = null
  deviceConfig = null

  describe 'startup', ->

    it "should startup", (finish) ->
      startup = require('../startup')
      startup.startup()
        .then( (fm)->
          framework = fm
        )
        .catch( (err) -> console.log(err))

      #    # finish()
      # ).catch(finish)

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

  describe '#addDeviceToConfig()', ->

    deviceConfig =
      id: 'test-actuator'
      class: 'TestActuatorClass'

    it 'should add the actuator to the config', ->

      framework.deviceManager.addDeviceToConfig deviceConfig
      assert framework.config.devices.length is 1
      assert framework.config.devices[0].id is deviceConfig.id

    it 'should throw an error if the actuator exists', ->
      try
        framework.deviceManager.addDeviceToConfig deviceConfig
        assert false
      catch e
        assert e.message is "An device with the ID #{deviceConfig.id} is already in the config"

  describe '#isDeviceInConfig()', ->

    it 'should find actuator in config', ->
      assert framework.deviceManager.isDeviceInConfig deviceConfig.id

    it 'should not find antother actuator in config', ->
      assert not framework.deviceManager.isDeviceInConfig 'a-not-present-id'
