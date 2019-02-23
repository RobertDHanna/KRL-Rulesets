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
  const sensorsCreated = Array.from(JSON.parse(result.body))
    .map(name => picosToCreate.includes(name))
    .reduce((accum, curr) => accum && curr, true);
  ll(
    "Testing: Create Sensor Picos",
    `Creating picos: ${picosToCreate.join(", ")}`,
    `Picos received from pico engine: ${JSON.parse(result.body).join(", ")}`,
    `Test Passed: ${sensorsCreated}`
  );
};

const deletePicoTest = async picoToDelete => {
  await got(`${eventBaseURL}unneeded_sensor?name=${picoToDelete}`);
  await sleep(100);
  const result = await got(`${queryBaseURL}sensors`);
  const jsonResult = JSON.parse(result.body);
  const picoWasDeleted = jsonResult.includes(picoToDelete) === false;
  ll(
    "Testing: Delete Sensor Pico",
    `Deleting pico: ${picoToDelete}`,
    `Picos received from pico engine: ${jsonResult.join(", ")}`,
    `Test Passed: ${picoWasDeleted}`
  );
};

const driver = async () => {
  await createPicosTest();
  await deletePicoTest("Sensor 1");
};

driver();
