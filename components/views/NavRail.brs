sub init()
    m.panel = m.top.findNode("panel")
    m.entries = m.top.findNode("entries")
    m.defs = [
        { id: "profile", label: L("Perfil"), icon: "", y: 56 }
        { id: "home", label: L("Inicio"), icon: "pkg:/images/ic_home.png", y: 400 }
        { id: "search", label: L("Buscar"), icon: "pkg:/images/ic_search.png", y: 492 }
        { id: "library", label: L("Biblioteca"), icon: "pkg:/images/ic_library.png", y: 584 }
        { id: "settings", label: L("Ajustes"), icon: "pkg:/images/ic_settings.png", y: 676 }
    ]
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
            icon.uri = "pkg:/images/circle.png"
            icon.width = 60
            icon.height = 60
            icon.translation = [8, 8]
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
            icon.uri = d.icon
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
    m.index = 1
    m.top.observeField("focusedChild", "onFocusChanged")
    paint()
end sub

sub onFocusChanged()
    if m.top.hasFocus()
        for i = 0 to m.defs.Count() - 1
            if m.defs[i].id = m.top.active then m.index = i
        end for
    end if
    paint()
end sub

sub paint()
    if m.nodes = invalid then return
    expanded = m.top.isInFocusChain()
    m.panel.visible = expanded
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
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
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
