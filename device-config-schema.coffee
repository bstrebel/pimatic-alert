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
      alert:
        description: "Alert switch"
        type: "string"
      sensors:
        description: "List of sensor devices"
        type: "array"
        default: []
        items:
          description: "Sensor ID"
          type: "string"
      switches:
        description: "List of switch devices"
        type: "array"
        default: []
        items:
          description: "Switch ID"
          type: "string"
      remote:
        description: "Remote control"
        type: "string"
        default: ""
}
