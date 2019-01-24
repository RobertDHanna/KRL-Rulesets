ruleset apis_and_picos.use_twilio {
  meta {
    use module apis_and_picos.keys
    use module apis_and_picos.twilio_wrapper alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
  }
 
  rule test_send_sms {
    select when test new_message
    twilio:send_sms(
      event:attr("to"),
      event:attr("from"),
      event:attr("message")
    )
  }
  
  rule get_sms_messages {
    select when test get_messages
    twilio:messages(
      event:attr("message_id"),
      event:attr("to"),
      event:attr("from"),
      event:attr("pagination_uri")
    )
  }
}