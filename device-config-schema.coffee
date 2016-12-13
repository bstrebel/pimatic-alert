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
}
