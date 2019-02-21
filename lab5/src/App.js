import React, { Component } from "react";
import "bulma/css/bulma.min.css";
import "./App.css";
import Modal from "./Modal";
import {
  getTemperatureLog,
  getProfileInformation,
  getThresholdViolations
} from "./pico-api";

class App extends Component {
  constructor(props) {
    super(props);
    this.state = { isLoaded: false, isModalVisible: false };
  }
  componentDidMount() {
    this.syncLocalStateWithPicoState();
  }

  toggleModalVisibility = () => {
    this.handleChangeModalVisibility(!this.state.isModalVisible);
  };
  syncLocalStateWithPicoState = async () => {
    this.setState(
      {
        temperatureLog: await getTemperatureLog(),
        thresholdViolationLog: await getThresholdViolations(),
        profile: await getProfileInformation()
      },
      () => {
        this.setState({ isLoaded: true });
      }
    );
  };
  handleChangeModalVisibility = isVisible => {
    this.setState({ isModalVisible: isVisible });
  };
  render() {
    if (this.state.isLoaded === false) {
      return null;
    }
    const tempList = this.state.temperatureLog.map(temp => (
      <div className="list-item" key={temp.timestamp}>
        <b>{temp.temperature}</b> |{" "}
        <i>
          <small>{temp.timestamp}</small>
        </i>
      </div>
    ));
    const thresholdList = this.state.temperatureLog
      .filter(temp => temp.temperature > this.state.profile.threshold)
      .map(violation => (
        <div className="list-item" key={violation.timestamp}>
          <b>{violation.temperature}</b> |{" "}
          <i>
            <small>{violation.timestamp}</small>
          </i>
        </div>
      ));
    const currentTemperature = this.state.temperatureLog[
      this.state.temperatureLog.length - 1
    ].temperature;
    return (
      <div className="App">
        <Modal
          onProfileUpdated={this.syncLocalStateWithPicoState}
          profile={this.state.profile}
          isActive={this.state.isModalVisible}
          changeModalVisibility={this.handleChangeModalVisibility}
        />
        <section className="hero is-small is-primary is-bold">
          <div className="hero-body">
            <div className="container">
              <a
                onClick={this.toggleModalVisibility}
                className="button profile-button"
              >
                Profile
              </a>
              <h2 className="subtitle">Current temp: {currentTemperature} F</h2>
            </div>
          </div>
        </section>
        <section className="hero is-small is-info is-bold">
          <div className="hero-body">
            <div className="container">
              <h2 className="subtitle">Recent Temperatures</h2>
              <div className="list temp-list">{tempList}</div>
            </div>
          </div>
        </section>
        <section className="hero is-small is-danger is-bold theshold-container">
          <div className="hero-body">
            <div className="container">
              <h2 className="subtitle">Threshold Violations</h2>
              <div className="list temp-list">{thresholdList}</div>
            </div>
          </div>
        </section>
      </div>
    );
  }
}

export default App;
