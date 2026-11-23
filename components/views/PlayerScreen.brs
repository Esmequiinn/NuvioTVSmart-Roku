sub init()
    m.video = m.top.findNode("video")
    m.top.video = m.video
    m.buffering = m.top.findNode("buffering")
    m.loadScreen = m.top.findNode("loadScreen")
    m.loadBg = m.top.findNode("loadBg")
    m.loadLogo = m.top.findNode("loadLogo")
    m.loadTitle = m.top.findNode("loadTitle")
    m.loadSpin = m.top.findNode("loadSpin")
    m.loadSpin.poster.uri = "pkg:/images/c/spinner56.png"
    m.loadSpin.poster.width = 56
    m.loadSpin.poster.height = 56
    m.loadTitle.font.size = 64
    m.loadLogo.observeField("loadStatus", "onLoadLogo")
    m.loadPct = m.top.findNode("loadPct")
    m.bufTimer = m.top.findNode("bufTimer")
    m.bufTimer.observeField("fire", "onBufTimer")
    m.holdTimer = m.top.findNode("holdTimer")
    m.holdTimer.observeField("fire", "Load_Next")
    m.loadQueue = []
    m.loadShown = ""
    m.holding = false
    m.started = false
    m.pauseScreen = m.top.findNode("pauseScreen")
    m.pauseBg = m.top.findNode("pauseBg")
    m.pauseLogo = m.top.findNode("pauseLogo")
    m.pauseTitle = m.top.findNode("pauseTitle")
    m.pauseMeta = m.top.findNode("pauseMeta")
    m.pauseDesc = m.top.findNode("pauseDesc")
    m.pauseHint = m.top.findNode("pauseHint")
    m.controls = m.top.findNode("controls")
    m.clock = m.top.findNode("clock")
    m.ends = m.top.findNode("ends")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.playBadges = m.top.findNode("playBadges")
    m.pauseBadges = m.top.findNode("pauseBadges")
    m.track = m.top.findNode("track")
    m.fill = m.top.findNode("fill")
    m.knob = m.top.findNode("knob")
    m.time = m.top.findNode("time")
    m.buttonsGroup = m.top.findNode("buttons")
    m.hint = m.top.findNode("hint")
    m.partyLabel = m.top.findNode("partyLabel")
    m.panel = m.top.findNode("panel")
    m.title.font.size = 54
    m.pauseTitle.font.size = 64
    L_Texts(["buffering", "pauseLabel", "pauseHint"])

    m.zone = "buttons"
    m.index = 0
    m.buttons = []
    m.panelKind = ""
    m.panelValues = []
    m.seekTarget = -1
    m.seekClock = CreateObject("roTimespan")
    m.seekCount = 0
    m.seekDir = 0
    m.seekLast = 0
    m.fallbackDur = 0
    m.applied = -1
    m.appliedClock = CreateObject("roTimespan")
    m.userAudio = ""
    m.audioFixes = 0
    m.resumeAt = 0
    m.resumeDone = true

    m.hideTimer = createTimer(5.0)
    m.hideTimer.observeField("fire", "onHideTimer")
    m.pauseTimer = createTimer(15.0)
    m.pauseTimer.observeField("fire", "onPauseTimer")
    m.seekTimer = createTimer(0.7)
    m.seekTimer.observeField("fire", "applySeek")
    m.clockTimer = createTimer(20.0)
    m.clockTimer.repeat = true
    m.clockTimer.observeField("fire", "updateClock")

    m.video.observeField("state", "onState")
    m.video.observeField("availableAudioTracks", "applyAudioPreference")
    m.video.observeField("bufferingStatus", "onBufferStatus")
    m.video.observeField("currentAudioTrack", "onAudioChanged")
    m.video.observeField("availableSubtitleTracks", "applySubtitlePreference")
    m.audioApplied = false
    m.subsApplied = false
    m.subsMatchedPref = false
    m.subsMatchedPrimary = false
    m.pinnedSubUrl = ""
    m.userSubChosen = false
    m.subGroupLang = ""
    m.subGroupsCache = invalid
    m.video.observeField("focusedChild", "onVideoFocus")
    m.video.observeField("position", "onPosition")
    m.panel.observeField("chosen", "onPanelChosen")
    m.panel.observeField("closed", "onPanelClosed")
    m.top.observeField("focusedChild", "onTopFocus")
    m.logo.observeField("loadStatus", "onLogoStatus")
    m.pauseLogo.observeField("loadStatus", "onPauseLogoStatus")
    Ex_Init()
end sub

function createTimer(seconds as float) as object
    t = m.top.createChild("Timer")
    t.duration = seconds
    t.repeat = false
    return t
end function

sub onActive()
    if m.top.active
        m.controls.visible = false
        m.panel.visible = false
        m.pauseScreen.visible = false
        m.seekTarget = -1
        m.applied = -1
        m.clockTimer.control = "start"
        m.panel.setFocus(false)
        m.top.setFocus(true)
    else
        m.hideTimer.control = "stop"
        m.pauseTimer.control = "stop"
        m.clockTimer.control = "stop"
        m.video.control = "stop"
        hideLoadScreen()
        m.exTimer.control = "stop"
        Ex_Reset()
    end if
end sub

sub onVideoFocus()
    if m.top.active and m.video.hasFocus() and not m.panel.visible then m.top.setFocus(true)
end sub

sub onTopFocus()
    if m.panel.visible and m.top.hasFocus() then m.panel.setFocus(true)
end sub

sub onInfo()
    info = m.top.info
    if info = invalid then return
    m.audioApplied = false
    m.subsApplied = false
    m.subsMatchedPref = false
    m.subsMatchedPrimary = false
    m.pinnedSubUrl = ""
    m.userSubChosen = false
    m.subGroupLang = ""
    m.subGroupsCache = invalid
    m.userAudio = ""
    m.audioFixes = 0
    m.applied = -1
    m.resumeAt = ToInt(info.resumeAt, 0)
    m.resumeDone = m.resumeAt <= 0
    m.fallbackDur = 0
    if not Bool_Of(info.isSeries, false) then m.fallbackDur = runtimeOf(Str_Of(info.metaLine))
    m.clock.visible = Bool_Of(info.clock, true)
    m.ends.visible = Bool_Of(info.clock, true)
    m.title.text = Str_Of(info.title)
    m.pauseTitle.text = Str_Of(info.title)
    m.meta.text = Str_Of(info.metaLine)
    m.pauseMeta.text = Str_Of(info.metaLine)
    m.pauseDesc.text = Str_Of(info.description)
    m.pauseBg.uri = Img_Sized(Str_Of(info.background), "w1280")
    m.loadBg.uri = Img_Sized(Str_Of(info.background), "w1280")
    m.loadTitle.text = Str_Of(info.title)
    m.loadTitle.visible = true
    m.loadLogo.visible = false
    m.loadLogo.uri = Img_Sized(Str_Of(info.logo), "w500")
    onLoadLogo()
    m.started = false
    m.loadPct.text = ""
    m.bufPct = -1
    m.loadScreen.visible = true
    m.loadSpin.control = "start"
    paintLoadText()
    logo = Str_Of(info.logo)
    m.logo.visible = false
    m.pauseLogo.visible = false
    m.title.visible = true
    m.pauseTitle.visible = true
    setLogo(logo)
    buildButtons(Bool_Of(info.isSeries, false))
    Badges_Show()
    if m.srcPanel <> invalid then m.srcPanel.visible = false
    if m.panel <> invalid then m.panel.visible = false
    Ex_SubSyncClose()
    Ex_SetSubPreview(false)
    Ex_OnInfo()
