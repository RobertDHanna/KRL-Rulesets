ruleset gossip_protocol {
  meta {
    shares __testing, eciToPicoID, seen, temperatures
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
    temperatures = function() {
      ent:rumors
    }
    seen = function() {
      ent:seen
    }
    getPeer = function(state) {
      myPeers = state{"peers"};
      peersThatNeedRumors = myPeers.filter(peerHasNotHeardAllRumors).klog("my peers: ");
      (peersThatNeedRumors.length() > 0) => peersThatNeedRumors[random:integer(peersThatNeedRumors.length() - 1)] | null
    }
    prepareMessage = function(peer) {
      id = ent:eciToId{ peer{"Tx"} };
      potentialMessages = peerHasNotHeardAllRumors(peer) => potentialMessages.append({"type": "rumor", "attrs": {"rumor": chooseRumorToSend(peer), "reply": meta:eci }}) | [];
      potentialMessages[random:integer(potentialMessages.length() - 1)]
    }
    chooseRumorToSend = function(peer) {
      // choose a rumor to send
     id = ent:eciToId{ peer{"Tx"} };
     messagesSeenByPeer = ent:seen{id};
     chosenMessageID = ent:rumors.keys().filter(function(messageID) {
       justID = messageID.split(":")[0];
       sequenceNumber = messageID.split(":")[1].as("Number");
       not (messagesSeenByPeer >< justID && messagesSeenByPeer{justID} >= sequenceNumber)
     }).head().klog("chosen message ID: ");
     ent:rumors{chosenMessageID};
    }
    peerHasNotHeardAllRumors = function(peer) {
     id =  ent:eciToId{ peer{"Tx"} };
    id.klog("THIS LADS ID: ");
     messagesSeenByPeer = ent:seen{id}.klog("messages seen by peer: ");
     ent:rumors.keys().filter(function(messageID) {
       peer != null && id != messageID.split(":")[0]
     }).any(function(messageID) {
       justID = messageID.split(":")[0];
       sequenceNumber = messageID.split(":")[1].as("Number");
       not (messagesSeenByPeer >< justID && messagesSeenByPeer{justID} >= sequenceNumber)
     }).klog("rumors not heard: ")
    }
    
    getHighestSequenceNumberFromMessageID = function(messageID, startNumber) {
      id = messageID.split(":")[0];
      (ent:rumors >< id + ":" + startNumber) => getHighestSequenceNumberFromMessageID(messageID, startNumber + 1) | startNumber - 1
    }
  } 
  
  rule gossip_heartbeat {
    select when gossip heartbeat
    pre {
      wait_duration = ent:schedule_delay.defaultsTo(1);
      peer = getPeer({
        "peers": Subscription:established("Tx_role", "node")
      }).klog("my peer: ");
      message = prepareMessage(peer).klog("my message: ");
    }
    
    if ent:on == true && message != null then event:send({
      "eci": peer{"Tx"},
      "eid": "none",
      "domain": "gossip",
      "type": message{"type"},
      "attrs": message{"attrs"}
    })
    
   always {
      schedule gossip event "heartbeat" at time:add(time:now(), {"seconds": wait_duration})
    }
  }
  rule gossip_rumor {
    select when gossip rumor
    pre {
      messageID = event:attrs{"rumor"}{"MessageID"}
      eci = event:attrs{"reply"}
    }
    // hey buddy, we have already seen that rumor.
    if ent:on == true && ent:rumors >< messageID then event:send({
      "eci": eci,
      "eid": "none",
      "domain": "gossip",
      "type": "seen",
      "attrs": {
        "picoID": meta:picoId,
        "seen": ent:seen{meta:picoId}
      }
    })
    always {
      ent:rumors{messageID} := (ent:on == true) => event:attrs{"rumor"} | ent:rumors{messageID};
      sequenceNumber = getHighestSequenceNumberFromMessageID(messageID, 0);
      ent:seen{meta:picoId} := (ent:on == true) => ent:seen{meta:picoId}.defaultsTo({}).put(messageID.split(":")[0], (sequenceNumber == -1) => 0 | sequenceNumber ) | ent:seen{meta:picoId};
      // ent:seen.klog("AFTER RUMOR SEEN: ")
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
  
  rule on_accept_id {
    select when gossip accept_id
    pre {
      id = event:attrs{"id"}
      who = event:attrs{"who"}
    }
    always {
      ent:eciToId{who} := id
    }
  }
  
  rule on_installation {
    select when wrangler ruleset_added where rids >< meta:rid
    pre {
    }
    noop()
    fired{
      ent:eciToId := {};
      ent:rumors := {};
      ent:seen := {};
      ent:sequenceNumber := 0;
      ent:on := true;
      raise gossip event "heartbeat"
        attributes event:attrs;
    }
  }
  
  rule on_new_subscription {
    select when wrangler subscription_added
    foreach Subscription:established("Tx_role", "node") setting (subscription)
      pre {
        eci = subscription{"Tx"}
        whoAmI = subscription{"Rx"}
        myId = meta:picoId
      }
      // let my peers know my id
      event:send({
        "eci": eci,
        "edi": "eid",
        "domain": "gossip",
        "type": "accept_id",
        "attrs": {
          "id": myId,
          "who": whoAmI
        }
      })
  }
  
  rule clear_data {
    select when sensor reading_reset
    always {
      ent:rumors := {};
      ent:seen := {};
      ent:sequenceNumber := 0;
      ent:on := true;
    }
  }
  
  rule set_node_status {
    select when gossip process
    pre {
      status = event:attrs{"status"}
    }
    always {
      ent:on := (status == "on") => true | false;
    }
  }
  
  rule process_new_temperature {
    select when wovyn new_temperature_reading
    pre {
      messageID = meta:picoId + ":" + ent:sequenceNumber.defaultsTo(0)
      temperature = event:attrs{["temperature", "temperatureF"]}
      timestamp = event:attrs{"timestamp"}
    }
    always {
      ent:seen{meta:picoId} := ent:seen{meta:picoId}.defaultsTo({}).put(meta:picoId, ent:sequenceNumber.defaultsTo(0));
      ent:rumors{messageID} := {
        "MessageID": messageID,
        "SensorID": meta:picoId,
        "Temperature": temperature,
        "Timestamp": timestamp
      };
      ent:sequenceNumber := ent:sequenceNumber + 1
    }
  }
}
