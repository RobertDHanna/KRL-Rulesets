ruleset manage_sensors {
  meta {
    shares sensors, sensorTemperatures
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    sensors = function() {
      ent:sensors.defaultsTo({}).keys()
    }
    sensorTemperatures = function() {
      sensor_names = ent:sensors.values();
      sensor_names.map(
        function(eci) { {"eci": eci, "temp": wrangler:skyQuery(eci, "temperature_store", "temperatures")} }
      )
      .reduce(function(accum, currentVal) { 
        accum{[currentVal{"eci"}]} = currentVal{"temp"};
        accum
      }, {})
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
  rule store_new_sensor {
    select when wrangler child_initialized
    pre {
      eci = event:attr("eci")
      sensor_name = event:attr("rs_attrs"){"name"}
    }
    if sensor_name.klog("found sensor_name") then 
      event:send({ "eci": eci,
         "domain": "sensor", "type": "profile_updated",
         "attrs" : {"name": sensor_name, "location": "some location", "number": "some number", "threshold": 12} })
    fired {
      ent:sensors := ent:sensors.defaultsTo({});
      ent:sensors{[sensor_name]} := eci
    }
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
      clear ent:sensors{[name]}
    }
  }
}
