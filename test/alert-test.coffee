events = require 'events'
grunt = require 'grunt'
assert = require 'assert'
Promise = require 'bluebird'

env =
  logger:
    debug: (stmt) ->
      grunt.log.writeln stmt
    info: (stmt) ->
      grunt.log.writeln stmt
    warn: (stmt) ->
      grunt.log.writeln stmt
    error: (stmt) ->
      grunt.log.writeln stmt
  require: (dep) ->
    require(dep)
    
env.plugins = require('../node_modules/pimatic/lib/plugins') env
env.devices = require('../node_modules/pimatic/lib/devices') env

describe "alert system device", ->

  framework = null
  plugin = null
  alert = null

  beforeEach ->

    framework = new events.EventEmitter()
    framework.pluginManager = new env.plugins.PluginManager(framework)
    framework.deviceManager = new env.devices.DeviceManager(framework, {})


    plugin = require('../alert')(env)
    plugin.init(null, framework, {debug: true})

  it "alert system device should be created", ->
    device = new AlertSystem({id: "alert", name: "alert system"})
    device = framework.deviceManager.getDeviceById("alert")
    assert device?

