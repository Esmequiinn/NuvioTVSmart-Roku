sub init()
    m.video = m.top.findNode("video")
    m.top.video = m.video
    m.buffering = m.top.findNode("buffering")
    m.pauseScreen = m.top.findNode("pauseScreen")
    m.pauseBg = m.top.findNode("pauseBg")
    m.pauseLogo = m.top.findNode("pauseLogo")
    m.pauseTitle = m.top.findNode("pauseTitle")
    m.pauseMeta = m.top.findNode("pauseMeta")
    m.pauseDesc = m.top.findNode("pauseDesc")
    m.controls = m.top.findNode("controls")
    m.clock = m.top.findNode("clock")
    m.ends = m.top.findNode("ends")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.track = m.top.findNode("track")
    m.fill = m.top.findNode("fill")
    m.knob = m.top.findNode("knob")
    m.time = m.top.findNode("time")
    m.buttonsGroup = m.top.findNode("buttons")
    m.hint = m.top.findNode("hint")
    m.panel = m.top.findNode("panel")
    m.panelTitle = m.top.findNode("panelTitle")
    m.panelList = m.top.findNode("panelList")
    m.panelList.font.size = 30
    m.panelList.focusedFont.size = 30
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
    m.video.observeField("availableSubtitleTracks", "applySubtitlePreference")
    m.audioApplied = false
    m.subsApplied = false
    m.video.observeField("focusedChild", "onVideoFocus")
    m.video.observeField("position", "onPosition")
    m.panelList.observeField("itemSelected", "onPanelSelect")
    m.top.observeField("focusedChild", "onTopFocus")
    m.logo.observeField("loadStatus", "onLogoStatus")
    m.pauseLogo.observeField("loadStatus", "onPauseLogoStatus")
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
        m.clockTimer.control = "start"
        m.top.setFocus(true)
    else
        m.hideTimer.control = "stop"
        m.pauseTimer.control = "stop"
        m.clockTimer.control = "stop"
        m.video.control = "stop"
    end if
end sub

sub onVideoFocus()
    if m.top.active and m.video.hasFocus() and not m.panel.visible then m.top.setFocus(true)
end sub

sub onTopFocus()
    if m.panel.visible and m.top.hasFocus() then m.panelList.setFocus(true)
end sub

sub onInfo()
    info = m.top.info
    if info = invalid then return
    m.audioApplied = false
    m.subsApplied = false
    m.fallbackDur = 0
    if not Bool_Of(info.isSeries, false) then m.fallbackDur = runtimeOf(Str_Of(info.metaLine))
    m.clock.visible = Bool_Of(info.clock, true)
    m.ends.visible = Bool_Of(info.clock, true)
    m.title.text = Str_Of(info.title)
    m.pauseTitle.text = Str_Of(info.title)
    m.meta.text = Str_Of(info.metaLine)
    m.pauseMeta.text = Str_Of(info.metaLine)
    m.pauseDesc.text = Str_Of(info.description)
    m.pauseBg.uri = Str_Of(info.background)
    logo = Str_Of(info.logo)
    m.logo.visible = false
    m.pauseLogo.visible = false
    m.title.visible = true
    m.pauseTitle.visible = true
    m.logo.uri = logo
    m.pauseLogo.uri = logo
    buildButtons(Bool_Of(info.isSeries, false))
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
    ]
    if isSeries
        defs.Push({ id: "next", icon: "pkg:/images/ic_next.png", hint: L("Siguiente episodio") })
        defs.Push({ id: "episodes", icon: "pkg:/images/ic_episodes.png", hint: L("Episodios") })
    end if
    m.buttons = []
    x = 0
    for each d in defs
        g = m.buttonsGroup.createChild("Group")
        g.translation = [x, 0]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/circle.png"
        bg.width = 72
        bg.height = 72
        icon = g.createChild("Poster")
        icon.uri = d.icon
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
                b.icon.uri = "pkg:/images/ic_pause.png"
                b.hint = L("Pausa")
            else
                b.icon.uri = "pkg:/images/ic_play.png"
                b.hint = L("Continuar")
            end if
        end if
        if m.zone = "buttons" and i = m.index
            b.bg.blendColor = m.top.accent
            m.hint.text = b.hint
        else
            b.bg.blendColor = "0xFFFFFF2E"
        end if
    end for
    m.knob.visible = m.zone = "bar"
    if m.zone = "bar" then m.hint.text = L("Izquierda o derecha para adelantar o regresar")
    m.fill.color = m.top.accent
