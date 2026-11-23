sub Watch_Init()
    m.bgRect = m.top.findNode("bg")
    m.watchGrad = m.top.findNode("watchGrad")
    m.bar = m.top.findNode("bar")
    m.barLogo = m.top.findNode("barLogo")
    m.barChannel = m.top.findNode("barChannel")
    m.barLive = m.top.findNode("barLive")
    m.barLiveText = m.top.findNode("barLiveText")
    m.barTech = m.top.findNode("barTech")
    m.barTitle = m.top.findNode("barTitle")
    m.barNext = m.top.findNode("barNext")
    m.barStart = m.top.findNode("barStart")
    m.barTrack = m.top.findNode("barTrack")
    m.barFill = m.top.findNode("barFill")
    m.barEnd = m.top.findNode("barEnd")
    m.barClock = m.top.findNode("barClock")
    m.watchMsg = m.top.findNode("watchMsg")
    m.barTimer = m.top.findNode("barTimer")
    m.barTimer.observeField("fire", "onBarTimer")
    m.zapTimer = m.top.findNode("zapTimer")
    m.zapTimer.observeField("fire", "onZap")
    m.barLiveText.text = L("EN VIVO")
    m.barTimer.duration = Watch_BarSecs()
    m.overlay = m.top.findNode("overlay")
    m.ovGroup = m.top.findNode("ovGroup")
    m.ovHint = m.top.findNode("ovHint")
    m.ovRows = m.top.findNode("ovRows")
    m.ovTimer = m.top.findNode("ovTimer")
    m.ovTimer.observeField("fire", "onOvTimer")
    m.ovHint.text = L("OK cambia de canal  ·  Izquierda: grupos")
    m.ovOpen = false
    m.ovSel = 0
    m.ovTop = 0
    m.ovN = 8
    m.ovNodes = []
    for r = 0 to m.ovN - 1
        g = m.ovRows.createChild("Group")
        g.translation = [0, r * 108]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/card.9.png"
        bg.width = 660
        bg.height = 100
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/focus_ring.9.png"
        ring.translation = [-5, -5]
        ring.width = 670
        ring.height = 110
        ring.blendColor = "0xE53935FF"
        num = g.createChild("Label")
        num.translation = [12, 0]
        num.width = 56
        num.height = 100
        num.vertAlign = "center"
        num.horizAlign = "right"
        Iptv_SetFont(num, 24, true)
        logo = g.createChild("Poster")
        logo.translation = [84, 20]
        logo.width = 108
        logo.height = 60
        logo.loadWidth = 216
        logo.loadHeight = 120
        logo.loadDisplayMode = "scaleToFit"
        name = g.createChild("Label")
        name.translation = [210, 10]
        name.width = 430
        name.height = 36
        name.maxLines = 1
        Iptv_SetFont(name, 25, true)
        prog = g.createChild("Label")
        prog.translation = [210, 46]
        prog.width = 430
        prog.height = 30
        prog.maxLines = 1
        Iptv_SetFont(prog, 22, false)
        track = g.createChild("Rectangle")
        track.translation = [210, 82]
        track.width = 430
        track.height = 4
        track.color = "0x3A3A44FF"
        fill = g.createChild("Rectangle")
        fill.translation = [210, 82]
        fill.height = 4
        fill.color = "0xFFFFFFFF"
        m.ovNodes.Push({ g: g, bg: bg, ring: ring, num: num, logo: logo, name: name, prog: prog, track: track, fill: fill })
    end for
end sub

function Watch_BarSecs() as integer
    v = ToInt(m.prefs.barSecs, 6)
    if v < 2 then v = 6
    return v
end function

sub Overlay_Show()
    if m.mode <> "watch" then return
    if not m.ovOpen
        m.ovOpen = true
        m.ovSel = Watch_PlayingPos()
    end if
    m.overlay.visible = true
    Watch_HideBar()
    Live_AskGuide()
    Overlay_Render()
    m.ovTimer.control = "stop"
    m.ovTimer.control = "start"
end sub

function Watch_PlayingPos() as integer
    if m.playingKey <> "" and m.keyIndex <> invalid and m.keyIndex.DoesExist(m.playingKey)
        idx = m.keyIndex[m.playingKey]
        for i = 0 to m.view.Count() - 1
            if m.view[i] = idx then return i
        end for
    end if
    return m.sel
