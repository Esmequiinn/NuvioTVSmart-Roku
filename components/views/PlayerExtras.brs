sub Ex_Init()
    m.subLayer = m.top.findNode("subLayer")
    m.subBg = m.top.findNode("subBg")
    m.subText = m.top.findNode("subText")
    m.subShadow = m.top.findNode("subShadow")
    m.parentalBox = m.top.findNode("parentalBox")
    m.parentalBar = m.top.findNode("parentalBar")
    m.parentalRows = m.top.findNode("parentalRows")
    m.skipBtn = m.top.findNode("skipBtn")
    m.skipBg = m.top.findNode("skipBg")
    m.skipIcon = m.top.findNode("skipIcon")
    m.skipLabel = m.top.findNode("skipLabel")
    m.nextCard = m.top.findNode("nextCard")
    m.nextBg = m.top.findNode("nextBg")
    Mask_Apply(m.top.findNode("nextMask"), 256, 144)
    nextCaps = m.top.findNode("nextCard").createChild("Group")
    nextCaps.translation = [24, 24]
    Mask_Caps(nextCaps, 256, 144, 14, "0x161616FF")
    m.nextThumb = m.top.findNode("nextThumb")
    m.nextKicker = m.top.findNode("nextKicker")
    m.nextCode = m.top.findNode("nextCode")
    m.nextTitle = m.top.findNode("nextTitle")
    m.nextPlayBg = m.top.findNode("nextPlayBg")
    m.nextPlayIcon = m.top.findNode("nextPlayIcon")
    m.nextPlayLabel = m.top.findNode("nextPlayLabel")
    m.nextCount = m.top.findNode("nextCount")
    m.postBox = m.top.findNode("postBox")
    m.postHeading = m.top.findNode("postHeading")
    m.postRow = m.top.findNode("postRow")
    m.postHint = m.top.findNode("postHint")
    m.stillBox = m.top.findNode("stillBox")
    m.stillBg = m.top.findNode("stillBg")
    m.stillLogo = m.top.findNode("stillLogo")
    m.stillShow = m.top.findNode("stillShow")
    m.stillHeading = m.top.findNode("stillHeading")
    m.stillSub = m.top.findNode("stillSub")
    m.stillButtons = m.top.findNode("stillButtons")
    m.stillCount = m.top.findNode("stillCount")
    m.statsBox = m.top.findNode("statsBox")
    m.statsBg = m.top.findNode("statsBg")
    m.statsText = m.top.findNode("statsText")
    m.skipPill = Ex_PillMake(m.skipBg, 64)
    m.nextPill = Ex_PillMake(m.nextPlayBg, 64)
    Ex_PillSet(m.nextPill, 220, "0xFFFFFFFF")
    m.stillLogo.observeField("loadStatus", "Ex_OnStillLogo")
    m.skipLabel.font.size = 28
    m.nextPlayLabel.font.size = 28
    m.nextCode.font.size = 30
    m.nextTitle.font.size = 24
    m.nextKicker.font.size = 22
    m.nextCount.font.size = 22
    m.stillHeading.font.size = 64
    m.stillShow.font.size = 48
    m.postHeading.font.size = 40
    m.statsText.font.size = 22
    m.exTimer = createTimer(1.0)
    m.exTimer.repeat = true
    m.exTimer.observeField("fire", "Ex_OnSecond")
    m.parentalTimer = createTimer(6.0)
    m.parentalTimer.observeField("fire", "Ex_HideParental")
    m.video.notificationInterval = 0.25
    Ex_Reset()
end sub

sub Ex_Reset()
    m.segments = []
    m.skipSeg = invalid
    m.skipDone = {}
    m.skipShownAt = invalid
    m.skipFocus = false
    m.nextShown = false
    m.nextDismissed = false
    m.nextLeft = -1
    m.prefetchAsked = false
    m.postShown = false
    m.postDismissed = false
    m.postIndex = 0
    m.postItems = []
    m.stillOn = false
    m.stillIndex = 0
    m.stillLeft = 0
    m.parentalShown = false
    m.cues = []
    m.cueIndex = 0
    m.subUrl = ""
    m.subTask = invalid
    m.top.postActive = false
    if m.skipBtn <> invalid
        m.skipBtn.visible = false
        m.nextCard.visible = false
        m.postBox.visible = false
        m.stillBox.visible = false
        m.parentalBox.visible = false
        m.subLayer.visible = false
    end if
