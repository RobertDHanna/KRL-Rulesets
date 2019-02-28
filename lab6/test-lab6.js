const got = require("got");
const queryBaseURL = `http://localhost:8080/sky/cloud/DsCZqtwo5kiQMw2WHnSYgT/manage_sensors/`;
const eventBaseURL = `http://localhost:8080/sky/event/VaCanTeGydW6E5qynXFuBL/5/sensor/`;

const sleep = ms => new Promise(r => setTimeout(r, ms));

const ll = (...args) => {
  console.log("\n\n**********************************");
  console.log("________________________________");
  console.log(args[0]);
  console.log("________________________________\n");
  delete args[0];
  args.map(arg => console.log("\n", arg, "\n"));
};

const createPicosTest = async () => {
  const picosToCreate = ["Sensor 1", "Sensor 2", "Sensor 3"];
  await Promise.all(
    picosToCreate.map(name => got(`${eventBaseURL}new_sensor?name=${name}`))
  );
  await sleep(100);
  const result = await got(`${queryBaseURL}sensors`);
  const sensorsCreated = Object.keys(JSON.parse(result.body))
    .map(name => picosToCreate.includes(name))
    .reduce((accum, curr) => accum && curr, true);
  ll(
    "Testing: Create Sensor Picos",
    `Creating picos: ${picosToCreate.join(", ")}`,
    `Picos received from pico engine: ${Object.keys(
      JSON.parse(result.body)
    ).join(", ")}`,
    `Test Passed: ${sensorsCreated}`
  );
};

const deletePicoTest = async picoToDelete => {
  await got(`${eventBaseURL}unneeded_sensor?name=${picoToDelete}`);
  await sleep(100);
  const result = await got(`${queryBaseURL}sensors`);
  const jsonResult = Object.keys(JSON.parse(result.body));
  const picoWasDeleted = jsonResult.includes(picoToDelete) === false;
  ll(
    "Testing: Delete Sensor Pico",
    `Deleting pico: ${picoToDelete}`,
    `Picos received from pico engine: ${jsonResult.join(", ")}`,
    `Test Passed: ${picoWasDeleted}`
  );
};

const testNewTemperatureEvents = async () => {
  const testTempInRange = {
    temperature: { temperatureF: 70 },
    timestamp: "Test Time Stamp"
  };
  const testTempThresholdViolation = {
    temperature: { temperatureF: 100.9 },
    timestamp: "Test Time Stamp"
  };
  let result = await got(`${queryBaseURL}sensors`);
  const jsonResult = JSON.parse(result.body);
  await Promise.all(
    Object.values(jsonResult).map(async eci =>
      got(
        `http://localhost:8080/sky/event/${eci}/5/wovyn/new_temperature_reading`,
        { json: true, body: testTempInRange }
      )
    )
  );
  await Promise.all(
    Object.values(jsonResult).map(async eci =>
      got(
        `http://localhost:8080/sky/event/${eci}/5/wovyn/new_temperature_reading`,
        { json: true, body: testTempThresholdViolation }
      )
    )
  );
  const temperatureResults = await Promise.all(
    Object.values(jsonResult).map(async eci =>
      got(
        `http://localhost:8080/sky/cloud/${eci}/temperature_store/temperatures`
      )
    )
  );
  const jsonTemps = temperatureResults.map(r => {
    return JSON.parse(r.body);
  });

  const tempPairs = jsonTemps.map(results => {
    const thresholdTemp = results[results.length - 1].temperature;
    const inRangeTemp = results[results.length - 2].temperature;
    return [thresholdTemp, inRangeTemp];
  });
  const testResult = tempPairs.reduce((accum, curr) => {
    const [thresholdTemp, inRangeTemp] = curr;
    return (
      accum &&
      thresholdTemp === testTempThresholdViolation.temperature.temperatureF &&
      inRangeTemp === testTempInRange.temperature.temperatureF
    );
  }, true);

  ll(
    "Testing: Sensor Picos Respond To Temp Events",
    `Adding temp: ${testTempInRange.temperature.temperatureF}`,
    `Adding temp: ${testTempThresholdViolation.temperature.temperatureF}`,
    `${tempPairs
      .map(pair => `Recieved temps: ${pair[0]}, ${pair[1]}`)
      .join("\n")}`,
    `Sensors Received And Stored Temps: ${testResult}`
  );
};

const testSensorProfiles = async () => {
  let result = await got(`${queryBaseURL}sensors`);
  const jsonResult = JSON.parse(result.body);
  const sensorProfileResults = await Promise.all(
    Object.values(jsonResult).map(async eci =>
      got(`http://localhost:8080/sky/cloud/${eci}/sensor_profile/profile`)
    )
  );
  const jsonSensorProfileResults = sensorProfileResults.map(r =>
    JSON.parse(r.body)
  );
  const sensorProfile1 = jsonSensorProfileResults[0];
  const sensorProfile2 = jsonSensorProfileResults[1];
  const testResult =
    sensorProfile1.name === "Sensor 2" &&
    sensorProfile1.location === "some location" &&
    sensorProfile1.number === "some number" &&
    sensorProfile1.threshold === 72 &&
    sensorProfile2.name === "Sensor 3" &&
    sensorProfile2.location === "some location" &&
    sensorProfile2.number === "some number" &&
    sensorProfile2.threshold === 72;
  ll(
    "Testing: Sensor Picos Profiles Are Set Correctly",
    sensorProfile1,
    sensorProfile2,
    `Sensors Received And Stored Temps: ${testResult}`
  );
};

const driver = async () => {
  await createPicosTest();
  await deletePicoTest("Sensor 1");
  await testNewTemperatureEvents();
  await testSensorProfiles();
};

driver();
