ruleset app_section_collection {
    meta {
      shares nameFromID, showChildren
      provides showChildren
      use module io.picolabs.wrangler alias wrangler
    }
    global {
      nameFromID = function(section_id) {
        "Section " + section_id + " Pico"
      }
      showChildren = function() {
        wrangler:children()
      }
    }
    rule section_already_exists {
      select when section needed
      pre {
        section_id = event:attr("section_id")
        exists = ent:sections >< section_id
      }
      if exists then
        send_directive("section_ready", {"section_id": section_id})
    }
    rule section_needed {
      select when section needed
      pre {
        section_id = event:attr("section_id")
        exists = ent:sections >< section_id
      }
      if not exists
      then
        noop()
      fired {
        raise wrangler event "child_creation"
          attributes { "name": nameFromID(section_id),
                       "color": "#ffff00",
                       "section_id": section_id,
                       "rids": "app_section" }
      }
    }
    rule store_new_section {
      select when wrangler child_initialized
      pre {
        the_section = {"id": event:attr("id"), "eci": event:attr("eci")}
        section_id = event:attr("rs_attrs"){"section_id"}
      }
      if section_id.klog("found section_id")
      then
        noop()
      fired {
        ent:sections := ent:sections.defaultsTo({});
        ent:sections{[section_id]} := the_section
      }
    }
    rule section_offline {
      select when section offline
      pre {
        section_id = event:attr("section_id")
        exists = ent:sections >< section_id
        child_to_delete = nameFromID(section_id)
      }
      if exists then
        send_directive("deleting_section", {"section_id":section_id})
      fired {
        raise wrangler event "child_deletion"
          attributes {"name": child_to_delete};
        clear ent:sections{[section_id]}
      }
    }
    rule collection_empty {
      select when collection empty
      always {
        ent:sections := {}
      }
    }
}