end sub

function Ex_Info(name as string, fallback as dynamic) as dynamic
    info = m.top.info
    if info = invalid or info[name] = invalid then return fallback
    return info[name]
end function

sub Ex_OnInfo()
    Ex_Reset()
    m.statsBox.visible = Bool_Of(Ex_Info("stats", false), false)
    m.exTimer.control = "start"
    Ex_StyleSubs()
end sub

sub Ex_OnSegments_Run()
    list = m.top.segments
    if type(list) <> "roArray" then list = []
    m.segments = list
end sub

sub Ex_OnParental_Run()
    list = m.top.parental
    if type(list) <> "roArray" or list.Count() = 0 then return
    m.parentalRows.removeChildrenIndex(m.parentalRows.getChildCount(), 0)
    names = { nudity: L("Desnudez"), violence: L("Violencia"), profanity: L("Lenguaje soez"), alcohol: L("Alcohol/drogas"), frightening: L("Terror") }
    levels = { severe: L("Severo"), moderate: L("Moderado"), mild: L("Leve") }
    y = 0
    for each item in list
        row = m.parentalRows.createChild("Label")
        row.font = "font:SmallSystemFont"
        row.font.size = 28
        row.color = "0xFFFFFFFF"
        level = Str_Of(levels[Str_Of(item.level)])
        if level = "" then level = Str_Of(item.level)
        row.text = Str_Of(names[Str_Of(item.kind)]) + "  ·  " + level
        row.translation = [0, y]
        y = y + 44
    end for
    m.parentalBar.height = y - 8
    m.parentalBar.color = m.top.accent
    m.parentalPending = true
    if m.started and m.video.state = "playing" then Ex_ShowParental()
end sub

sub Ex_ShowParental()
    if not Bool_Of(m.parentalPending, false) or m.parentalShown then return
    m.parentalPending = false
    m.parentalShown = true
    m.parentalBox.visible = true
    m.parentalTimer.control = "start"
end sub

sub Ex_HideParental()
    m.parentalBox.visible = false
end sub

sub Ex_OnState(state as string)
    if state = "playing" then Ex_ShowParental()
    if state = "finished" and m.postShown then m.top.postActive = true
end sub

sub Ex_OnSecond_Run()
    if not m.top.active then return
    if m.statsBox.visible then Ex_Stats()
    if m.nextShown and m.nextLeft > 0 and not m.stillOn
        m.nextLeft = m.nextLeft - 1
        Ex_PaintNext()
        if m.nextLeft = 0
            Ex_HideNext()
            m.top.event = { type: "nextAuto" }
        end if
    end if
    if m.stillOn and m.stillLeft > 0
        m.stillLeft = m.stillLeft - 1
        Ex_PaintStill()
        if m.stillLeft = 0 then Ex_StillChoose(false)
    end if
    if m.skipBtn.visible and m.skipShownAt <> invalid and not m.controls.visible
        if m.skipShownAt.TotalSeconds() >= 10 then m.skipBtn.visible = false
    end if
end sub

sub Ex_Tick(at0 as float)
    if not m.started then return
    dur = m.video.duration
    Ex_Subs(at0)
    Ex_Skip(at0)
    if dur > 0
        Ex_Next(at0, dur)
        Ex_Post(at0, dur)
    end if
end sub

function Ex_SegLabel(kind as string) as string
    if kind = "intro" then return L("Saltar introducción")
    if kind = "recap" then return L("Saltar resumen")
    if kind = "outro" or kind = "credits" then return L("Saltar créditos")
    return L("Saltar")
end function