end sub

sub onLoadLogo()
    if m.loadLogo.loadStatus = "ready" and m.loadLogo.uri <> ""
        m.loadLogo.visible = true
        m.loadTitle.visible = false
    end if
end sub

sub hideLoadScreen()
    m.started = true
    m.bufTimer.control = "stop"
    m.loadScreen.visible = false
    m.loadSpin.control = "stop"
    m.loadPct.text = ""
    m.top.loadStatus = ""
end sub

sub onBufTimer()
    if m.video.state <> "buffering" or not m.started or m.postBox.visible then return
    m.bufPct = -1
    paintLoadText()
    m.loadScreen.visible = true
    m.loadSpin.control = "start"
end sub

sub onBufferStatus()
    st = m.video.bufferingStatus
    if type(st) <> "roAssociativeArray" or not m.loadScreen.visible then return
    m.bufPct = ToInt(st.percentage, -1)
    paintLoadText()
end sub

sub onLoadStatus()
    Load_Push(Str_Of(m.top.loadStatus), false)
end sub

sub onLoadNote()
    Load_Push(Str_Of(m.top.loadNote), true)
end sub

sub Load_Push(text as string, important as boolean)
    if text = ""
        if important then return
        m.loadQueue = []
        m.loadShown = ""
        m.holding = false
        m.holdTimer.control = "stop"
        paintLoadText()
        return
    end if
    keep = []
    for each q in m.loadQueue
        if q.important then keep.Push(q)
    end for
    if keep.Count() >= 3 then keep.Shift()
    keep.Push({ text: text, important: important })
    m.loadQueue = keep
    if not m.holding then Load_Next()
end sub

sub Load_Next()
    if m.loadQueue.Count() = 0
        m.holding = false
        return
    end if
    q = m.loadQueue.Shift()
    m.loadShown = q.text
    m.bufPct = -1
    m.holding = true
    if q.important then m.holdTimer.duration = 3.5 else m.holdTimer.duration = 1.5
    m.holdTimer.control = "stop"
    m.holdTimer.control = "start"
    paintLoadText()
end sub

sub paintLoadText()
    if not m.top.loadDetails
        m.loadPct.text = ""
        return
    end if
    text = m.loadShown
    pct = ToInt(m.bufPct, -1)
    if pct >= 0 and pct < 100
        line = L("Cargando") + "  " + pct.ToStr() + "%"
        if text = "" then text = line else text = text + chr(10) + line
    end if
    m.loadPct.text = text
end sub

sub setLogo(logo as string)
    sized = Img_Sized(logo, "w500")
    m.logo.uri = sized
    m.pauseLogo.uri = sized
    onLogoStatus()
    onPauseLogoStatus()
end sub

sub onMetaPatch()
    p = m.top.metaPatch
    if type(p) <> "roAssociativeArray" then return
    if Str_Of(p.metaLine) <> "" and m.meta.text = ""
        m.meta.text = Str_Of(p.metaLine)
        m.pauseMeta.text = Str_Of(p.metaLine)
        Badges_Show()
    end if
    if Str_Of(p.description) <> "" and m.pauseDesc.text = "" then m.pauseDesc.text = Str_Of(p.description)
    if Str_Of(p.background) <> "" and m.pauseBg.uri = ""
        m.pauseBg.uri = Img_Sized(Str_Of(p.background), "w1280")
        if not Bool_Of(m.started, false) then m.loadBg.uri = m.pauseBg.uri
    end if
    if m.fallbackDur = 0 and Str_Of(p.metaLine) <> "" and not Bool_Of(p.isSeries, false) then m.fallbackDur = runtimeOf(Str_Of(p.metaLine))
    Badges_Show()
end sub

sub Badges_Show()
    list = []
    info = m.top.info
    if type(info) = "roAssociativeArray" and type(info.badges) = "roArray"
        for each b in info.badges
            if type(b) = "roAssociativeArray" and Str_Of(b.i) <> "" then list.Push(Str_Of(b.i))
        end for
    end if
    has = list.Count() > 0
    if has
        m.top.findNode("logo").translation = [120, 656]
        m.title.translation = [120, 696]
        m.meta.translation = [120, 792]
        m.playBadges.translation = [120, 836]
        m.pauseDesc.translation = [120, 908]
        m.pauseBadges.translation = [120, 860]
        m.pauseHint.translation = [120, 1016]
    else
        m.top.findNode("logo").translation = [120, 700]
        m.title.translation = [120, 740]
        m.meta.translation = [120, 836]
        m.pauseDesc.translation = [120, 862]
        m.pauseHint.translation = [120, 980]
    end if
    Badges_Fill(m.playBadges, list, 30)
    Badges_Fill(m.pauseBadges, list, 32)
end sub

sub Badges_Fill(group as object, list as object, size as integer)
    group.removeChildrenIndex(group.getChildCount(), 0)
    x = 0
    for each uri in list
        if x > 1500 then exit for
        p = group.createChild("Poster")
        p.height = size
        p.width = size * 3
        p.loadHeight = size * 2
        p.loadDisplayMode = "scaleToFit"
        p.uri = uri
        p.translation = [x, 0]
        p.observeField("loadStatus", "onBadgeSized")
        x = x + size * 3 + 8
    end for
end sub

sub onBadgeSized()
    for each g in [m.playBadges, m.pauseBadges]
        x = 0
        for i = 0 to g.getChildCount() - 1
            p = g.getChild(i)
            w = p.width
            if p.loadStatus = "ready" and p.bitmapHeight > 0 then w = Int(p.height * p.bitmapWidth / p.bitmapHeight)
            if p.loadStatus = "failed" then w = 0
            p.width = w
            p.translation = [x, 0]
            if w > 0 then x = x + w + 8
        end for
    end for
end sub

sub onLogo()
    logo = m.top.logo
    sized = Img_Sized(logo, "w500")
    if logo = "" or sized = m.logo.uri then return
    if not m.started
        m.loadLogo.uri = sized
        onLoadLogo()
    end if
    m.logo.visible = false
    m.pauseLogo.visible = false
    setLogo(logo)
end sub

sub onLogoStatus()
    if m.logo.loadStatus = "ready" and m.logo.uri <> ""
        m.logo.visible = true
        m.title.visible = false
    end if
end sub

sub onPauseLogoStatus()
    if m.pauseLogo.loadStatus = "ready" and m.pauseLogo.uri <> ""
        m.pauseLogo.visible = true
        m.pauseTitle.visible = false
    end if
end sub