end function

sub Overlay_Hide()
    m.ovOpen = false
    m.overlay.visible = false
    m.ovTimer.control = "stop"
end sub

sub onOvTimer()
    if m.zone = "groups" then return
    Overlay_Hide()
end sub

sub Overlay_Render()
    n = m.view.Count()
    if m.ovSel >= n then m.ovSel = n - 1
    if m.ovSel < 0 then m.ovSel = 0
    if m.ovSel < m.ovTop then m.ovTop = m.ovSel
    if m.ovSel > m.ovTop + m.ovN - 1 then m.ovTop = m.ovSel - m.ovN + 1
    if m.ovTop > n - m.ovN then m.ovTop = n - m.ovN
    if m.ovTop < 0 then m.ovTop = 0
    gl = ""
    if m.groups.Count() > m.groupIdx then gl = Str_Of(m.groups[m.groupIdx].label)
    m.ovGroup.text = gl
    now = Live_Now()
    for r = 0 to m.ovN - 1
        node = m.ovNodes[r]
        vp = m.ovTop + r
        c = Live_Chan(vp)
        if c = invalid
            node.g.visible = false
        else
            node.g.visible = true
            node.num.text = Live_Number(vp)
            node.logo.uri = Str_Of(c.l)
            node.name.text = Live_Name(c)
            pr = Live_At(c, now)
            if pr <> invalid
                node.prog.text = Str_Of(pr.t)
                node.track.visible = true
                node.fill.visible = true
                span = pr.b - pr.a
                if span < 1 then span = 1
                node.fill.width = Int(430 * (now - pr.a) / span)
            else
                node.prog.text = Str_Of(c.g)
                node.track.visible = false
                node.fill.visible = false
            end if
            node.ring.visible = c.k = m.playingKey
            if vp = m.ovSel
                node.bg.blendColor = "0xF2F2F7FF"
                node.name.color = "0x111114FF"
                node.prog.color = "0x3A3A44FF"
                node.num.color = "0x3A3A44FF"
                node.fill.color = "0x111114FF"
                node.track.color = "0xC9C9D6FF"
            else
                node.bg.blendColor = "0x1A1A21E6"
                node.name.color = "0xFFFFFFFF"
                node.prog.color = "0xA9A9B8FF"
                node.num.color = "0x8E8E9CFF"
                node.fill.color = "0xFFFFFFFF"
                node.track.color = "0x3A3A44FF"
            end if
        end if
    end for
end sub

function Overlay_Key(key as string) as boolean
    m.ovTimer.control = "stop"
    m.ovTimer.control = "start"
    n = m.view.Count()
    if key = "up" or key = "down"
        if n = 0 then return true
        if key = "up" then m.ovSel = m.ovSel - 1 else m.ovSel = m.ovSel + 1
        if m.ovSel < 0 then m.ovSel = n - 1
        if m.ovSel >= n then m.ovSel = 0
        Overlay_Render()
        Live_AskGuide()
    else if key = "rewind" or key = "fastforward"
        if key = "rewind" then m.ovSel = m.ovSel - m.ovN else m.ovSel = m.ovSel + m.ovN
        Overlay_Render()
        Live_AskGuide()
    else if key = "OK"
        c = Live_Chan(m.ovSel)
        if c <> invalid
            m.sel = m.ovSel
            Live_ClampTop()
            if c.k <> m.playingKey then Live_PlayChannel(c, false)
            Live_AddRecent(c.k)
            Live_AskGuide()
        end if
        Overlay_Hide()
        Watch_ShowBar()
    else if key = "left"
        Groups_Open()
    else if key = "right"
        Overlay_Hide()
        Watch_ShowBar()
    else if key = "back"
        Overlay_Hide()
    else if key = "options"
        m.top.event = Live_Options()
    end if
    return true
end function

sub Watch_Start()
    c = Live_Chan(m.sel)
    if c = invalid then return
    m.previewTimer.control = "stop"
    m.mode = "watch"
    m.guideGroup.visible = false
    m.watch.visible = true
    m.watchMsg.text = ""
    m.video.translation = [0, 0]
    m.video.width = 1920
    m.video.height = 1080
    if c.k <> m.playingKey or m.video.content = invalid
        Live_PlayChannel(c, false)
    else if m.video.hasField("mute")
        m.video.mute = false
    end if
    Live_AskGuide()
    Watch_ShowBar()
    Live_AddRecent(c.k)
    m.top.event = { action: "watch", on: true }