sub Ex_Skip(at0 as float)
    current = invalid
    for each seg in m.segments
        if seg.type <> "postcredits" and at0 >= seg.start and at0 < seg.finish - 1 then current = seg
    end for
    if current = invalid
        m.skipSeg = invalid
        m.skipBtn.visible = false
        return
    end if
    key = current.type + Str(current.start)
    auto = Ex_Info("autoSkip", [])
    if type(auto) = "roArray" and not m.skipDone.DoesExist(key)
        for each t in auto
            if t = current.type
                m.skipDone[key] = true
                Ex_DoSkip(current)
                return
            end if
        end for
    end if
    if not Bool_Of(Ex_Info("skip", true), true) then return
    if m.nextCard.visible
        m.skipBtn.visible = false
        return
    end if
    if m.skipSeg = invalid or m.skipSeg.start <> current.start
        m.skipSeg = current
        m.skipLabel.text = Ex_SegLabel(current.type)
        w = Int(m.skipLabel.boundingRect().width) + 96
        m.skipPill.w = w
        Ex_PillSet(m.skipPill, w, m.skipPill.color)
        m.skipBtn.translation = [1800 - w, 900]
        m.skipShownAt = CreateObject("roTimespan")
        m.skipBtn.visible = true
        Ex_PaintSkip()
    end if
end sub

sub Ex_PaintSkip()
    focused = m.skipBtn.visible and not m.controls.visible
    if focused
        Ex_PillSet(m.skipPill, m.skipPill.w, "0xFFFFFFFF")
        m.skipLabel.color = "0x0C0C0FFF"
        m.skipIcon.blendColor = "0x0C0C0FFF"
    else
        Ex_PillSet(m.skipPill, m.skipPill.w, "0x1C1C1CD9")
        m.skipLabel.color = "0xFFFFFFFF"
        m.skipIcon.blendColor = "0xFFFFFFFF"
    end if
    if m.controls.visible then m.skipBtn.translation = [m.skipBtn.translation[0], 620] else m.skipBtn.translation = [m.skipBtn.translation[0], 900]
end sub

sub Ex_DoSkip(seg as object)
    target = seg.finish
    dur = m.video.duration
    if dur > 0 and target > dur - 2 then target = dur - 2
    m.skipBtn.visible = false
    m.skipSeg = invalid
    m.video.seek = target
    m.applied = target
    m.appliedClock.Mark()
end sub

function Ex_NextAt(dur as float) as float
    for each seg in m.segments
        if seg.type = "outro" and seg.start > dur * 0.5 then return seg.start
    end for
    if Ex_Info("nextMode", "pct") = "min"
        mins = 0.0 + Ex_Info("nextMin", 2)
        return dur - mins * 60
    end if
    pct = 0.0 + Ex_Info("nextPct", 99)
    return dur * pct / 100.0
end function

sub Ex_Next(at0 as float, dur as float)
    nxt = m.top.nextInfo
    if nxt = invalid or Str_Of(nxt.code) = "" or m.nextDismissed then return
    at = Ex_NextAt(dur)
    if not m.prefetchAsked and at0 >= at - 60
        m.prefetchAsked = true
        m.top.event = { type: "prefetchNext" }
    end if
    if m.nextShown or at0 < at then return
    m.nextShown = true
    m.nextThumb.uri = Str_Of(nxt.thumb)
    m.nextKicker.text = UCase(L("Siguiente episodio"))
    m.nextCode.text = Str_Of(nxt.code)
    m.nextTitle.text = Str_Of(nxt.title)
    m.nextPlayLabel.text = L("Reproducir")
    m.nextPlayLabel.width = 0
    tw = Int(m.nextPlayLabel.boundingRect().width)
    if tw > 150 then tw = 150
    left0 = 24 + Int((220 - (32 + 10 + tw)) / 2)
    m.nextPlayIcon.translation = [left0, 212]
    m.nextPlayLabel.translation = [left0 + 42, 196]
    m.nextPlayLabel.width = tw + 4
    m.nextLeft = -1
    if Bool_Of(Ex_Info("autoNext", true), true)
        remain = Int(dur - at0)
        if remain > 10 then remain = 10
        if remain < 3 then remain = 3
        m.nextLeft = remain
    end if
    Ex_PaintNext()
    m.nextCard.visible = not m.controls.visible
    if m.nextCard.visible then m.skipBtn.visible = false
