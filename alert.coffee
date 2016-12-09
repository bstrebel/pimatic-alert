module.exports = (env) =>
  Promise = env.require 'bluebird'
  t = env.require('decl-api').types
  _ = env.require 'lodash'

  class AlertPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info "Starting alert system ..."

      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'AlertSwitch',
        configDef: deviceConfigDef.AlertSwitch
        createCallback: (config, lastState) ->
          return new AlertSwitch(config, lastState)

      @framework.deviceManager.registerDeviceClass 'AlertSystem',
        configDef: deviceConfigDef.AlertSystem
        createCallback: (config, lastState) =>
          return new AlertSystem(config, lastState, @)

  plugin = new AlertPlugin

  class AlertSwitch extends env.devices.DummySwitch

  class AlertSystem extends env.devices.DummySwitch

    _trigger: ""
    _sensors: []
    _switches: []

    attributes:
      trigger:
        description: "device that triggered the alarm"
        type: t.string
      state:
        description: "The current state of the switch"
        type: t.boolean
        labels: ['on', 'off']

    getTrigger: () -> Promise.resolve(@_trigger)

    _setTrigger: (trigger) ->
      trigger = "" unless trigger
      @_trigger = if trigger then trigger else ""
      @emit 'trigger', trigger

    constructor: (config, lastState, plugin) ->

      super(config, lastState)
      @config = config
      @plugin = plugin

      @on 'state', (state) =>
        stateString = if state then 'activated' else 'deactivated'
        env.logger.info("alert system \"#{@id}\" #{stateString}")

      @plugin.framework.on 'after init', =>

        if not @config.alert?
          env.logger.error("Missing alert switch in configuration for \"#{@id}\"")
          return
        alert = @plugin.framework.deviceManager.getDeviceById(@config.alert)
        if alert not instanceof AlertSwitch
          env.logger.error("Device \"#{alert.id}\" is not a valid alert switch!")
          return
        alert.on 'state', (state) =>
          @setAlert(alert, state)

        @_switches.push(alert)

        env.logger.debug("Initializing alert system \"#{@id}\" with switch #{alert.id}")

        register = (sensor, event, expectedValue) =>
          env.logger.info("Device \"#{sensor.id}\" registerd as sensor for \"#{@id}\"")
          @_sensors.push(sensor)
          sensor.on event, (value) =>
            if value is expectedValue
              @setAlert(sensor, true)

        for id in @config.sensors
          sensor = @plugin.framework.deviceManager.getDeviceById(id)
          if sensor instanceof env.devices.PresenceSensor
            register sensor, 'presence', true
          else if sensor instanceof env.devices.ContactSensor
            register sensor, 'contact', false
          else
            env.logger.error("Device \"#{sensor.id}\" is not a valid sensor for \"#{@id}\"")

        for id in @config.switches
          actuator = @plugin.framework.deviceManager.getDeviceById(id)
          if actuator instanceof env.devices.SwitchActuator
            @_switches.push(actuator)
            env.logger.info("Device \"#{actuator.id}\" registerd as switch for \"#{@id}\"")
          else
            env.logger.info("Device \"#{actuator.id}\" is not a valid switch for \"#{@id}\"")

    setAlert: (device, alert) =>
      if @_state
        if alert
          if device not instanceof env.devices.SwitchActuator
            env.logger.info("Alert triggered by \"#{device.id}\"")
            @_setTrigger(device.id)
        else
          env.logger.info("OFF")
          @_setTrigger(null)

        for actuator in @_switches
          actuator.changeStateTo(alert)

  return plugin