end sub

sub Watch_Leave()
    if m.mode <> "watch" then return
    Overlay_Hide()
    if m.groupPanel.visible
        m.groupPanel.visible = false
        m.top.event = { action: "panel", on: false }
    end if
    m.mode = "guide"
    m.zapTimer.control = "stop"
    m.barTimer.control = "stop"
    m.watch.visible = false
    m.guideGroup.visible = true
    m.video.translation = [1302, 112]
    m.video.width = 498
    m.video.height = 280
    if not Bool_Of(m.prefs.preview, true) then Live_StopVideo()
    if m.playingKey <> "" and m.keyIndex <> invalid and m.keyIndex.DoesExist(m.playingKey)
        idx = m.keyIndex[m.playingKey]
        for i = 0 to m.view.Count() - 1
            if m.view[i] = idx then m.sel = i
        end for
    end if
    m.zone = "grid"
    Live_ClampTop()
    Live_ResetWindow()
    Live_AskGuide()
    Live_Render()
    m.top.event = { action: "watch", on: false }
end sub

sub Watch_ShowBar()
    m.watchGrad.visible = true
    m.bar.visible = true
    Watch_Paint()
    m.barTimer.duration = Watch_BarSecs()
    m.barTimer.control = "stop"
    m.barTimer.control = "start"
end sub

sub Watch_HideBar()
    m.watchGrad.visible = false
    m.bar.visible = false
    m.barTimer.control = "stop"
end sub

sub onBarTimer()
    if m.watchMsg.text <> "" then return
    Watch_HideBar()
end sub

sub Watch_Paint()
    if m.mode <> "watch" then return
    c = invalid
    if not Bool_Of(m.zapping, false) then c = Live_PlayingChan()
    if c = invalid then c = Live_Chan(m.sel)
    if c = invalid then return
    now = Live_Now()
    m.barLogo.uri = Str_Of(c.l)
    num = ""
    if m.keyIndex <> invalid and m.keyIndex.DoesExist(c.k) then num = (m.keyIndex[c.k] + 1).ToStr()
    line = num + "   " + Live_Name(c)
    alts = Live_Alts(c)
    if alts.Count() > 1
        idx = 0
        if c.k = m.playingKey then idx = ToInt(m.altIdx, 0)
        line = line + "   ·   " + L("Opción {i} de {n}").Replace("{i}", (idx + 1).ToStr()).Replace("{n}", alts.Count().ToStr())
    end if
    m.barChannel.text = line
    tech = []
    if c.k = m.playingKey and m.video.state = "playing"
        vf = Watch_Format(Str_Of(m.video.videoFormat))
        af = Watch_Format(Str_Of(m.video.audioFormat))
        if vf <> "" then tech.Push(vf)
        if af <> "" then tech.Push(af)
        subs = m.video.availableSubtitleTracks
        if type(subs) = "roArray" and subs.Count() > 0 then tech.Push("CC")
    end if
    if m.favs.DoesExist(c.k) then tech.Push(L("Favorito"))
    m.barTech.text = tech.Join("   ·   ")
    pr = Live_At(c, now)
    if pr = invalid
        m.barTitle.text = Live_Name(c)
        m.barStart.text = ""
        m.barEnd.text = ""
        m.barTrack.visible = false
        m.barFill.visible = false
        nx = Live_After(c, now)
    else
        m.barTitle.text = Str_Of(pr.t)
        m.barStart.text = Live_Clock(pr.a)
        m.barEnd.text = Live_Clock(pr.b)
        m.barTrack.visible = true
        m.barFill.visible = true
        span = pr.b - pr.a
        if span < 1 then span = 1
        m.barFill.width = Int(1350 * (now - pr.a) / span)
        nx = Live_After(c, pr.b)
    end if
    if nx <> invalid
        m.barNext.text = L("A continuación") + ":  " + Str_Of(nx.t) + "  ·  " + Live_Clock(nx.a)
    else
        m.barNext.text = Str_Of(c.g)
    end if
    m.barClock.text = Fmt_Clock(Live_LocalNow())
