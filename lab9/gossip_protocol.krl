ruleset gossip_protocol {
  meta {
    shares __testing
    use module io.picolabs.subscription alias Subscription
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
    getPeer = function(state) {
      myPeers = state{"peers"};
      peersThatNeedRumor = myPeers.filter(function(peer) {
        not hasPeerHeardAllRumors(peer{"Tx"})
      });
      {}
    }
    hasPeerHeardAllRumors = function(id) {
      
    }
    hasPeerSeenMyTemperatures = function(id) {
      
    }
  } 
  
  rule gossip_heartbeat {
    select when gossip heartbeat
    pre {
      wait_duration = ent:schedule_delay.defaultsTo(2)
      peer = getPeer({
        "peers": Subscription:established("Tx_role", "node")
      })
    }
    fired {
      
    } finally {
      schedule gossip_protocol event "heartbeat" at time:add(time:now(), {"seconds": wait_duration})
    }
  }
  rule gossip_rumor {
    select when gossip rumor
    pre {
      messageID = event:attrs{"MessageID"}
    }
    always {
      ent:rumors{messageID} := event:attrs
    }
  }
  rule gossip_seen {
    select when gossip seen
    pre {
      picoID = event:attrs{"picoID"}
      whatHasBeenSeen = event:attrs{"seen"}
    }
    always {
      ent:seen{picoID} := whatHasBeenSeen
    }
  }
  rule process_picoID_notification {
    select when gossip notify_picoID
    pre {
      peerEci = event:attrs{"eci"}
      peerPicoID = event:attrs{"picoID"}
    }
  }
  rule process_new_subscription {
    select when wrangler subscription_added
    foreach Subscription:established("Tx_role", "node") setting (peer)
    pre {
      messageAttrs = {
        "eci": meta:eci,
        "picoID": meta:picoId
      }
    }
    event:send({
      "eci": peer{"Tx"},
      "edi": "none",
      "domain": "gossip",
      "type": "notify_picoID",
      "attrs": messageAttrs
    })
  }
}
