ruleset gossip_protocol {
  meta {
    shares __testing, eciToPicoID
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
      peersThatNeedRumors = myPeers.filter(peerHasNotHeardAllRumors);
      peersThatNeedMySeen = myPeers.filter(hasPeerSeenMyTemperatures);
      needyPeers = peersThatNeedRumors.append(peersThatNeedMySeen);
      (needyPeers.length() > 0) => needyPeers[random:integer(needyPeers.length() - 1)] | null
    }
    prepareMessage = function(peer) {
      potentialMessages = peerHasNotHeardAllRumors(peer) => potentialMessages.append({"type": "rumor", "attrs": chooseRumorToSend(peer)}) | potentialMessages;
      potentialMessages = hasPeerSeenMyTemperatures(peer) => potentialMessages.append({"type": "seen", "attrs": ent:seen}) | potentialMessages;
      potentialMessages[random:integer(potentialMessages.length() - 1)]
    }
    chooseRumorToSend = function(peer) {
      // choose a rumor to send
     id = peer{"Id"};
     messagesSeenByPeer = ent:seen{id};
     chosenMessageID = ent:rumors.keys().filter(function(messageID) {
       justID = messageID.split(":")[0];
       sequenceNumber = messageID.split(":")[1];
       not (messagesSeenByPeer >< justID && messagesSeenByPeer{justID} == sequenceNumber)
     }).head();
     ent:rumors{chosenMessageID};
    }
    peerHasNotHeardAllRumors = function(peer) {
     id = peer{"Id"};
     messagesSeenByPeer = ent:seen{id};
     ent:rumors.keys().any(function(messageID) {
       justID = messageID.split(":")[0];
       sequenceNumber = messageID.split(":")[1];
       not (messagesSeenByPeer >< justID && messagesSeenByPeer{justID} == sequenceNumber)
     })
    }
    
    hasPeerSeenMyTemperatures = function(peer) {
      id = peer{"Id"};
      messagesSeenByPeer = ent:seen{id};
      messagesSeenByPeer >< meta:picoId && messagesSeenByPeer{meta:picoId} != ent:sequenceNumber
    }
    
    getHighestSequenceNumberFromMessageID = function(messageID, startNumber) {
      id = messageID.split(":")[0];
      (ent:rumors >< id + ":" + startNumber) => getHighestSequenceNumberFromMessageID(messageID, startNumber + 1) | startNumber - 1
    }
  } 
  
  rule gossip_heartbeat {
    select when gossip heartbeat
    pre {
      wait_duration = ent:schedule_delay.defaultsTo(2)
      peer = getPeer({
        "peers": Subscription:established("Tx_role", "node")
      })
      message = prepareMessage(peer)
    }
    if not message == null then event:send({
      "eci": peer{"Tx"},
      "eid": "none",
      "domain": "gossip",
      "type": message{"type"},
      "attrs": message{"attrs"}
    })
    always {
      schedule gossip_protocol event "heartbeat" at time:add(time:now(), {"seconds": wait_duration})
    }
  }
  rule gossip_rumor {
    select when gossip rumor
    pre {
      messageID = event:attrs{"MessageID"}
    }
    always {
      ent:rumors{messageID} := event:attrs;
      ent:seen{messageID.split(":")[0]} := getHighestSequenceNumberFromMessageID(messageID, 0)
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
  rule process_new_temperature {
    select when wovyn new_temperature_reading
    pre {
      messageID = meta:picoId + ":" + ent:sequenceNumber
    }
    always {
      ent:seen{meta:picoId} := ent:sequence_number;
      ent:rumors{messageID} := {
        "MessageID": messageID,
        "SensorID": meta:picoId,
        "Temperature": attrs{"temperature"},
        "Timestamp": attrs{"timestamp"}
      };
      ent:sequenceNumber := ent:sequenceNumber + 1
    }
  }
}
