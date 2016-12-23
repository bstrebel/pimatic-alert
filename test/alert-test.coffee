assert = require 'cassert'
_ = require 'lodash'

describe "[pimatic]", ->

  framework = null
  env = null

  config =
    settings:
      debug: true
      logLevel: "debug"
      httpServer:
        enabled: false
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
    devices: [
      {
        id: "alert-remote"
        name: "alert remote"
        class: "DummySwitch"
      },
      {
        id: "alert-alarm"
        name: "alert alarm"
        class: "DummySwitch"
      },
      {
        id: "contact-sensor"
        name: "contact sensor"
        class: "DummyContactSensor"
      },
      {
        id: "presence-sensor"
        name: "presence sensor"
        autoReset: true
        resetTime: 1000
        class: "DummyPresenceSensor"
      }
    ]
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
    startup = require('./startup')
    env = startup.env
    startup.startup()
      .then( (fw) ->
        framework = fw
        # env.logger.info("Startup completed ...")
    ).catch( (err) -> env.logger.error(err))

  after ->
    fs.unlinkSync configFile

  deviceConfig = null

  describe "[startup]", ->

    if config.settings.httpServer.enabled

      it "httpServer should run", (done) ->
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

    else
      it "should be initialized", ->
        assert framework?

  describe "[devices]", ->
    it "should have remote switch", ->
      assert framework.deviceManager.getDeviceById("alert-remote")?
    it "should have alarm switch", ->
      assert framework.deviceManager.getDeviceById("alert-alarm")?
    it "should have contact sensor", ->
      assert framework.deviceManager.getDeviceById("contact-sensor")?
    it "should have presence switch", ->
      assert framework.deviceManager.getDeviceById("presence-sensor")?

  describe "[AlertPlugin]", ->

    it "should be installed", ->
      assert framework.pluginManager.isInstalled('pimatic-alert')

    it "should have plugin config", ->
      plugin = framework.pluginManager.getPlugin('alert')
      config = framework.pluginManager.getPluginConfig('alert')
      assert config.timeformat == "YYYY-MM-DD hh:mm:ss"


  describe "[AlertSystem]", ->

    alert = null
    alert_switch = null
    alert_enabled = null
    alert_remote = null
    alert_state = null
    contact = null
    presence = null

    it "should be created and initialized", ->

      config = {
        id: "alert"
        name: "alert system"
        remote: "alert-remote"
        checkSensors: true
        rejectDelay: 100
        sensors: [
          {
            name: "contact-sensor"
            required: true
          }
          {
            name: "presence-sensor"
          }
        ]
        switches: [
          "alert-alarm"
        ]
        class: "AlertSystem"
      }
      alert = framework.deviceManager._loadDevice(config, null, null)
      assert alert?

    it "should have alert switch", ->
      alert_switch = framework.deviceManager.getDeviceById(alert.config.alert)
      assert alert_switch? and alert_switch.system == alert

    it "should have remote switch", ->
      alert_remote = framework.deviceManager.getDeviceById(alert.config.remote)
      assert alert_remote?  and alert_remote.system == alert

    it "should have enabled switch", ->
      alert_enabled = framework.deviceManager.getDeviceById(alert.config.enabled)
      assert alert_enabled?

    it "should have state variable device", ->
      alert_state = framework.deviceManager.getDeviceById(alert.config.state)
      assert alert_switch?
      
    it "should have 2 registered sensor devices", ->
      assert alert?
      sensors = alert.getSensors()
      assert sensors.length == 2
      for device in sensors
        assert device.system == alert

    describe "[alert system]", ->

      it "should be ready for activation", (done) ->
        # alert = framework.deviceManager.getDeviceById('alert')
        assert alert?
        contact = _.find alert.getSensors(), (sensor) ->
          sensor instanceof env.devices.ContactSensor
        assert contact?
        presence = _.find alert.getSensors(), (sensor) ->
          sensor instanceof env.devices.PresenceSensor
        assert presence?
        done()

      it "should not enable if contact sensor is open", (done) ->
        contact.changeContactTo(false)
        alert.changeStateTo(true)
        assert alert.getEnabled()._state == false
        assert alert.getRemote()._state == false
        check = () ->
          assert alert._state == false
          done()
        setTimeout(check, alert.config.rejectDelay * 2)

      it "should not trigger an alarm if disabled", (done) ->
        alert.getAlert()._state = false
        presence.changePresenceTo(true)
        check = () ->
          assert alert.getAlert()._state == false
          done()
        setTimeout(check, 100)

      it "should enable if contact sensor is closed", (done) ->
        contact.changeContactTo(true)
        alert.changeStateTo(true)
        assert alert._state == true
        check = () ->
          assert alert.getEnabled()._state == true
          assert alert.getRemote()._state == true
          done()
        setTimeout(check, 100)

      it "should trigger an alarm if enabled", (done) ->
        presence.changePresenceTo(false)
        presence.changePresenceTo(true)
        check = () ->
          assert alert.getAlert()._state == true
          assert framework.variableManager.getVariableValue('alert-trigger') == 'presence-sensor'
          done()
        setTimeout(check, 100)

      it "should switch off alarm devices if disabled", (done) ->
        alert.changeStateTo(false)
        check = () ->
          assert alert._state == false
          assert alert_enabled._state == false
          assert alert_remote._state == false
          for device in alert.getSwitches()
            assert device._state == false
          done()
        setTimeout(check, 100)

    describe "[alert remote]", ->

      it "should sync remote with system (reject==false)", (done) ->
        contact.changeContactTo(true)
        presence.changePresenceTo(false)
        alert.changeStateTo(false)
        alert_remote.changeStateTo(false)
        assert alert._state == false
        assert alert_remote._state == false
        alert.changeStateTo(true)
        check = () ->
          assert alert_remote._state == true
          done()
        setTimeout(check, 100)

      it "should sync remote with system (reject==true)", (done) ->
        contact.changeContactTo(false)
        presence.changePresenceTo(false)
        alert.changeStateTo(false)
        alert_remote.changeStateTo(false)
        assert alert._state == false
        assert alert_remote._state == false
        alert.changeStateTo(true)
        check = () ->
          assert alert ._state == false
          assert alert_remote._state == false
          done()
        setTimeout(check, 100)

      it "should sync system with remote (reject==false)", (done) ->
        contact.changeContactTo(true)
        presence.changePresenceTo(false)
        alert.changeStateTo(false)
        alert_remote.changeStateTo(false)
        assert alert._state == false
        assert alert_remote._state == false
        alert_remote.changeStateTo(true)
        check = () ->
          assert alert._state == true
          done()
        setTimeout(check, 100)

      it "should sync system with remote (reject==true)", (done) ->
        contact.changeContactTo(false)
        presence.changePresenceTo(false)
        alert.changeStateTo(false)
        alert_remote.changeStateTo(false)
        assert alert._state == false
        assert alert_remote._state == false
        alert_remote.changeStateTo(true)
        check = () ->
          assert alert ._state == false
          assert alert_remote._state == false
          done()
        setTimeout(check, 100)
