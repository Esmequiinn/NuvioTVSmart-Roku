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
    m.top.findNode("nextMask").maskUri = ""
    nextCaps = m.top.findNode("nextCard").createChild("Group")
    nextCaps.translation = [24, 24]
    Mask_Caps(nextCaps, 256, 144, 14, "0x161616FF", true)
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
    m.epPanel = m.top.findNode("epPanel")
    m.postBg = m.top.findNode("postBg")
    m.postLogo = m.top.findNode("postLogo")
    m.postTitle = m.top.findNode("postTitle")
    m.postMeta = m.top.findNode("postMeta")
    m.postDesc = m.top.findNode("postDesc")
    m.postFill = m.top.findNode("postFill")
    m.postCount = m.top.findNode("postCount")
    m.postWinRing = m.top.findNode("postWinRing")
    m.postWinHint = m.top.findNode("postWinHint")
    m.postTimer = m.top.findNode("postTimer")
    m.postTimer.observeField("fire", "Ex_PostTick")
    m.postLogo.observeField("loadStatus", "Ex_PostLogo")
    m.postClock = CreateObject("roTimespan")
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
        Ex_PostEnd()
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
    m.postZone = "buttons"
    m.postBtn = 0
    title = Str_Of(Ex_Info("title", ""))
    if title <> "" then m.postHeading.text = L("Porque viste") + " " + title else m.postHeading.text = L("Recomendado para ti")
    m.postHint.text = L("Cambia sola cada 10 segundos  ·  Arriba para volver al video  ·  Atrás para cerrar")
    m.postWinHint.text = L("OK para volver al video")
    m.postBox.visible = true
    m.postBg.visible = true
    m.video.translation = [1208, 64]
    m.video.width = 608
    m.video.height = 342
    Ex_PostFill()
    m.postClock.Mark()
    m.postTimer.control = "start"
end sub

sub Ex_PostEnd()
    m.postTimer.control = "stop"
    m.postBox.visible = false
    m.postBg.visible = false
    m.video.translation = [0, 0]
    m.video.width = 1920
    m.video.height = 1080
end sub

sub Ex_PostFill()
    r = m.postItems[m.postIndex]
    bg = Str_Of(r.background)
    if bg = "" then bg = Str_Of(r.poster)
    m.postBg.uri = bg
    m.postTitle.text = Str_Of(r.name)
    m.postTitle.visible = true
    m.postLogo.visible = false
    m.postLogo.uri = Str_Of(r.logo)
    Ex_PostLogo()
    parts = []
    if Str_Of(r.rating) <> "" then parts.Push("IMDb " + Str_Of(r.rating))
    if Str_Of(r.year) <> "" then parts.Push(Str_Of(r.year))
    if Str_Of(r.kind) = "series" then parts.Push(L("Serie")) else parts.Push(L("Película"))
    m.postMeta.text = parts.Join("   •   ")
    m.postDesc.text = Str_Of(r.overview)
    m.postCount.text = (m.postIndex + 1).ToStr() + " / " + m.postItems.Count().ToStr()
    Ex_PostButtons()
end sub

sub Ex_PostLogo()
    if m.postLogo.uri <> "" and m.postLogo.loadStatus = "ready"
        m.postLogo.visible = true
        m.postTitle.visible = false
    end if
end sub

sub Ex_PostButtons()
    m.postRow.removeChildrenIndex(m.postRow.getChildCount(), 0)
    r = m.postItems[m.postIndex]
    main = { id: "play", icon: "ic_play", label: L("Reproducir"), w: 300 }
    if Str_Of(r.kind) = "series" then main = { id: "details", icon: "ic_info", label: L("Ver detalles"), w: 300 }
    defs = [main, { id: "prev", icon: "chevron", flip: true, label: "", w: 72 }, { id: "next", icon: "chevron", label: "", w: 72 }]
    m.postBtns = []
    x = 0
    for each d in defs
        g = m.postRow.createChild("Group")
        g.translation = [x, 0]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.width = d.w
        pill.height = 72
        ic = g.createChild("Poster")
        ic.uri = "pkg:/images/s/" + d.icon + "_36.png"
        ic.width = 36
        ic.height = 36
        if d.label = ""
            ic.translation = [18, 18]
            if d.flip = true
                ic.scaleRotateCenter = [18, 18]
                ic.rotation = 3.14159
            end if
        else
            ic.translation = [28, 18]
        end if
        lb = invalid
        if d.label <> ""
            lb = g.createChild("Label")
            lb.font = "font:SmallBoldSystemFont"
            lb.font.size = 28
            lb.translation = [78, 0]
            lb.width = d.w - 96
            lb.height = 72
            lb.vertAlign = "center"
            lb.text = d.label
        end if
        m.postBtns.Push({ id: d.id, pill: pill, icon: ic, label: lb })
        x = x + d.w + 20
    end for
    Ex_PaintPost()
