module.exports = {
  title: "pimatic alarm device config schemas"
  AlertSwitch:
    title: "AlertSwitch config"
    type: "object"
    extensions: ["xLink", "xConfirm", "xOnLabel", "xOffLabel"]
    properties: {}
  EnabledSwitch:
    title: "EnabledSwitch config"
    type: "object"
    extensions: ["xLink", "xConfirm", "xOnLabel", "xOffLabel"]
    properties: {}
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
        default: ''
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
        default: 1000
}
