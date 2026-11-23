sub init()
    m.guideGroup = m.top.findNode("guide")
    m.video = m.top.findNode("video")
    m.watch = m.top.findNode("watch")
    m.topTitle = m.top.findNode("topTitle")
    m.topGroup = m.top.findNode("topGroup")
    m.topStatus = m.top.findNode("topStatus")
    m.clock = m.top.findNode("clock")
    m.headPanel = m.top.findNode("headPanel")
    m.artBg = m.top.findNode("artBg")
    m.artImg = m.top.findNode("artImg")
    m.artImg.observeField("loadStatus", "onArtImg")
    m.artBad = {}
    m.artEpg = false
    m.artLogo = m.top.findNode("artLogo")
    m.chLine = m.top.findNode("chLine")
    m.liveBadge = m.top.findNode("liveBadge")
    m.liveText = m.top.findNode("liveText")
    m.infoTitle = m.top.findNode("infoTitle")
    m.infoLine = m.top.findNode("infoLine")
    m.infoTrack = m.top.findNode("infoTrack")
    m.infoBar = m.top.findNode("infoBar")
    m.infoDesc = m.top.findNode("infoDesc")
    m.previewFrame = m.top.findNode("previewFrame")
    m.previewHint = m.top.findNode("previewHint")
    m.dayLabel = m.top.findNode("dayLabel")
    m.times = m.top.findNode("times")
    m.rows = m.top.findNode("rows")
    m.nowLine = m.top.findNode("nowLine")
    m.nowDot = m.top.findNode("nowDot")
    m.status = m.top.findNode("status")
    m.previewTimer = m.top.findNode("previewTimer")
    m.previewTimer.observeField("fire", "onPreviewTimer")
    m.clockTimer = m.top.findNode("clockTimer")
    m.clockTimer.observeField("fire", "onClockTimer")
    m.watchdog = m.top.findNode("watchdog")
    m.watchdog.observeField("fire", "onWatchdog")
    m.retryTimer = m.top.findNode("retryTimer")
    m.retryTimer.observeField("fire", "onRetryTimer")
    Iptv_FontSizes(m.top, { topTitle: 36, topGroup: 30, clock: 26, topStatus: 24, chLine: 25, liveText: 20, infoTitle: 50, infoLine: 25, infoDesc: 24, previewHint: 24, dayLabel: 26, status: 30, ovGroup: 32, ovHint: 22, gpTitle: 32, gpHint: 22 })
    m.topTitle.text = L("TV en vivo")
    m.liveText.text = L("EN VIVO")
    m.previewHint.text = L("La vista previa empieza al quedarte en un canal.")
    m.accent = "0x7C4DFFFF"
    if m.global.hasField("accent") then m.accent = m.global.accent
    m.win = 7200
    m.all = []
    m.view = []
    m.groups = []
    m.groupIdx = 1
    m.sel = 0
    m.top0 = 0
    m.zone = "grid"
    m.guide = {}
    m.guideAsked = {}
    m.loaded = false
    m.loading = false
    m.epgLoading = false
    m.epgReady = false
    m.epgText = ""
    m.epgAt = 0
    m.playingKey = ""
    m.prevKey = ""
    m.mode = "guide"
    m.unlocked = {}
    m.reconnects = 0
    m.reconnectAt = 0
    m.art = {}
    m.artAsked = {}
    m.artWant = []
    Live_PrefsLoad()
    Live_FavLoad()
    Live_Layout()
    Live_ResetWindow()
    Groups_Init()
    Watch_Init()
    m.video.observeField("state", "onVideoState")
end sub

sub Live_PrefsLoad()
    m.prefs = Iptv_Prefs()
    m.names = Iptv_Store("Names")
    m.hidden = Iptv_Store("Hidden")
    m.hiddenGroups = Iptv_Store("HiddenGroups")
    m.favGroups = Iptv_Store("FavGroups")
    m.locks = Iptv_Store("Locks")
    m.trackMemory = Iptv_Store("Tracks")
    m.remind = Iptv_ReminderMap()
end sub

sub Live_Layout()
    spec = Iptv_SizeSpec(Str_Of(m.prefs.size))
    sig = Str_Of(m.prefs.size) + Bool_Of(m.prefs.nums, true).ToStr() + Bool_Of(m.prefs.logos, true).ToStr() + Bool_Of(m.prefs.names, true).ToStr() + Bool_Of(m.prefs.twoLine, false).ToStr() + Bool_Of(m.prefs.times, true).ToStr()
    if m.layoutSig = sig then return
    m.layoutSig = sig
    m.spec = spec
    xx = 16
    m.colNum = -1
    m.colLogo = -1
    m.colName = -1
    if Bool_Of(m.prefs.nums, true)
        m.colNum = xx
        xx = xx + 64
    end if
    if Bool_Of(m.prefs.logos, true)
        m.colLogo = xx
        xx = xx + spec.logoW + 14
    end if
    if Bool_Of(m.prefs.names, true)
        m.colName = xx
        xx = xx + spec.nameW + 8
    end if
    m.cw = xx + 8
    if m.cw < 110 then m.cw = 110
    m.gx0 = 112 + m.cw + 10
    m.gx1 = 1824
    m.pps = (m.gx1 - m.gx0) / m.win
    m.rowY0 = 492
    m.rowStep = spec.step
    m.rowH = spec.h
    m.nRows = Int((1064 - m.rowY0) / m.rowStep)
    m.dayLabel.width = m.cw
    Live_BuildRows()
    if m.timeLabels <> invalid
        m.times.removeChildrenIndex(m.times.getChildCount(), 0)
        m.timeLabels = invalid
    end if
    Live_ApplyPreviewPref()
end sub

sub Live_ApplyPreviewPref()
    on = Bool_Of(m.prefs.preview, true)
    m.previewFrame.visible = on
    m.previewHint.visible = on and m.playingKey = ""
    w = 930
    if not on then w = 1440
    m.infoTitle.width = w
    m.infoLine.width = w
    m.infoTrack.width = w
    m.infoDesc.width = w
    m.infoW = w
    if m.mode = "guide"
        m.video.visible = on and m.playingKey <> ""
        if not on and m.playingKey <> "" then Live_StopVideo()
    end if
end sub

function Live_Now() as integer
    return CreateObject("roDateTime").AsSeconds()
end function

sub Live_ResetWindow()
    now = Live_Now()
    m.winStart = now - (now mod 1800)
    m.focusT = now
end sub

sub Live_FavLoad()
    m.favs = {}
    m.favOrder = []
    v = St_Get("iptvFavs_" + St_ActiveProfile().id, invalid)
    if type(v) = "roArray"
        for each k in v
            if not m.favs.DoesExist(k)
                m.favs[k] = true
                m.favOrder.Push(k)
            end if
        end for
    end if