end sub

sub Watch_Error()
    m.watchMsg.text = L("No se pudo reproducir este canal.")
    Watch_ShowBar()
end sub

sub onZap()
    m.zapping = false
    if m.mode <> "watch" then return
    c = Live_Chan(m.sel)
    if c = invalid then return
    if c.k <> m.playingKey then Live_PlayChannel(c, false)
    Live_AddRecent(c.k)
    Live_AskGuide()
end sub

function Watch_Key(key as string) as boolean
    if m.ovOpen then return Overlay_Key(key)
    if key = "up" or key = "down"
        n = m.view.Count()
        if n = 0 then return true
        goUp = key = "up"
        if Bool_Of(m.prefs.reverseZap, false) then goUp = not goUp
        if goUp then m.sel = m.sel - 1 else m.sel = m.sel + 1
        if m.sel < 0 then m.sel = n - 1
        if m.sel >= n then m.sel = 0
        m.zapping = true
        m.watchMsg.text = ""
        Watch_ShowBar()
        m.zapTimer.control = "stop"
        m.zapTimer.control = "start"
        return true
    else if key = "OK"
        if m.bar.visible then Overlay_Show() else Watch_ShowBar()
        return true
    else if key = "left" or key = "right"
        c = Live_Chan(m.sel)
        alts = []
        if c <> invalid then alts = Live_Alts(c)
        if alts.Count() > 1
            idx = ToInt(m.altIdx, 0)
            if c.k <> m.playingKey then idx = 0
            if key = "right" then idx = idx + 1 else idx = idx - 1
            if idx < 0 then idx = alts.Count() - 1
            if idx >= alts.Count() then idx = 0
            m.zapTimer.control = "stop"
            m.altFails = 0
            m.reconnects = 0
            m.watchMsg.text = ""
            Live_PlayAlt(c, idx)
            Watch_ShowBar()
        else if key = "left"
            Overlay_Show()
        else
            Watch_ShowBar()
        end if
        return true
    else if key = "replay"
        Watch_Previous()
        return true
    else if key = "play"
        if m.bar.visible then Watch_HideBar() else Watch_ShowBar()
        return true
    else if key = "options"
        m.top.event = Live_Options()
        return true
    else if key = "back"
        if m.bar.visible
            Watch_HideBar()
        else
            Watch_Leave()
        end if
        return true
    end if
    return true
end function

sub Watch_Previous()
    if m.prevKey = "" or m.keyIndex = invalid or not m.keyIndex.DoesExist(m.prevKey)
        Watch_ShowBar()
        return
    end if
    target = m.keyIndex[m.prevKey]
    vp = -1
    for i = 0 to m.view.Count() - 1
        if m.view[i] = target then vp = i
    end for
    if vp < 0
        m.groupIdx = Groups_Find("all")
        Live_ApplyGroup(false)
        for i = 0 to m.view.Count() - 1
            if m.view[i] = target then vp = i
        end for
    end if
    if vp < 0 then return
    m.sel = vp
    Live_ClampTop()
    c = Live_Chan(vp)
    Live_PlayChannel(c, false)
    Live_AddRecent(c.k)
    Live_AskGuide()
    Watch_ShowBar()
end sub

function Watch_Format(raw as string) as string
    v = LCase(raw)
    if v = "" or v = "none" then return ""
    map = { "mpeg4_10b": "H.264", "h264": "H.264", "avc": "H.264", "hevc": "HEVC", "h265": "HEVC", "mpeg4_15": "HEVC", "vp9": "VP9", "av1": "AV1", "mpeg2": "MPEG-2", "mpeg4_2": "MPEG-4", "aac_adts": "AAC", "aac_latm": "AAC", "aac": "AAC", "ac3": "Dolby Digital", "eac3": "Dolby Digital Plus", "mp3": "MP3", "mpg123": "MP3", "mpeg": "MP3", "mp1": "MP3", "mp2": "MP2", "opus": "Opus", "dts": "DTS", "lpcm": "PCM" }
    if map.DoesExist(v) then return map[v]
    us = Instr(1, v, "_")
    if us > 1 and map.DoesExist(Left(v, us - 1)) then return map[Left(v, us - 1)]
    return UCase(raw)
end function
