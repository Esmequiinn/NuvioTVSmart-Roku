sub init()
    m.top.functionName = "partyLoop"
end sub

function Party_LocalMs() as dynamic
    dt = CreateObject("roDateTime")
    return dt.AsSeconds() * 1000& + dt.GetMilliseconds()
end function

sub partyLoop()
    port = CreateObject("roMessagePort")
    m.top.observeField("command", port)
    m.partyId = ""
    m.code = ""
    m.memberId = ""
    m.offset = 0&
    m.clockAt = -600000&
    m.lastCmd = 0
    m.rtPath = ""
    m.rtDead = false
    Nuvio_Ensure()
    first = m.top.command
    if type(first) = "roAssociativeArray" then Party_Run(first)
    while true
        msg = wait(2500, port)
        if type(msg) = "roSGNodeEvent"
            Party_Run(msg.getData())
        else if m.partyId <> ""
            Party_Clock(false)
            Party_Emit("snapshot", Party_Rpc("watch_party_heartbeat", { p_party_id: m.partyId, p_device_id: St_ClientId() }), "poll")
        end if
    end while
end sub

sub Party_Run(cmd as dynamic)
    if type(cmd) <> "roAssociativeArray" then return
    id = ToInt(cmd.id, 0)
    if id <> 0 and id <= m.lastCmd then return
    m.lastCmd = id
    Party_Command(cmd)
end sub

sub Party_Clock(force as boolean)
    now = Party_LocalMs()
    if not force and now - m.clockAt < 60000 then return
    best = -1
    for i = 1 to 3
        sent = Party_LocalMs()
        r = Nuvio_Call("POST", "/rest/v1/rpc/watch_party_clock", {})
        back = Party_LocalMs()
        if r.code >= 200 and r.code < 300
            server = r.json
            if server = invalid and IsStr(r.body) then server = r.body.Trim()
            if IsStr(server) then server = ParseJson(server)
            if server <> invalid and (GetInterface(server, "ifLongInt") <> invalid or GetInterface(server, "ifInt") <> invalid or GetInterface(server, "ifFloat") <> invalid or GetInterface(server, "ifDouble") <> invalid)
                trip = back - sent
                if best < 0 or trip < best
                    best = trip
                    m.offset = (0& + server) + trip \ 2 - back
                    m.clockAt = now
                end if
            end if
        end if
        if not force then exit for
    end for
end sub

function Party_IsFatal(code as string) as boolean
    return code = "party_ended" or code = "removed" or code = "party_not_found"
end function

sub Party_Emit(kind as string, data as dynamic, origin as string)
    snap = data
    if type(snap) = "roArray" and snap.Count() > 0 then snap = snap[0]
    now = Party_LocalMs() + m.offset
    if type(snap) <> "roAssociativeArray"
        if origin = "start" then m.top.result = { type: "error", error: "network", serverNow: now }
        return
    end if
    if snap.server_time_ms <> invalid and origin = "start"
        server = 0& + snap.server_time_ms
        m.offset = server - Party_LocalMs()
    end if
    if IsStr(snap.error) and origin <> "start"
        code = snap.error
        if code = "not_member" and m.code <> ""
            again = Party_Rpc("watch_party_join", Party_JoinParams(m.code))
            if type(again) = "roArray" and again.Count() > 0 then again = again[0]
            if type(again) = "roAssociativeArray" and type(again.party) = "roAssociativeArray"
                Party_Emit("snapshot", again, "rejoin")
                return
            end if
            code = "party_ended"
            if type(again) = "roAssociativeArray" and IsStr(again.error) and again.error = "removed" then code = "removed"
        end if
        if Party_IsFatal(code)
            m.partyId = ""
            m.code = ""
            m.top.result = { type: "snapshot", snap: { error: code }, serverNow: now }
        end if
        return
    end if
    if type(snap.party) = "roAssociativeArray" and IsStr(snap.party.id)
        m.partyId = snap.party.id
        m.code = Str_Of(snap.party.code)
        if IsStr(snap.member_id) then m.memberId = snap.member_id
    else if IsStr(snap.error)
        m.partyId = ""
        m.code = ""
    else
        return
    end if
    m.top.result = { type: kind, snap: snap, serverNow: now }
end sub