end sub

sub Live_FavToggle(key as string)
    if key = "" then return
    if m.favs.DoesExist(key)
        m.favs.Delete(key)
        out = []
        for each k in m.favOrder
            if k <> key then out.Push(k)
        end for
        m.favOrder = out
    else
        m.favs[key] = true
        m.favOrder.Push(key)
    end if
    St_Set("iptvFavs_" + St_ActiveProfile().id, m.favOrder)
end sub

function Live_ProfileChanged() as boolean
    pid = Str_Of(St_ActiveProfile().id)
    if m.loadedPid = invalid then m.loadedPid = pid
    if m.loadedPid = pid then return false
    m.loadedPid = pid
    m.loaded = false
    m.guide = {}
    m.guideAsked = {}
    m.all = []
    m.view = []
    m.keyIndex = invalid
    m.unlocked = {}
    m.startedLast = false
    Live_PrefsLoad()
    Live_Layout()
    Live_FavLoad()
    Live_Load(false)
    return true
end function

function Live_Recent() as object
    v = St_Get("iptvRecent_" + St_ActiveProfile().id, invalid)
    if type(v) = "roArray" then return v
    return []
end function

sub Live_AddRecent(key as string)
    if key = "" then return
    out = [key]
    for each k in Live_Recent()
        if k <> key and out.Count() < 20 then out.Push(k)
    end for
    St_Set("iptvRecent_" + St_ActiveProfile().id, out)
    m.top.event = { action: "channels" }
end sub

function Live_Name(c as object) as string
    if c = invalid then return ""
    if m.names.DoesExist(c.k) then return Str_Of(m.names[c.k])
    return Str_Of(c.n)
end function

function Live_Number(vp as integer) as string
    if vp < 0 or vp >= m.view.Count() then return ""
    return (m.view[vp] + 1).ToStr()
end function

sub onActive()
    if m.top.active then Live_ProfileChanged()
    if m.top.active
        Live_FavLoad()
        m.clockTimer.control = "start"
        onClockTimer()
        if not m.loaded and not m.loading
            Live_Load(false)
        else
            Live_ApplyGroup(false)
            Live_StartLast()
        end if
    else
        m.clockTimer.control = "stop"
        m.previewTimer.control = "stop"
        m.watchdog.control = "stop"
        m.retryTimer.control = "stop"
        Groups_Close()
        Watch_Leave()
        Live_StopVideo()
    end if
end sub

sub Live_StartLast()
    if Bool_Of(m.startedLast, false) or not m.top.active or not m.loaded then return
    m.startedLast = true
    if not Bool_Of(m.prefs.startLast, false) or m.mode = "watch" then return
    recent = Live_Recent()
    if recent.Count() = 0 then return
    Live_PlayKey(Str_Of(recent[0]))
end sub

sub onReload()
    m.loaded = false
    m.guide = {}
    m.guideAsked = {}
    if m.top.active or m.top.reload then Live_Load(true)
end sub

sub Live_Load(force as boolean)
    m.loading = true
    m.loadedPid = Str_Of(St_ActiveProfile().id)
    m.status.text = L("Cargando canales...")
    m.status.visible = true
    m.loadTask = CreateObject("roSGNode", "IptvTask")
    m.loadTask.mode = "load"
    m.loadTask.params = { force: force }
    m.loadTask.observeField("channels", "onChannels")
    m.loadTask.observeField("result", "onEpgDone")
    m.loadTask.observeField("progress", "onEpgProgress")
    m.loadTask.control = "RUN"
end sub

sub onChannels(event as object)
    task = event.getRoSGNode()
    if m.loadTask = invalid or not task.isSameNode(m.loadTask) then return
    r = task.channels
    m.loading = false
    m.loaded = true
    m.all = []
    if r <> invalid and type(r.channels) = "roArray" then m.all = r.channels
    m.keyIndex = {}
    for i = 0 to m.all.Count() - 1
        m.keyIndex[m.all[i].k] = i
    end for
    m.epgLoading = true
    m.epgReady = false
    m.epgText = ""
    m.epgAt = Live_Now()
    Live_BuildGroups()
    m.groupIdx = Groups_Initial()
    Live_ApplyGroup(true)
    errs = r.errors
    if type(errs) = "roArray" and errs.Count() > 0 then m.top.event = { action: "toast", text: L("No se pudo cargar: {n}").Replace("{n}", errs.Join(", ")) }
    m.top.event = { action: "channels" }
    if m.pendingPlay <> invalid
        key = m.pendingPlay
        m.pendingPlay = invalid
        Live_PlayKey(key)
    else
        Live_StartLast()
    end if
end sub

sub onEpgDone(event as object)
    task = event.getRoSGNode()
    if m.loadTask = invalid or not task.isSameNode(m.loadTask) then return
    m.loadTask = invalid
    m.epgLoading = false
    m.epgReady = true
    m.epgText = ""
    r = task.result
    m.top.event = { action: "epg" }
    m.guide = {}
    m.guideAsked = {}
    if r <> invalid and type(r.failed) = "roArray" and r.failed.Count() > 0 and ToInt(r.count, 0) = 0 then m.top.event = { action: "toast", text: L("No se pudo cargar la guía. Si es un archivo .gz, usa la versión .xml.") }
    onClockTimer()
    Live_AskGuide()
    Live_Render()
end sub

sub onEpgProgress(event as object)
    task = event.getRoSGNode()
    if m.loadTask = invalid or not task.isSameNode(m.loadTask) then return
    pr = task.progress
    if pr = invalid then return
    m.epgAt = Live_Now()
    stepName = Str_Of(pr.step)
    if stepName = "ready"
        m.epgReady = true
        m.guide = {}
        m.guideAsked = {}
        Live_AskGuide()
        return
    end if
    n = ToInt(pr.n, 1)
    part = ""
    if n > 1 then part = " " + ToInt(pr.i, 1).ToStr() + "/" + n.ToStr()
    size = "..."
    if ToInt(pr.mb, 0) > 0 then size = " · " + ToInt(pr.mb, 0).ToStr() + " MB"
    if stepName = "get"
        m.epgText = L("Descargando guía") + part + size
    else if stepName = "unzip"
        m.epgText = L("Abriendo guía") + part + size
    else if stepName = "read"
        m.epgText = L("Leyendo guía") + part + " · " + ToInt(pr.pct, 0).ToStr() + "%"
    end if
    Live_ClockText()
end sub

