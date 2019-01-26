ruleset apis_and_picos.use_twilio {
  meta {
    use module apis_and_picos.keys
    use module apis_and_picos.twilio_wrapper alias twilio
        with account_sid = keys:twilio{"account_sid"}
             auth_token =  keys:twilio{"auth_token"}
    shares messages
    logging on
  }
  
  global {
    messages = function(message_id, to, from, page_size, page, page_token) {
      twilio:messages(
        message_id,
        to,
        from,
        page_size,
        page,
        page_token
      )
    }
  }
 
  rule test_send_sms {
    select when test new_message
    twilio:send_sms(event:attr("to"),
                    event:attr("from"),
                    event:attr("message")
                   )
  }
}