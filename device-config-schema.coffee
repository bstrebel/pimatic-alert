module.exports = {
  title: "pimatic alarm device config schemas"
  AlertSwitch:
    title: "AlertSwitch config"
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
      rfdelay:
        description: "Delay switching of HomuduinoRFSwitch for rfdelay ms"
        type: "number"
        default: "250"
      checksensors:
        description: "Enable/Disable sensor checking on activation"
        type: "boolean"
        default: false
}