end sub

sub Ex_PaintNext()
    m.nextBg.blendColor = "0x161616EB"
    if m.nextLeft > 0
        m.nextCount.text = L("Empieza en ") + m.nextLeft.ToStr() + " s"
    else
        m.nextCount.text = ""
    end if
end sub

sub Ex_HideNext()
    m.nextCard.visible = false
end sub

sub Ex_Post(at0 as float, dur as float)
    if m.postShown or m.postDismissed then return
    if not Bool_Of(Ex_Info("postPlay", true), true) then return
    nxt = m.top.nextInfo
    if nxt <> invalid and Str_Of(nxt.code) <> "" then return
    recs = m.top.recs
    if type(recs) <> "roArray" or recs.Count() = 0 then return
    at = dur * (0.0 + Ex_Info("postPct", 96)) / 100.0
    for each seg in m.segments
        if seg.type = "credits" then at = seg.start
    end for
    if at0 < at then return
    Ex_ShowPost(recs)
end sub

sub Ex_ShowPost(recs as object)
    m.postShown = true
    m.postItems = recs
    m.postIndex = 0
    m.postRow.removeChildrenIndex(m.postRow.getChildCount(), 0)
    m.postHeading.text = L("Te puede gustar")
    m.postHint.text = L("OK para ver los detalles  ·  Atrás para cerrar")
    x = 0
    m.postCards = []
    for each r in recs
        g = m.postRow.createChild("Group")
        g.translation = [x, 0]
        mask = g.createChild("MaskGroup")
        mask.maskUri = "pkg:/images/mask_poster.png"
        Mask_Apply(mask, 200, 300)
        base = mask.createChild("Rectangle")
        base.width = 200
        base.height = 300
        base.color = "0x262626FF"
        pic = mask.createChild("Poster")
        pic.width = 200
        pic.height = 300
        pic.loadWidth = 200
        pic.loadHeight = 300
        pic.loadDisplayMode = "scaleToZoom"
        pic.uri = Str_Of(r.poster)
        Mask_Caps(g, 200, 300, 20, "0x050505FF")
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/iring.9.png"
        ring.width = 200
        ring.height = 300
        ring.blendColor = m.top.accent
        ring.visible = false
        m.postCards.Push(ring)
        x = x + 224
    end for
    m.postBox.visible = true
    Ex_PaintPost()
end sub

sub Ex_PaintPost()
    for i = 0 to m.postCards.Count() - 1
        m.postCards[i].visible = i = m.postIndex
    end for
end sub

function Ex_PostKey(key as string) as boolean
    if not m.postBox.visible then return false
    if key = "left"
        if m.postIndex > 0 then m.postIndex = m.postIndex - 1
        Ex_PaintPost()
    else if key = "right"
        if m.postIndex < m.postItems.Count() - 1 then m.postIndex = m.postIndex + 1
        Ex_PaintPost()
    else if key = "OK"
        r = m.postItems[m.postIndex]
        m.postBox.visible = false
        m.top.postActive = false
        m.top.event = { type: "recPick", id: Str_Of(r.id), kind: Str_Of(r.kind), name: Str_Of(r.name), poster: Str_Of(r.poster), background: Str_Of(r.background) }
    else if key = "back"
        m.postBox.visible = false
        m.postDismissed = true
        m.top.postActive = false
        if m.video.state = "finished" then m.top.event = { type: "close" }
    else
        return false
    end if
    return true
end function

function Ex_OverlayKey(key as string) as boolean
    if m.stillOn then return Ex_StillKey(key)
    if Ex_PostKey(key) then return true
    if m.controls.visible then return false
    if m.skipBtn.visible and key = "OK"
        if m.skipSeg <> invalid then Ex_DoSkip(m.skipSeg)
        return true
    end if
    if m.nextCard.visible
        if key = "OK"
            Ex_HideNext()
            m.top.event = { type: "nextNow" }
            return true
        else if key = "back"
            Ex_HideNext()
            m.nextDismissed = true
            m.nextLeft = -1
            return true
        end if
    end if
    return false
end function

