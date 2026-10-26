sub Party_Start()
    if m.partyTask <> invalid then return
    m.partyTask = CreateObject("roSGNode", "PartyTask")
    m.partyTask.observeField("result", "onPartyState")
    m.partyTask.control = "RUN"
end sub

sub Party_Send(cmd as object)
    Party_Start()
    m.partyCmdId = ToInt(m.partyCmdId, 0) + 1
    cmd.id = m.partyCmdId
    m.partyTask.command = cmd
end sub

function Party_Type(kind as string) as string
    k = LCase(kind)
    if k = "movie" then return "movie"
    if k = "tv" or k = "show" then return "series"
    return k
end function

function Party_Key(kind as string, metaId as string, season as dynamic, episode as dynamic) as string
    s = ""
    e = ""
    if season <> invalid and ToInt(season, -1) >= 0 then s = ToInt(season, -1).ToStr()
    if episode <> invalid and ToInt(episode, -1) > 0 then e = ToInt(episode, -1).ToStr()
    return LCase(Party_Type(kind)) + "|" + metaId + "|" + s + "|" + e
end function

function Party_MediaKey(media as dynamic) as string
    if type(media) <> "roAssociativeArray" then return ""
    return Party_Key(Str_Of(media.meta_type), Str_Of(media.meta_id), media.season, media.episode)
end function

function Party_PlayingKey() as string
    if not m.player.visible or m.ctx = invalid then return ""
    return Party_Key(Str_Of(m.ctx.kind), Str_Of(m.ctx.metaId), m.ctx.epSeason, m.ctx.epEpisode)
end function

function Party_CanControl() as boolean
    if m.party = invalid then return false
    if not Bool_Of(m.party.hostOnly, false) then return true
    return Str_Of(m.party.hostId) = Str_Of(m.party.memberId)
end function

function Party_IsHost() as boolean
    if m.party = invalid then return false
    return Str_Of(m.party.hostId) <> "" and Str_Of(m.party.hostId) = Str_Of(m.party.memberId)
end function

function Party_Media() as object
    kind = Party_Type(Str_Of(m.ctx.kind))
    media = { type: kind, meta_id: m.ctx.metaId, meta_type: kind, video_id: m.ctx.videoId, season: invalid, episode: invalid, title: Str_Of(m.ctx.title), episode_title: invalid, description: invalid, poster: invalid, background: invalid, logo: invalid }
    s = ToInt(m.ctx.epSeason, -1)
    e = ToInt(m.ctx.epEpisode, -1)
    if s >= 0 and e > 0
        media.season = s
        media.episode = e
    end if
    if m.ctx.episodeMeta <> invalid and m.ctx.episodeLabel <> "" and Str_Of(m.ctx.episodeMeta.name) <> "" then media.episode_title = m.ctx.episodeMeta.name
    if Str_Of(m.ctx.description) <> "" then media.description = Left(m.ctx.description, 600)
    if Str_Of(m.ctx.poster) <> "" then media.poster = m.ctx.poster
    if Str_Of(m.ctx.background) <> "" then media.background = m.ctx.background
    if Str_Of(m.ctx.logo) <> "" then media.logo = m.ctx.logo
    st = m.ctx.playingStream
    if type(st) = "roAssociativeArray"
        source = { name: invalid, filename: invalid, binge_group: invalid, addon_id: invalid }
        if Str_Of(st.name) <> "" then source.name = Left(Str_OneLine(st.name), 120)
        if Str_Of(st.filename) <> "" then source.filename = st.filename
        if Str_Of(st.binge) <> "" then source.binge_group = st.binge
        if Str_Of(st.addon) <> "" then source.addon_id = st.addon
        media.source = source
    end if
    return media
end function

function Party_Playback(paused as boolean, positionSec as float) as object
    seq = 0
    if m.party <> invalid and type(m.party.playback) = "roAssociativeArray" then seq = ToInt(m.party.playback.seq, 0)
    if ToInt(m.partyMySeq, 0) > seq then seq = ToInt(m.partyMySeq, 0)
    seq = seq + 1
    m.partyMySeq = seq
    member = invalid
    if m.party <> invalid and Str_Of(m.party.memberId) <> "" then member = m.party.memberId
    ms = Int(positionSec * 1000)
    if ms < 0 then ms = 0
    return { seq: seq, member_id: member, paused: paused, position_ms: ms, rate: 1, at: 0, media_key: Party_PlayingKey(), waiting: false }
