const eci = "3RRYVMNphUh2ayQ2iaFUUi";
const baseQueryUrl = `http://localhost:8080/sky/cloud/${eci}/`;
const baseEventUrl = `http://localhost:8080/sky/event/${eci}/5/`;

export const getTemperatureLog = async () => {
  return await fetch(baseQueryUrl + "temperature_store/temperatures").then(r =>
    r.json()
  );
};

export const getThresholdViolations = async () => {
  return await fetch(
    baseQueryUrl + "temperature_store/threshold_violations"
  ).then(r => r.json());
};

export const getProfileInformation = async () => {
  return await fetch(baseQueryUrl + "sensor_profile/profile").then(r =>
    r.json()
  );
};

export const updateProfileInformation = async params => {
  return await fetch(
    baseEventUrl +
      "sensor/profile_updated?" +
      Object.keys(params)
        .map(
          key => encodeURIComponent(key) + "=" + encodeURIComponent(params[key])
        )
        .join("&")
  ).then(r => r.json());
};