sub Live_ClockText()
    if m.epgLoading and m.epgAt > 0 and Live_Now() - m.epgAt > 600
        m.epgLoading = false
        m.epgReady = true
        m.epgText = ""
        m.top.event = { action: "toast", text: L("La guía tardó demasiado en cargar. Revisa el enlace en Ajustes → TV en vivo.") }
    end if
    if m.epgLoading and m.epgText <> ""
        m.topStatus.text = m.epgText
    else if m.epgLoading
        m.topStatus.text = L("Cargando guía...")
    else
        m.topStatus.text = ""
    end if
    m.clock.text = Fmt_Clock(Live_LocalNow())
end sub

sub Live_ClampTop()
    if m.sel < m.top0 then m.top0 = m.sel
    if m.sel > m.top0 + m.nRows - 1 then m.top0 = m.sel - m.nRows + 1
    if m.top0 > m.view.Count() - m.nRows then m.top0 = m.view.Count() - m.nRows
    if m.top0 < 0 then m.top0 = 0
end sub

function Live_Chan(viewPos as integer) as dynamic
    if viewPos < 0 or viewPos >= m.view.Count() then return invalid
    return m.all[m.view[viewPos]]
end function

function Live_Eid(c as object) as string
    e = Str_Of(c.e)
    if e = "" then e = Str_Of(c.n)
    return LCase(e)
end function

sub Live_AskGuide()
    if not m.loaded then return
    if m.epgLoading and not m.epgReady then return
    if m.guideTask <> invalid
        m.guideAgain = true
        return
    end if
    ids = []
    first = m.top0 - 6
    if first < 0 then first = 0
    last = m.top0 + m.nRows + 12
    if m.mode = "watch" and Bool_Of(m.ovOpen, false)
        first = ToInt(m.ovTop, 0) - 4
        if first < 0 then first = 0
        last = ToInt(m.ovTop, 0) + 14
    end if
    for i = first to last
        c = Live_Chan(i)
        if c <> invalid
            e = Live_Eid(c)
            if e <> "" and not m.guideAsked.DoesExist(e)
                m.guideAsked[e] = true
                ids.Push(e)
            end if
        end if
    end for
    if m.mode = "watch" and m.playingKey <> "" and m.keyIndex <> invalid and m.keyIndex.DoesExist(m.playingKey)
        e = Live_Eid(m.all[m.keyIndex[m.playingKey]])
        if not m.guideAsked.DoesExist(e)
            m.guideAsked[e] = true
            ids.Push(e)
        end if
    end if
    if ids.Count() = 0 then return
    m.guideTask = CreateObject("roSGNode", "IptvTask")
    m.guideTask.mode = "guide"
    m.guideTask.params = { ids: ids, shift: ToInt(m.prefs.epgShift, 0) * 60 }
    m.guideTask.observeField("result", "onGuide")
    m.guideTask.control = "RUN"
end sub

sub onGuide(event as object)
    task = event.getRoSGNode()
    if m.guideTask = invalid or not task.isSameNode(m.guideTask) then return
    m.guideTask = invalid
    r = task.result
    if r <> invalid and type(r.guide) = "roAssociativeArray"
        for each k in r.guide
            m.guide[k] = r.guide[k]
        end for
    end if
    Live_Render()
    if m.mode = "watch"
        Watch_Paint()
        if Bool_Of(m.ovOpen, false) then Overlay_Render()
    end if
    if Bool_Of(m.guideAgain, false)
        m.guideAgain = false
        Live_AskGuide()
    end if
end sub

function Live_Progs(c as object) as dynamic
    return m.guide[Live_Eid(c)]
end function

function Live_At(c as object, t as integer) as dynamic
    progs = Live_Progs(c)
    if type(progs) <> "roArray" then return invalid
    for each pr in progs
        if pr.a <= t and pr.b > t then return pr
    end for
    return invalid
end function

function Live_After(c as object, t as integer) as dynamic
    progs = Live_Progs(c)
    if type(progs) <> "roArray" then return invalid
    for each pr in progs
        if pr.a >= t then return pr
    end for
    return invalid
end function

function Live_Cells(c as object) as object
    winA = m.winStart
    winB = winA + m.win
    out = []
    progs = Live_Progs(c)
    t = winA
    if type(progs) = "roArray"
        for each pr in progs
            if pr.b > winA and pr.a < winB
                if pr.a > t then out.Push({ a: t, b: pr.a, gap: true })
                out.Push({ a: pr.a, b: pr.b, t: pr.t, d: pr.d, i: pr.i, c: pr.c, e: pr.e, gap: false })
                t = pr.b
            end if
        end for
    end if
    if t < winB then out.Push({ a: t, b: winB, gap: true })
    return out
end function

function Live_FocusCell(cells as object) as integer
    for i = 0 to cells.Count() - 1
        if cells[i].a <= m.focusT and cells[i].b > m.focusT then return i
    end for
    if cells.Count() > 0 then return 0
    return -1
end function

sub Live_BuildRows()
    m.rows.removeChildrenIndex(m.rows.getChildCount(), 0)
    spec = m.spec
    m.rowNodes = []
    nameLines = 1
    if Bool_Of(m.prefs.twoLine, false) then nameLines = 2
    for r = 0 to m.nRows - 1
        g = m.rows.createChild("Group")
        g.translation = [112, m.rowY0 + r * m.rowStep]
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/focus_ring.9.png"
        ring.translation = [-5, -5]
        ring.width = m.cw + 10
        ring.height = m.rowH + 10
        ring.blendColor = "0xE53935FF"
        ring.visible = false
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/card.9.png"
        bg.width = m.cw
        bg.height = m.rowH
        bg.blendColor = "0x16161BFF"
        num = g.createChild("Label")
        num.translation = [m.colNum, 0]
        num.width = 52
        num.height = m.rowH
        num.vertAlign = "center"
        num.horizAlign = "right"
        Iptv_SetFont(num, spec.num, true)
        num.color = "0x8E8E9CFF"
        num.visible = m.colNum >= 0
        logo = g.createChild("Poster")
        logo.translation = [m.colLogo, Int((m.rowH - spec.logoH) / 2)]
        logo.width = spec.logoW
        logo.height = spec.logoH
        logo.loadWidth = spec.logoW * 2
        logo.loadHeight = spec.logoH * 2
        logo.loadDisplayMode = "scaleToFit"
        logo.visible = m.colLogo >= 0
        name = g.createChild("Label")
        name.translation = [m.colName, 0]
        name.width = spec.nameW
        name.height = m.rowH
        name.vertAlign = "center"
        name.maxLines = nameLines
        name.wrap = nameLines > 1
        Iptv_SetFont(name, spec.name, false)
        name.color = "0xE5E5EEFF"
        name.visible = m.colName >= 0
        star = g.createChild("Poster")
        star.translation = [m.cw - 26, 6]
        star.width = 18
        star.height = 18
        star.uri = "pkg:/images/ic_star.png"
        star.blendColor = "0xFFC94DFF"
        cellsG = g.createChild("Group")
        cellsG.translation = [m.gx0 - 112, 0]
        m.rowNodes.Push({ g: g, ring: ring, bg: bg, logo: logo, num: num, name: name, star: star, cellsG: cellsG, cells: [] })
    end for
