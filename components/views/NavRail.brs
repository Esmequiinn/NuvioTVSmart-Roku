sub init()
    m.panel = m.top.findNode("panel")
    m.float = m.top.findNode("float")
    m.pill = m.top.findNode("pill")
    m.pillBg = m.top.findNode("pillBg")
    m.pillIcon = m.top.findNode("pillIcon")
    m.pillText = m.top.findNode("pillText")
    m.pillTimer = m.top.findNode("pillTimer")
    m.pillTimer.observeField("fire", "onPillTimer")
    m.pillShort = false
    m.pillFor = ""
    m.entries = m.top.findNode("entries")
    Nav_Build()
    m.index = 1
    m.top.observeField("focusedChild", "onFocusChanged")
    paint()
end sub

sub Nav_Build()
    m.entries.removeChildrenIndex(m.entries.getChildCount(), 0)
    m.defs = [{ id: "profile", label: L("Perfil"), icon: "", y: 56, my: 52 }]
    items = [{ id: "home", label: L("Inicio"), icon: "pkg:/images/ic_home.png" }, { id: "search", label: L("Buscar"), icon: "pkg:/images/ic_search.png" }]
    if m.top.discover then items.Push({ id: "discover", label: L("Descubrir"), icon: "pkg:/images/ic_discover.png" })
    items.Push({ id: "library", label: L("Biblioteca"), icon: "pkg:/images/ic_library.png" })
    items.Push({ id: "settings", label: L("Ajustes"), icon: "pkg:/images/ic_settings.png" })
    y = 400
    gap = 104
    my = 180 + Int((872 - ((items.Count() - 1) * gap + 76)) / 2)
    for each it in items
        it.y = y
        it.my = my
        m.defs.Push(it)
        y = y + 92
        my = my + gap
    end for
    m.nodes = []
    for each d in m.defs
        g = m.entries.createChild("Group")
        g.translation = [24, d.y]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.width = 76
        pill.height = 76
        pill.visible = false
        icon = invalid
        initial = invalid
        if d.id = "profile"
            icon = g.createChild("Poster")
            icon.uri = "pkg:/images/c/d60.png"
            icon.width = 60
            icon.height = 60
            icon.translation = [8, 8]
            mask = g.createChild("MaskGroup")
            mask.maskUri = "pkg:/images/c/d60.png"
            Mask_Apply(mask, 60, 60)
            mask.translation = [8, 8]
            m.avatar = mask.createChild("Poster")
            m.avatar.width = 60
            m.avatar.height = 60
            m.avatar.loadWidth = 120
            m.avatar.loadHeight = 120
            m.avatar.loadDisplayMode = "scaleToZoom"
            m.avatar.observeField("loadStatus", "paint")
            initial = g.createChild("Label")
            initial.width = 60
            initial.height = 60
            initial.translation = [8, 8]
            initial.horizAlign = "center"
            initial.vertAlign = "center"
            initial.font = "font:MediumBoldSystemFont"
            initial.color = "0xFFFFFFFF"
        else
            icon = g.createChild("Poster")
            icon.uri = d.icon.Replace("/images/", "/images/s/").Replace(".png", "_40.png")
            icon.width = 40
            icon.height = 40
            icon.translation = [18, 18]
        end if
        label = g.createChild("Label")
        label.translation = [104, 0]
        label.height = 76
        label.width = 300
        label.vertAlign = "center"
        label.font = "font:MediumBoldSystemFont"
        label.text = d.label
        label.visible = false
        m.nodes.Push({ group: g, pill: pill, icon: icon, initial: initial, label: label })
    end for
    if m.index <> invalid and m.index >= m.defs.Count() then m.index = m.defs.Count() - 1
    paint()
end sub

sub onDiscover()
    Nav_Build()
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        for i = 0 to m.defs.Count() - 1
            if m.defs[i].id = m.top.active then m.index = i
        end for
    end if
    paint()
end sub

sub onPillTimer()
    m.pillShort = true
    paint()
end sub

sub Nav_Pill(expanded as boolean)
    show = m.top.modern and not m.top.collapsed and not expanded
    m.pill.visible = show
    if not show then return
    active = m.top.active
    if active <> m.pillFor
        m.pillFor = active
        m.pillShort = false
        m.pillTimer.control = "stop"
        m.pillTimer.control = "start"
    end if
    def = invalid
    for each d in m.defs
        if d.id = active then def = d
    end for
    if def = invalid then return
    m.pillIcon.uri = def.icon.Replace("/images/", "/images/s/").Replace(".png", "_40.png")
    m.pillText.text = def.label
    m.pillText.visible = not m.pillShort
    width = 64
    if not m.pillShort
        textW = m.pillText.boundingRect().width
        if textW <= 0 then textW = Len(def.label) * 16
        width = 62 + textW + 26
    end if
    m.pillBg.width = width
    if m.top.blur then m.pillBg.blendColor = "0x2A2A33D9" else m.pillBg.blendColor = "0x1E1E24FF"
end sub

sub paint()
    if m.nodes = invalid then return
    expanded = m.top.isInFocusChain()
    modern = m.top.modern
    Nav_Pill(expanded)
    m.entries.visible = expanded or not (m.top.collapsed or modern)
    m.float.visible = expanded and modern
    if modern
        m.float.height = 1024
        if m.top.blur then m.float.blendColor = "0x1F1F27E0" else m.float.blendColor = "0x141418FF"
    end if
    for i = 0 to m.nodes.Count() - 1
        if modern then m.nodes[i].group.translation = [44, m.defs[i].my] else m.nodes[i].group.translation = [24, m.defs[i].y]
    end for
    m.panel.visible = expanded and not modern
    for i = 0 to m.nodes.Count() - 1
        n = m.nodes[i]
        d = m.defs[i]
        isActive = d.id = m.top.active
        isFocused = expanded and i = m.index
        n.label.visible = expanded
        n.pill.visible = isFocused or (isActive and d.id <> "profile")
        if isFocused
            n.pill.blendColor = "0xFFFFFFFF"
            n.pill.width = 380
            n.label.color = "0x0C0C0FFF"
            if d.id <> "profile" then n.icon.blendColor = "0x0C0C0FFF"
        else
            n.pill.blendColor = "0x2A2A33FF"
            n.pill.width = 76
            n.label.color = "0xD8D8E0FF"
            if d.id <> "profile"
                if isActive
                    n.icon.blendColor = "0xFFFFFFFF"
                else
                    n.icon.blendColor = "0x8E8E9CFF"
                end if
            end if
        end if
        if d.id = "profile"
            name = m.top.profileName
            n.label.text = name
            if name <> "" then n.initial.text = UCase(Left(name, 1))
            color = m.top.profileColor
            if color <> "" then n.icon.blendColor = "0x" + color + "FF"
            avatar = m.top.profileAvatar
            avatar = Mask_Circle(avatar, 120)
            if m.avatar.uri <> avatar then m.avatar.uri = avatar
            ready = avatar <> "" and m.avatar.loadStatus = "ready"
            m.avatar.visible = ready
            n.initial.visible = not ready
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.global.hasField("activity") then m.global.activity = true
    if key = "up"
        if m.index > 0 then m.index = m.index - 1
        paint()
        return true
    else if key = "down"
        if m.index < m.defs.Count() - 1 then m.index = m.index + 1
        paint()
        return true
    else if key = "OK"
        m.top.chosen = m.defs[m.index].id
        return true
    else if key = "right"
        m.top.leave = true
        return true
    else if key = "left"
        return true
    end if
    return false
end function
