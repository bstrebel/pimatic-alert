pimatic-alert [work in progress]
================================
The plugin is based on [pimatic-alarm](https://github.com/michbeck100/pimatic-alarm) which is a very neat and powerfull solution
to realize a simple alarm system with pimatic sensor and actuator devices.

I've learned a lot about pimatic event handling by the examination of the code ...

The new pimatic-alert plugin was build to replace a multi-instance alarm
system which requires about 50 rules to maintain states and actions of
15 (HomeduinoRF)-sensors and -switch devices. The system works reliable
but administration and change management is painfull and error-prone.
The plugin provides an AlertSystem device which can be easily configured
through the mobile frontend.

Once you setup the alert system you can easily react on alert events
with simple rules like:

```
when alert-switch is turned on then log "alert triggerd by
$alert-trigger at $alert-time" and turn alert-switch off after 5 minutes
```


Installation
------------
Just install the most recent revision and change the plugin properties
according to your requirements

```
  title: "Plugin config options"
  type: "object"
  properties:
    debug:
      description: "Enable debug output"
      type: "boolean"
      default: false
    timeformat:
      description: "Time format specification"
      type: "string"
      default: "YYYY-MM-DD hh:mm:ss"
```

Configuration
-------------
Create an AlertSystem device which is the main control switch to
enable/disabe the alert system and references the sensor devices and
actuators of the system. The device provides an "autoconfig" option to
generate required devices and runtime variables in the background.

```
  AlertSystem:
    title: "AlertSystem config"
    type: "object"
    extensions: ["xLink", "xConfirm", "xOnLabel", "xOffLabel"]
    properties:
      remote:
        description: "Optional remote control switch"
        type: "string"
        default: ""
      autoconfig:
        description: "Generate default switch devices and variables"
        type: "boolean"
        default: true
      trigger:
        description: "Display trigger device on alert system switch"
        type: "boolean"
        default: false
      alert:
        description: "Alert switch"
        type: "string"
        default: ""
      state:
        description: "Alert system variable device"
        type: "string"
        default: ""
      switches:
        description: "List of switch devices"
        type: "array"
        default: []
        items:
          description: "Switch ID"
          type: "string"
      sensors:
        description: "List of sensor devices"
        type: "array"
        default: []
        items:
          description: "Sensor ID"
          type: "object"
          properties:
            name:
              description: "Device ID of the sensor"
              type: "string"
            required:
              description: "Required to enable alert system"
              type: "boolean"
              default: true
```