function Party_Identity() as object
    profile = St_ActiveProfile()
    name = Left(Str_Of(profile.name), 40)
    if name = "" then name = "Roku"
    id = { p_device_id: St_ClientId(), p_display_name: name, p_avatar_url: invalid, p_avatar_color: invalid }
    avatar = Str_Of(profile.avatar)
    if Left(avatar, 8) = "https://" and Len(avatar) <= 512 then id.p_avatar_url = avatar
    color = Str_Of(profile.color)
    if Left(color, 1) = "#" then color = Mid(color, 2)
    if Len(color) = 6 then id.p_avatar_color = "#" + UCase(color)
    return id
end function

function Party_JoinParams(code as string) as object
    params = Party_Identity()
    params.p_code = code
    return params
end function

sub Party_Command(cmd as object)
    action = Str_Of(cmd.action)
    device = St_ClientId()
    if action = "create" or action = "join" then Party_Clock(true)
    if action = "create"
        params = Party_Identity()
        params.p_media = cmd.media
        params.p_playback = cmd.playback
        if params.p_playback <> invalid then params.p_playback.at = Party_LocalMs() + m.offset
        Party_Emit("snapshot", Party_Rpc("watch_party_create", params), "start")
    else if action = "join"
        Party_Emit("snapshot", Party_Rpc("watch_party_join", Party_JoinParams(UCase(Str_Of(cmd.code).Trim()))), "start")
    else if action = "update" and m.partyId <> ""
        params = { p_party_id: m.partyId, p_device_id: device }
        if cmd.media <> invalid then params.p_media = cmd.media
        if cmd.playback <> invalid
            pb = cmd.playback
            pb.at = Party_LocalMs() + m.offset
            if m.memberId <> "" then pb.member_id = m.memberId
            params.p_playback = pb
            Party_Broadcast("state", pb)
        end if
        Party_Emit("snapshot", Party_Rpc("watch_party_update", params), "update")
    else if action = "status" and m.partyId <> ""
        Party_Broadcast("status", { member_id: m.memberId, status: Str_Of(cmd.status), media_key: cmd.mediaKey, behind_ms: invalid })
    else if action = "hostOnly" and m.partyId <> ""
        Party_Emit("snapshot", Party_Rpc("watch_party_set_host_only", { p_party_id: m.partyId, p_device_id: device, p_host_only: Bool_Of(cmd.value, false) }), "update")
    else if (action = "leave" or action = "end") and m.partyId <> ""
        name = "watch_party_leave"
        if action = "end" then name = "watch_party_end"
        Nuvio_Rpc(name, { p_party_id: m.partyId, p_device_id: device })
        m.partyId = ""
        m.code = ""
        m.top.result = { type: "left", serverNow: Party_LocalMs() + m.offset }
    end if
end sub

sub Party_Broadcast(event as string, payload as object)
    if m.partyId = "" or m.rtDead then return
    integ = St_Integrations()
    body = { messages: [{ topic: "watch-party:" + m.partyId, event: event, payload: payload, private: true }] }
    paths = [m.rtPath]
    if m.rtPath = "" then paths = ["/realtime/v1/api/broadcast?nuvio_realtime=1", "/realtime/v1/api/broadcast"]
    for each path in paths
        r = Http_Request("POST", integ.nuvioUrl + path, Nuvio_Headers(integ, true), body, 6000)
        if r.code >= 200 and r.code < 300
            m.rtPath = path
            return
        end if
    end for
    if m.rtPath = "" then m.rtDead = true
end sub

function Party_Rpc(name as string, args as object) as dynamic
    r = Nuvio_Call("POST", "/rest/v1/rpc/" + name, args)
    if r.code >= 200 and r.code < 300 then return r.json
    if r.code >= 400 and r.code < 500
        text = ""
        if type(r.json) = "roAssociativeArray" then text = LCase(Str_Of(r.json.message) + " " + Str_Of(r.json.error) + " " + Str_Of(r.json.details))
        if text = "" and IsStr(r.body) then text = LCase(r.body)
        for each code in ["party_not_found", "party_full", "party_ended", "not_member", "removed", "rate_limited", "not_host", "unavailable"]
            if Instr(1, text, code) > 0 then return { error: code }
        end for
        return { error: "request_failed" }
    end if
    return invalid
end function
