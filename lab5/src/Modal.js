import React, { Component } from "react";
import { updateProfileInformation } from "./pico-api";

class Modal extends Component {
  componentDidMount() {
    this.closeButton.addEventListener("click", this.closeModal);
    this.submitButton.addEventListener("click", this.handleSubmit);
  }
  componentWillUnmount() {
    this.closeButton.removeEventListener("click", this.closeModal);
    this.submitButton.removeEventListener("click", this.handleSubmit);
  }
  handleSubmit = async () => {
    const query = {
      name: this.nameInput.value,
      location: this.locationInput.value,
      number: this.numberInput.value,
      threshold: this.thresholdInput.value
    };
    await updateProfileInformation(query);
    this.props.changeModalVisibility(false);
    this.props.onProfileUpdated();
  };
  setCloseButton = node => {
    this.closeButton = node;
  };
  setSubmitButton = node => {
    this.submitButton = node;
  };
  setNameInput = node => {
    this.nameInput = node;
  };
  setLocationInput = node => {
    this.locationInput = node;
  };
  setNumberInput = node => {
    this.numberInput = node;
  };
  setThresholdInput = node => {
    this.thresholdInput = node;
  };
  closeModal = () => {
    this.props.changeModalVisibility(false);
  };
  render() {
    const { name, location, number, threshold } = this.props.profile;
    return (
      <div className={`modal ${this.props.isActive ? "is-active" : ""}`}>
        <div className="modal-background" />
        <div className="modal-content">
          <div className="card">
            <header className="card-header">
              <p className="card-header-title">Profile Info</p>
            </header>
            <div className="card-content">
              <div className="field is-horizontal">
                <div className="field-label is-normal">
                  <label className="label">Name</label>
                </div>
                <div className="field-body">
                  <div className="field">
                    <p className="control">
                      <input
                        ref={this.setNameInput}
                        className="input"
                        type="string"
                        placeholder="Name"
                        defaultValue={name}
                      />
                    </p>
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label is-normal">
                  <label className="label">Location</label>
                </div>
                <div className="field-body">
                  <div className="field">
                    <p className="control">
                      <input
                        ref={this.setLocationInput}
                        className="input"
                        type="string"
                        placeholder="Location"
                        defaultValue={location}
                      />
                    </p>
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label is-normal">
                  <label className="label">Contact #</label>
                </div>
                <div className="field-body">
                  <div className="field">
                    <p className="control">
                      <input
                        ref={this.setNumberInput}
                        className="input"
                        type="tel"
                        placeholder="Phone #"
                        defaultValue={number}
                      />
                    </p>
                  </div>
                </div>
              </div>
              <div className="field is-horizontal">
                <div className="field-label is-normal">
                  <label className="label">Threshold</label>
                </div>
                <div className="field-body">
                  <div className="field">
                    <p className="control">
                      <input
                        ref={this.setThresholdInput}
                        className="input"
                        type="string"
                        placeholder="Threshold"
                        defaultValue={threshold}
                      />
                    </p>
                  </div>
                </div>
              </div>
            </div>
            <a ref={this.setSubmitButton} className="button">
              Submit
            </a>
          </div>
        </div>
        <button
          ref={this.setCloseButton}
          className="modal-close is-large"
          aria-label="close"
        />
      </div>
    );
  }
}

export default Modal;
