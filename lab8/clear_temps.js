const got = require("../lab6/node_modules/got/source");
const sensorEcis = [
  "RddvwhQMn34xw8D5EtoNnV",
  "FXGMt9KxKEXNdKN2A4LmHG",
  "7HbX1msy6DqBrqa3HCchUg"
];

const baseEventUrl = `http://localhost:8080/sky/event/`;

sensorEcis.map(eci =>
  got(`${baseEventUrl}${eci}/none/sensor/reading_reset`, {
    json: true,
    body: {
      temperature: { temperatureF: Math.random() * 120 },
      timestamp: new Date()
    }
  })
);
