sub init()
    L_Texts(["trailerHint"])
    m.hero = m.top.findNode("hero")
    m.buttonRow = m.top.findNode("buttonRow")
    m.statusLabel = m.top.findNode("statusLabel")
    m.buttons = []
    m.index = 0
    m.top.observeField("focusedChild", "paint")
    m.video = m.top.findNode("trailerVideo")
    m.trailerHint = m.top.findNode("trailerHint")
    m.trailerTimer = m.top.findNode("trailerTimer")
    m.trailerTimer.observeField("fire", "startTrailer")
    m.video.observeField("state", "onTrailerState")
    m.top.observeField("visible", "onVisible")
    m.page = m.top.findNode("page")
    m.lower = m.top.findNode("lower")
    m.zone = "buttons"
    m.seasonIndex = 0
    m.epIndex = 0
    m.castIndex = 0
    m.seasonNodes = []
    m.epNodes = []
    m.castNodes = []
    m.epGroup = invalid
    m.castGroup = invalid
    m.layoutInfo = { seasonsY: -1, episodesY: -1, castY: -1 }
end sub

sub onTrailer()
    stopTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = "" then return
    delay = ToInt(t.delay, 7)
    if delay < 1 then delay = 1
    m.trailerTimer.duration = delay
    m.trailerTimer.control = "start"
end sub

sub startTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = "" or not m.top.visible or not m.top.isInFocusChain() then return
    m.video.content = Trailer_Content(t)
    m.video.control = "play"
end sub

sub onTrailerState()
    state = m.video.state
    if state = "playing"
        m.video.visible = true
        m.hero.videoMode = true
        m.hero.visible = false
        m.lower.visible = false
        m.buttonRow.visible = false
        m.statusLabel.visible = false
        m.trailerHint.visible = true
        m.top.trailerPlaying = true
    else if state = "finished" or state = "error" or state = "stopped"
        endTrailer()
    end if
end sub

sub stopTrailer()
    m.trailerTimer.control = "stop"
    if m.video.state <> "none" and m.video.state <> "stopped" then m.video.control = "stop"
    endTrailer()
end sub

sub endTrailer()
    m.video.visible = false
    m.hero.videoMode = false
    m.hero.visible = true
    m.lower.visible = true
    m.buttonRow.visible = true
    m.statusLabel.visible = true
    m.trailerHint.visible = false
    m.top.trailerPlaying = false
end sub

sub onVisible()
    if not m.top.visible then stopTrailer()
end sub

sub onFocusIndex()
    m.index = m.top.focusIndex
    m.zone = "buttons"
    paintLower()
    paint()
end sub

sub render()
    m.hero.data = m.top.data
end sub