end function

sub Party_Create()
    if not m.player.visible then return
    m.partyPending = "create"
    m.partyMySeq = 0
    paused = m.playerVideo.state = "paused"
    Party_Send({ action: "create", media: Party_Media(), playback: Party_Playback(paused, m.playerVideo.position) })
end sub

sub Party_Join(code as string)
    clean = UCase(code.Trim()).Replace(" ", "")
    if clean = "" then return
    m.partyPending = "join"
    m.partyMySeq = 0
    m.partyIdle = ""
    m.partyFollowing = ""
    if m.partyJoin.visible
        m.partyJoin.busy = true
        m.partyJoin.status = ""
    else
        showBusy(L("Uniéndote a la Watch Party..."))
    end if
    Party_Send({ action: "join", code: clean })
end sub

sub Party_Leave()
    if m.party = invalid then return
    if Party_IsHost() then Party_Send({ action: "end" }) else Party_Send({ action: "leave" })
end sub

function Party_ErrorText(code as string) as string
    if code = "party_not_found" then return L("No se encontró ninguna Watch Party con ese código.")
    if code = "party_full" then return L("Esta Watch Party está llena.")
    if code = "party_ended" then return L("Esta Watch Party ha terminado.")
    if code = "not_member" or code = "removed" then return L("No puedes unirte a esta Watch Party.")
    if code = "rate_limited" then return L("Demasiados intentos. Vuelve a intentarlo en unos minutos.")
    if code = "network" then return L("No se pudo conectar con la Watch Party. Revisa tu conexión.")
    return L("Las Watch Parties no están disponibles en este momento.")
end function

sub Party_JoinFailed(text as string)
    if m.partyJoin.visible
        m.partyJoin.busy = false
        m.partyJoin.status = text
    else
        hideBusy()
        showMessage("Watch Party", text)
    end if
end sub

sub onPartyState()
    st = m.partyTask.result
    if st = invalid then return
    kind = Str_Of(st.type)
    pending = Str_Of(m.partyPending)
    if kind = "left"
        m.partyLastStatus = ""
        m.party = invalid
        m.partyPending = ""
        Party_Indicator()
        Party_PanelRefresh()
        return
    end if
    if kind = "error"
        if pending = "join"
            m.partyPending = ""
            Party_JoinFailed(Party_ErrorText("network"))
        else if pending <> ""
            m.partyPending = ""
            m.partyStarting = false
            Party_PanelRefresh()
            Toast_Show(Party_ErrorText("network"))
        end if
        return
    end if
    if kind <> "snapshot" then return
    snap = st.snap
    p = snap.party
    if IsStr(snap.error) or type(p) <> "roAssociativeArray"
        hadParty = m.party <> invalid
        m.party = invalid
        m.partyPending = ""
        m.partyStarting = false
        Party_Indicator()
        Party_PanelRefresh()
        code = "party_ended"
        if IsStr(snap.error) then code = snap.error
        if pending = "join"
            Party_JoinFailed(Party_ErrorText(code))
        else if hadParty and code = "party_ended"
            Toast_Show(L("La Watch Party ha terminado"))
        else if hadParty or pending <> ""
            hideBusy()
            Toast_Show(Party_ErrorText(code))
        end if
        return
    end if
    member = Str_Of(snap.member_id)
    if member = "" and m.party <> invalid then member = Str_Of(m.party.memberId)
    previous = m.party
    if previous = invalid or previous.id <> Str_Of(p.id) then m.partyLastStatus = ""
    maxMembers = 8
    if p.max_members <> invalid then maxMembers = ToInt(p.max_members, 8)
    m.party = { id: Str_Of(p.id), code: Str_Of(p.code), hostId: Str_Of(p.host_member_id), hostOnly: Bool_Of(p.host_only, false), media: p.media, playback: p.playback, members: snap.members, memberId: member, serverNow: st.serverNow, mediaKey: Party_MediaKey(p.media), maxMembers: maxMembers }
    if type(m.party.members) <> "roArray" then m.party.members = []
    m.partyStamp = CreateObject("roTimespan")
    m.partyPending = ""
    m.partyStarting = false
    Party_Indicator()
    if previous <> invalid and previous.id = m.party.id then Party_Notices(previous, m.party)
    if pending = "join"
        hideBusy()
        if m.partyJoin.visible
            m.partyJoin.busy = false
            m.partyJoin.visible = false
        end if
        Toast_Show(L("Ya estás dentro"))
    end if
    Party_PanelRefresh()
    if Str_Of(m.partyLastStatus) = ""
        if m.player.visible and (m.playerVideo.state = "playing" or m.playerVideo.state = "paused") then Party_Status("ready") else Party_Status("browsing")
    end if
    Party_Follow()
