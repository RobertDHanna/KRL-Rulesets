ruleset sensor_profile {
  meta {
        provides profile
        shares profile
    }
  global {
    profile = function() {
      {
        "name": ent:name.defaultsTo("Default"), 
        "location": ent:location.defaultsTo("Default"),
        "number": ent:number.defaultsTo("555-555-5555"),
        "threshold": ent:threshold.defaultsTo(72.9)
      }
    }
  }
  rule profile_updated {
    select when sensor profile_updated
    pre {
      defaultName = ent:name.defaultsTo("Default")
      defaultLocation = ent:location.defaultsTo("Default")
      defaultNumber = ent:number.defaultsTo("555-555-5555")
      defaultThreshold = ent:threshold.defaultsTo(72.9)
    }
    always {
      ent:name := event:attr("name").defaultsTo(defaultName);
      ent:location := event:attr("location").defaultsTo(defaultLocation);
      ent:number := event:attr("number").defaultsTo(defaultNumber);
      ent:threshold := event:attr("threshold").defaultsTo(defaultThreshold);
    }
  }
  rule auto_accept {
    select when wrangler inbound_pending_subscription_added
    pre {
      attributes = event:attrs.klog("subcription:")
    }
    always {
      raise wrangler event "pending_subscription_approval"
        attributes attributes
    }
  }
}