end sub

function Live_CellNode(row as object, idx as integer) as object
    spec = m.spec
    while row.cells.Count() <= idx
        g = row.cellsG.createChild("Group")
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/card.9.png"
        bg.height = m.rowH
        title = g.createChild("Label")
        title.maxLines = 1
        Iptv_SetFont(title, spec.title, true)
        tm = g.createChild("Label")
        tm.maxLines = 1
        Iptv_SetFont(tm, spec.time, false)
        if Bool_Of(m.prefs.times, true)
            gap = Int((m.rowH - spec.title - spec.time - 14) / 2)
            if gap < 2 then gap = 2
            title.translation = [16, gap]
            title.height = spec.title + 8
            title.vertAlign = "center"
            tm.translation = [16, gap + spec.title + 8]
            tm.height = spec.time + 6
        else
            title.translation = [16, 0]
            title.height = m.rowH
            title.vertAlign = "center"
            tm.visible = false
        end if
        bell = g.createChild("Poster")
        bell.uri = "pkg:/images/ic_bell.png"
        bell.width = 20
        bell.height = 20
        bell.visible = false
        row.cells.Push({ g: g, bg: bg, title: title, tm: tm, bell: bell, ty: title.translation[1], th: title.height })
    end while
    return row.cells[idx]
end function

function Live_Clock(t as integer) as string
    d = CreateObject("roDateTime")
    d.FromSeconds(t)
    d.ToLocalTime()
    return Fmt_Clock(d)
end function

function Live_Span(a as integer, b as integer) as string
    return Live_Clock(a) + " – " + Live_Clock(b)
end function

function Live_DayWord(t as integer) as string
    d = CreateObject("roDateTime")
    d.FromSeconds(t)
    d.ToLocalTime()
    today = CreateObject("roDateTime")
    today.ToLocalTime()
    if d.GetDayOfMonth() = today.GetDayOfMonth() then return L("Hoy")
    tomorrow = CreateObject("roDateTime")
    tomorrow.FromSeconds(today.AsSeconds() + 86400)
    if d.GetDayOfMonth() = tomorrow.GetDayOfMonth() then return L("Mañana")
    return L("Ayer")
end function

sub Live_Render()
    Live_RenderTop()
    Live_RenderTimes()
    now = Live_Now()
    showTimes = Bool_Of(m.prefs.times, true)
    for r = 0 to m.nRows - 1
        row = m.rowNodes[r]
        vp = m.top0 + r
        c = Live_Chan(vp)
        if c = invalid
            row.g.visible = false
        else
            row.g.visible = true
            focusedRow = m.zone = "grid" and vp = m.sel
            if m.colLogo >= 0 then row.logo.uri = Str_Of(c.l)
            row.num.text = Live_Number(vp)
            row.name.text = Live_Name(c)
            row.star.visible = m.favs.DoesExist(c.k)
            row.ring.visible = c.k = m.playingKey and Bool_Of(m.prefs.markPlaying, true)
            if focusedRow
                row.bg.blendColor = "0x2C2C36FF"
                row.name.color = "0xFFFFFFFF"
            else
                row.bg.blendColor = "0x16161BFF"
                row.name.color = "0xD6D6E0FF"
            end if
            cells = Live_Cells(c)
            fi = -1
            if focusedRow then fi = Live_FocusCell(cells)
            for i = 0 to cells.Count() - 1
                cell = cells[i]
                node = Live_CellNode(row, i)
                a = cell.a
                if a < m.winStart then a = m.winStart
                b = cell.b
                if b > m.winStart + m.win then b = m.winStart + m.win
                x = Int((a - m.winStart) * m.pps)
                w = Int((b - m.winStart) * m.pps) - x - 6
                if w < 6 then w = 6
                node.g.visible = true
                node.g.translation = [x, 0]
                node.bg.width = w
                reminded = not cell.gap and m.remind.DoesExist(c.k + "|" + cell.a.ToStr())
                node.bell.visible = reminded and w > 60
                node.bell.translation = [w - 32, 10]
                if reminded then node.title.width = w - 64 else node.title.width = w - 28
                node.tm.width = w - 28
                showText = w > 56
                node.title.visible = showText
                node.tm.visible = showText and showTimes and w > 120
                if cell.gap
                    if type(Live_Progs(c)) = "roArray" then node.title.text = L("Sin información") else node.title.text = Live_Name(c)
                    node.tm.text = ""
                    node.title.translation = [16, 0]
                    node.title.height = m.rowH
                else
                    node.title.translation = [16, node.ty]
                    node.title.height = node.th
                    node.title.text = Str_Of(cell.t)
                    node.tm.text = Live_Span(cell.a, cell.b)
                end if
                if i = fi
                    node.bell.blendColor = "0x111114FF"
                else
                    node.bell.blendColor = "0xFFC94DFF"
                end if
                if i = fi
                    node.bg.blendColor = "0xF2F2F7FF"
                    node.title.color = "0x111114FF"
                    node.tm.color = "0x3A3A44FF"
                else if not cell.gap and cell.a <= now and cell.b > now
                    node.bg.blendColor = "0x24242DFF"
                    node.title.color = "0xFFFFFFFF"
                    node.tm.color = "0xA9A9B8FF"
                else
                    node.bg.blendColor = "0x18181EFF"
                    node.title.color = "0xC9C9D6FF"
                    node.tm.color = "0x80808EFF"
                end if
            end for
            for i = cells.Count() to row.cells.Count() - 1
                row.cells[i].g.visible = false
            end for
        end if
    end for
    if Bool_Of(m.prefs.nowLine, true) and now >= m.winStart and now < m.winStart + m.win and m.view.Count() > 0
        shown = m.view.Count() - m.top0
        if shown > m.nRows then shown = m.nRows
        x = m.gx0 + Int((now - m.winStart) * m.pps) - 1
        m.nowLine.visible = true
        m.nowLine.height = shown * m.rowStep + 8
        m.nowLine.translation = [x, m.rowY0 - 12]
        m.nowDot.visible = true
        m.nowDot.translation = [x - 5, m.rowY0 - 20]
    else
        m.nowLine.visible = false
        m.nowDot.visible = false
    end if
    Live_RenderInfo()
end sub

sub Live_RenderTop()
    gl = ""
    if m.groups.Count() > m.groupIdx then gl = Str_Of(m.groups[m.groupIdx].label)
    tw = m.topTitle.boundingRect().width
    if tw < 40 then tw = 210
    m.topGroup.translation = [112 + tw + 18, 26]
    if gl <> "" then m.topGroup.text = "·   " + gl else m.topGroup.text = ""