sub buildButtons(isSeries as boolean)
    m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
    defs = [
        { id: "play", icon: "pkg:/images/ic_pause.png", hint: L("Pausa") }
        { id: "subs", icon: "pkg:/images/ic_subs.png", hint: L("Subtítulos") }
        { id: "audio", icon: "pkg:/images/ic_audio.png", hint: "Audio" }
        { id: "sources", icon: "pkg:/images/ic_sources.png", hint: L("Fuentes") }
        { id: "switch", icon: "pkg:/images/ic_switch.png", hint: L("Cambiar forma de abrir") }
    ]
    if isSeries
        defs.Push({ id: "next", icon: "pkg:/images/ic_next.png", hint: L("Siguiente episodio") })
        defs.Push({ id: "episodes", icon: "pkg:/images/ic_episodes.png", hint: L("Episodios") })
    end if
    if m.top.partyEnabled then defs.Push({ id: "party", icon: "pkg:/images/ic_party.png", hint: "Watch Party" })
    m.buttons = []
    x = 0
    for each d in defs
        g = m.buttonsGroup.createChild("Group")
        g.translation = [x, 0]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/c/d72.png"
        bg.width = 72
        bg.height = 72
        icon = g.createChild("Poster")
        icon.uri = d.icon.Replace("/images/", "/images/s/").Replace(".png", "_36.png")
        icon.width = 36
        icon.height = 36
        icon.translation = [18, 18]
        m.buttons.Push({ id: d.id, hint: d.hint, bg: bg, icon: icon })
        x = x + 92
    end for
    m.index = 0
    paintButtons()
end sub

sub paintButtons()
    playing = m.video.state = "playing" or m.video.state = "buffering"
    for i = 0 to m.buttons.Count() - 1
        b = m.buttons[i]
        if b.id = "play"
            if playing
                b.icon.uri = "pkg:/images/s/ic_pause_36.png"
                b.hint = L("Pausa")
            else
                b.icon.uri = "pkg:/images/s/ic_play_36.png"
                b.hint = L("Continuar")
            end if
        end if
        if m.zone = "buttons" and i = m.index
            b.bg.blendColor = m.top.accent
            b.icon.blendColor = Ui_Ink(m.top.accent)
            m.hint.text = b.hint
        else
            b.bg.blendColor = "0xFFFFFF2E"
            b.icon.blendColor = "0xFFFFFFFF"
        end if
    end for
    m.knob.visible = m.zone = "bar"
    if m.zone = "bar" then m.hint.text = L("Izquierda o derecha para adelantar o regresar")
    m.fill.color = m.top.accent
end sub

sub showControls(zone as string)
    if Bool_Of(m.subBarOn, false) then Ex_SubSyncClose()
    m.zone = zone
    m.pauseScreen.visible = false
    m.controls.visible = true
    updateClock()
    updateBar()
    paintButtons()
    restartHide()
    Ex_OnControls(true)
end sub

sub hideControls()
    m.controls.visible = false
    Ex_OnControls(false)
    m.hideTimer.control = "stop"
    if m.video.state = "paused" then restartPauseTimer()
end sub

sub restartHide()
    m.hideTimer.control = "stop"
    if m.video.state = "playing" then m.hideTimer.control = "start"
end sub

sub restartPauseTimer()
    m.pauseTimer.control = "stop"
    m.pauseTimer.control = "start"
end sub

sub onHideTimer()
    if not m.panel.visible and m.video.state = "playing" then hideControls()
end sub

sub applyAudioPreference()
    if m.audioApplied then return
    info = m.top.info
    if info = invalid then return
    tracks = m.video.availableAudioTracks
    if type(tracks) <> "roArray" or tracks.Count() = 0 then return
    m.audioApplied = true
    original = Str_Of(info.originalLang)
    for each code in [Str_Of(info.audioLang), Str_Of(info.audioLang2)]
        wanted = Lang_Resolve(code, original)
        if wanted <> ""
            for each t in tracks
                if Lang_Matches(Str_Of(t.Language), wanted) and Audio_Playable(t)
                    Audio_Pick(t)
                    return
                end if
            end for
        end if
    end for
    current = invalid
    for each t in tracks
        if Str_Of(t.Track) = m.video.currentAudioTrack then current = t
    end for
    if current = invalid then current = tracks[0]
    if Audio_Playable(current) then return
    for each t in tracks
        if Audio_Playable(t)
            Audio_Pick(t)
            return
        end if
    end for
end sub

sub Audio_Pick(t as object)
    if Str_Of(t.Track) <> m.video.currentAudioTrack then m.video.audioTrack = Str_Of(t.Track)
    m.userAudio = Str_Of(t.Track)
end sub

function Audio_Codec(t as object) as string
    text = LCase(Str_Of(t.Format) + " " + Str_Of(t.Name) + " " + Str_Of(t.Description))
    if Instr(1, text, "truehd") > 0 or Instr(1, text, "mlp") > 0 then return "truehd"
    if Instr(1, text, "dts") > 0 then return "dts"
    if Instr(1, text, "eac3") > 0 or Instr(1, text, "e-ac-3") > 0 or Instr(1, text, "dd+") > 0 or Instr(1, text, "ddp") > 0 or Instr(1, text, "atmos") > 0 then return "eac3"
    if Instr(1, text, "ac3") > 0 or Instr(1, text, "ac-3") > 0 or Instr(1, text, "dolby digital") > 0 then return "ac3"
    if Instr(1, text, "flac") > 0 then return "flac"
    if Instr(1, text, "opus") > 0 then return "opus"
    if Instr(1, text, "vorbis") > 0 then return "vorbis"
    if Instr(1, text, "pcm") > 0 then return "pcm"
    return ""
end function

function Audio_Playable(t as object) as boolean
    codec = Audio_Codec(t)
    if codec = "" then return true
    if m.audioCan = invalid then m.audioCan = {}
    if not m.audioCan.DoesExist(codec)
        ok = true
        r = CreateObject("roDeviceInfo").CanDecodeAudio({ Codec: codec })
        if type(r) = "roAssociativeArray" and r.result <> invalid then ok = r.result = true
        m.audioCan[codec] = ok
    end if
    return m.audioCan[codec]
end function

sub onAudioChanged()
    if m.userAudio = "" or m.audioFixes >= 3 then return
    current = m.video.currentAudioTrack
    if current = "" or current = m.userAudio then return
    m.audioFixes = m.audioFixes + 1
    m.video.audioTrack = m.userAudio
end sub

function isForcedTrack(t as object) as boolean
    text = LCase(Str_Of(t.Description) + " " + Str_Of(t.TrackName))
    return Instr(1, text, "forced") > 0 or Instr(1, text, "forzad") > 0
end function

function currentAudioLang() as string
    tracks = m.video.availableAudioTracks
    if type(tracks) <> "roArray" then return ""
    for each t in tracks
        if Str_Of(t.Track) = m.video.currentAudioTrack then return Str_Of(t.Language)
    end for
    if tracks.Count() > 0 then return Str_Of(tracks[0].Language)
    return ""
end function

sub onResumeOverride()
    ov = m.top.resumeOverride
    if type(ov) <> "roAssociativeArray" then return
    if ov.resumeAt <> invalid
        m.resumeAt = ToInt(ov.resumeAt, 0)
        m.resumeDone = m.resumeAt <= 0
    end if
    if Str_Of(ov.subUrl) <> ""
        m.pinnedSubUrl = Str_Of(ov.subUrl)
        m.subsApplied = false
    end if
end sub

sub selectSubtitle(track as string)
    Ex_SubSelect(track)
end sub

function currentActiveSubUrl() as string
    ext = Ex_SubActive()
    if ext <> "" then return ext
    if m.video <> invalid and m.video.globalCaptionMode = "On" then return Str_Of(m.video.subtitleTrack)
    return ""