end sub

sub Party_Indicator()
    if m.party = invalid
        m.player.partyText = ""
        return
    end if
    text = "Watch Party · " + m.party.code + " · " + m.party.members.Count().ToStr()
    if m.party.members.Count() = 1 then text = text + L(" persona") else text = text + L(" personas")
    m.player.partyText = text
end sub

sub Party_Follow()
    if m.party = invalid then return
    key = m.party.mediaKey
    if key = "" then return
    if key = Party_PlayingKey()
        m.partyFollowing = ""
        Party_Sync()
        return
    end if
    if m.partyQuiet <> invalid and m.partyQuiet.TotalMilliseconds() < 3000 then return
    if Str_Of(m.partyFollowing) = key or Str_Of(m.partyIdle) = key then return
    Party_Open(m.party.media)
end sub

sub Party_Open(media as object)
    key = Party_MediaKey(media)
    if m.player.visible then closePlayer(true)
    m.partyFollowing = key
    m.partyIdle = ""
    if m.streamsOpen then closeStreams(false)
    m.stack.Clear()
    m.list.visible = false
    if m.settingsOpen then closeSettings()
    holder = CreateObject("roSGNode", "ContentNode")
    item = Content_Item(holder, {
        title: Str_Of(media.title)
        poster: Str_Of(media.poster)
        description: Str_Of(media.description)
        kind: Str_Of(media.meta_type)
        metaId: Str_Of(media.meta_id)
        videoId: ""
        background: Str_Of(media.background)
        logo: Str_Of(media.logo)
        metaLine: ""
        episodeLabel: ""
        progress: 0.0
    })
    openDetails(item)
    m.ctx.partyMedia = media
    m.ctx.nextAuto = true
    m.ctx.fromStart = true
    src = media.source
    if type(src) = "roAssociativeArray"
        m.ctx.bingePrefer = Str_Of(src.binge_group)
        m.ctx.partyFile = Str_Of(src.filename)
    end if
    runDetailAction("partyPlay")
end sub

sub Party_PlayMedia()
    media = m.ctx.partyMedia
    if type(media) <> "roAssociativeArray"
        playMain()
        return
    end if
    s = ToInt(media.season, -1)
    e = ToInt(media.episode, -1)
    if isSeries() and s >= 0 and e > 0
        for each season in m.ctx.seasons
            for each v in season.episodes
                if ToInt(v.season, -1) = s and ToInt(v.episode, -1) = e
                    pickEpisodeVideo(season, v)
                    return
                end if
            end for
        end for
        if Str_Of(media.video_id) <> ""
            pickEpisodeById(media.video_id)
            return
        end if
    end if
    playMain()
end sub

sub Party_Sync()
    if m.party = invalid or not m.player.visible then return
    pb = m.party.playback
    if type(pb) <> "roAssociativeArray" then return
    if Str_Of(pb.media_key) <> "" and Str_Of(pb.media_key) <> m.party.mediaKey then return
    if Str_Of(pb.member_id) = Str_Of(m.party.memberId) and ToInt(pb.seq, 0) <= ToInt(m.partyMySeq, 0) then return
    if m.partyQuiet <> invalid and m.partyQuiet.TotalMilliseconds() < 3000 then return
    state = m.playerVideo.state
    if state <> "playing" and state <> "paused" then return
    paused = Bool_Of(pb.paused, false)
    expected = 0& + pb.position_ms
    if not paused
        now = 0& + m.party.serverNow
        if m.partyStamp <> invalid then now = now + m.partyStamp.TotalMilliseconds()
        elapsed = now - pb.at
        if elapsed > 0 then expected = expected + elapsed
    end if
    total = m.playerVideo.duration * 1000
    if total > 0 and expected > total then expected = total
    local = Int(m.playerVideo.position * 1000)
    drift = local - expected
    if drift < 0 then drift = -drift
    tolerance = 1500
    if paused then tolerance = 500
    if drift > tolerance then m.playerVideo.seek = expected / 1000
    if paused and state = "playing" then m.playerVideo.control = "pause"
    if not paused and state = "paused" then m.playerVideo.control = "resume"
