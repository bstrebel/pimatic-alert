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

describe "alert", ->
  plugin = null
  alertSystem = null
  alertSwitch = null
  dummySwitch = null

  framework = null

  beforeEach ->
    framework = new events.EventEmitter()
    framework.deviceManager = {
      registerDeviceClass: (name, {configDef, createCallback}) ->
        if name is "AlertSystem"
          alertSystem =
            createCallback(
              {id: "alert-system", name: "alertSystem", includes: ["dummy_id", "test_id"]}, null)
        if name is "AlertSwitch"
          alertSwitch = createCallback({id: "alert-system", name: "alertSystem"}, null)
    }
    plugin = require('../alert')(env)
    plugin.init(null, framework, {id: "test_id", name: "test"})
    dummySwitch = new env.devices.DummySwitch({id: "dummy_id", name: "dummy"}, null)
    framework.deviceManager.devices = { "dummy_id": dummySwitch }

  it "switching to on should set active state", ->
    alertSystem.turnOn()
    assert alertSystem._state is on

  it "switching to off should disable alert", ->
    alertSystem.turnOn()
    called = false
    alertSystem._setAlert = (alert, device) ->
      assert alert is off
      called = true
    alertSystem.turnOff()
    assert called
    assert alertSystem._state is off

  describe "after init event", ->

    it "should add actuators", ->
      framework.emit "after init"
      assert alertSystem._actuators.length is 1
      assert alertSystem._actuators[0] is dummySwitch

  describe "alert switch", ->

    beforeEach ->
      framework.deviceManager.devices = { "test_id": alertSwitch }
      framework.emit "after init"

    it "should activate alert when switched on", ->
      called = false
      alertSystem._setAlert = (alert, device) =>
        assert device is alertSwitch
        assert alert
        called = true
      alertSwitch.turnOn()
      assert called

    it "should deactivate alert when switched off", ->
      alertSwitch.turnOn()
      called = false
      alertSystem._setAlert = (alert, device) =>
        assert alert is false
        called = true
      alertSwitch.turnOff()
      assert called

  describe "contact sensor", ->
    sensor = null

    beforeEach ->
      sensor = new env.devices.DummyContactSensor({id: "test_id", name: "contact"})
      sensor.changeContactTo(on)
      framework.deviceManager.devices = { "test_id": sensor }
      framework.emit "after init"
      alertSystem.turnOn()

    it "should activate alert when contact changes", ->
      sensor.changeContactTo(false)
      assert alertSystem._alert
      assert alertSystem._trigger == "contact"

  describe "presence sensor", ->
    sensor = null

    beforeEach ->
      sensor = new env.devices.DummyPresenceSensor({id: "test_id", name: "presence"})
      framework.deviceManager.devices = { "test_id": sensor }
      framework.emit "after init"
      alertSystem.turnOn()

    it "should activate alert when contact changes", ->
      sensor.changePresenceTo(on)
      assert alertSystem._alert
      assert alertSystem._trigger == "presence"

  describe "setAlert", ->

    beforeEach ->
      framework.emit "after init"

    it "should ignore alert if deactivated", ->
      called = false
      dummySwitch.changeStateTo = (state) =>
        called = true
      framework.emit "after init"
      alertSystem._state = false
      alertSystem._setAlert(true, alertSwitch)
      assert not called

    it "should change state of actuators if activated", ->
      stateChanged = false
      dummySwitch.changeStateTo = (state) =>
        assert state
        stateChanged = true
      alertSystem._state = true
      alertSystem._setAlert(true, alertSwitch)
      assert stateChanged

    it "should set trigger to name of alert trigger", ->
      alertSystem._state = true
      alertSystem._setAlert(true, dummySwitch)
      assert alertSystem._trigger is dummySwitch.name

    it "should set trigger to empty string if alert is switched off", ->
      alertSystem._state = true
      alertSystem._alert = true
      alertSystem._trigger = "test"
      alertSystem._setAlert(false, null)
      assert alertSystem._trigger is ""