end function

function Player_CollectSubs(internalTracks as dynamic, extraSubs as dynamic, info as dynamic, activeUrl as string) as object
    if type(info) <> "roAssociativeArray" then info = {}
    out = []
    byUrl = {}
    if type(extraSubs) = "roArray"
        for each entry in extraSubs
            if type(entry) = "roAssociativeArray" and Str_Of(entry.url) <> ""
                copy = invalid
                if Str_Of(entry.langKey) <> ""
                    copy = {}
                    for each ek in entry
                        copy[ek] = entry[ek]
                    end for
                    if Str_Of(copy.sourceType) = "" then copy.sourceType = "addon"
                    if Str_Of(copy.provider) = "" then copy.provider = L("Complemento")
                    if Str_Of(copy.langLabel) = "" then copy.langLabel = Lang_Name(copy.langKey)
                    if Str_Of(copy.label) = "" then copy.label = Sub_FormatLabel(copy)
                else
                    stype = Str_Of(entry.sourceType)
                    if stype = "" then stype = "addon"
                    prov = Str_Of(entry.provider)
                    if prov = "" then prov = L("Complemento")
                    copy = Sub_NormalizeTrack(entry, prov, stype)
                end if
                if copy <> invalid
                    key = Sub_UrlKey(copy.url)
                    if byUrl.DoesExist(key)
                        Sub_MergeInto(byUrl[key], copy)
                    else
                        byUrl[key] = copy
                        out.Push(copy)
                    end if
                end if
            end if
        end for
    end if
    builtIn = []
    if type(internalTracks) = "roArray"
        for each t in internalTracks
            trackName = Str_Of(t.TrackName)
            if trackName <> ""
                key = Sub_UrlKey(trackName)
                if byUrl.DoesExist(key)
                    existing = byUrl[key]
                    existing.trackName = trackName
                    if isForcedTrack(t) then existing.forced = true
                    if Sub_DetectSdh(Str_Of(t.Description) + " " + Str_Of(t.Name)) then existing.sdh = true
                    existing.label = Sub_FormatLabel(existing)
                else
                    norm = Sub_NormalizeTrack(t, L("Integrado"), "internal")
                    if norm <> invalid
                        norm.trackName = trackName
                        if isForcedTrack(t) then norm.forced = true
                        byUrl[key] = norm
                        builtIn.Push(norm)
                    end if
                end if
            end if
        end for
    end if
    combined = []
    for each it in builtIn
        combined.Push(it)
    end for
    for each it in out
        combined.Push(it)
    end for
    stripSdh = Bool_Of(info.stripSdh, false)
    onlyPref = Bool_Of(info.onlyPreferred, false)
    original = Str_Of(info.originalLang)
    pref1 = Lang_Resolve(Str_Of(info.subLang), original)
    pref2 = Lang_Resolve(Str_Of(info.subLang2), original)
    filtered = []
    for each item in combined
        isActive = (activeUrl <> "" and (item.url = activeUrl or Str_Of(item.trackName) = activeUrl))
        allow = true
        if not isActive
            if stripSdh and Bool_Of(item.sdh, false) then allow = false
            if allow and onlyPref
                isUnknownInternal = (item.sourceType = "internal" and item.langKey = "und")
                if not isUnknownInternal
                    ok = false
                    if pref1 <> "" and Lang_Matches(item.langKey, pref1) then ok = true
                    if pref2 <> "" and Lang_Matches(item.langKey, pref2) then ok = true
                    if not ok then allow = false
                end if
            end if
        end if
        if allow then filtered.Push(item)
    end for
    return filtered
end function

function Player_GroupSubs(items as object, info as dynamic, activeUrl as string, audioLang as string) as object
    if type(info) <> "roAssociativeArray" then info = {}
    original = Str_Of(info.originalLang)
    pref1 = Lang_Resolve(Str_Of(info.subLang), original)
    pref2 = Lang_Resolve(Str_Of(info.subLang2), original)
    uiLang = Str_Of(info.uiLang)
    if uiLang = "" then uiLang = Lang_UiCode()
    audNorm = Lang_Norm(audioLang)
    origNorm = Lang_Norm(original)
    byLang = {}
    groups = []
    for each item in items
        lk = Str_Of(item.langKey)
        if lk = "" then lk = "und"
        if not byLang.DoesExist(lk)
            grp = {
                langKey: lk
                langLabel: Lang_Name(lk)
                tracks: []
                active: false
            }
            byLang[lk] = grp
            groups.Push(grp)
        end if
        grp = byLang[lk]
        isActive = (activeUrl <> "" and (item.url = activeUrl or Str_Of(item.trackName) = activeUrl))
        if isActive then grp.active = true
        grp.tracks.Push(item)
    end for
    for each grp in groups
        lk = grp.langKey
        rank = 500
        if lk = "und"
            rank = 900
        else
            s1 = Lang_MatchScore(lk, pref1)
            s2 = Lang_MatchScore(lk, pref2)
            if s1 >= 2
                rank = 10 + (3 - s1)
            else if grp.active
                rank = 20
            else if s1 = 1
                rank = 30
            else if s2 >= 2
                rank = 40 + (3 - s2)
            else if s2 = 1
                rank = 50
            else if (audNorm <> "" and audNorm <> "und" and Lang_Matches(lk, audNorm)) or (origNorm <> "" and origNorm <> "und" and Lang_Matches(lk, origNorm)) or (uiLang <> "" and uiLang <> "und" and Lang_Matches(lk, uiLang))
                rank = 60
            end if
        end if
        grp.rank = rank
        padRank = rank.ToStr()
        if rank < 10
            padRank = "00" + padRank
        else if rank < 100
            padRank = "0" + padRank
        end if
        grp.sortKey = padRank + "|" + LCase(grp.langLabel)
        Player_SortTracksInGroup(grp.tracks)
    end for
    for i = 1 to groups.Count() - 1
        cur = groups[i]
        j = i - 1
        while j >= 0 and groups[j].sortKey > cur.sortKey
            groups[j + 1] = groups[j]
            j = j - 1
        end while
        groups[j + 1] = cur
    end for
    return groups
end function

sub Player_SortTracksInGroup(tracks as object)
    if tracks.Count() < 2 then return
    srcOrder = { internal: 0, server: 1, stream: 2, addon: 3 }
    for i = 1 to tracks.Count() - 1
        cur = tracks[i]
        curScore = ToInt(srcOrder[Str_Of(cur.sourceType)], 3) * 10
        if Bool_Of(cur.forced, false) then curScore = curScore + 4 else if Bool_Of(cur.sdh, false) then curScore = curScore + 2
        j = i - 1
        while j >= 0
            prev = tracks[j]
            prevScore = ToInt(srcOrder[Str_Of(prev.sourceType)], 3) * 10
            if Bool_Of(prev.forced, false) then prevScore = prevScore + 4 else if Bool_Of(prev.sdh, false) then prevScore = prevScore + 2
            if prevScore > curScore
                tracks[j + 1] = prev
                j = j - 1
            else
                exit while
            end if
        end while
        tracks[j + 1] = cur
    end for
end sub