sub Ex_OnControls(visible as boolean)
    if m.nextShown and not m.nextDismissed then m.nextCard.visible = not visible
    if m.skipBtn.visible
        if visible then m.skipShownAt = CreateObject("roTimespan")
        Ex_PaintSkip()
    end if
end sub

sub Ex_OnStill_Run()
    if not m.top.stillWatching then return
    info = m.top.info
    m.stillOn = true
    m.stillIndex = 0
    m.stillLeft = 30
    Ex_HideNext()
    m.skipBtn.visible = false
    m.controls.visible = false
    m.pauseScreen.visible = false
    if m.video.state = "playing" then m.video.control = "pause"
    m.stillBg.uri = Str_Of(info.background)
    m.stillShow.text = Str_Of(info.title)
    m.stillShow.visible = true
    m.stillLogo.visible = false
    m.stillLogo.uri = m.logo.uri
    Ex_OnStillLogo()
    m.stillHeading.text = L("¿Sigues viendo?")
    nxt = m.top.nextInfo
    nextLine = ""
    if nxt <> invalid then nextLine = L("Siguiente: ") + Str_Of(nxt.code) + "  ·  " + Str_Of(nxt.title)
    m.stillSub.text = nextLine
    m.stillButtons.removeChildrenIndex(m.stillButtons.getChildCount(), 0)
    m.stillDefs = []
    x = 0
    for each label in [L("Sí"), L("No")]
        g = m.stillButtons.createChild("Group")
        g.translation = [x, 0]
        bg = Ex_PillMake(g, 72)
        t = g.createChild("Label")
        t.font = "font:MediumBoldSystemFont"
        t.font.size = 34
        t.text = label
        t.height = 72
        t.vertAlign = "center"
        t.translation = [44, 0]
        w = Int(t.boundingRect().width) + 88
        if w < 180 then w = 180
        t.width = w - 88
        t.horizAlign = "center"
        Ex_PillSet(bg, w, "0xFFFFFF2E")
        m.stillDefs.Push({ bg: bg, text: t })
        x = x + w + 20
    end for
    m.stillBox.visible = true
    Ex_PaintStill()
end sub

sub Ex_OnStillLogo()
    if m.stillLogo.loadStatus = "ready" and m.stillLogo.uri <> ""
        m.stillLogo.visible = true
        m.stillShow.visible = false
    end if
end sub

sub Ex_PaintStill()
    for i = 0 to m.stillDefs.Count() - 1
        d = m.stillDefs[i]
        if i = m.stillIndex
            Ex_PillSet(d.bg, d.bg.w, "0xFFFFFFFF")
            d.text.color = "0x0C0C0FFF"
        else
            Ex_PillSet(d.bg, d.bg.w, "0xFFFFFF2E")
            d.text.color = "0xFFFFFFFF"
        end if
    end for
    m.stillCount.text = L("Se detendrá en ") + m.stillLeft.ToStr() + " s"
end sub

function Ex_StillKey(key as string) as boolean
    if key = "left"
        m.stillIndex = 0
        Ex_PaintStill()
    else if key = "right"
        m.stillIndex = 1
        Ex_PaintStill()
    else if key = "OK"
        Ex_StillChoose(m.stillIndex = 0)
    else if key = "back"
        Ex_StillChoose(false)
    end if
    return true
end function

sub Ex_StillChoose(yes as boolean)
    m.stillOn = false
    m.stillBox.visible = false
    if yes then m.top.event = { type: "stillYes" } else m.top.event = { type: "stillNo" }
end sub

