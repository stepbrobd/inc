target_om = ObjectManager({
	Interest({
		type = "node",
		Constraint({ "node.description", "=", "UA Apollo Solo Multichannel", type = "pw-global" }),
		Constraint({ "media.class", "=", "Audio/Sink", type = "pw-global" }),
	}),
})
playback_om = ObjectManager({
	Interest({
		type = "node",
		Constraint({ "node.name", "=", "swproj_playback", type = "pw-global" }),
	}),
})
capture_om = ObjectManager({
	Interest({
		type = "node",
		Constraint({ "node.name", "=", "swproj_capture", type = "pw-global" }),
	}),
})
metadata_om = ObjectManager({
	Interest({
		type = "metadata",
		Constraint({ "metadata.name", "=", "default", type = "pw-global" }),
	}),
})
port_om = ObjectManager({ Interest({ type = "port" }) })
link_om = ObjectManager({ Interest({ type = "link" }) })

local function find_port(node_bid, name, direction)
	for port in port_om:iterate() do
		if
			tonumber(port.properties["node.id"]) == node_bid
			and port.properties["port.name"] == name
			and port.properties["port.direction"] == direction
		then
			return port
		end
	end
	return nil
end

local function link_exists(src_bid, dst_bid)
	for link in link_om:iterate() do
		if
			tonumber(link.properties["link.output.port"]) == src_bid
			and tonumber(link.properties["link.input.port"]) == dst_bid
		then
			return true
		end
	end
	return false
end

local function destroy_other_links_from(src_node_bid, keep_dst_node_bid)
	for link in link_om:iterate() do
		if
			tonumber(link.properties["link.output.node"]) == src_node_bid
			and tonumber(link.properties["link.input.node"]) ~= keep_dst_node_bid
		then
			link:request_destroy()
		end
	end
end

local function ensure_link(src_port, dst_port)
	if not src_port or not dst_port then
		return
	end
	if link_exists(src_port["bound-id"], dst_port["bound-id"]) then
		return
	end
	Link("link-factory", {
		["link.output.node"] = tostring(src_port.properties["node.id"]),
		["link.output.port"] = tostring(src_port["bound-id"]),
		["link.input.node"] = tostring(dst_port.properties["node.id"]),
		["link.input.port"] = tostring(dst_port["bound-id"]),
		["object.linger"] = "true",
	}):activate(Feature.Proxy.BOUND)
end

local function sync()
	local target = target_om:lookup()
	local playback = playback_om:lookup()
	local capture = capture_om:lookup()
	local metadata = metadata_om:lookup()
	if not metadata then
		return
	end
	if capture then
		if target then
			metadata:set(
				0,
				"default.configured.audio.sink",
				"Spa:String:JSON",
				'{"name":"' .. capture.properties["node.name"] .. '"}'
			)
		else
			metadata:set(0, "default.configured.audio.sink", nil, nil)
		end
	end
	if playback and target then
		local pb = playback["bound-id"]
		local tg = target["bound-id"]
		destroy_other_links_from(pb, tg)
		ensure_link(find_port(pb, "output_FL", "out"), find_port(tg, "playback_AUX0", "in"))
		ensure_link(find_port(pb, "output_FR", "out"), find_port(tg, "playback_AUX1", "in"))
	elseif playback then
		destroy_other_links_from(playback["bound-id"], -1)
	end
end

target_om:connect("object-added", sync)
target_om:connect("object-removed", sync)
playback_om:connect("object-added", sync)
capture_om:connect("object-added", sync)
metadata_om:connect("object-added", sync)
port_om:connect("object-added", sync)

target_om:activate()
playback_om:activate()
capture_om:activate()
metadata_om:activate()
port_om:activate()
link_om:activate()