sub onExtraSubs()
    m.subGroupsCache = invalid
    if not m.top.active then return
    if not Bool_Of(m.userSubChosen, false) and not Bool_Of(m.subsMatchedPrimary, false)
        m.subsApplied = false
        applySubtitlePreference()
    end if
    if m.panel.visible and (m.panelKind = "subs" or m.panelKind = "subsLang")
        focused = m.panel.focusIndex
        if m.panelKind = "subs"
            openSubs(m.subGroupLang, -1)
        else
            openSubsLang(m.subGroupLang, focused)
        end if
    end if
end sub

sub applySubtitlePreference()
    if m.subsApplied or Bool_Of(m.userSubChosen, false) then return
    info = m.top.info
    if info = invalid then return
    allInternal = m.video.availableSubtitleTracks
    allExtra = m.top.extraSubs
    hasAny = (type(allInternal) = "roArray" and allInternal.Count() > 0) or (type(allExtra) = "roArray" and allExtra.Count() > 0)
    if not hasAny then return
    m.subsApplied = true
    items = Player_CollectSubs(allInternal, allExtra, info, currentActiveSubUrl())
    pinnedUrl = Str_Of(m.pinnedSubUrl)
    if pinnedUrl = "" and Left(Str_Of(info.subLang), 4) = "url:" then pinnedUrl = Mid(Str_Of(info.subLang), 5)
    if pinnedUrl <> ""
        for each t in items
            if t.url = pinnedUrl or Str_Of(t.trackName) = pinnedUrl
                m.subsMatchedPref = true
                m.subsMatchedPrimary = true
                selectSubtitle(t.url)
                return
            end if
        end for
    end if
    first = LCase(Str_Of(info.subLang))
    second = LCase(Str_Of(info.subLang2))
    if Bool_Of(info.forcedSubs, false)
        audio = currentAudioLang()
        if audio <> ""
            for each t in items
                if Bool_Of(t.forced, false) and Lang_Matches(t.langKey, audio)
                    m.subsMatchedPref = true
                    m.subsMatchedPrimary = true
                    selectSubtitle(t.url)
                    return
                end if
            end for
        end if
    end if
    if first = "" or first = "off" or first = "none"
        m.subsMatchedPref = true
        m.subsMatchedPrimary = true
        Ex_SubSelect("")
        return
    end if
    original = Str_Of(info.originalLang)
    prefCodes = [first, second]
    for passIdx = 0 to 1
        wanted = Lang_Resolve(prefCodes[passIdx], original)
        if wanted <> ""
            bestNormal = invalid
            bestScore = 0
            bestFallback = invalid
            bestFallbackScore = 0
            for each t in items
                score = Lang_MatchScore(t.langKey, wanted)
                if score > 0
                    if not Bool_Of(t.forced, false) and not Bool_Of(t.sdh, false)
                        if score > bestScore
                            bestScore = score
                            bestNormal = t
                        end if
                    else if not Bool_Of(t.forced, false)
                        if score > bestFallbackScore
                            bestFallbackScore = score
                            bestFallback = t
                        end if
                    else if bestFallback = invalid
                        bestFallback = t
                        bestFallbackScore = score
                    end if
                end if
            end for
            picked = bestNormal
            if picked = invalid then picked = bestFallback
            if picked <> invalid
                m.subsMatchedPref = true
                if passIdx = 0 then m.subsMatchedPrimary = true
                selectSubtitle(picked.url)
                return
            end if
        end if
    end for
    if not Bool_Of(m.subsMatchedPref, false) then Ex_SubSelect("")
end sub

sub onPauseTimer()
    info = m.top.info
    if info <> invalid and not Bool_Of(info.pauseOverlay, true) then return
    if m.video.state = "paused" and not m.panel.visible and not Bool_Of(m.subBarOn, false)
        m.controls.visible = false
        m.pauseScreen.visible = true
    end if
end sub

sub updateClock()
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    m.clock.text = Fmt_Clock(now)
    remaining = Int(totalTime() - settledPosition())
    if totalTime() > 0 and remaining > 0
        now.FromSeconds(now.AsSeconds() + remaining)
        m.ends.text = L("Termina a las ") + Fmt_Clock(now)
    else
        m.ends.text = ""
    end if
end sub

function totalTime() as float
    known = m.top.knownDuration
    if known > 0 and (m.video.duration <= 0 or m.video.duration > known * 1.3 or m.video.duration < known * 0.7) then return known
    if m.video.duration > 0 then return m.video.duration
    if m.fallbackDur <> invalid and m.fallbackDur > 0 then return m.fallbackDur
    return 0
end function

function runtimeOf(text as string) as integer
    re = CreateObject("roRegex", "(\d+)\s*h(?:\s*(\d+)\s*m)?|(\d+)\s*(?:m\b|min)", "i")
    found = re.Match(text)
    if found.Count() = 0 then return 0
    if found.Count() > 1 and found[1] <> ""
        mins = found[1].ToInt() * 60
        if found.Count() > 2 and found[2] <> "" then mins = mins + found[2].ToInt()
        return mins * 60
    end if
    if found.Count() > 3 and found[3] <> "" then return found[3].ToInt() * 60
    return 0
end function

sub updateBar()
    duration = totalTime()
    current = settledPosition()
    if m.seekTarget >= 0 then current = m.seekTarget
    if duration > 0
        ratio = current / duration
        if ratio > 1 then ratio = 1
        if ratio < 0 then ratio = 0
        m.fill.width = Int(m.track.width * ratio)
        m.knob.translation = [120 + m.fill.width - 10, 883]
        m.time.text = Fmt_Time(Int(current)) + "  /  " + Fmt_Time(Int(duration))
    else
        m.fill.width = 0
        m.time.text = Fmt_Time(Int(current))
    end if
end sub

sub onPosition_Run()
    if m.controls.visible then updateBar()
    Ex_Tick(m.video.position)
end sub

sub Seek_Guard(target as integer)
    if m.seekGuard = invalid
        m.seekGuard = CreateObject("roSGNode", "Timer")
        m.seekGuard.repeat = false
        m.seekGuard.duration = 22
        m.seekGuard.observeField("fire", "onSeekGuard")
    end if
    m.seekGuardAt = target
    m.seekGuardTries = 0
    m.seekGuard.control = "stop"
    m.seekGuard.control = "start"
end sub

sub onSeekGuard()
    if not m.top.visible or m.seekGuardAt = invalid then return
    state = m.video.state
    if state = "playing" or state = "paused" or state = "finished" then return
    if m.video.position >= m.seekGuardAt + 2 then return
    m.top.event = { type: "reseek", position: m.seekGuardAt }
    m.seekGuardAt = invalid
end sub

sub onState_Run()
    state = m.video.state
    if state = "playing" and not Bool_Of(m.captionApplied, false)
        m.captionApplied = true
        Ex_NativeCaptionApply()
    end if
    if state = "buffering" then m.captionApplied = false
    if (state = "playing" or state = "paused") and m.seekGuard <> invalid then m.seekGuard.control = "stop"
    m.buffering.visible = false
    if state = "buffering" and m.started and not m.loadScreen.visible then m.bufTimer.control = "start"
    if state = "playing" or state = "paused" or state = "error" or state = "finished" then hideLoadScreen()
    if state = "playing" and not m.resumeDone
        m.resumeDone = true
        if m.video.position < m.resumeAt - 8
            Dbg_Log("resume seek " + Int(m.resumeAt).ToStr() + " from " + Int(m.video.position).ToStr())
            m.video.seek = m.resumeAt
            m.applied = m.resumeAt
            m.appliedClock.Mark()
        end if
    end if
    if state = "playing"
        m.pauseScreen.visible = false
        m.pauseTimer.control = "stop"
        restartHide()
    else if state = "paused"
        restartPauseTimer()
    else if state = "finished"
        if m.postShown and m.postBox.visible
            m.top.postActive = true
        else
            m.top.event = { type: "finished", position: Int(m.video.position), duration: Int(m.video.duration) }
        end if
    else if state = "error"
        m.top.event = { type: "error", message: m.video.errorMsg }
    end if
    if m.controls.visible then paintButtons()
    Ex_OnState(state)