end sub

sub Live_RenderTimes()
    if m.timeLabels = invalid
        m.timeLabels = []
        for k = 0 to 3
            lb = m.times.createChild("Label")
            lb.translation = [m.gx0 + Int(k * 1800 * m.pps) + 10, 440]
            lb.height = 44
            lb.width = 300
            lb.vertAlign = "center"
            Iptv_SetFont(lb, 24, true)
            lb.color = "0xA9A9B8FF"
            tick = m.times.createChild("Rectangle")
            tick.translation = [m.gx0 + Int(k * 1800 * m.pps), 448]
            tick.width = 2
            tick.height = 28
            tick.color = "0x34343FFF"
            m.timeLabels.Push(lb)
        end for
    end if
    for k = 0 to 3
        m.timeLabels[k].text = Live_Clock(m.winStart + k * 1800)
    end for
    m.dayLabel.text = Live_DayWord(m.winStart)
end sub

function Live_Left(b as integer, now as integer) as string
    mins = Int((b - now + 59) / 60)
    if mins >= 60
        h = Int(mins / 60)
        mm = mins mod 60
        if mm = 0 then return L("Quedan {h} h").Replace("{h}", h.ToStr())
        return L("Quedan {h} h {m} min").Replace("{h}", h.ToStr()).Replace("{m}", mm.ToStr())
    end if
    return L("Quedan {n} min").Replace("{n}", mins.ToStr())
end function

sub Live_RenderInfo()
    c = Live_Chan(m.sel)
    if c = invalid
        m.infoTitle.text = ""
        m.infoLine.text = ""
        m.infoDesc.text = ""
        m.chLine.text = ""
        m.artLogo.uri = ""
        m.artImg.uri = ""
        m.liveBadge.visible = false
        m.liveText.visible = false
        m.infoTrack.visible = false
        m.infoBar.visible = false
        return
    end if
    now = Live_Now()
    cell = invalid
    cells = Live_Cells(c)
    fi = Live_FocusCell(cells)
    if fi >= 0 then cell = cells[fi]
    name = Live_Name(c)
    head = Live_Number(m.sel) + "   " + name
    if Str_Of(c.g) <> "" then head = head + "  ·  " + Str_Of(c.g)
    m.chLine.width = 0
    m.chLine.text = head
    cw = m.chLine.boundingRect().width
    if cw > m.infoW - 140
        cw = m.infoW - 140
        m.chLine.width = cw
    end if
    icon = ""
    if cell = invalid or cell.gap
        m.infoTitle.text = name
        isLive = cell <> invalid and cell.a <= now and cell.b > now
        m.infoLine.text = ""
        if type(Live_Progs(c)) = "roArray" then m.infoDesc.text = L("Sin información del programa.") else m.infoDesc.text = L("Este canal no tiene guía.")
        m.infoTrack.visible = false
        m.infoBar.visible = false
    else
        isLive = cell.a <= now and cell.b > now
        m.infoTitle.text = Str_Of(cell.t)
        meta = [Live_DayWord(cell.a) + "  " + Live_Span(cell.a, cell.b)]
        if isLive then meta.Push(Live_Left(cell.b, now))
        if Str_Of(cell.e) <> "" then meta.Push(Str_Of(cell.e))
        if Str_Of(cell.c) <> "" then meta.Push(Str_Of(cell.c))
        m.infoLine.text = meta.Join("   ·   ")
        m.infoDesc.text = Str_Of(cell.d)
        icon = Str_Of(cell.i)
        if isLive
            m.infoTrack.visible = true
            m.infoBar.visible = true
            m.infoBar.width = Int(m.infoW * (now - cell.a) / (cell.b - cell.a))
        else
            m.infoTrack.visible = false
            m.infoBar.visible = false
        end if
    end if
    fromEpg = false
    if cell <> invalid and not cell.gap
        art = Live_ArtFor(Str_Of(cell.t), name)
        if art <> invalid and Str_Of(art.p) <> ""
            icon = Str_Of(art.p)
        else if icon <> ""
            fromEpg = true
        end if
    end if
    if icon <> "" and m.artBad.DoesExist(icon) then icon = ""
    m.artLogo.uri = Str_Of(c.l)
    if icon <> ""
        m.artEpg = fromEpg
        if fromEpg then m.artImg.loadDisplayMode = "scaleToFit" else m.artImg.loadDisplayMode = "scaleToZoom"
        if m.artImg.uri <> icon then m.artImg.uri = icon
        m.artImg.visible = true
        m.artLogo.visible = false
        if fromEpg and m.artImg.loadStatus = "ready" then onArtImg()
    else
        m.artImg.uri = ""
        m.artImg.visible = false
        m.artLogo.visible = true
        m.artLogo.uri = Str_Of(c.l)
    end if
    m.liveBadge.visible = isLive
    m.liveText.visible = isLive
    m.liveBadge.translation = [348 + cw + 18, 116]
    m.liveText.translation = [348 + cw + 18, 116]
end sub

sub onClockTimer()
    Live_ClockText()
    if m.mode = "watch"
        Watch_Paint()
        if Bool_Of(m.ovOpen, false) then Overlay_Render()
    end if
    if m.top.active and m.mode = "guide" and m.loaded then Live_Render()
end sub

function Live_LocalNow() as object
    d = CreateObject("roDateTime")
    d.ToLocalTime()
    return d
end function

sub Live_SchedulePreview()
    m.previewTimer.control = "stop"
    if m.mode <> "guide" or m.zone <> "grid" or not Bool_Of(m.prefs.preview, true) then return
    m.previewTimer.control = "start"
end sub

sub onPreviewTimer()
    if m.mode <> "guide" or m.zone <> "grid" or not m.top.active or not Bool_Of(m.prefs.preview, true) then return
    c = Live_Chan(m.sel)
    if c = invalid then return
    if c.k = m.playingKey then return
    Live_PlayChannel(c, true)
end sub

sub Live_PlayChannel(c as object, preview as boolean)
    m.altFails = 0
    m.reconnects = 0
    Live_PlayAlt(c, 0)
end sub

function Live_Alts(c as object) as object
    if type(c.a) = "roArray" and c.a.Count() > 0 then return c.a
    return [{ u: Str_Of(c.u), n: Str_Of(c.n) }]
end function

sub Live_PlayAlt(c as object, idx as integer)
    alts = Live_Alts(c)
    if idx < 0 or idx >= alts.Count() then idx = 0
    if m.playingKey <> "" and m.playingKey <> c.k and m.mode = "watch" then m.prevKey = m.playingKey
    m.playingKey = c.k
    m.altIdx = idx
    m.attempt = 0
    m.tracksApplied = false
    Live_StartUrl(Iptv_PlayUrlUi(Str_Of(alts[idx].u)), Live_Name(c))
    if m.video.hasField("mute") then m.video.mute = false
