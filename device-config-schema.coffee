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
        description: "Remote control"
        type: "string"
        default: ""
      alert:
        description: "Alert switch"
        type: "string"
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