end sub

sub togglePlay()
    if m.video.state = "paused"
        m.video.control = "resume"
        m.top.event = { type: "control", paused: false, position: settledPosition() }
    else if m.video.state = "playing" or m.video.state = "buffering"
        m.video.control = "pause"
        m.top.event = { type: "control", paused: true, position: settledPosition() }
    end if
end sub

function seekStep(direction as integer) as integer
    now = m.seekClock.TotalMilliseconds()
    if direction = m.seekDir and now - m.seekLast < 1200
        m.seekCount = m.seekCount + 1
    else
        m.seekCount = 0
    end if
    m.seekDir = direction
    m.seekLast = now
    stepSize = 10
    if m.seekCount >= 3 then stepSize = 30
    if m.seekCount >= 7 then stepSize = 60
    if m.seekCount >= 12 then stepSize = 120
    return stepSize * direction
end function

function settledPosition() as float
    here = m.video.position
    if m.applied >= 0
        if Abs(here - m.applied) < 4 or m.appliedClock.TotalMilliseconds() > 20000
            m.applied = -1
        else
            return m.applied
        end if
    end if
    return here
end function

sub seekBy(delta as integer)
    base = settledPosition()
    if m.seekTarget >= 0 then base = m.seekTarget
    target = base + delta
    if target < 0 then target = 0
    total = totalTime()
    if total > 0 and target > total - 5 then target = total - 5
    m.seekTarget = target
    updateBar()
    m.seekTimer.control = "stop"
    m.seekTimer.control = "start"
end sub

sub applySeek()
    if m.seekTarget >= 0
        target = m.seekTarget
        Dbg_Log("seek " + Int(target).ToStr() + " from " + Int(m.video.position).ToStr())
        m.video.seek = target
        m.applied = target
        m.appliedClock.Mark()
        m.seekTarget = -1
        Seek_Guard(target)
        m.top.event = { type: "control", paused: m.video.state = "paused", position: target }
    end if
end sub

sub activate(id as string)
    if id = "play"
        togglePlay()
    else if id = "subs"
        openSubs()
    else if id = "audio"
        openAudio()
    else if id = "sources"
        openSources()
    else if id = "next"
        m.top.event = { type: "next" }
    else if id = "episodes"
        m.top.event = { type: "episodes", inPlayer: true }
    else if id = "party"
        m.top.event = { type: "party" }
    else if id = "switch"
        m.top.event = { type: "switch", position: Int(m.video.position) }
    end if
end sub

sub openPanel(kind as string, title as string, items as object, values as object, focus as integer, subtitle = "" as string, leftAction = "close" as string, panelY = -1 as integer, compact = false as boolean)
    m.panelKind = kind
    m.panelValues = values
    if focus < 0 then focus = 0
    width = 1040
    if kind = "sources" then width = 1400
    if kind = "subSyncCue" then width = 1280
    cfg = { title: title, subtitle: subtitle, items: items, focus: focus, style: "cards", width: width, leftAction: leftAction, compact: compact, previewBottom: compact }
    if panelY >= 0 then cfg.y = panelY
    m.panel.config = cfg
    m.panel.visible = true
    m.hideTimer.control = "stop"
    m.controls.visible = false
    m.panel.setFocus(true)
end sub

sub closePanel()
    Ex_SetSubPreview(false)
    m.panel.visible = false
    m.panel.setFocus(false)
    m.top.setFocus(true)
    showControls("buttons")
end sub

sub onPanelClosed()
    if m.panel.visible then closePanel()
end sub

sub onPanelChosen()
    choiceStr = Str_Of(m.panel.chosen)
    if choiceStr = "__back__"
        if m.panelKind = "subsLang"
            openSubs(m.subGroupLang, -1)
        else if m.panelKind = "subStyle"
            Ex_SetSubPreview(false)
            openSubs("", 2)
        else if m.panelKind = "subSyncCue"
            m.panel.visible = false
            m.panel.setFocus(false)
            m.top.setFocus(true)
            Ex_SubSyncOpen()
        else
            closePanel()
        end if
        return
    end if
    choosePanel(ToInt(choiceStr, -1))
end sub

function audioLabel(t as object, number as integer) as string
    lang = Str_Of(t.Language)
    label = ""
    if lang <> "" then label = Lang_Name(lang)
    if label = "" or label = L("Desconocido") then label = L("Pista ") + number.ToStr()
    details = []
    for each part in [Str_Of(t.Name), Str_Of(t.Format), Str_Of(t.Description)]
        clean = part.Trim()
        if clean <> "" and LCase(clean) <> LCase(lang) and LCase(clean) <> LCase(label)
            dup = false
            for each d in details
                if LCase(d) = LCase(clean) then dup = true
            end for
            if not dup then details.Push(clean)
        end if
    end for
    if details.Count() > 0 then label = label + " (" + details.Join(", ") + ")"
    return label
end function

sub openSubs(focusLang = "" as string, fallbackFocus = -1 as integer)
    activeUrl = currentActiveSubUrl()
    collected = Player_CollectSubs(m.video.availableSubtitleTracks, m.top.extraSubs, m.top.info, activeUrl)
    groups = Player_GroupSubs(collected, m.top.info, activeUrl, currentAudioLang())
    m.subGroupsCache = groups
    items = []
    values = []
    offLabel = L("Desactivados")
    if groups.Count() = 0 then offLabel = L("Desactivados (no hay subtítulos)")
    items.Push({ id: "0", label: offLabel, checked: activeUrl = "" })
    values.Push("off:")
    items.Push({ id: "1", label: L("Sincronización de subtítulos"), badge: Ex_DelayBadge(), chevron: true })
    values.Push("timing:")
    items.Push({ id: "2", label: L("Estilo de subtítulos"), chevron: true })
    values.Push("style:")
    focus = 0
    for each grp in groups
        if grp.active and focusLang = "" then focus = items.Count()
        if focusLang <> "" and grp.langKey = focusLang then focus = items.Count()
        items.Push({
            id: values.Count().ToStr()
            label: grp.langLabel
            badge: grp.tracks.Count().ToStr()
            checked: grp.active
            chevron: true
        })
        values.Push("lang:" + grp.langKey)
    end for
    if fallbackFocus >= 0 and fallbackFocus < items.Count() then focus = fallbackFocus
    subText = ""
    if groups.Count() > 0 then subText = L("Elige un idioma para ver sus pistas")
    openPanel("subs", L("Subtítulos"), items, values, focus, subText, "close")
end sub

