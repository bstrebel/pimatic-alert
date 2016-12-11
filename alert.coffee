module.exports = (env) =>

  Promise = env.require 'bluebird'
  t = env.require('decl-api').types
  _ = env.require 'lodash'


  class AlertPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      env.logger.info "Starting alert system ..."

      @_afterInit = false

      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'AlertSwitch',
        configDef: deviceConfigDef.AlertSwitch
        createCallback: (config, lastState) ->
          return new AlertSwitch(config, lastState)

      @framework.deviceManager.registerDeviceClass 'AlertSystem',
        configDef: deviceConfigDef.AlertSystem
        createCallback: (config, lastState) =>
          return new AlertSystem(config, lastState, @)

      @framework.on 'after init', =>
        @_afterInit = true

    afterInit: () =>
      return @_afterInit

  plugin = new AlertPlugin


  class AlertSwitch extends env.devices.DummySwitch


  class AlertSystem extends env.devices.DummySwitch

    _trigger: ""
    _afterInit = false

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

      @sensors = null
      @switches = null
      @alert = null
      @remote = null

      env.logger.debug("Constructor for alert system \"#{@id}\" with @afterInit=#{@plugin.afterInit()}")

      @on 'state', (state) =>
        # sync with optional remote switch
        @remote.changeStateTo(state) if @remote?

        # always switch off alert if system is disabled
        if @switches? and not state
          @alert?.changeStateTo(state)
          for actuator in @switches
            actuator?.changeStateTo(state)

        stateString = if state then 'activated' else 'deactivated'
        env.logger.info("Alert system \"#{@id}\" #{stateString}")

      @plugin.framework.on 'after init', =>
        @_initDevice('after init')

      # initialize only on recreation of the device
      @_initDevice('constructor') if @plugin.afterInit()

    destroy: () ->
      # remove event handlers from sensor devices
      env.logger.debug("Destroying alert system \"#{@id}\"")
      if @alert?
        @alert.removeListener 'state', alertHandler
        delete(@alert.system)
      if @remote?
        @remote.removeListener 'state', alertHandler
        delete(@remote.system)
      if @sensors?
        for sensor in @sensors
          delete(sensor.system)
          if sensor instanceof env.devices.PresenceSensor
            sensor.removeListener 'presence', sensorHandler
          else if sensor instanceof env.devices.ContactSensor
            sensor.removeListener 'contact', sensorHandler
          else
            env.logger.error("Invalid sensor type found in alert system \"#{@id}\"")
      super()

    setAlert: (device, alert) =>
      if @_state
        if alert
          if device not instanceof env.devices.SwitchActuator
            env.logger.info("Alert triggered by \"#{device.id}\"")
            @_setTrigger(device.id)
        else
          env.logger.info("Alert switched off")
          @_setTrigger(null)

        for actuator in @switches
          actuator.changeStateTo(alert)

    alertHandler = (state) ->
      @system.setAlert(this, state)

    remoteHandler = (state) ->
      @system.changeStateTo(state)

    sensorHandler = (value) ->
      if value is @expectedValue
        @system.setAlert(this, true)

    _initDevice: (event) =>

      env.logger.debug("Initializing alert system \"#{@id}\" from [#{event}]")

      @sensors = []
      @switches = []
      @alert = null
      @remote = null

      if not @config.alert?
        env.logger.error("Missing alert switch in configuration for \"#{@id}\"")
        return
      alert = @plugin.framework.deviceManager.getDeviceById(@config.alert)
      if alert not instanceof AlertSwitch
        env.logger.error("Device \"#{alert.id}\" is not a valid alert switch for \"#{@id}\"")
        return

      alert.system = @
      alert.on 'state', alertHandler

      @alert = alert
      @switches.push(alert)

      env.logger.debug("Device \"#{alert.id}\" registered as alert switch device for \"#{@id}\"")

      if @config.remote?
        remote = @plugin.framework.deviceManager.getDeviceById(@config.remote)
        if remote?
          @remote = remote
          env.logger.debug("Device \"#{remote.id}\" registered as remote device for \"#{@id}\"")

          remote.system = @
          remote.on 'state', remoteHandler

      register = (sensor, event, expectedValue) =>
        env.logger.debug("Device \"#{sensor.id}\" registered as sensor for \"#{@id}\"")
        @sensors.push(sensor)

        sensor.system = @
        sensor.expectedValue = expectedValue
        sensor.on event, sensorHandler

      for id in @config.sensors
        sensor = @plugin.framework.deviceManager.getDeviceById(id)
        if sensor?
          if sensor instanceof env.devices.PresenceSensor
            register sensor, 'presence', true
          else if sensor instanceof env.devices.ContactSensor
            register sensor, 'contact', false
          else
            env.logger.error("Device \"#{sensor.id}\" is not a valid sensor for \"#{@id}\"")
        else
          env.logger.error("Device \"#{id}\" not found for \"#{@id}\"")

      for id in @config.switches
        actuator = @plugin.framework.deviceManager.getDeviceById(id)
        if actuator?
          if actuator instanceof env.devices.SwitchActuator
            @switches.push(actuator)
            env.logger.debug("Device \"#{actuator.id}\" registerd as switch for \"#{@id}\"")
          else
            env.logger.error("Device \"#{actuator.id}\" is not a valid switch for \"#{@id}\"")

  return plugin