sub onExtra()
    ex = m.top.extra
    m.lower.removeChildrenIndex(m.lower.getChildCount(), 0)
    m.seasonNodes = []
    m.epNodes = []
    m.castNodes = []
    m.epGroup = invalid
    m.castGroup = invalid
    m.layoutInfo = { seasonsY: -1, episodesY: -1, castY: -1 }
    if ex = invalid then return
    y = 0
    seasons = ex.seasons
    if type(seasons) = "roArray" and seasons.Count() > 0
        if ex.seasonIndex <> invalid then m.seasonIndex = ex.seasonIndex
        if m.seasonIndex >= seasons.Count() then m.seasonIndex = 0
        m.layoutInfo.seasonsY = y
        chips = m.lower.createChild("Group")
        chips.translation = [160, y]
        x = 0
        for i = 0 to seasons.Count() - 1
            g = chips.createChild("Group")
            g.translation = [x, 0]
            bg = g.createChild("Poster")
            bg.uri = "pkg:/images/pill60.9.png"
            bg.height = 60
            lbl = g.createChild("Label")
            lbl.font = "font:SmallBoldSystemFont"
            lbl.font.size = 28
            lbl.height = 60
            lbl.vertAlign = "center"
            lbl.translation = [30, 0]
            lbl.text = Str_Of(seasons[i].label)
            w = Int(lbl.boundingRect().width)
            est = Len(lbl.text) * 15
            if w < est then w = est
            bg.width = w + 60
            m.seasonNodes.Push({ bg: bg, label: lbl, x: x, w: w + 60 })
            x = x + w + 76
        end for
        m.chips = chips
        y = y + 96
        m.layoutInfo.episodesY = y
        m.epGroup = m.lower.createChild("Group")
        m.epGroup.translation = [160, y]
        buildEpisodes()
        y = y + 470
    end if
    crew = Str_Of(ex.crew)
    if crew <> ""
        lbl = m.lower.createChild("Label")
        lbl.font = "font:SmallSystemFont"
        lbl.font.size = 26
        lbl.color = "0xB3B3B3FF"
        lbl.translation = [160, y]
        lbl.width = 1600
        lbl.text = crew
        y = y + 60
    end if
    cast = ex.cast
    if type(cast) = "roArray" and cast.Count() > 0
        head = m.lower.createChild("Label")
        head.font = "font:MediumBoldSystemFont"
        head.font.size = 34
        head.color = "0xFFFFFFFF"
        head.translation = [160, y]
        head.text = L("Reparto")
        m.layoutInfo.castY = y
        y = y + 64
        m.castGroup = m.lower.createChild("Group")
        m.castGroup.translation = [160, y]
        for i = 0 to cast.Count() - 1
            c = cast[i]
            g = m.castGroup.createChild("Group")
            g.translation = [i * 200, 0]
            ring = g.createChild("Poster")
            ring.uri = "pkg:/images/c/d160.png"
            ring.width = 160
            ring.height = 160
            ring.translation = [-5, -5]
            ring.visible = false
            disc = g.createChild("Poster")
            disc.uri = "pkg:/images/c/d150.png"
            disc.width = 150
            disc.height = 150
            disc.blendColor = "0x262626FF"
            initial = g.createChild("Label")
            initial.font = "font:LargeBoldSystemFont"
            initial.font.size = 54
            initial.width = 150
            initial.height = 150
            initial.horizAlign = "center"
            initial.vertAlign = "center"
            initial.color = "0x9E9E9EFF"
            initial.text = UCase(Left(Str_Of(c.name), 1))
            if Str_Of(c.photo) <> ""
                mask = g.createChild("MaskGroup")
                mask.maskUri = "pkg:/images/c/d150.png"
                Mask_Apply(mask, 150, 150)
                pic = mask.createChild("Poster")
                pic.width = 150
                pic.height = 150
                pic.loadWidth = 185
                pic.loadHeight = 278
                pic.loadDisplayMode = "scaleToZoom"
                pic.uri = Mask_Circle(c.photo, 150)
            end if
            nm = g.createChild("Label")
            nm.font = "font:SmallBoldSystemFont"
            nm.font.size = 24
            nm.color = "0xFFFFFFFF"
            nm.translation = [-15, 166]
            nm.width = 180
            nm.horizAlign = "center"
            nm.text = Str_Of(c.name)
            rl = g.createChild("Label")
            rl.font = "font:SmallestSystemFont"
            rl.font.size = 21
            rl.color = "0x9E9E9EFF"
            rl.translation = [-15, 200]
            rl.width = 180
            rl.horizAlign = "center"
            rl.text = Str_Of(c.role)
            m.castNodes.Push({ ring: ring })
        end for
    end if
    if m.castIndex >= m.castNodes.Count() then m.castIndex = 0
    if m.zone = "seasons" and m.seasonNodes.Count() = 0 then m.zone = "buttons"
    if m.zone = "episodes" and m.epNodes.Count() = 0 then m.zone = "buttons"
    if m.zone = "cast" and m.castNodes.Count() = 0 then m.zone = "buttons"
    paintLower()
end sub