sub openSubStyle(focusIdx = 0 as integer)
    Ex_SetSubPreview(true)
    st = m.subStyleLocal
    if type(st) <> "roAssociativeArray" then st = {}
    sizeNames = { small: L("Pequeño"), normal: "Normal", large: L("Grande"), xlarge: L("Muy grande") }
    colorNames = { white: L("Blanco"), yellow: L("Amarillo"), cyan: L("Cian"), green: L("Verde"), gray: L("Gris") }
    bgNames = { none: L("Sin fondo"), soft: L("Semitransparente"), solid: L("Negro") }
    edgeNames = { shadow: L("Sombra"), none: L("Ninguno") }
    sz = Str_Of(st.size)
    if sz = "" then sz = "normal"
    cl = Str_Of(st.color)
    if cl = "" then cl = "white"
    bg = Str_Of(st.bg)
    if bg = "" then bg = "none"
    ed = Str_Of(st.edge)
    if ed = "" then ed = "shadow"
    bd = Bool_Of(st.bold, false)
    off = ToInt(st.offset, 0)
    boldBadge = L("Desactivado")
    if bd then boldBadge = L("Activado")
    items = [
        { id: "0", label: L("Tamaño"), badge: Str_Of(sizeNames[sz]) }
        { id: "1", label: L("Color del texto"), badge: Str_Of(colorNames[cl]) }
        { id: "2", label: L("Fondo"), badge: Str_Of(bgNames[bg]) }
        { id: "3", label: L("Borde"), badge: Str_Of(edgeNames[ed]) }
        { id: "4", label: L("Negritas"), badge: boldBadge }
        { id: "5", label: L("Altura"), badge: off.ToStr() }
    ]
    values = ["subSize", "subColor", "subBg", "subEdge", "subBold", "subOffset"]
    openPanel("subStyle", L("Estilo de subtítulos"), items, values, focusIdx, L("Pulsa OK para cambiar · Atrás para volver"), "back", 32, true)
end sub

sub openSyncLinePicker(capturedMs as integer)
    win = Ex_SyncLineWindow(m.cues, capturedMs, ToInt(m.subDelayMs, 0))
    if win.entries.Count() = 0
        Ex_SubSyncOpen()
        return
    end if
    items = []
    values = []
    for each entry in win.entries
        items.Push({ id: values.Count().ToStr(), label: entry.label })
        values.Push("cue:" + entry.cueIdx.ToStr())
    end for
    secLabel = Fmt_Time(Int(capturedMs / 1000))
    subText = L("Capturado en {t}  ·  Elige la línea que acabas de escuchar").Replace("{t}", secLabel)
    openPanel("subSyncCue", L("Sincronizar línea"), items, values, win.focus, subText, "back")
end sub

function cycleStyleVal(list as object, cur as dynamic) as dynamic
    idx = -1
    for i = 0 to list.Count() - 1
        if list[i] = cur then idx = i
    end for
    return list[(idx + 1) mod list.Count()]
end function

sub openSubsLang(langKey as string, fallbackFocus = -1 as integer)
    m.subGroupLang = langKey
    activeUrl = currentActiveSubUrl()
    groups = m.subGroupsCache
    if groups = invalid
        collected = Player_CollectSubs(m.video.availableSubtitleTracks, m.top.extraSubs, m.top.info, activeUrl)
        groups = Player_GroupSubs(collected, m.top.info, activeUrl, currentAudioLang())
        m.subGroupsCache = groups
    end if
    grp = invalid
    for each g in groups
        if g.langKey = langKey
            grp = g
            exit for
        end if
    end for
    if grp = invalid
        openSubs("", -1)
        return
    end if
    items = []
    values = []
    focus = 0
    for i = 0 to grp.tracks.Count() - 1
        t = grp.tracks[i]
        title = Str_Of(t.provider)
        if title = "" then title = L("Complemento")
        rel = Str_Of(t.release)
        if rel <> "" and LCase(rel) <> LCase(title) then title = title + "  ·  " + rel
        tags = []
        if t.sourceType = "internal"
            tags.Push(L("Integrado"))
        else if t.sourceType = "server"
            tags.Push(L("Servidor"))
        else if t.sourceType = "stream"
            tags.Push(L("Fuente"))
        end if
        if Bool_Of(t.forced, false) then tags.Push(L("Forzados"))
        if Bool_Of(t.sdh, false) then tags.Push("SDH")
        if Str_Of(t.format) <> "" then tags.Push(Str_Of(t.format))
        isActive = activeUrl <> "" and (t.url = activeUrl or Str_Of(t.trackName) = activeUrl)
        if isActive then focus = items.Count()
        items.Push({
            id: values.Count().ToStr()
            label: title
            badge: tags.Join(" · ")
            checked: isActive
        })
        if t.sourceType = "internal"
            values.Push("track:" + t.url)
        else
            values.Push("reload:" + t.url)
        end if
    end for
    if fallbackFocus >= 0 and fallbackFocus < items.Count() then focus = fallbackFocus
    openPanel("subsLang", L("Subtítulos") + "  ·  " + grp.langLabel, items, values, focus, L("Atrás o Izquierda para cambiar idioma"), "back")
end sub

sub openAudio()
    items = []
    values = []
    focus = 0
    ts = m.top.tsAudio
    if type(ts) = "roAssociativeArray" and type(ts.tracks) = "roArray" and ts.tracks.Count() > 1
        for i = 0 to ts.tracks.Count() - 1
            t = ts.tracks[i]
            label = Lang_Name(Str_Of(t.lang))
            if Str_Of(t.lang) = "" then label = L("Audio") + " " + (i + 1).ToStr()
            label = label + "  ·  " + Str_Of(t.codec)
            if not Bool_Of(t.ok, true) then label = label + "  ·  " + L("abre el enlace original")
            active = i = ToInt(ts.selected, -1)
            items.Push({ id: values.Count().ToStr(), label: label, checked: active })
            values.Push("ts:" + i.ToStr())
            if active then focus = items.Count() - 1
        end for
        openPanel("audio", L("Pistas de audio"), items, values, focus)
        return
    end if
    tracks = m.video.availableAudioTracks
    if type(tracks) = "roArray"
        number = 0
        for each t in tracks
            number = number + 1
            active = Str_Of(t.Track) = m.video.currentAudioTrack
            items.Push({ id: values.Count().ToStr(), label: audioLabel(t, number), checked: active })
            values.Push(Str_Of(t.Track))
            if active then focus = items.Count() - 1
        end for
    end if
    if items.Count() = 0
        note = ""
        if type(ts) = "roAssociativeArray" then note = Str_Of(ts.note)
        if note = "" then note = L("Esta fuente tiene un solo audio")
        items.Push({ id: "0", label: note, checked: true })
        values.Push("")
    end if
    if m.top.altAudio and items.Count() <= 1
        items.Push({ id: values.Count().ToStr(), label: L("Cargar todos los audios del enlace original") })
        values.Push("alt:")
    end if
    openPanel("audio", L("Pistas de audio"), items, values, focus)
end sub

sub onSrcPanel()
    r = m.srcPanel.result
    m.srcPanel.visible = false
    m.srcPanel.setFocus(false)
    m.top.setFocus(true)
    if type(r) = "roAssociativeArray" and r.action = "pick" and ToInt(r.index, -1) <> m.top.sourceIndex
        m.top.event = { type: "source", index: ToInt(r.index, -1), position: Int(settledPosition()) }
        return
    end if
    showControls("buttons")