end sub

function Iptv_PlayUrlUi(url as string) as string
    u = url.Trim()
    low = LCase(u)
    q = Instr(1, low, "?")
    path = low
    if q > 0 then path = Left(low, q - 1)
    if Right(path, 3) = ".ts" then return Left(u, Len(path) - 3) + ".m3u8" + Mid(u, Len(path) + 1)
    return u
end function

sub Live_StartUrl(url as string, title as string)
    content = CreateObject("roSGNode", "ContentNode")
    content.url = url
    content.title = title
    content.live = true
    low = LCase(url)
    if Instr(1, low, ".mp4") > 0
        content.streamFormat = "mp4"
    else if Instr(1, low, ".mpd") > 0
        content.streamFormat = "dash"
    else if Instr(1, low, ".m3u8") > 0 or Instr(1, low, ".ts") = 0
        content.streamFormat = "hls"
    end if
    content.HttpHeaders = ["User-Agent: VLC/3.0.20 LibVLC/3.0.20"]
    m.video.control = "stop"
    m.video.content = content
    m.video.control = "play"
    m.video.visible = true
    m.previewHint.visible = false
    m.lastPos = -1
    m.frozen = 0
    m.buffering = 0
    m.watchdog.control = "start"
end sub

sub Live_StopVideo()
    m.video.control = "stop"
    m.video.content = invalid
    m.playingKey = ""
    m.watchdog.control = "stop"
    m.retryTimer.control = "stop"
    m.previewHint.visible = Bool_Of(m.prefs.preview, true)
end sub

function Live_PlayingChan() as dynamic
    if m.playingKey = "" or m.keyIndex = invalid or not m.keyIndex.DoesExist(m.playingKey) then return invalid
    return m.all[m.keyIndex[m.playingKey]]
end function

sub onVideoState()
    st = m.video.state
    if st = "error" or (st = "finished" and m.playingKey <> "")
        Live_Trouble(st = "error")
    else if st = "playing"
        m.video.visible = true
        m.buffering = 0
        Live_ApplyTracks()
        if m.mode = "watch"
            m.watchMsg.text = ""
            Watch_Paint()
        end if
    end if
end sub

sub Live_Trouble(isError as boolean)
    c = Live_PlayingChan()
    if c = invalid then return
    alts = Live_Alts(c)
    idx = ToInt(m.altIdx, 0)
    if idx >= alts.Count() then idx = 0
    m.attempt = ToInt(m.attempt, 0) + 1
    alt = Str_Of(alts[idx].u)
    if isError and m.attempt = 1 and alt <> Iptv_PlayUrlUi(alt)
        Live_StartUrl(alt, Live_Name(c))
        return
    end if
    now = Live_Now()
    if now - m.reconnectAt > 90 then m.reconnects = 0
    if Bool_Of(m.prefs.reconnect, true) and m.reconnects < 2
        m.reconnects = m.reconnects + 1
        m.reconnectAt = now
        if m.mode = "watch"
            m.watchMsg.text = L("Reconectando...")
            Watch_ShowBar()
        end if
        m.retryTimer.control = "stop"
        m.retryTimer.control = "start"
        return
    end if
    if m.mode = "watch" and Bool_Of(m.prefs.backup, true) and alts.Count() > 1 and ToInt(m.altFails, 0) < alts.Count() - 1
        m.altFails = ToInt(m.altFails, 0) + 1
        m.reconnects = 0
        Live_PlayAlt(c, (idx + 1) mod alts.Count())
        m.watchMsg.text = ""
        Watch_ShowBar()
        return
    end if
    m.watchdog.control = "stop"
    if m.mode = "watch"
        Watch_Error()
    else
        m.previewHint.visible = true
        m.previewHint.text = L("No se pudo reproducir este canal.")
        m.video.visible = false
    end if
end sub

sub onRetryTimer()
    c = Live_PlayingChan()
    if c = invalid then return
    keep = m.reconnects
    Live_PlayAlt(c, ToInt(m.altIdx, 0))
    m.reconnects = keep
end sub

sub onWatchdog()
    if m.playingKey = "" or m.video.content = invalid then return
    st = m.video.state
    if st = "buffering"
        m.buffering = ToInt(m.buffering, 0) + 1
        if m.buffering >= 6
            m.buffering = 0
            Live_Trouble(false)
        end if
    else if st = "playing"
        m.buffering = 0
        vpos = m.video.position
        if vpos = m.lastPos
            m.frozen = ToInt(m.frozen, 0) + 1
            if m.frozen >= 4
                m.frozen = 0
                Live_Trouble(false)
            end if
        else
            m.frozen = 0
        end if
        m.lastPos = vpos
    end if
end sub

sub Live_ApplyTracks()
    if Bool_Of(m.tracksApplied, false) or not Bool_Of(m.prefs.rememberTracks, true) then return
    m.tracksApplied = true
    mem = m.trackMemory[m.playingKey]
    if type(mem) <> "roAssociativeArray" then return
    lang = Str_Of(mem.audio)
    if lang <> ""
        tracks = m.video.availableAudioTracks
        if type(tracks) = "roArray"
            for each t in tracks
                if Str_Of(t.Language) = lang or Str_Of(t.Name) = lang
                    m.video.audioTrack = Str_Of(t.Track)
                    exit for
                end if
            end for
        end if
    end if
    sub1 = Str_Of(mem.subs)
    if sub1 = "off"
        m.video.globalCaptionMode = "Off"
    else if sub1 <> ""
        tracks = m.video.availableSubtitleTracks
        if type(tracks) = "roArray"
            for each t in tracks
                if Str_Of(t.Language) = sub1 or Str_Of(t.Description) = sub1
                    m.video.globalCaptionMode = "On"
                    m.video.subtitleTrack = Str_Of(t.TrackName)
                    exit for
                end if
            end for
        end if
    end if
end sub

sub Live_RememberTrack(kind as string, value as string)
    if m.playingKey = "" or not Bool_Of(m.prefs.rememberTracks, true) then return
    mem = m.trackMemory[m.playingKey]
    if type(mem) <> "roAssociativeArray" then mem = {}
    mem[kind] = value
    m.trackMemory[m.playingKey] = mem
    Iptv_SaveStore("Tracks", m.trackMemory)
end sub

