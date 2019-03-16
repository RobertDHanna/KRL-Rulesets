ruleset manage_sensors8 {
  meta {
    shares sensors, sensorTemperatures, reports
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias Subscriptions
  }
  global {
    sensors = function() {
      ent:sensors.defaultsTo({})
    }
    sensorTemperatures = function() {
      Subscriptions:established("Tx_role", "sensor").map(function(subscription) {
        {"eci": subscription{"Tx"}, "temp": wrangler:skyQuery(subscription{"Tx"}, "temperature_store", "temperatures", {}, subscription{"Tx_host"})}
      })
      .reduce(function(accum, currentVal) { 
        accum{[currentVal{"eci"}]} = currentVal{"temp"};
        accum
      }, {})
    }
    reports = function() {
      sensorReportsLength = ent:sensorReports.defaultsTo({}).values().length();
      (sensorReportsLength > 5) => ent:sensorReports.values().splice(sensorReportsLength - 5, sensorReportsLength) | ent:sensorReports.values()
    }
    thresholdNumber = 72
  }
  rule create_temperature_report {
    select when sensor report
    foreach Subscriptions:established("Tx_role","sensor") setting (subscription)
      pre {
        sensorReports = ent:sensorReports.defaultsTo({})
        correlationID = ent:correlationID.defaultsTo(0)
        sensorEci = subscription{"Tx"}
      }
      event:send({
        "eci": sensorEci, 
        "eid": "report",
        "domain": "temperature", 
        "type": "report",
        "attrs": {
          "eci": meta:eci,
          "correlationID": correlationID,
          "Rx": sensorEci
        }
      })
      always {
        ent:sensorReports{correlationID} := { 
          "temperature_sensors": Subscriptions:established("Tx_role","sensor").length(),
          "responding": 0, "temperatures": [] 
        } on final;
        ent:correlationID := correlationID + 1 on final
      }
  }
  rule report_catcher {
    select when sensor report_ready
    pre {
      correlationID = event:attrs{"correlationID"}
      temperatures = event:attrs{"temperatures"}
      currentResponders = ent:sensorReports{[correlationID, "responding"]}
    }
    always {
      ent:sensorReports{[correlationID, "temperatures"]}.append(temperatures);
      ent:sensorReports{[correlationID, "responding"]} := currentResponders + 1
    }
  }
  rule create_new_sensor {
    select when sensor new_sensor
    pre {
      name = event:attr("name").defaultsTo("Default Sensor Name")
    }
    if not (ent:sensors.klog("sensors: ") >< name.klog("name: ")) then noop()
    fired {
      raise wrangler event "child_creation"
        attributes { "name": name,
                     "color": "#ffff00",
                     "rids": ["temperature_store", "wovyn_base", "sensor_profile"] }
    }
  }
  rule introduce_sensor {
    select when sensor introduce
    pre {
      sensor_name = event:attr("name")
      eci = event:attr("eci")
      host = event:attr("host")
      exists = ent:sensors >< sensor_name
    }
    if not exists then 
      event:send(
        { "eci": meta:eci, "eid": "subscription",
          "domain": "wrangler", "type": "subscription",
          "attrs": { "name": sensor_name,
                     "Rx_role": "sensor_manager",
                     "Tx_role": "sensor",
                     "channel_type": "subscription",
                     "wellKnown_Tx": eci,
                     "Tx_host": host } } )
    fired {
      ent:sensors := ent:sensors.defaultsTo({});
      ent:sensors{[sensor_name]} := eci;
    }
  }
  rule store_new_sensor {
    select when wrangler child_initialized
    pre {
      eci = event:attr("eci")
      sensor_name = event:attr("rs_attrs"){"name"}
    }
    if sensor_name.klog("found sensor_name") then 
      event:send({ "eci": eci,
         "domain": "sensor", "type": "profile_updated",
         "attrs" : {"name": sensor_name, "location": "some location", "number": "some number", "threshold": thresholdNumber} })
    fired {
      ent:sensors := ent:sensors.defaultsTo({});
      ent:sensors{[sensor_name]} := eci;
    }
  }
  rule start_sensor_subscription {
    select when wrangler child_initialized
    pre {
      eci = event:attr("eci")
      sensor_name = event:attr("rs_attrs"){"name"}
    }
    if sensor_name.klog("found sensor_name") then 
      event:send(
        { "eci": meta:eci, "eid": "subscription",
          "domain": "wrangler", "type": "subscription",
          "attrs": { "name": sensor_name,
                     "Rx_role": "sensor_manager",
                     "Tx_role": "sensor",
                     "channel_type": "subscription",
                     "wellKnown_Tx": eci } } )
  }
  rule forget_sensor {
    select when sensor unneeded_sensor
    pre {
      name = event:attr("name")
      exists = ent:sensors >< name
    }
    if exists then noop()
    fired {
      raise wrangler event "child_deletion"
        attributes {"name": name};
      clear ent:sensors{[name]};
    }
  }
}