end sub

sub openSources()
    cards = m.top.sourceCards
    if type(cards) = "roArray" and cards.Count() > 0
        if m.srcPanel = invalid
            m.srcPanel = m.top.createChild("SourcesPanel")
            m.srcPanel.observeField("result", "onSrcPanel")
        end if
        info = Str_Of(m.top.info.title)
        if m.meta.text <> "" then info = m.meta.text
        m.controls.visible = false
        m.srcPanel.data = { streams: cards, current: m.top.sourceIndex, info: info }
        m.srcPanel.visible = true
        m.srcPanel.setFocus(true)
        return
    end if
    labels = m.top.sources
    if labels = invalid then labels = []
    items = []
    values = []
    for i = 0 to labels.Count() - 1
        items.Push({ id: i.ToStr(), label: labels[i], checked: i = m.top.sourceIndex })
        values.Push(i.ToStr())
    end for
    if items.Count() = 0
        items.Push({ id: "0", label: L("Buscando enlaces..."), checked: false })
        values.Push("")
    end if
    openPanel("sources", L("Fuentes"), items, values, m.top.sourceIndex)
end sub

sub choosePanel(index as integer)
    if not m.panel.visible then return
    if index < 0 or index >= m.panelValues.Count() then return
    value = m.panelValues[index]
    if m.panelKind = "subs"
        if value = "off:"
            m.userSubChosen = true
            Ex_SubSelect("")
            closePanel()
            return
        else if value = "timing:"
            m.panel.visible = false
            m.panel.setFocus(false)
            m.top.setFocus(true)
            Ex_SubSyncOpen()
            return
        else if value = "style:"
            openSubStyle(0)
            return
        else if Left(value, 5) = "lang:"
            openSubsLang(Mid(value, 6), -1)
            return
        end if
    else if m.panelKind = "subStyle"
        st = m.subStyleLocal
        if type(st) <> "roAssociativeArray" then st = {}
        if value = "subSize"
            Ex_SetSubStyleProp("subSize", cycleStyleVal(["small", "normal", "large", "xlarge"], Str_Of(st.size)))
        else if value = "subColor"
            Ex_SetSubStyleProp("subColor", cycleStyleVal(["white", "yellow", "cyan", "green", "gray"], Str_Of(st.color)))
        else if value = "subBg"
            Ex_SetSubStyleProp("subBg", cycleStyleVal(["none", "soft", "solid"], Str_Of(st.bg)))
        else if value = "subEdge"
            Ex_SetSubStyleProp("subEdge", cycleStyleVal(["shadow", "none"], Str_Of(st.edge)))
        else if value = "subBold"
            Ex_SetSubStyleProp("subBold", not Bool_Of(st.bold, false))
        else if value = "subOffset"
            Ex_SetSubStyleProp("subOffset", cycleStyleVal([0, 1, 2, 3, 4, 5, 6, 8, 10], ToInt(st.offset, 0)))
        end if
        openSubStyle(index)
        return
    else if m.panelKind = "subSyncCue"
        if Left(value, 4) = "cue:"
            cueIdx = ToInt(Mid(value, 5), -1)
            if cueIdx >= 0 and cueIdx < m.cues.Count()
                newDelay = Ex_CalcSyncDelay(ToInt(m.syncCapturedMs, 0), m.cues[cueIdx].s)
                Ex_SetSubDelay(newDelay, true)
                m.panel.visible = false
                m.panel.setFocus(false)
                m.top.setFocus(true)
                Ex_SubSyncOpen()
                return
            end if
        end if
    else if m.panelKind = "subsLang"
        m.userSubChosen = true
        if Left(value, 6) = "track:"
            Ex_SubSelect(Mid(value, 7))
        else if Left(value, 7) = "reload:" and Ex_UseCustom(Mid(value, 8))
            Ex_SubSelect(Mid(value, 8))
        else if Left(value, 7) = "reload:"
            m.panel.visible = false
            m.panel.setFocus(false)
            m.top.setFocus(true)
            m.top.event = { type: "subsReload", url: Mid(value, 8), position: Int(settledPosition()) }
            return
        end if
    else if m.panelKind = "audio"
        if Left(value, 3) = "ts:"
            if ToInt(Mid(value, 4), -1) <> ToInt(m.top.tsAudio.selected, -1)
                m.panel.visible = false
                m.panel.setFocus(false)
                m.top.setFocus(true)
                m.top.event = { type: "tsAudio", index: ToInt(Mid(value, 4), -1), position: Int(settledPosition()) }
                return
            end if
        else if value = "alt:"
            m.top.event = { type: "altAudio", position: Int(settledPosition()) }
        else if value <> ""
            m.userAudio = value
            m.audioFixes = 0
            m.audioApplied = true
            m.video.audioTrack = value
        end if
    else if m.panelKind = "sources"
        if value <> "" and index <> m.top.sourceIndex
            m.panel.visible = false
            m.panel.setFocus(false)
            m.top.setFocus(true)
            m.top.event = { type: "source", index: index, position: Int(settledPosition()) }
            return
        end if
    end if
    closePanel()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.panel.visible then return true
    if m.epPanel.visible then return EpP_Key(key)
    if Ex_OverlayKey(key) then return true
    if m.pauseScreen.visible
        m.pauseScreen.visible = false
        if key = "OK" or key = "play"
            togglePlay()
            hideControls()
        else if key = "back"
            m.top.event = { type: "close" }
        else
            showControls("buttons")
        end if
        return true
    end if
    if key = "play"
        togglePlay()
        showControls("buttons")
        return true
    else if key = "fastforward"
        seekBy(seekStep(1) * 3)
        showControls("bar")
        return true
    else if key = "rewind"
        seekBy(seekStep(-1) * 3)
        showControls("bar")
        return true
    end if
    if not m.controls.visible
        if key = "back"
            m.top.event = { type: "close" }
        else if key = "left"
            seekBy(seekStep(-1))
            showControls("bar")
        else if key = "right"
            seekBy(seekStep(1))
            showControls("bar")
        else if key = "OK"
            togglePlay()
            m.index = 0
            showControls("buttons")
        else
            m.index = 0
            showControls("buttons")
        end if
        return true
    end if
    restartHide()
    if key = "back"
        hideControls()
    else if m.zone = "bar"
        if key = "left"
            seekBy(seekStep(-1))
        else if key = "right"
            seekBy(seekStep(1))
        else if key = "down"
            m.zone = "buttons"
            paintButtons()
        else if key = "OK"
            togglePlay()
        end if
    else
        if key = "left"
            if m.index > 0 then m.index = m.index - 1
            paintButtons()
        else if key = "right"
            if m.index < m.buttons.Count() - 1 then m.index = m.index + 1
            paintButtons()
        else if key = "up"
            m.zone = "bar"
            paintButtons()
        else if key = "OK"
            activate(m.buttons[m.index].id)
            paintButtons()
        end if
    end if
    return true
end function

sub onPartyText()
    m.partyLabel.text = m.top.partyText
    m.partyLabel.visible = m.top.partyText <> ""
end sub

sub onState()
    try
        onState_Run()
    catch e
        Ex_Crash(e)
    end try
end sub

sub onPosition()
    try
        onPosition_Run()
    catch e
        Ex_Crash(e)
    end try
end sub
