module.exports = (env) =>

  Promise = env.require 'bluebird'
  t = env.require('decl-api').types

  class AlertPlugin extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @_afterInit = false

      deviceConfigDef = require('./device-config-schema.coffee')

      @framework.deviceManager.registerDeviceClass 'AlertSwitch',
        configDef: deviceConfigDef.AlertSwitch
        createCallback: (config, lastState) ->
          return new AlertSwitch(config, lastState)

      @framework.deviceManager.registerDeviceClass 'EnabledSwitch',
        configDef: deviceConfigDef.EnabledSwitch
        createCallback: (config, lastState) ->
          return new EnabledSwitch(config, lastState)

      @framework.deviceManager.registerDeviceClass 'AlertSystem',
        configDef: deviceConfigDef.AlertSystem
        createCallback: (config, lastState) =>

          # process legacy config settings: maybe removed in future releases
          # config: trigger, autoconfig, rfdelay, rejectdelay, checksensors

          if config.trigger?
            config.displayTrigger = config.trigger
            delete(config.trigger)

          if config.autoconfig?
            config.autoConfig = config.autoconfig
            delete(config.autoconfig)

          if config.rfdelay?
            config.rfDelay = config.rfdelay
            delete(config.rfdelay)

          if config.rejectdelay?
            config.rejectDelay = config.rejectdelay
            delete(config.rejectdelay)

          if config.checksensors?
            config.checkSensors = config.checksensors
            delete(config.checksensors)

          return new AlertSystem(config, lastState, @)

      @framework.on 'after init', =>
        @_afterInit = true

    afterInit: () =>
      return @_afterInit

  plugin = new AlertPlugin

  class AlertSwitch extends env.devices.DummySwitch
  class EnabledSwitch extends env.devices.DummySwitch

  class AlertSystem extends env.devices.DummySwitch

    _trigger: ""

    attributes:
      trigger:
        description: "Device that triggered the alarm"
        type: t.string
      state:
        description: "The current state of the switch"
        type: t.boolean
        labels: ['on', 'off']

    getTrigger: () -> Promise.resolve(@_trigger)

    _setTrigger: (trigger) ->
      @_trigger = if trigger? then @_trigger = trigger else @_trigger = ""
      @emit 'trigger', @_trigger if @config.displayTrigger

    ###############################################################################################
    ###############################################################################################

    log: (level, msg) =>
      env.logger[level]("[#{@config.id}] #{msg}")

    ###############################################################################################
    ###############################################################################################

    constructor: (config, lastState, plugin) ->

      super(config, lastState)

      @id = @config.id
      @name = @config.name

      @config = config
      @plugin = plugin

      @deviceManager = @plugin.framework.deviceManager
      @variableManager = @plugin.framework.variableManager
      @timeformat = @plugin.config.timeformat

      @alert = null
      @remote = null
      @enabled = null

      @sensors = null
      @switches = null

      @rejected = false
      @sensorAlert = false

      @variables = {
        time: null    # timestamp of the last update
        info: null   # Enabled,Disabled,Rejected,Alert,Error
        state: null   # Enabled,Disabled,Rejected,Alert,Error
        trigger: null # device id of alert trigger
        reject: null  # device id which caused the reject
        error: null   # error message
      }

      if @plugin.afterInit()
        # initialize only on recreation of the device
        # skip initialization if we are called the
        # first time during startup
        @_initDevice('constructor')

      ###############################
      # AlertSwitch event listeners #
      ###############################

      @on 'rejected', () =>
        # switch back to "off" immediately after we resolved the state change
        @log('debug', "Activation rejected")
        @getState()
          .then( (state) => setTimeout((=>
            @changeStateTo(false)), @config.rejectDelay))

      @on 'state', (state) =>
        # process system switch state changes
        return unless @plugin.afterInit()
        # sync with optional remote switch
        if state
          @rejected = not @_checkSensors()
          if @rejected
            @variables['state'] = "Rejected"
            @emit 'rejected'
          else
            @variables['state'] = "Enabled"
            @variables['trigger'] = null
            @log('debug', "Alert system enabled")
            @remote.changeStateTo(state) if @remote?
            @enabled.changeStateTo(true) if @enabled?
        else
          if not @rejected
            @_switchDevices(false)
            @variables['state'] = "Disabled"
            @variables['trigger'] = null
            @_setTrigger("")
            @log('debug', "Alert system disabled")
            @remote.changeStateTo(state) if @remote?
            @enabled.changeStateTo(false) if @enabled?

        @_updateState('state')

      @plugin.framework.on 'after init', =>
        # wait for the 'after init' event
        # until all devices are loaded
        @_initDevice('after init')

    ###############################################################################################
    ###############################################################################################

    destroy: () ->
      # remove event handlers from sensor devices
      @log('debug', "Destroying alert system")
      if @alert?
        @alert.removeListener 'state', alertHandler
        delete(@alert.system)
      if @remote?
        @remote.removeListener 'state', alertHandler
        delete(@remote.system)
      if @sensors?
        for sensor in @sensors
          delete(sensor.system)
          delete(sensor.required)
          delete(sensor.expectedValue)
          if sensor instanceof env.devices.PresenceSensor
            sensor.removeListener 'presence', sensorHandler
          else if sensor instanceof env.devices.ContactSensor
            sensor.removeListener 'contact', sensorHandler
          else
            @log('error', "Invalid sensor type found for \"#{sensor.id}\"")
      super()

    ###############################################################################################
    ###############################################################################################

    setAlert: (device, alert) =>

      # called indirect by sensor devices via event handler
      # and from alert system device to switch off the alert

      @getState()
        .then((state) =>
          if state
            if alert
              if device not instanceof env.devices.SwitchActuator
                @log('info', "Alert triggered by sensor \"#{device.id}\"")
                ####################################################
                # strange: setVariable must be called to make sure #
                # that $alert-trigger is available for alert rule  #
                ####################################################
                @variableManager.setVariableToValue(@id + '-' + 'trigger', device.id)
                @variables['state'] = 'Alert'
                @variables['trigger'] = device.id
                @_updateState('alert')
                @_setTrigger(device.id)
                @sensorAlert = true
                @_switchDevices(alert)
              else
                if @sensorAlert
                  @log('debug', "Alert from \"#{device.id}\" ignored")
                  @sensorAlert = false
                else
                  @log('info', "Alert triggered by switch \"#{device.id}\"")
                  @_switchDevices(alert)
            else
              @log('info', "Alert switched off")
              @variables['state'] = 'Disabled'
              @_setTrigger(null)
              @_switchDevices(alert)
      )

    ################################################
    #  named removeable(!) alert handlers required #
    #  because auf device recreation               #
    ################################################

    alertHandler = (state) ->
      # if not state
      @system.setAlert(this, state)

    remoteHandler = (state) ->
      @system.changeStateTo(state)

    sensorHandler = (value) ->
      if value is @expectedValue
        @system.setAlert(this, true)

    ###############################################
    # delayed device initialization after startup #
    ###############################################

    _initDevice: (event) =>

      @log('debug', "Initializing from [#{event}]")
      if @config.autoConfig
        @_autoConfig()
        @config.autoConfig = false

      @alert = null
      @remote = null
      @enabled = null

      @sensors = []
      @switches = []

      @variables['state'] = "Error"

      if not !!@config.alert or @config.alert == '<auto>'
        @log('error', "Missing alert switch in configuration")
        return
      alert = @deviceManager.getDeviceById(@config.alert)
      if alert not instanceof AlertSwitch
        @log('error', "Device \"#{alert.id}\" is not a valid alert switch")
        return

      alert.system = @
      alert.on 'state', alertHandler

      @alert = alert
      @switches.push(alert)

      @log('debug', "Device \"#{alert.id}\" registered as alert switch device")

      if !!@config.remote and @config.remote != '<auto>'
        remote = @deviceManager.getDeviceById(@config.remote)
        if remote?
          @remote = remote
          @log('debug', "Device \"#{remote.id}\" registered as remote device")

          remote.system = @
          remote.on 'state', remoteHandler

      if !!@config.enabled and @config.enabled != '<auto>'
        enabled = @deviceManager.getDeviceById(@config.enabled)
        if enabled?
          @enabled = enabled
          @log('debug', "Device \"#{enabled.id}\" registered as enabled device")

      register = (sensor, event, expectedValue, required) =>
        @log('debug', "Device \"#{sensor.id}\" registered as sensor")
        @sensors.push(sensor)

        sensor.system = @
        sensor.required = if required then '_' + event else null
        sensor.expectedValue = expectedValue
        sensor.on event, sensorHandler

      for item in @config.sensors
        sensor = @deviceManager.getDeviceById(item.name)
        if sensor?
          if sensor instanceof env.devices.PresenceSensor
            register sensor, 'presence', true, item.required
          else if sensor instanceof env.devices.ContactSensor
            register sensor, 'contact', false, item.required
          else
            @log('error', "Device \"#{sensor.id}\" is not a valid sensor")
        else
          @log('error', "Device \"#{id}\" not found")

      for id in @config.switches
        actuator = @deviceManager.getDeviceById(id)
        if actuator?
          if actuator instanceof env.devices.SwitchActuator
            @switches.push(actuator)
            @log('debug', "Device \"#{actuator.id}\" registerd as switch")
          else
            @log('error', "Device \"#{actuator.id}\" is not a valid switch")

      # always turn off alert on system start
      @_switchDevices(false)

      # adjust variable to initial state after initialization
      @variables['state'] = if @_state then "Enabled" else "Disabled"
      @_updateState('init')

    _checkSensors: () =>

      if @config.checkSensors
        for sensor in @sensors
          if sensor.required?
            if sensor[sensor.required] == sensor.expectedValue
              @log('info', "Device #{sensor.id} not ready for activation")
              @variables['reject'] = sensor.id
              return false

        # all devices checked for a valid state
        @variables['reject'] = null
        return true

      else
        @log('debug', "Sensor checks disabled")
        @variables['reject'] = null
        return true

    #####################################################
    # dynamic creation of devices and runtime vatiabled #
    #####################################################

    _autoConfig: () =>

      @log('debug', "Running autoConfig ...")

      # AlertSwitch device
      alertId = if !!@config.alert and @config.alert != '<auto>' then @config.alert else @config.id + '-switch'
      @config.alert = alertId
      if not @deviceManager.isDeviceInConfig(alertId)
        config = {
          id: alertId
          name: "#{@config.name} switch"
          class: "AlertSwitch"
        }
        try
          alert = @deviceManager._loadDevice(config, null, null)
          @deviceManager.addDeviceToConfig(config)
          @log('debug', "Device \"#{alertId}\" added to configuration")
        catch error
          @log('error', error)

      # EnabledSwitch device
      enabledId = if !!@config.enabled and @config.enabled != '<auto>' then @config.enabled else @config.id + '-enabled'
      @config.enabled = enabledId
      if not @deviceManager.isDeviceInConfig(enabledId)
        config = {
          id: enabledId
          name: "#{@config.name} enabled"
          class: "EnabledSwitch"
        }
        try
          enabled = @deviceManager._loadDevice(config, null, null)
          @deviceManager.addDeviceToConfig(config)
          @log('debug', "Device \"#{enabledId}\" added to configuration")
        catch error
          @log('error', error)

      # AlertSystem variable device setup
      variables = []
      for suffix in ["time", "info", "state"]
        name = @config.id + '-' + suffix
        variables.push({
          name: name
          expression: '$' + name
        })

      stateId = if !!@config.state and @config.state != '<auto>' then @config.state else @config.id + '-state'
      @config.state = stateId
      if not @deviceManager.isDeviceInConfig(stateId)
        config = {
          id: stateId,
          name: "#{@config.name} state"
          class: "VariablesDevice"
          variables: variables
        }
        try
          state = @deviceManager._loadDevice(config, null, null)
          @deviceManager.addDeviceToConfig(config)
          @log('debug', "Device \"#{stateId}\" added to configuration")
        catch error
          @log('error', error)


    ################################################
    # update VariableDevice from runtime variables #
    ################################################

    _updateState: (reason) =>
    # display the state variables defined elsewhere
      @variables['time'] = new Date().format(@timeformat)
      V = { "time": @variables['time'], "state": @variables['state'].toUpperCase() }

      trigger = @variables['trigger']
      reject = @variables['reject']
      error = @variables['error']

      V.info =
        if V.state is "ALERT" and trigger? then "[#{@deviceManager.getDeviceById(trigger).name}]"
        else if V.state is "REJECTED" and reject? then "[#{@deviceManager.getDeviceById(reject).name}]"
        else if V.state is "ERROR" and error? then "[#{error}]"
        else if V.state is "ENABLED" then "[on]"
        else if V.state is "DISABLED" then "[off]"
        else ""

      for k, v of V
        @variableManager.setVariableToValue(@id + '-' + k, if v? then v else "")

    ##################################################
    # delayed switching of HomeduinoRFSwitch devices #
    ##################################################

    _switchDevices: (state) =>

      timeout = 0

      if @switches?
        for actuator in @switches
          # TODO: check against HomeduinoRFSwitch
          @log('debug', "Switching device \"#{actuator.id}\" => #{if state then 'ON' else 'OFF'}")
          if actuator instanceof env.devices.DummySwitch
            actuator.changeStateTo(state)
          else
            timeout += @config.rfDelay
            @log('debug', "Switching device \"#{actuator.id}\" delayed #{timeout} ms!")
            setTimeout((->
              actuator.changeStateTo(state)), timeout)
      return true


  return plugin