sub buildEpisodes()
    if m.epGroup = invalid then return
    m.epGroup.removeChildrenIndex(m.epGroup.getChildCount(), 0)
    m.epNodes = []
    seasons = m.top.extra.seasons
    eps = seasons[m.seasonIndex].episodes
    if type(eps) <> "roArray" then eps = []
    accent = m.top.accent
    for i = 0 to eps.Count() - 1
        e = eps[i]
        g = m.epGroup.createChild("Group")
        g.translation = [i * 478, 0]
        frame = g.createChild("Poster")
        frame.uri = "pkg:/images/card.9.png"
        frame.width = 448
        frame.height = 252
        frame.blendColor = "0x1E1E22FF"
        mask = g.createChild("MaskGroup")
        mask.maskUri = "pkg:/images/mask_landscape.png"
        Mask_Apply(mask, 448, 252)
        pic = mask.createChild("Poster")
        pic.width = 448
        pic.height = 252
        pic.loadWidth = 448
        pic.loadHeight = 252
        pic.loadDisplayMode = "scaleToZoom"
        pic.uri = Str_Of(e.thumb)
        Mask_Caps(g, 448, 252, 22, "0x0C0C0FFF")
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/iring.9.png"
        ring.width = 448
        ring.height = 252
        ring.translation = [0, 0]
        ring.blendColor = accent
        ring.visible = false
        progress = 0.0
        if e.progress <> invalid then progress = e.progress
        if progress > 0.01
            track = g.createChild("Rectangle")
            track.translation = [16, 232]
            track.width = 416
            track.height = 6
            track.color = "0xFFFFFF40"
            bar = g.createChild("Rectangle")
            bar.translation = [16, 232]
            if progress > 1 then progress = 1
            bar.width = Int(416 * progress)
            bar.height = 6
            bar.color = accent
        end if
        if e.watched = true
            dot = g.createChild("Poster")
            dot.uri = "pkg:/images/c/d38.png"
            dot.width = 38
            dot.height = 38
            dot.blendColor = accent
            dot.translation = [398, 12]
            chk = g.createChild("Poster")
            chk.uri = "pkg:/images/s/ic_check_s_26.png"
            chk.width = 26
            chk.height = 26
            chk.blendColor = "0x0D0D0DFF"
            chk.translation = [404, 18]
        end if
        t = g.createChild("Label")
        t.font = "font:SmallBoldSystemFont"
        t.font.size = 28
        t.color = "0xFFFFFFFF"
        t.translation = [0, 270]
        t.width = 448
        t.text = Str_Of(e.code) + "  " + Str_Of(e.name)
        d = g.createChild("Label")
        d.font = "font:SmallestSystemFont"
        d.font.size = 22
        d.color = "0xA6A6A6FF"
        d.translation = [0, 310]
        d.width = 448
        d.height = 96
        d.wrap = true
        d.maxLines = 3
        d.text = Str_Of(e.overview)
        info = g.createChild("Label")
        info.font = "font:SmallestSystemFont"
        info.font.size = 21
        info.color = "0x808080FF"
        info.translation = [0, 416]
        info.width = 448
        info.text = Str_Of(e.meta)
        m.epNodes.Push({ ring: ring, id: Str_Of(e.id) })
    end for
    if m.epIndex >= m.epNodes.Count() then m.epIndex = 0
end sub

sub paintLower()
    for i = 0 to m.seasonNodes.Count() - 1
        n = m.seasonNodes[i]
        if m.zone = "seasons" and i = m.seasonIndex and m.top.isInFocusChain()
            n.bg.blendColor = "0xFFFFFFFF"
            n.label.color = "0x0D0D0DFF"
        else if i = m.seasonIndex
            n.bg.blendColor = "0x3A3A3AFF"
            n.label.color = "0xFFFFFFFF"
        else
            n.bg.blendColor = "0x1E1E1EFF"
            n.label.color = "0xB3B3B3FF"
        end if
    end for
    for i = 0 to m.epNodes.Count() - 1
        m.epNodes[i].ring.visible = m.zone = "episodes" and i = m.epIndex
    end for
    if m.epGroup <> invalid
        first = m.epIndex - 2
        if first < 0 then first = 0
        if m.zone <> "episodes" then first = 0
        m.epGroup.translation = [160 - first * 478, m.layoutInfo.episodesY]
    end if
    for i = 0 to m.castNodes.Count() - 1
        m.castNodes[i].ring.visible = m.zone = "cast" and i = m.castIndex
    end for
    if m.castGroup <> invalid
        first = m.castIndex - 6
        if first < 0 then first = 0
        m.castGroup.translation = [160 - first * 200, m.castGroup.translation[1]]
    end if
    target = 0
    if m.zone = "seasons" or m.zone = "episodes"
        target = -(900 + m.layoutInfo.seasonsY - 140)
    else if m.zone = "cast"
        if m.layoutInfo.seasonsY >= 0 then target = -(900 + m.layoutInfo.castY - 360) else target = -(900 + m.layoutInfo.castY - 520)
    end if
    m.page.translation = [0, target]
    m.statusLabel.visible = m.zone = "buttons" and not m.top.trailerPlaying
end sub