end sub

sub showControls(zone as string)
    m.zone = zone
    m.pauseScreen.visible = false
    m.controls.visible = true
    updateClock()
    updateBar()
    paintButtons()
    restartHide()
end sub

sub hideControls()
    m.controls.visible = false
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
                if Lang_Matches(Str_Of(t.Language), wanted)
                    if Str_Of(t.Track) <> m.video.currentAudioTrack then m.video.audioTrack = Str_Of(t.Track)
                    return
                end if
            end for
        end if
    end for
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

sub selectSubtitle(track as string)
    m.video.subtitleTrack = track
    m.video.globalCaptionMode = "On"
end sub

sub applySubtitlePreference()
    if m.subsApplied then return
    info = m.top.info
    if info = invalid then return
    tracks = m.video.availableSubtitleTracks
    if type(tracks) <> "roArray" or tracks.Count() = 0 then return
    m.subsApplied = true
    first = LCase(Str_Of(info.subLang))
    second = LCase(Str_Of(info.subLang2))
    if Bool_Of(info.forcedSubs, false)
        audio = currentAudioLang()
        if audio <> ""
            for each t in tracks
                if isForcedTrack(t) and Lang_Matches(Str_Of(t.Language), audio)
                    selectSubtitle(Str_Of(t.TrackName))
                    return
                end if
            end for
        end if
    end if
    if first = "" or first = "off" or first = "none"
        m.video.globalCaptionMode = "Off"
        return
    end if
    original = Str_Of(info.originalLang)
    for each code in [first, second]
        wanted = Lang_Resolve(code, original)
        if wanted <> ""
            fallback = ""
            for each t in tracks
                if Lang_Matches(Str_Of(t.Language), wanted)
                    if not isForcedTrack(t)
                        selectSubtitle(Str_Of(t.TrackName))
                        return
                    end if
                    if fallback = "" then fallback = Str_Of(t.TrackName)
                end if
            end for
            if fallback <> ""
                selectSubtitle(fallback)
                return
            end if
        end if
    end for
    m.video.globalCaptionMode = "Off"
end sub

sub onPauseTimer()
    info = m.top.info
    if info <> invalid and not Bool_Of(info.pauseOverlay, true) then return
    if m.video.state = "paused" and not m.panel.visible
        m.controls.visible = false
        m.pauseScreen.visible = true
    end if
end sub

sub updateClock()
    now = CreateObject("roDateTime")
    now.ToLocalTime()
    m.clock.text = Fmt_Clock(now)
    remaining = Int(m.video.duration - m.video.position)
    if m.video.duration > 0 and remaining > 0
        now.FromSeconds(now.AsSeconds() + remaining)
        m.ends.text = L("Termina a las ") + Fmt_Clock(now)
    else
        m.ends.text = ""
    end if
end sub

function totalTime() as float
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
    current = m.video.position
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

sub onPosition()
    if m.controls.visible then updateBar()
end sub

sub onState()
    state = m.video.state
    m.buffering.visible = state = "buffering"
    if state = "playing"
        m.pauseScreen.visible = false
        m.pauseTimer.control = "stop"
        restartHide()
    else if state = "paused"
        restartPauseTimer()
    else if state = "finished"
        m.top.event = { type: "finished" }
    else if state = "error"
        m.top.event = { type: "error", message: m.video.errorMsg }
    end if
    if m.controls.visible then paintButtons()
end sub

