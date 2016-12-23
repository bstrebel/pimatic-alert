[![Build Status](http://img.shields.io/travis/bstrebel/pimatic-alert/master.svg)](https://travis-ci.org/bstrebel/pimatic-alert)
[![Version](https://img.shields.io/npm/v/pimatic-alert.svg)](https://img.shields.io/npm/v/pimatic-alert.svg)
[![downloads][downloads-image]][downloads-url]

[downloads-image]: https://img.shields.io/npm/dm/pimatic-alert.svg?style=flat
[downloads-url]: https://npmjs.org/package/pimatic-alert

pimatic-alert
=============
The plugin is based on [_pimatic-alarm_](https://github.com/michbeck100/pimatic-alarm) which is a very neat and powerfull solution
to realize a simple alarm system with pimatic sensors and actuator devices.

The new _pimatic-alert_ plugin was build to replace my multi-instance
alarm system which required 83 rules to maintain configuration, states
and actions of (HomeduinoRF-) contact/PIR sensors (27) and switch
devices (8). The system works fairly reliable but administration and
change management is painful and error-prone. 

This plugin provides an AlertSystem device which can be easily
configured through the mobile frontend. Many devices, rules and actions
required by such kind of alert systems are configurable through the
controller device. The alert system can be reconfigured on the fly even
without restarting pimatic. It's also simple, to maintain several alert
profiles (day, night, vacation, etc.) and activate them on demand.

Once you setup the alert system you can easily react on alert events
with simple rules like:

```
when alert-switch is turned on then log "alert triggered by
$alert-trigger at $alert-time" and turn alert-switch off after 5 minutes
```
Use the [sample configuration](https://github.com/bstrebel/pimatic-alert/tree/master/assets) from github to start playing on a test system.

An alert system is build from the following components:

- **Sensor Devices**: most probably something like HomeduinoRFPir or
  HomeduinoRFContactSensor to trigger an alert.
- **AlertSystem**: main controller device to enable/disable the alert system
- **AlertSwitch**: main switch turned on by the sensor trigger devices
- **Rules**: to do something when an alert is triggered ...

The alert switch as well as some runtime variables are generated
automatically in the background with the following pre-defined IDs (where _ALERT_
stands for the ID of the AlertSystem device):

- _ALERT_-**switch**: AlertSwitch device triggerd by sensor
- _ALERT_-**enabled**: EnabledSwitch reflecting the state of the system
- _ALERT_-**state**: VariablesDevice to be used in the frontend
- **$**_ALERT_-**trigger**: the device that triggerd the alert
- **$**_ALERT_-**time**: the timestamp of the last update
- **$**_ALERT_-**reject**: device that caused a rejection (see below)
- **$**_ALERT_-**error**: some error descriptions

Set the **autoConfig** option to false if you don't want the plugin to
generate devices but create them manually.

In adition their are some optional properties which may be useful for
your environment:

- **remote**: additional switch which is kept in sync with the system
  switch. Can be used to enable/disable the alert system via the mobile
  frontend **and** an optional HomeduinoRFSwitch remote control

- **switches**: a list of additional switch devices that will be
  automatically turned on when an alert is triggered (and turned off
  when disabling the alarm system) without the need of additional rules

- **required**: sensors marked "required" are checked for a valid state
  if you try to turn on the alarm system. The activation will be
  rejected if, for example, a contact sensor is open. You have to close
  the door/window first before activating the alert system ;-) If you
  use this feature (can be disabled with the **checkSensors** option)
  make sure to use the ALERT-enabled switch to trigger actions on
  enabling the alert system. The controller switch may immediately
  switch back to off if the activation is rejected but fires your rule
  by accident.

Installation
------------
Just install the most recent revision and change the plugin properties
according to your requirements

```json
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
actuators of the system. The device provides an "autoConfig" option to
generate required slave devices and runtime variables in the background.

```json
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
              default: false
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
        default: ""
      enabled:
        description: "EnabledSwitch device"
        type: "string"
        default: '<auto>'
      alert:
        description: "AlertSwitch device"
        type: "string"
        default: '<auto>'
      state:
        description: "Alert system VariablesDevice"
        type: "string"
        default: '<auto>'
      displayTrigger:
        description: "Display trigger device on alert system switch"
        type: "boolean"
        default: false
      autoConfig:
        description: "Generate default switch devices and variables"
        type: "boolean"
        default: true
      rfDelay:
        description: "Delay switching of HomuduinoRFSwitch for rfdelay ms"
        type: "number"
        default: 500
      checkSensors:
        description: "Enable/Disable sensor checking on activation"
        type: "boolean"
        default: false
      rejectDelay:
        description: "Delay before resetting the AlertSwitch after rejection"
        type: "number"
        default: 3000
```

Todo
----
- ~~Grunt test script~~
- ~~Travis integration~~


Changelog
---------

0.3.7

- basic grunt/mocha test suite
- updated documnetation
- some minor improvements

0.3.6

- initial grunt setup and travis integration

0.3.5

- allow recreation of alert system switch devices [#3](https://github.com/bstrebel/pimatic-alert/issues/2)
- improved error messages during device init

0.3.4

- bugfix delayed switching of HomeduinoRFSwitch
- several other changes to fix broken releases 0.3.2 and 0.3.3

0.3.1

- optimized triggering of remote controls to avoid racing conditions [#2](https://github.com/bstrebel/pimatic-alert/issues/2)

0.3.0

- EnabledSwitch device implementation [#2](https://github.com/bstrebel/pimatic-alert/issues/2)
- config properties refactoring (may issue some attribute warnings on
  first startup, pls. ignore)
- code cleanup

0.2.11

- bug fixes of event timing issues [#1](https://github.com/bstrebel/pimatic-alert/issues/1)
- many minor improvements

0.2.0

- initial release