sub Live_PlayKey(key as string)
    if not m.loaded
        m.pendingPlay = key
        if not m.loading then Live_Load(false)
        return
    end if
    if m.keyIndex = invalid or not m.keyIndex.DoesExist(key) then return
    idx = m.keyIndex[key]
    vp = -1
    for i = 0 to m.view.Count() - 1
        if m.view[i] = idx then vp = i
    end for
    if vp < 0
        m.groupIdx = Groups_Find("all")
        Live_ApplyGroup(false)
        for i = 0 to m.view.Count() - 1
            if m.view[i] = idx then vp = i
        end for
    end if
    if vp < 0 then return
    m.sel = vp
    m.zone = "grid"
    Live_ClampTop()
    Live_ResetWindow()
    Live_AskGuide()
    Live_Render()
    Watch_Start()
end sub

sub onCommand()
    cmd = m.top.command
    if cmd = invalid then return
    action = Str_Of(cmd.action)
    key = Str_Of(cmd.key)
    if action = "fav"
        Live_FavToggle(key)
        Live_BuildGroups()
        Live_ApplyGroup(false)
        if m.mode = "watch" then Watch_Paint()
        m.top.event = { action: "channels" }
    else if action = "play"
        Live_PlayKey(key)
    else if action = "refresh"
        onReload()
    else if action = "audio"
        m.video.audioTrack = Str_Of(cmd.track)
        tracks = m.video.availableAudioTracks
        if type(tracks) = "roArray"
            for each t in tracks
                if Str_Of(t.Track) = Str_Of(cmd.track)
                    lang = Str_Of(t.Language)
                    if lang = "" then lang = Str_Of(t.Name)
                    Live_RememberTrack("audio", lang)
                end if
            end for
        end if
    else if action = "captions"
        m.video.globalCaptionMode = Str_Of(cmd.mode)
        di = CreateObject("roDeviceInfo")
        if Str_Of(cmd.mode) = "On" or Str_Of(di.GetCaptionsMode()) = "On" then di.SetCaptionsMode(Str_Of(cmd.mode))
        if Str_Of(cmd.track) <> "" then m.video.subtitleTrack = Str_Of(cmd.track)
        if Str_Of(cmd.mode) = "Off"
            Live_RememberTrack("subs", "off")
        else
            tracks = m.video.availableSubtitleTracks
            if type(tracks) = "roArray"
                for each t in tracks
                    if Str_Of(t.TrackName) = Str_Of(cmd.track)
                        lang = Str_Of(t.Language)
                        if lang = "" then lang = Str_Of(t.Description)
                        Live_RememberTrack("subs", lang)
                    end if
                end for
            end if
        end if
    else if action = "focus"
        if m.mode = "watch" then Watch_Paint()
    else if action = "prefs"
        old = Str_Of(m.prefs.epgShift)
        Live_PrefsLoad()
        Live_Layout()
        if old <> Str_Of(m.prefs.epgShift)
            m.guide = {}
            m.guideAsked = {}
        end if
        if m.loaded
            Live_BuildGroups()
            Live_ApplyGroup(false)
        end if
        m.barTimer.duration = Watch_BarSecs()
    else if action = "rename"
        names = Iptv_Store("Names")
        nm = Str_Of(cmd.name).Trim()
        if nm = "" then names.Delete(key) else names[key] = nm
        Iptv_SaveStore("Names", names)
        m.names = names
        Live_Render()
        if m.mode = "watch" then Watch_Paint()
        m.top.event = { action: "channels" }
    else if action = "hide"
        hid = Iptv_Store("Hidden")
        if hid.DoesExist(key) then hid.Delete(key) else hid[key] = true
        Iptv_SaveStore("Hidden", hid)
        m.hidden = hid
        Live_BuildGroups()
        Live_ApplyGroup(false)
    else if action = "unhideAll"
        Iptv_SaveStore("Hidden", {})
        Iptv_SaveStore("HiddenGroups", {})
        m.hidden = {}
        m.hiddenGroups = {}
        Live_BuildGroups()
        Live_ApplyGroup(false)
    else if action = "group"
        Groups_Command(cmd)
    else if action = "reminders"
        m.remind = Iptv_ReminderMap()
        Live_Render()
    else if action = "previous"
        if m.mode = "watch" then Watch_Previous()
    else if action = "unlock"
        m.unlocked[Str_Of(cmd.group)] = true
        Groups_Pick(Groups_FindLabel(Str_Of(cmd.group)))
    end if
end sub

function Live_HomeData(arg = invalid as dynamic) as object
    out = { recent: [], favs: [] }
    if Live_ProfileChanged() then return out
    if not m.loaded or m.keyIndex = invalid then return out
    now = Live_Now()
    for each k in Live_Recent()
        if m.keyIndex.DoesExist(k) and not m.hidden.DoesExist(k) then out.recent.Push(Live_HomeItem(m.all[m.keyIndex[k]], now))
    end for
    for each k in m.favOrder
        if m.keyIndex.DoesExist(k) and not m.hidden.DoesExist(k) then out.favs.Push(Live_HomeItem(m.all[m.keyIndex[k]], now))
    end for
    return out
end function

function Live_HomeItem(c as object, now as integer) as object
    pr = Live_At(c, now)
    item = { k: c.k, n: Live_Name(c), l: Str_Of(c.l), g: Str_Of(c.g), now: "", d: "", pct: -1, left: "", next: "", num: m.keyIndex[c.k] + 1 }
    if pr <> invalid
        item.now = Str_Of(pr.t)
        item.d = Str_Of(pr.d)
        span = pr.b - pr.a
        if span < 1 then span = 1
        item.pct = Int(100 * (now - pr.a) / span)
        item.left = Live_Left(pr.b, now)
        nx = Live_After(c, pr.b)
        if nx <> invalid then item.next = Live_Clock(nx.a) + "  " + Str_Of(nx.t)
        art = Live_ArtFor(Str_Of(pr.t), Live_Name(c))
        if art <> invalid and Str_Of(art.p) <> ""
            item.art = Str_Of(art.p)
            item.backdrop = Str_Of(art.b)
        else if Str_Of(pr.i) <> "" and not m.artBad.DoesExist(Str_Of(pr.i))
            item.art = Str_Of(pr.i)
        end if
    end if
    return item
end function

