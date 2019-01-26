ruleset apis_and_picos.twilio_wrapper {
  meta {
    configure using account_sid = ""
                    auth_token = ""
    provides
        send_sms, messages
  }
 
  global {
    send_sms = defaction(to, from, message) {
       base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/>>
       http:post(base_url + "Messages.json", form = {
            "From":from,
            "To":to,
            "Body":message
        })
    }
    
    messages = function(message_id, to, from, pagination_uri) {
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages>>;
        base_url = (message_id == null) => base_url | base_url + "/" + message_id;
        base_url = base_url + ".json";
        pagination_uri_is_set = pagination_uri != null && pagination_uri != "";
        base_url = pagination_uri_is_set == false => base_url | <<https://#{account_sid}:#{auth_token}@api.twilio.com#{pagination_uri}>>;
        m_qs = {
          "To": to,
          "From": from
        };
        m_qs = (pagination_uri_is_set || (to == null || to == "")) => m_qs.delete(["To"]) | m_qs;
        m_qs = (pagination_uri_is_set || (from == null || from == "")) => m_qs.delete(["From"]) | m_qs;
        
        response = http:get(base_url, qs = m_qs);
        
        status = response{"status_code"};
 
 
        error_info = {
            "error": "sky cloud request was unsuccesful.",
            "httpStatus": {
                "code": status,
                "message": response{"status_line"}
            }
        };
    
        response_content = response{"content"}.decode();
        response_error = (response_content.typeof() == "Map" && response_content{"error"}) => response_content{"error"} | 0;
        response_error_str = (response_content.typeof() == "Map" && response_content{"error_str"}) => response_content{"error_str"} | 0;
        error = error_info.put({"skyCloudError": response_error, "skyCloudErrorMsg": response_error_str, "skyCloudReturnValue": response_content});
        is_bad_response = (response_content.isnull() || response_content == "null" || response_error || response_error_str);
    
    
        // if HTTP status was OK & the response was not null and there were no errors...
        (status == 200 && not is_bad_response) => response_content | error
        // send_directive("message test sss", {"response": response_content })
    }
  }
}