sub togglePlay()
    if m.video.state = "paused"
        m.video.control = "resume"
    else if m.video.state = "playing" or m.video.state = "buffering"
        m.video.control = "pause"
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

sub seekBy(delta as integer)
    base = m.video.position
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
        m.video.seek = m.seekTarget
        m.seekTarget = -1
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
        m.top.event = { type: "episodes" }
    end if
end sub

sub openPanel(kind as string, title as string, labels as object, values as object, focus as integer)
    m.panelKind = kind
    m.panelValues = values
    m.panelTitle.text = title
    content = CreateObject("roSGNode", "ContentNode")
    for each text in labels
        child = content.createChild("ContentNode")
        child.title = text
    end for
    m.panelList.content = content
    if focus < 0 then focus = 0
    m.panelList.jumpToItem = focus
    m.panel.visible = true
    m.hideTimer.control = "stop"
    m.panelList.setFocus(true)
end sub

sub closePanel()
    m.panel.visible = false
    m.top.setFocus(true)
    showControls("buttons")
end sub

sub openSubs()
    labels = [L("Desactivados")]
    values = [""]
    focus = 0
    tracks = m.video.availableSubtitleTracks
    if type(tracks) = "roArray"
        for each t in tracks
            name = Str_Of(t.Description)
            if name = "" then name = Lang_Name(Str_Of(t.Language))
            labels.Push(name)
            values.Push(Str_Of(t.TrackName))
            if m.video.globalCaptionMode = "On" and Str_Of(t.TrackName) = m.video.subtitleTrack then focus = labels.Count() - 1
        end for
    end if
    if labels.Count() = 1 then labels[0] = L("Desactivados (no hay subtítulos)")
    openPanel("subs", L("Subtítulos"), labels, values, focus)
end sub

sub openAudio()
    labels = []
    values = []
    focus = 0
    tracks = m.video.availableAudioTracks
    if type(tracks) = "roArray"
        for each t in tracks
            name = Str_Of(t.Name)
            lang = Lang_Name(Str_Of(t.Language))
            label = lang
            if name <> "" then label = lang + "  ·  " + name
            labels.Push(label)
            values.Push(Str_Of(t.Track))
            if Str_Of(t.Track) = m.video.currentAudioTrack then focus = labels.Count() - 1
        end for
    end if
    if labels.Count() = 0
        labels.Push(L("Esta fuente tiene un solo audio"))
        values.Push("")
    end if
    openPanel("audio", "Audio", labels, values, focus)
end sub

sub openSources()
    labels = m.top.sources
    if labels = invalid then labels = []
    values = []
    for i = 0 to labels.Count() - 1
        values.Push(i.ToStr())
    end for
    openPanel("sources", L("Fuentes"), labels, values, m.top.sourceIndex)
end sub

sub onPanelSelect()
    choosePanel(m.panelList.itemSelected)
end sub

sub choosePanel(index as integer)
    if not m.panel.visible then return
    if index < 0 or index >= m.panelValues.Count() then return
    value = m.panelValues[index]
    if m.panelKind = "subs"
        if value = ""
            m.video.globalCaptionMode = "Off"
        else
            m.video.subtitleTrack = value
            m.video.globalCaptionMode = "On"
        end if
    else if m.panelKind = "audio"
        if value <> "" then m.video.audioTrack = value
    else if m.panelKind = "sources"
        if index <> m.top.sourceIndex
            m.panel.visible = false
            m.top.setFocus(true)
            m.top.event = { type: "source", index: index, position: Int(m.video.position) }
            return
        end if
    end if
    closePanel()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.panel.visible
        if key = "back" or key = "left"
            closePanel()
            return true
        end if
        count = m.panelValues.Count()
        current = m.panelList.itemFocused
        if current < 0 then current = 0
        m.panelList.setFocus(true)
        if key = "up" and current > 0
            m.panelList.jumpToItem = current - 1
        else if key = "down" and current < count - 1
            m.panelList.jumpToItem = current + 1
        else if key = "OK"
            choosePanel(current)
        end if
        return true
    end if
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
