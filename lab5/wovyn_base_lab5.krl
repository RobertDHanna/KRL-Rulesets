ruleset wovyn_base {
  meta {
    shares __testing
    use module apis_and_picos.keys
    use module apis_and_picos.twilio_wrapper alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    use module sensor_profile
  }
  global {
    __testing = { "queries": [ { "name": "__testing" } ],
                  "events": [ { "domain": "post", "type": "test",
                              "attrs": [ "temp", "baro" ] } ] }
    temperature_threshold = 75.7
    threshold_violation_number = "$NUMBER"
  }
 
  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      genericThing = event:attrs{"genericThing"}.klog("attrs: ")
    }
    if genericThing != null then send_directive("wovyn heartbeat", {"wovyn":"Wovyn Directive"})
    fired {
      raise wovyn event "new_temperature_reading"
        attributes { "temperature": genericThing{["data", "temperature"]}[0], "timestamp": time:now() }
    }
  }
  
  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attrs{["temperature", "temperatureF"]}.klog("temp: ")
      timestamp = event:attrs{"timestamp"}
    }
    if temperature > sensor_profile:profile{"threshold"} then send_directive("high temp violation", {"temp": temperature})
    fired {
      raise wovyn event "threshold_violation"
        attributes {"temperature": temperature, "timestamp":timestamp}
    }
  }
  
  rule threshold_notification {
    select when wovyn threshold_violation
    twilio:send_sms(
      sensor_profile:profile{"number"},
      "$TWILIONUMBER",
      "There was a temperature violation."
    )
  }
}