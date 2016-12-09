[![Build Status](http://img.shields.io/travis/michbeck100/pimatic-alarm/master.svg)](https://travis-ci.org/michbeck100/pimatic-alarm)
[![Version](https://img.shields.io/npm/v/pimatic-alarm.svg)](https://img.shields.io/npm/v/pimatic-alarm.svg)
[![downloads][downloads-image]][downloads-url]

[downloads-image]: https://img.shields.io/npm/dm/pimatic-alarm.svg?style=flat
[downloads-url]: https://npmjs.org/package/pimatic-alarm

pimatic-alarm
=======================

pimatic-alarm is a [pimatic](https://github.com/pimatic/pimatic) plugin, that creates an alarm system based on the existing sensors and actuators defined in the pimatic installation.

The alarm system can switches on all devices, that extend from SwitchActuator, e.g. lights or smoke alarms.
The alarm can triggered by any of the devices, that extend from PresenceSensor or ContactSensor, e.g. [HomeduinoRFPir](https://github.com/pimatic/pimatic-homeduino#pir-sensor-example) or [HomeduinoRFContactSensor](https://github.com/pimatic/pimatic-homeduino#contact-sensor-example).

#### Installation

To install the plugin just add the plugin to the config.json of pimatic:

    {
      "plugin": "alarm"   
    }

The plugin comes with two types of devices. The "AlarmSwitch" can be used to manually trigger an alarm and the "AlarmSystem" is used to activate the alarm system.

Usage:

```json
"devices": [
  {
    "id": "alarm_system",
    "name": "Alarm system",
    "class": "AlarmSystem"
  },
  {
    "id": "alarm_trigger",
    "name": "Alarm",
    "class": "AlarmSwitch"
  }
]
```

Note that you need at least the "AlarmSystem" device, because the default state of the alarm system is "off".

#### Configuration

To add devices to the alarm system, the configuration of pimatic-alarm must be extended by adding a list of device ids to the attribute called "includes" of the plugin configuration.
Example:

```json
"plugins": [
  {
    "plugin": "alarm",
    "includes": [
      "id_of_switch",
      "id_of_presenceSensor"
    ]
  }
]
```

### Sponsoring

Do you like this plugin? Then consider a donation to support development.

<span class="badge-paypal"><a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=2T48JXA589B4Y" title="Donate to this project using Paypal"><img src="https://img.shields.io/badge/paypal-donate-yellow.svg" alt="PayPal donate button" /></a></span>
[![Flattr pimatic-alarm](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=michbeck100&url=https://github.com/michbeck100/pimatic-alarm&title=pimatic-alarm&language=&tags=github&category=software)

### Changelog
0.1.1
* Use empty string as trigger for no alarm because trigger is shown in gui next to switch

0.1.0
* [#2](https://github.com/michbeck100/pimatic-alarm/issues/2) setting name of triggering device into variable
* added alarm event

0.0.3
* [#1](https://github.com/michbeck100/pimatic-alarm/issues/1) switched from blacklist to whitelist

0.0.2
* fixed version

0.0.1
* Initial release
