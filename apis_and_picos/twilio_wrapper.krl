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
    
    messages = function(message_id, to, from, page_size, page, page_token) {
        base_url = <<https://#{account_sid}:#{auth_token}@api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages>>;
        base_url = (message_id == null) => base_url | base_url + "/" + message_id;
        base_url = base_url + ".json";
        m_qs = {
          "To": to,
          "From": from,
          "PageSize": page_size,
          "Page": page,
          "PageToken": page_token
        };
        
        m_qs = (to == null || to == "") => m_qs.delete(["To"]) | m_qs;
        m_qs = (from == null || from == "") => m_qs.delete(["From"]) | m_qs;
        m_qs = (page_size == null || page_size == "") => m_qs.delete(["PageSize"]) | m_qs;
        m_qs = (page == null || page == "") => m_qs.delete(["Page"]) | m_qs;
        m_qs = (page_token == null || page_token == "") => m_qs.delete(["PageToken"]) | m_qs;
        
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
    }
  }
}