end sub

sub Ex_PaintPost()
    for i = 0 to m.postBtns.Count() - 1
        b = m.postBtns[i]
        on = m.postZone = "buttons" and i = m.postBtn
        if on then b.pill.blendColor = "0xFFFFFFFF" else b.pill.blendColor = "0xFFFFFF2E"
        ink = "0xFFFFFFFF"
        if on then ink = "0x0C0C0FFF"
        b.icon.blendColor = ink
        if b.label <> invalid then b.label.color = ink
    end for
    m.postWinRing.visible = m.postZone = "window"
    m.postWinRing.blendColor = m.top.accent
    m.postWinHint.visible = m.postZone = "window"
end sub

sub Ex_PostTick()
    if not m.postBox.visible then
        m.postTimer.control = "stop"
        return
    end if
    span = 10000
    ms = m.postClock.TotalMilliseconds()
    if ms >= span
        if m.postItems.Count() > 1
            m.postIndex = (m.postIndex + 1) mod m.postItems.Count()
            Ex_PostFill()
        end if
        m.postClock.Mark()
        ms = 0
    end if
    m.postFill.color = m.top.accent
    m.postFill.width = Int(560 * ms / span)
end sub

sub Ex_PostMove(delta as integer)
    n = m.postItems.Count()
    if n = 0 then return
    m.postIndex = (m.postIndex + delta + n) mod n
    m.postClock.Mark()
    Ex_PostFill()
end sub

function Ex_PostKey(key as string) as boolean
    if not m.postBox.visible then return false
    if m.postZone = "window"
        if key = "down"
            m.postZone = "buttons"
        else if key = "OK"
            Ex_PostEnd()
            m.postDismissed = true
            m.top.postActive = false
            if m.video.state = "finished" then m.top.event = { type: "close" }
        else if key = "back"
            Ex_PostClose()
        end if
        Ex_PaintPost()
        return true
    end if
    if key = "left"
        if m.postBtn > 0 then m.postBtn = m.postBtn - 1
        Ex_PaintPost()
    else if key = "right"
        if m.postBtn < m.postBtns.Count() - 1 then m.postBtn = m.postBtn + 1
        Ex_PaintPost()
    else if key = "up"
        if m.video.state <> "finished" then m.postZone = "window"
        Ex_PaintPost()
    else if key = "rewind"
        Ex_PostMove(-1)
    else if key = "fastforward"
        Ex_PostMove(1)
    else if key = "OK"
        id = m.postBtns[m.postBtn].id
        if id = "prev"
            Ex_PostMove(-1)
        else if id = "next"
            Ex_PostMove(1)
        else
            r = m.postItems[m.postIndex]
            Ex_PostEnd()
            m.top.postActive = false
            m.top.event = { type: "recPick", id: Str_Of(r.id), kind: Str_Of(r.kind), name: Str_Of(r.name), poster: Str_Of(r.poster), background: Str_Of(r.background), play: id = "play" }
        end if
    else if key = "back"
        Ex_PostClose()
    else
        return false
    end if
    return true
end function

sub Ex_PostClose()
    Ex_PostEnd()
    m.postDismissed = true
    m.top.postActive = false
    if m.video.state = "finished" then m.top.event = { type: "close" }
end sub

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

sub EpP_Open()
    data = m.top.episodes
    if data = invalid or type(data.seasons) <> "roArray" or data.seasons.Count() = 0 then return
    m.epSeasons = data.seasons
    m.epCurrent = Str_Of(data.current)
    m.epSeason = 0
    m.epIdx = 0
    for si = 0 to m.epSeasons.Count() - 1
        eps = m.epSeasons[si].episodes
        if type(eps) = "roArray"
            for ei = 0 to eps.Count() - 1
                if Str_Of(eps[ei].id) = m.epCurrent
                    m.epSeason = si
                    m.epIdx = ei
                end if
            end for
        end if
    end for
    m.epZone = "list"
    m.epRows = []
    m.epChips = []
    p = m.epPanel
    p.removeChildrenIndex(p.getChildCount(), 0)
    shade = p.createChild("Poster")
    shade.uri = "pkg:/images/grad_left.png"
    shade.width = 500
    shade.height = 1080
    shade.translation = [1420, 0]
    shade.scaleRotateCenter = [250, 540]
    shade.rotation = 3.14159
    shade.blendColor = "0x000000FF"
    bg = p.createChild("Rectangle")
    bg.translation = [980, 0]
    bg.width = 940
    bg.height = 1080
    bg.color = "0x0E0E11F2"
    title = p.createChild("Label")
    title.translation = [1036, 56]
    title.font = "font:LargeBoldSystemFont"
    title.font.size = 40
    title.color = "0xFFFFFFFF"
    title.text = L("Episodios")
    hint = p.createChild("Label")
    hint.translation = [1300, 66]
    hint.width = 560
    hint.horizAlign = "right"
    hint.font = "font:SmallestSystemFont"
    hint.font.size = 22
    hint.color = "0x8C8C96FF"
    hint.text = L("Atrás para cerrar")
    m.epChipBox = p.createChild("Group")
    m.epChipBox.translation = [1036, 136]
    clip = p.createChild("Group")
    clip.clippingRect = [1000, 220, 920, 860]
    m.epList = clip.createChild("Group")
    EpP_Chips()
    EpP_List()
    p.visible = true
    m.hideTimer.control = "stop"
    m.controls.visible = false
