pimatic-alert
=============
The plugin is based on [_pimatic-alarm_](https://github.com/michbeck100/pimatic-alarm) which is a very neat and powerfull solution
to realize a simple alarm system with pimatic sensor and actuator devices.

I've learned a lot about pimatic event handling by the examination of the code ...

The new _pimatic-alert_ plugin was build to replace my multi-instance
alarm system which requires about 50 rules to maintain states and
actions of 15 (HomeduinoRF)-sensors and -switch devices. The system
works reliable but administration and change management is painful and
error-prone. The plugin provides an AlertSystem device which can be
easily configured through the mobile frontend. Even without restarting
pimatic.

Once you setup the alert system you can easily react on alert events
with simple rules like:

```
when alert-switch is turned on then log "alert triggered by
$alert-trigger at $alert-time" and turn alert-switch off after 5 minutes
```
An alert system is build from the following components:

- Sensor Devices: Most probably something like HomeduinoRFPir or
  HomeduinoRFContactSensor to trigger an alert. Or use dummy devices
  like in the sample config.json from the repository.
- AlertSystem: Main controller device to enable/disable the alert system
- AlertSwitch: Main switch turned on by the sensor trigger devices.
- Rules to do something when an alert is triggered

The alert switch as well as some runtime variables are generated
automatically in the background with the following IDs (where _ALERT_
stands for the ID of the AlertSystem device):

- _ALERT_-**switch**: the AlertSwitch device
- _ALERT_-**state**: VariablesDevice to be used in the frontend
- **$**_ALERT_-**trigger**: the device that triggerd the alert
- **$**_ALERT_-**time**: the timestamp of the last update
- **$**_ALERT_-**reject**: device that caused a rejection (see below)
- **$**_ALERT_-**error**: some error descriptions

In adition their are some optional properties which may be useful for
your environment:

- **remote**: and additional switch which is kept in sync with the system
  switch. Can be used to enable/disable the alert system with via the
  mobile frontend **and** an addition HomeduinoRFSwitch
- **switches**: a list of additional switch devices that will be
  automatically turned on when an alert is triggered (and turned off
  when disabling the alarm system) without the need of additional rules.
- **required**: sensors marked "required" are checked for a valid state if
  you try to turn on the alarm system. The activation will be rejected
  if, for example, a contact sensor is open. You have to close the
  door/window first before activating the alert system ;-)


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
      switches:
        description: "List of switch devices"
        type: "array"
        default: []
        items:
          description: "Switch ID"
          type: "string"
      remote:
        description: "Optional remote control switch"
        type: "string"
      alert:
        description: "AlertSwitch device"
        type: "string"
        default: '<auto>'
      state:
        description: "Alert system VariablesDevice"
        type: "string"
        default: '<auto>'
      trigger:
        description: "Display trigger device on alert system switch"
        type: "boolean"
        default: false
      autoconfig:
        description: "Generate default switch devices and variables"
        type: "boolean"
        default: true
```