sub Ex_StyleSubs()
    style = Ex_Info("subStyle", {})
    if type(style) <> "roAssociativeArray" then style = {}
    sizes = { small: 34, normal: 42, large: 52, xlarge: 62 }
    size = sizes[Str_Of(style.size)]
    if size = invalid then size = 42
    font = "font:MediumSystemFont"
    if Bool_Of(style.bold, false) then font = "font:MediumBoldSystemFont"
    for each lbl in [m.subText, m.subShadow]
        lbl.font = font
        lbl.font.size = size
        lbl.lineSpacing = 4
    end for
    colors = { white: "0xFFFFFFFF", yellow: "0xFFE14DFF", cyan: "0x6FE3FFFF", green: "0x7CFF8AFF", gray: "0xCFCFCFFF" }
    c = colors[Str_Of(style.color)]
    if c = invalid then c = "0xFFFFFFFF"
    m.subText.color = c
    m.subShadow.visible = Str_Of(style.edge) <> "none"
    bgs = { none: "0x00000000", soft: "0x00000088", solid: "0x000000E6" }
    b = bgs[Str_Of(style.bg)]
    if b = invalid then b = "0x00000000"
    m.subBg.blendColor = b
    m.subBg.visible = b <> "0x00000000"
    m.subBottom = 1000 - ToInt(style.offset, 0) * 20
end sub

function Ex_UseCustom(track as string) as boolean
    if not Bool_Of(Ex_Info("customSubs", true), true) then return false
    return LCase(Left(track, 4)) = "http"
end function

sub Ex_SubSelect(track as string)
    if track = ""
        Ex_SubOff()
        m.video.globalCaptionMode = "Off"
        return
    end if
    if Ex_UseCustom(track)
        m.video.globalCaptionMode = "Off"
        if m.subUrl = track then return
        m.subUrl = track
        m.cues = []
        m.cueIndex = 0
        m.subLayer.visible = false
        task = CreateObject("roSGNode", "PlayerDataTask")
        task.mode = "subs"
        task.params = { url: track }
        task.observeField("result", "Ex_OnSubsLoaded")
        task.control = "RUN"
        m.subTask = task
        return
    end if
    Ex_SubOff()
    m.video.subtitleTrack = track
    m.video.globalCaptionMode = "On"
end sub

sub Ex_SubOff()
    m.subUrl = ""
    m.cues = []
    m.subTask = invalid
    m.subLayer.visible = false
end sub

sub Ex_OnSubsLoaded(event as object)
    task = event.getRoSGNode()
    if m.subTask = invalid or not task.isSameNode(m.subTask) then return
    m.subTask = invalid
    r = task.result
    cues = invalid
    if r <> invalid then cues = r.cues
    if type(cues) <> "roArray" or cues.Count() = 0
        url = m.subUrl
        m.subUrl = ""
        m.video.subtitleTrack = url
        m.video.globalCaptionMode = "On"
        return
    end if
    m.cues = cues
    m.cueIndex = 0
end sub

function Ex_SubActive() as string
    return m.subUrl
end function

sub Ex_Subs(at0 as float)
    if m.cues.Count() = 0
        if m.subLayer.visible then m.subLayer.visible = false
        return
    end if
    i = m.cueIndex
    if i >= m.cues.Count() then i = m.cues.Count() - 1
    if i < 0 then i = 0
    if m.cues[i].s > at0
        while i > 0 and m.cues[i].s > at0
            i = i - 1
        end while
    else
        while i < m.cues.Count() - 1 and m.cues[i + 1].s <= at0
            i = i + 1
        end while
    end if
    m.cueIndex = i
    cue = m.cues[i]
    if at0 >= cue.s and at0 <= cue.e
        if m.subText.text <> cue.t
            m.subText.text = cue.t
            m.subShadow.text = cue.t
            rect = m.subText.boundingRect()
            h = Int(rect.height)
            w = Int(rect.width)
            bottom = m.subBottom
            if m.controls.visible then bottom = 680
            m.subText.translation = [160, bottom - h]
            m.subText.height = h
            m.subShadow.height = h
            m.subShadow.translation = [163, bottom - h + 3]
            m.subBg.width = w + 48
            m.subBg.height = h + 20
            m.subBg.translation = [960 - Int((w + 48) / 2), bottom - h - 10]
        end if
        m.subLayer.visible = true
    else if m.subLayer.visible
        m.subLayer.visible = false
        m.subText.text = ""
    end if
end sub