end sub

sub EpP_Chips()
    m.epChipBox.removeChildrenIndex(m.epChipBox.getChildCount(), 0)
    m.epChips = []
    x = 0
    for i = 0 to m.epSeasons.Count() - 1
        g = m.epChipBox.createChild("Group")
        g.translation = [x, 0]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/pill60.9.png"
        bg.height = 56
        lb = g.createChild("Label")
        lb.font = "font:SmallBoldSystemFont"
        lb.font.size = 24
        lb.height = 56
        lb.vertAlign = "center"
        lb.translation = [26, 0]
        lb.text = Str_Of(m.epSeasons[i].label)
        w = Int(lb.boundingRect().width)
        est = Len(lb.text) * 13
        if w < est then w = est
        bg.width = w + 52
        m.epChips.Push({ g: g, bg: bg, label: lb, x: x, w: w + 52 })
        x = x + w + 66
    end for
    EpP_Paint()
end sub

sub EpP_List()
    m.epList.removeChildrenIndex(m.epList.getChildCount(), 0)
    m.epRows = []
    eps = m.epSeasons[m.epSeason].episodes
    if type(eps) <> "roArray" then eps = []
    if m.epIdx >= eps.Count() then m.epIdx = 0
    accent = m.top.accent
    for i = 0 to eps.Count() - 1
        e = eps[i]
        g = m.epList.createChild("Group")
        g.translation = [1016, 232 + i * 176]
        hl = g.createChild("Poster")
        hl.uri = "pkg:/images/card.9.png"
        hl.width = 868
        hl.height = 160
        hl.translation = [0, -8]
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/iring.9.png"
        ring.width = 868
        ring.height = 160
        ring.translation = [0, -8]
        ring.blendColor = accent
        mask = g.createChild("Group")
        mask.translation = [12, 4]
        base = mask.createChild("Rectangle")
        base.width = 240
        base.height = 135
        base.color = "0x26262BFF"
        pic = mask.createChild("Poster")
        pic.width = 240
        pic.height = 135
        pic.loadWidth = 240
        pic.loadHeight = 135
        pic.loadDisplayMode = "scaleToZoom"
        pic.uri = Str_Of(e.thumb)
        caps = g.createChild("Group")
        caps.translation = [12, 4]
        Mask_Caps(caps, 240, 135, 10, "0x0E0E11FF", true)
        badgeBg = g.createChild("Poster")
        badgeBg.uri = "pkg:/images/pill34.9.png"
        badgeBg.width = 64
        badgeBg.height = 30
        badgeBg.translation = [20, 12]
        badgeBg.blendColor = "0x000000C0"
        badge = g.createChild("Label")
        badge.font = "font:SmallestBoldSystemFont"
        badge.font.size = 18
        badge.color = "0xFFFFFFFF"
        badge.translation = [20, 12]
        badge.width = 64
        badge.height = 30
        badge.horizAlign = "center"
        badge.vertAlign = "center"
        badge.text = Str_Of(e.code)
        if Str_Of(e.id) = m.epCurrent
            now = g.createChild("Poster")
            now.uri = "pkg:/images/c/d38.png"
            now.width = 34
            now.height = 34
            now.translation = [208, 12]
            now.blendColor = accent
            pl = g.createChild("Poster")
            pl.uri = "pkg:/images/s/ic_play_24.png"
            pl.width = 18
            pl.height = 18
            pl.translation = [217, 20]
            pl.blendColor = "0x0C0C0FFF"
        else if e.watched = true
            dot = g.createChild("Poster")
            dot.uri = "pkg:/images/c/d38.png"
            dot.width = 34
            dot.height = 34
            dot.translation = [208, 12]
            dot.blendColor = accent
            chk = g.createChild("Poster")
            chk.uri = "pkg:/images/s/ic_check_s_24.png"
            chk.width = 22
            chk.height = 22
            chk.translation = [214, 18]
            chk.blendColor = "0x0D0D0DFF"
        end if
        if e.progress <> invalid and e.progress > 0.01
            tr = g.createChild("Rectangle")
            tr.translation = [24, 126]
            tr.width = 216
            tr.height = 5
            tr.color = "0xFFFFFF40"
            fl = g.createChild("Rectangle")
            fl.translation = [24, 126]
            pr = e.progress
            if pr > 1 then pr = 1
            fl.width = Int(216 * pr)
            fl.height = 5
            fl.color = accent
        end if
        t = g.createChild("Label")
        t.font = "font:SmallBoldSystemFont"
        t.font.size = 27
        t.color = "0xFFFFFFFF"
        t.translation = [276, 6]
        t.width = 570
        t.text = Str_Of(e.name)
        d = g.createChild("Label")
        d.font = "font:SmallestSystemFont"
        d.font.size = 20
        d.color = "0x9A9AA6FF"
        d.translation = [276, 44]
        d.width = 570
        d.text = Str_Of(e.meta)
        o = g.createChild("Label")
        o.font = "font:SmallestSystemFont"
        o.font.size = 21
        o.color = "0xC4C4CCFF"
        o.translation = [276, 76]
        o.width = 570
        o.height = 64
        o.wrap = true
        o.maxLines = 2
        o.text = Str_Of(e.overview)
        m.epRows.Push({ hl: hl, ring: ring, caps: caps, id: Str_Of(e.id) })
    end for
    EpP_Paint()