function Live_Options() as object
    c = invalid
    if m.mode = "watch" then c = Live_PlayingChan() else c = Live_Chan(m.sel)
    grp = ""
    if m.groups.Count() > m.groupIdx then grp = Str_Of(m.groups[m.groupIdx].label)
    if c = invalid then return { action: "options", key: "", name: "", fav: false, watch: false, group: grp }
    audio = []
    subs = []
    if m.mode = "watch"
        tracks = m.video.availableAudioTracks
        if type(tracks) = "roArray"
            for each t in tracks
                label = Str_Of(t.Name)
                if label = "" then label = Str_Of(t.Language)
                if label = "" then label = Str_Of(t.Track)
                audio.Push({ id: Str_Of(t.Track), label: label })
            end for
        end if
        tracks = m.video.availableSubtitleTracks
        if type(tracks) = "roArray"
            for each t in tracks
                label = Str_Of(t.Description)
                if label = "" then label = Str_Of(t.Language)
                subs.Push({ id: Str_Of(t.TrackName), label: label })
            end for
        end if
    end if
    return { action: "options", key: c.k, name: Live_Name(c), original: Str_Of(c.n), renamed: m.names.DoesExist(c.k), fav: m.favs.DoesExist(c.k), hidden: m.hidden.DoesExist(c.k), watch: m.mode = "watch", audio: audio, subs: subs, captions: m.video.globalCaptionMode, group: Str_Of(c.g), alts: Live_Alts(c).Count(), prev: m.prevKey <> "" }
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "options" then Dbg_Log("live key options mode=" + m.mode + " zone=" + m.zone + " ov=" + Bool_Of(m.ovOpen, false).ToStr())
    if m.zone = "groups" then return Groups_Key(key)
    if m.mode = "watch" then return Watch_Key(key)
    if key = "options"
        if m.loaded then m.top.event = Live_Options()
        return true
    end if
    return Live_GridKey(key)
end function

function Live_GridKey(key as string) as boolean
    c = Live_Chan(m.sel)
    if c = invalid
        if key = "left"
            Groups_Open()
            return true
        end if
        if key = "back"
            m.top.event = { action: "nav" }
            return true
        end if
        return true
    end if
    cells = Live_Cells(c)
    fi = Live_FocusCell(cells)
    if key = "up" or key = "down"
        stepBy = 1
        if key = "up" then stepBy = -1
        n = m.view.Count()
        m.sel = m.sel + stepBy
        if m.sel < 0 then m.sel = n - 1
        if m.sel >= n then m.sel = 0
        Live_ClampTop()
        Live_AskGuide()
        Live_SchedulePreview()
        Live_Render()
        return true
    else if key = "rewind" or key = "fastforward"
        jump = m.nRows
        if key = "rewind" then jump = -jump
        m.sel = m.sel + jump
        if m.sel < 0 then m.sel = 0
        if m.sel > m.view.Count() - 1 then m.sel = m.view.Count() - 1
        Live_ClampTop()
        Live_AskGuide()
        Live_SchedulePreview()
        Live_Render()
        return true
    else if key = "right"
        if fi >= 0
            cell = cells[fi]
            if cell.b < m.winStart + m.win and fi + 1 < cells.Count()
                m.focusT = cells[fi + 1].a
            else if m.winStart < Live_Now() + 79200
                m.winStart = m.winStart + 1800
                if cell.b <= m.winStart + m.win and cell.b > m.focusT then m.focusT = cell.b
                if m.focusT < m.winStart then m.focusT = m.winStart
            end if
            Live_Render()
        end if
        return true
    else if key = "left"
        base = Live_Now() - (Live_Now() mod 1800)
        if fi > 0 and cells[fi].a > m.winStart
            prev = cells[fi - 1]
            m.focusT = prev.a
            if m.focusT < m.winStart then m.focusT = m.winStart
            if m.focusT < Live_Now() and prev.b > Live_Now() then m.focusT = Live_Now()
            Live_Render()
        else if m.winStart > base
            m.winStart = m.winStart - 1800
            if fi >= 0 and cells[fi].a < m.winStart + m.win and cells[fi].a >= m.winStart then m.focusT = cells[fi].a
            if m.focusT >= m.winStart + m.win then m.focusT = m.winStart + m.win - 1
            if m.focusT < m.winStart + 1 and fi >= 0 and cells[fi].a < m.winStart then m.focusT = m.winStart
            if m.winStart = base and m.focusT < Live_Now() then m.focusT = Live_Now()
            Live_Render()
        else
            Groups_Open()
        end if
        return true
    else if key = "OK" or key = "play"
        now = Live_Now()
        if key = "OK" and fi >= 0 and not cells[fi].gap and cells[fi].a > now
            cell = cells[fi]
            m.top.event = { action: "remind", key: c.k, channel: Live_Name(c), logo: Str_Of(c.l), title: Str_Of(cell.t), a: cell.a, b: cell.b, set: m.remind.DoesExist(c.k + "|" + cell.a.ToStr()) }
            return true
        end if
        Watch_Start()
        return true
    else if key = "back"
        if m.winStart > Live_Now() - (Live_Now() mod 1800)
            Live_ResetWindow()
            Live_Render()
        else
            m.top.event = { action: "nav" }
        end if
        return true
    end if
    return false
end function

sub onArtImg()
    st = m.artImg.loadStatus
    if not m.artEpg or m.artImg.uri = "" then return
    bad = st = "failed"
    if st = "ready" and m.artImg.bitmapWidth > 0 and m.artImg.bitmapWidth * 10 > m.artImg.bitmapHeight * 9 then bad = true
    if st = "ready" and m.artImg.bitmapHeight > 0 and m.artImg.bitmapHeight < 200 then bad = true
    if bad
        m.artBad[m.artImg.uri] = true
        m.artImg.visible = false
        m.artLogo.visible = true
    end if
end sub

function Live_ArtFor(title as string, chan = "" as string) as dynamic
    if title = "" or not Bool_Of(m.prefs.tmdbArt, true) then return invalid
    if chan <> "" and Instr(1, LCase(chan), LCase(title.Trim())) = 1 then return invalid
    a = m.art[title]
    if type(a) = "roAssociativeArray"
        if Str_Of(a.p) = "" then return invalid
        return a
    end if
    if not m.artAsked.DoesExist(title)
        m.artAsked[title] = true
        m.artWant.Push(title)
        Live_AskArt()
    end if
    return invalid
end function

sub Live_AskArt()
    if m.artTask <> invalid or m.artWant.Count() = 0 then return
    batch = []
    while m.artWant.Count() > 0 and batch.Count() < 10
        batch.Push(m.artWant.Shift())
    end while
    m.artTask = CreateObject("roSGNode", "IptvTask")
    m.artTask.mode = "art"
    m.artTask.params = { titles: batch }
    m.artTask.observeField("result", "onArt")
    m.artTask.control = "RUN"
end sub

sub onArt(event as object)
    task = event.getRoSGNode()
    if m.artTask = invalid or not task.isSameNode(m.artTask) then return
    m.artTask = invalid
    r = task.result
    found = false
    if r <> invalid and type(r.art) = "roAssociativeArray"
        for each t in r.art
            m.art[t] = r.art[t]
            if Str_Of(r.art[t].p) <> "" then found = true
        end for
    end if
    if found
        if m.mode = "guide" and m.loaded then Live_RenderInfo()
        m.top.event = { action: "channels" }
    end if
    Live_AskArt()
end sub

function Live_OptionsData(arg = invalid as dynamic) as object
    return Live_Options()
end function

