target_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "api.alsa.card.name", "=", "UA Apollo Solo", type = "pw-global" },
    Constraint { "media.class", "=", "Audio/Sink", type = "pw-global" },
  },
}
playback_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "node.name", "=", "swproj_playback", type = "pw-global" },
  },
}
capture_om = ObjectManager {
  Interest {
    type = "node",
    Constraint { "node.name", "=", "swproj_capture", type = "pw-global" },
  },
}
metadata_om = ObjectManager {
  Interest {
    type = "metadata",
    Constraint { "metadata.name", "=", "default", type = "pw-global" },
  },
}

local function sync()
  local target = target_om:lookup()
  local playback = playback_om:lookup()
  local capture = capture_om:lookup()
  local metadata = metadata_om:lookup()
  if playback and metadata then
    local id = playback["bound-id"]
    if target then
      local name = target.properties["node.name"]
      metadata:set(id, "target.object", "Spa:String:JSON", '"' .. name .. '"')
    else
      metadata:set(id, "target.object", nil, nil)
    end
  end
  if capture then
    local prio = target and 2000 or 500
    capture:update_properties { ["priority.session"] = tostring(prio) }
  end
end

target_om:connect("object-added", sync)
target_om:connect("object-removed", sync)
playback_om:connect("object-added", sync)
capture_om:connect("object-added", sync)
metadata_om:connect("object-added", sync)

target_om:activate()
playback_om:activate()
capture_om:activate()
metadata_om:activate()
