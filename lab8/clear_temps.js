const got = require("../lab6/node_modules/got/source");
const sensorEcis = [
  "S8tSGVoqMmHQKuh5tsLZu3",
  "CtDcLTyCQgMqikdNoTu7v7",
  "JsRPGa8QtEGsHVjjL5QVnL"
];

const baseEventUrl = `http://localhost:8080/sky/event/`;

sensorEcis.map(eci =>
  got(`${baseEventUrl}${eci}/none/sensor/reading_reset`, {
    // json: true,
    // body: {
    //   temperature: { temperatureF: Math.random() * 120 },
    //   timestamp: new Date()
    // }
  })
);
