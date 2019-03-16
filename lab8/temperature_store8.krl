ruleset temperature_store {
    meta {
        provides temperatures, threshold_violations, inrange_temperatures
        shares temperatures, threshold_violations, inrange_temperatures
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias Subscriptions
    }
    global {
        temperatures = function() {
          ent:temperatures.defaultsTo([])
        }
        threshold_violations = function() {
          ent:threshold_violations.defaultsTo([])
        }
        inrange_temperatures = function() {
          ent:temperatures.filter(function(el) {  not ent:threshold_violations.any(function(el2) {el{"timestamp"} == el2{"timestamp"}}) })
        }
    }
    rule process_temperature_report {
      select when temperature report
      pre {
        correlationID = event:attrs{"correlationID"}
        requesterEci = event:attrs{"eci"}
        temperatures = temperatures()
      }
      event:send({
        "eci": requesterEci,
        "eid": "report",
        "domain": "sensor",
        "type": "report_ready",
        "attrs": {
          "correlationID": correlationID,
          "temperatures": temperatures
        }
      })
    }
    rule collect_temperatures {
        select when wovyn new_temperature_reading
        pre {
          temperature = event:attrs{["temperature", "temperatureF"]}.klog("temp: ")
          timestamp = event:attrs{"timestamp"}
        }
        always {
          ent:temperatures := ent:temperatures.defaultsTo([]).append({"temperature":temperature, "timestamp":timestamp});
        }
    }
    rule collect_threshold_violations {
        select when wovyn threshold_violation
        pre {
          temperature = event:attrs{"temperature"}.klog("temp: ")
          timestamp = event:attrs{"timestamp"}
        }
        always {
          ent:threshold_violations := ent:threshold_violations.defaultsTo([]).append({"temperature":temperature, "timestamp": timestamp});
        }
    }
    rule notify_manager_threshold_violation {
      select when wovyn threshold_violation
      pre {
        sub =  Subscriptions:established("Tx_role", "sensor_manager").map(function(subscription) {
          subscription
        })[0];
      }
      if sub then event:send({ 
          "eci": sub{"Tx"}, "eid": "none",
          "domain": "manager", "type": "threshold_violation",
          "attrs": {}
      }, sub{"Tx_host"})
    }
    rule clear_temeratures {
        select when sensor reading_reset
        always {
          ent:temperatures := [];
          ent:threshold_violations := [];
        }
    }
}