end sub

sub Party_Publish(paused as boolean, positionSec as float)
    if m.party = invalid then return
    if not Party_CanControl()
        Party_Sync()
        return
    end if
    m.partyQuiet = CreateObject("roTimespan")
    Party_Send({ action: "update", playback: Party_Playback(paused, positionSec) })
end sub

sub Party_OnPlaying()
    if m.party = invalid then return
    m.partyIdle = ""
    key = Party_PlayingKey()
    if key = m.party.mediaKey
        m.partyFollowing = ""
        Party_Sync()
        return
    end if
    if Str_Of(m.partyFollowing) <> "" then return
    if not Party_IsHost() then return
    m.partyQuiet = CreateObject("roTimespan")
    Party_Send({ action: "update", media: Party_Media(), playback: Party_Playback(m.playerVideo.state = "paused", m.playerVideo.position) })
end sub

sub Party_Status(status as string)
    if m.party = invalid then return
    key = Party_PlayingKey()
    if status = "browsing" then key = ""
    stamp = status + "|" + key
    if Str_Of(m.partyLastStatus) = stamp then return
    m.partyLastStatus = stamp
    media = invalid
    if key <> "" then media = key
    Party_Send({ action: "status", status: status, mediaKey: media })
end sub

sub Party_OnVideoState(state as string)
    if m.party = invalid then return
    if state = "buffering"
        if Str_Of(m.partyLastStatus) = "" or Left(Str_Of(m.partyLastStatus), 8) = "browsing" then Party_Status("loading") else Party_Status("buffering")
    else if state = "playing" or state = "paused"
        Party_Status("ready")
    end if
end sub

sub Party_Menu()
    m.partyPanelMode = "auto"
    m.partyPanel.visible = true
    Party_PanelRefresh()
    m.partyPanel.setFocus(true)
end sub

function Party_MemberName(id as string) as string
    if m.party = invalid then return ""
    for each mem in m.party.members
        if type(mem) = "roAssociativeArray" and Str_Of(mem.member_id) = id then return Str_Of(mem.display_name)
    end for
    return ""
end function

sub Party_Notices(before as object, after as object)
    names = {}
    for each mem in before.members
        if type(mem) = "roAssociativeArray" then names[Str_Of(mem.member_id)] = Str_Of(mem.display_name)
    end for
    now = {}
    for each mem in after.members
        if type(mem) = "roAssociativeArray"
            id = Str_Of(mem.member_id)
            now[id] = true
            if not names.DoesExist(id) and id <> after.memberId then Toast_Show(L("{n} se unió a la Watch Party").Replace("{n}", Str_Of(mem.display_name)))
        end if
    end for
    for each id in names
        if not now.DoesExist(id) and id <> after.memberId then Toast_Show(L("{n} salió de la Watch Party").Replace("{n}", names[id]))
    end for
    a = before.playback
    b = after.playback
    if type(a) <> "roAssociativeArray" or type(b) <> "roAssociativeArray" then return
    if ToInt(b.seq, 0) <= ToInt(a.seq, 0) then return
    who = Str_Of(b.member_id)
    if who = "" or who = after.memberId then return
    name = Party_MemberName(who)
    if name = "" then return
    if Bool_Of(b.paused, false) and not Bool_Of(a.paused, false)
        Toast_Show(L("{n} pausó").Replace("{n}", name))
    else if not Bool_Of(b.paused, false) and Bool_Of(a.paused, false)
        Toast_Show(L("{n} reanudó").Replace("{n}", name))
    else
        diff = (0& + b.position_ms) - a.position_ms
        if diff < 0 then diff = -diff
        if diff > 8000
            secs = Int((0& + b.position_ms) / 1000)
            Toast_Show(L("{n} saltó a {t}").Replace("{n}", name).Replace("{t}", Fmt_Time(secs)))
        end if
    end if
end sub