sub Ex_Stats()
    lines = []
    seg = m.video.streamingSegment
    if type(seg) = "roAssociativeArray" and ToInt(seg.width, 0) > 0 then lines.Push(L("Resolución: ") + ToInt(seg.width, 0).ToStr() + " x " + ToInt(seg.height, 0).ToStr())
    vf = Str_Of(m.video.videoFormat)
    if vf <> "" then lines.Push(L("Video: ") + UCase(vf))
    af = Str_Of(m.video.audioFormat)
    if af <> "" then lines.Push("Audio: " + UCase(af))
    si = m.video.streamInfo
    if type(si) = "roAssociativeArray"
        rate = ToInt(si.streamBitrate, 0)
        if rate > 0 then lines.Push(L("Bitrate: ") + Ex_Mbps(rate))
        measured = ToInt(si.measuredBitrate, 0)
        if measured > 0 then lines.Push(L("Velocidad: ") + Ex_Mbps(measured))
    end if
    lines.Push(L("Estado: ") + m.video.state)
    m.statsText.text = lines.Join(chr(10))
    rect = m.statsText.boundingRect()
    m.statsBg.width = Int(rect.width) + 48
    m.statsBg.height = Int(rect.height) + 36
end sub

function Ex_Mbps(bps as integer) as string
    mb = bps / 1000000.0
    whole = Int(mb * 10)
    return (whole / 10).ToStr() + " Mbps"
end function

function Ex_SubAllowed(t as object) as boolean
    text = LCase(Str_Of(t.Description) + " " + Str_Of(t.Name))
    if Bool_Of(Ex_Info("stripSdh", false), false)
        for each word in ["sdh", "[cc]", "(cc)", "hearing", " hi)", "(hi", "[hi]", "sordos"]
            if Instr(1, text, word) > 0 then return false
        end for
    end if
    if Bool_Of(Ex_Info("onlyPreferred", false), false)
        info = m.top.info
        lang = Str_Of(t.Language)
        original = Str_Of(info.originalLang)
        ok = false
        for each code in [Str_Of(info.subLang), Str_Of(info.subLang2)]
            wanted = Lang_Resolve(LCase(code), original)
            if wanted <> "" and Lang_Matches(lang, wanted) then ok = true
        end for
        if not ok then return false
    end if
    return true
end function

function Ex_PillMake(parent as object, h as integer) as object
    lc = parent.createChild("Poster")
    lc.uri = "pkg:/images/c/hl" + h.ToStr() + ".png"
    lc.width = h / 2
    lc.height = h
    mid = parent.createChild("Rectangle")
    mid.translation = [h / 2, 0]
    mid.height = h
    r = parent.createChild("Poster")
    r.uri = "pkg:/images/c/hr" + h.ToStr() + ".png"
    r.width = h / 2
    r.height = h
    return { l: lc, mid: mid, r: r, h: h, w: h, color: "0xFFFFFFFF" }
end function

sub Ex_PillSet(p as object, w as integer, color as string)
    if w < p.h then w = p.h
    p.w = w
    p.color = color
    half = Int(p.h / 2)
    p.mid.width = w - half * 2
    p.r.translation = [w - half, 0]
    p.l.blendColor = color
    p.mid.color = color
    p.r.blendColor = color
end sub

sub Ex_OnSecond()
    try
        Ex_OnSecond_Run()
    catch e
        Ex_Crash(e)
    end try
end sub

sub Ex_OnSegments()
    try
        Ex_OnSegments_Run()
    catch e
        Ex_Crash(e)
    end try
end sub

sub Ex_OnParental()
    try
        Ex_OnParental_Run()
    catch e
        Ex_Crash(e)
    end try
end sub

sub Ex_OnStill()
    try
        Ex_OnStill_Run()
    catch e
        Ex_Crash(e)
    end try
end sub

sub Ex_Crash(e as object)
    text = Str_Of(e.message)
    if type(e.backtrace) = "roArray"
        for each b in e.backtrace
            if type(b) = "roAssociativeArray"
                file = Str_Of(b.filename)
                cut = file.Split("/")
                text = text + chr(10) + cut[cut.Count() - 1] + ":" + Str_Any(b.line_number)
            end if
        end for
    end if
    print "PLAYER ERROR "; text
    m.top.event = { type: "crash", message: text }
end sub
