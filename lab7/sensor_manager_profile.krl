ruleset sensor_manager_profile {
  meta {
    use module apis_and_picos.keys
    use module apis_and_picos.twilio_wrapper alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token = keys:twilio{"auth_token"}
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    sms_number = "some number"
  }
  rule notify_sms_threshold_violation {
    select when manager threshold_violation
     twilio:send_sms(
       sms_number,
       "$TWILIONUMBER",
       "There was a temperature violation."
     )
  }
}