sub Party_PanelRefresh()
    if not m.partyPanel.visible then return
    profile = St_ActiveProfile()
    color = St_ProfileColor(St_ActiveProfileIndex())
    st = { profileName: Str_Of(profile.name), profileColor: color, profileAvatar: Str_Of(profile.avatar), signedIn: St_Integrations().nuvioAccess <> "" }
    if m.party = invalid
        st.mode = "start"
        if Bool_Of(m.partyStarting, false) then st.signedIn = St_Integrations().nuvioAccess <> ""
    else
        st.mode = "party"
        if m.partyPanelMode = "invite" then st.mode = "invite"
        st.code = m.party.code
        st.isHost = Party_IsHost()
        st.hostOnly = m.party.hostOnly
        st.maxMembers = m.party.maxMembers
        st.inviteLink = "https://nuvio.tv/party/" + m.party.code
        media = m.party.media
        if type(media) = "roAssociativeArray"
            st.mediaTitle = Str_Of(media.title)
            seNum = ToInt(media.season, -1)
            epNum = ToInt(media.episode, -1)
            if seNum >= 0 and epNum > 0
                ep = L("T{s} E{e}").Replace("{s}", seNum.ToStr()).Replace("{e}", epNum.ToStr())
                if Str_Of(media.episode_title) <> "" then ep = ep + "  ·  " + Str_Of(media.episode_title)
                st.episode = ep
            end if
        end if
        list = []
        for each mem in m.party.members
            if type(mem) = "roAssociativeArray"
                id = Str_Of(mem.member_id)
                you = id = m.party.memberId
                status = L("Viendo")
                list.Push({ name: Str_Of(mem.display_name), color: Str_Of(mem.avatar_color), avatar: Str_Of(mem.avatar_url), host: id = m.party.hostId, you: you, status: status })
            end if
        end for
        st.members = list
    end if
    m.partyPanel.accent = m.accent
    m.partyPanel.state = st
end sub

sub Party_PanelClose()
    m.partyPanel.visible = false
    m.partyPanelMode = "auto"
    focusCurrent()
end sub

sub onPartyPanelEvent()
    ev = m.partyPanel.event
    if ev = invalid then return
    kind = Str_Of(ev.type)
    if kind = "close"
        Party_PanelClose()
    else if kind = "start"
        if m.party = invalid and not Bool_Of(m.partyStarting, false)
            m.partyStarting = true
            Party_Create()
        end if
    else if kind = "invite"
        m.partyPanelMode = "invite"
        Party_PanelRefresh()
    else if kind = "inviteBack"
        m.partyPanelMode = "auto"
        Party_PanelRefresh()
    else if kind = "hostOnly" and m.party <> invalid
        m.party.hostOnly = not m.party.hostOnly
        Party_PanelRefresh()
        Party_Send({ action: "hostOnly", value: m.party.hostOnly })
    else if kind = "leave"
        Party_Send({ action: "leave" })
        Party_PanelClose()
    else if kind = "end"
        items = [{ id: "cancel", label: L("Cancelar") }, { id: "end", label: L("Terminar para todos"), danger: true }]
        Sheet_Open({ title: L("¿Terminar la Watch Party?"), subtitle: L("Todos se desconectarán de la party."), items: items }, "party", invalid)
    end if
end sub

sub Party_RunMenu(choice as string)
    if choice = "end" and m.party <> invalid
        Party_Send({ action: "end" })
        Party_PanelClose()
        return
    end if
    focusCurrent()
end sub

sub PartyJoin_Open()
    if St_Integrations().nuvioAccess = ""
        showMessage("Watch Party", L("Inicia sesión en tu cuenta de Nuvio para usar las Watch Parties."))
        return
    end if
    profile = St_ActiveProfile()
    m.partyJoin.profile = { name: Str_Of(profile.name), color: St_ProfileColor(St_ActiveProfileIndex()), avatar: Str_Of(profile.avatar) }
    m.partyJoin.reset = true
    m.partyJoin.busy = false
    m.partyJoin.visible = true
    m.partyJoin.setFocus(true)
end sub

sub onPartyJoinEvent()
    ev = m.partyJoin.event
    if ev = invalid then return
    if Str_Of(ev.type) = "join"
        Party_Join(Str_Of(ev.code))
    else if Str_Of(ev.type) = "back"
        m.partyJoin.visible = false
        focusCurrent()
    end if
end sub
