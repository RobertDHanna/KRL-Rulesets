const got = require("../lab6/node_modules/got/source");
const sensorEcis = ["JsRPGa8QtEGsHVjjL5QVnL"];

const baseEventUrl = `http://localhost:8080/sky/event/`;

sensorEcis.map(eci =>
  got(`${baseEventUrl}${eci}/none/wovyn/new_temperature_reading`, {
    json: true,
    body: {
      temperature: { temperatureF: Math.random() * 120 },
      timestamp: new Date()
    }
  })
);