function lowerKey(key as string) as boolean
    if m.zone = "seasons"
        if key = "left" and m.seasonIndex > 0
            m.seasonIndex = m.seasonIndex - 1
            m.epIndex = 0
            buildEpisodes()
        else if key = "right" and m.seasonIndex < m.seasonNodes.Count() - 1
            m.seasonIndex = m.seasonIndex + 1
            m.epIndex = 0
            buildEpisodes()
        else if key = "down"
            if m.epNodes.Count() > 0 then m.zone = "episodes" else if m.castNodes.Count() > 0 then m.zone = "cast"
        else if key = "up" or key = "back"
            m.zone = "buttons"
        end if
    else if m.zone = "episodes"
        if key = "left" and m.epIndex > 0
            m.epIndex = m.epIndex - 1
        else if key = "right" and m.epIndex < m.epNodes.Count() - 1
            m.epIndex = m.epIndex + 1
        else if key = "up"
            m.zone = "seasons"
        else if key = "down" and m.castNodes.Count() > 0
            m.zone = "cast"
        else if key = "back"
            m.zone = "buttons"
        else if key = "OK"
            stopTrailer()
            m.top.selected = "ep:" + m.epNodes[m.epIndex].id
        end if
    else if m.zone = "cast"
        if key = "left" and m.castIndex > 0
            m.castIndex = m.castIndex - 1
        else if key = "right" and m.castIndex < m.castNodes.Count() - 1
            m.castIndex = m.castIndex + 1
        else if key = "up"
            if m.epNodes.Count() > 0 then m.zone = "episodes" else m.zone = "buttons"
        else if key = "back"
            m.zone = "buttons"
        else if key = "OK"
            stopTrailer()
            m.top.selected = "cast:" + m.castIndex.ToStr()
        end if
    end if
    paintLower()
    paint()
    return true
end function

sub onStatus()
    m.statusLabel.text = m.top.status
end sub

sub buildButtons()
    m.buttonRow.removeChildrenIndex(m.buttonRow.getChildCount(), 0)
    m.buttons = []
    defs = m.top.buttons
    if defs = invalid then defs = []
    for each d in defs
        g = m.buttonRow.createChild("Group")
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.height = 76
        icon = g.createChild("Poster")
        icon.uri = d.icon.Replace("/images/", "/images/s/").Replace(".png", "_36.png")
        icon.width = 36
        icon.height = 36
        icon.translation = [28, 20]
        label = g.createChild("Label")
        label.font = "font:MediumBoldSystemFont"
        label.text = d.label
        label.translation = [80, 0]
        label.height = 76
        label.vertAlign = "center"
        width = Int(label.boundingRect().width) + 112
        if d.label = ""
            width = 76
            icon.translation = [20, 20]
        end if
        pill.width = width
        m.buttons.Push({ id: d.id, pill: pill, icon: icon, label: label })
    end for
    if m.index >= m.buttons.Count() then m.index = 0
    paint()
end sub

sub paint()
    focused = m.top.isInFocusChain() and m.zone = "buttons"
    for i = 0 to m.buttons.Count() - 1
        b = m.buttons[i]
        if focused and i = m.index
            b.pill.blendColor = "0xFFFFFFFF"
            b.icon.blendColor = "0x0C0C0FFF"
            b.label.color = "0x0C0C0FFF"
        else
            b.pill.blendColor = "0xFFFFFF33"
            b.icon.blendColor = "0xFFFFFFFF"
            b.label.color = "0xFFFFFFFF"
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.top.trailerPlaying
        stopTrailer()
        return true
    end if
    if m.zone <> "buttons" then return lowerKey(key)
    if key = "down"
        if m.seasonNodes.Count() > 0
            m.zone = "seasons"
        else if m.castNodes.Count() > 0
            m.zone = "cast"
        else
            return true
        end if
        paintLower()
        paint()
        return true
    end if
    if key = "left"
        if m.index > 0 then m.index = m.index - 1
        paint()
        return true
    else if key = "right"
        if m.index < m.buttons.Count() - 1 then m.index = m.index + 1
        paint()
        return true
    else if key = "OK"
        if m.buttons.Count() > 0
            id = m.buttons[m.index].id
            if id <> "library" then stopTrailer()
            m.top.selected = id
        end if
        return true
    else if key = "options"
        if m.buttons.Count() > 0 and (m.buttons[m.index].id = "play" or m.buttons[m.index].id = "restart")
            stopTrailer()
            m.top.selected = "manual"
        end if
        return true
    else if key = "back"
        if m.top.trailerPlaying
            stopTrailer()
            return true
        end if
        stopTrailer()
        m.top.back = true
        return true
    end if
    return key = "up" or key = "down"
end function