end sub

sub EpP_Paint()
    for i = 0 to m.epChips.Count() - 1
        c = m.epChips[i]
        if m.epZone = "seasons" and i = m.epSeason
            c.bg.blendColor = "0xFFFFFFFF"
            c.label.color = "0x0D0D0DFF"
        else if i = m.epSeason
            c.bg.blendColor = "0x3A3A40FF"
            c.label.color = "0xFFFFFFFF"
        else
            c.bg.blendColor = "0x1E1E22FF"
            c.label.color = "0xB3B3BBFF"
        end if
    end for
    off = 0
    if m.epChips.Count() > 0
        c = m.epChips[m.epSeason]
        if c.x + c.w > 820 then off = c.x + c.w - 820
    end if
    m.epChipBox.translation = [1036 - off, 136]
    for i = 0 to m.epRows.Count() - 1
        r = m.epRows[i]
        on = m.epZone = "list" and i = m.epIdx
        r.ring.visible = on
        if on then r.hl.blendColor = "0xFFFFFF1A" else r.hl.blendColor = "0xFFFFFF00"
        capColor = "0x0E0E11FF"
        if on then capColor = "0x26262AFF"
        if r.caps <> invalid
            for each cap in r.caps.findNode("maskCaps").getChildren(-1, 0)
                cap.blendColor = capColor
            end for
        end if
    end for
    first = m.epIdx - 1
    if first < 0 then first = 0
    last = m.epRows.Count() - 4
    if last < 0 then last = 0
    if first > last then first = last
    m.epList.translation = [0, -first * 176]
end sub

sub EpP_Close()
    m.epPanel.visible = false
    m.epPanel.removeChildrenIndex(m.epPanel.getChildCount(), 0)
    m.epRows = []
    m.epChips = []
    showControls("buttons")
end sub

function EpP_Key(key as string) as boolean
    if key = "back"
        EpP_Close()
        return true
    end if
    if m.epZone = "seasons"
        if key = "left" and m.epSeason > 0
            m.epSeason = m.epSeason - 1
            m.epIdx = 0
            EpP_List()
        else if key = "right" and m.epSeason < m.epSeasons.Count() - 1
            m.epSeason = m.epSeason + 1
            m.epIdx = 0
            EpP_List()
        else if key = "down" and m.epRows.Count() > 0
            m.epZone = "list"
        end if
    else
        if key = "up"
            if m.epIdx > 0 then m.epIdx = m.epIdx - 1 else m.epZone = "seasons"
        else if key = "down"
            if m.epIdx < m.epRows.Count() - 1 then m.epIdx = m.epIdx + 1
        else if key = "OK" and m.epRows.Count() > 0
            id = m.epRows[m.epIdx].id
            m.epPanel.visible = false
            m.top.event = { type: "pickEpisode", id: id }
            return true
        end if
    end if
    EpP_Paint()
    return true
end function
