sub init()
    m.nav = m.top.findNode("nav")
    m.rows = m.top.findNode("rows")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.sectionSubtitle = m.top.findNode("sectionSubtitle")
    m.moreUp = m.top.findNode("moreUp")
    m.moreDown = m.top.findNode("moreDown")
    m.navUp = m.top.findNode("navUp")
    m.navDown = m.top.findNode("navDown")
    m.sectionTitle.font.size = 56
    m.sectionSubtitle.font.size = 30
    m.sectionIndex = 0
    m.rowIndex = 0
    m.offset = 0
    m.navOffset = 0
    m.zone = "nav"
    m.listHeight = 721
    m.navVisible = 6
    m.navNodes = []
    m.rowNodes = []
    m.icons = { account: "set_account", profiles: "set_profiles", party: "set_party", appearance: "set_appearance", layout: "set_layout", content: "set_content", integration: "set_integration", fusion: "set_fusion", playback: "set_playback", tracking: "set_tracking", advanced: "set_advanced", about: "set_about" }
    m.top.observeField("focusedChild", "paint")
end sub

sub onReset()
    m.sectionIndex = 0
    m.rowIndex = 0
    m.offset = 0
    m.navOffset = 0
    m.zone = "nav"
    render()
end sub

function sections() as object
    model = m.top.model
    if model = invalid or type(model.sections) <> "roArray" then return []
    return model.sections
end function

sub render()
    try
        drawAll()
    catch e
        showError(e)
    end try
end sub

sub drawAll()
    list = sections()
    if list.Count() = 0 then return
    if m.sectionIndex >= list.Count() then m.sectionIndex = list.Count() - 1
    drawNav()
    renderRows()
end sub

sub drawNav()
    list = sections()
    if m.sectionIndex < m.navOffset then m.navOffset = m.sectionIndex
    if m.sectionIndex >= m.navOffset + m.navVisible then m.navOffset = m.sectionIndex - m.navVisible + 1
    m.nav.removeChildrenIndex(m.nav.getChildCount(), 0)
    m.navNodes = []
    y = 0
    last = m.navOffset + m.navVisible - 1
    if last > list.Count() - 1 then last = list.Count() - 1
    for i = m.navOffset to last
        s = list[i]
        g = m.nav.createChild("Group")
        g.translation = [0, y]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/navpill.9.png"
        bg.width = 440
        bg.height = 112
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/navpill_ring.9.png"
        ring.width = 440
        ring.height = 112
        ring.visible = false
        icon = invalid
        name = m.icons[Str_Of(s.id)]
        if name <> invalid
            icon = g.createChild("Poster")
            icon.uri = "pkg:/images/s/" + name + "_40.png"
            icon.width = 40
            icon.height = 40
            icon.translation = [30, 36]
        end if
        label = g.createChild("Label")
        label.translation = [92, 0]
        label.width = 290
        label.height = 112
        label.vertAlign = "center"
        label.font = "font:MediumSystemFont"
        label.font.size = 32
        label.text = s.label
        chev = g.createChild("Poster")
        chev.uri = "pkg:/images/s/chevron_36.png"
        chev.width = 36
        chev.height = 36
        chev.translation = [376, 38]
        m.navNodes.Push({ index: i, bg: bg, ring: ring, icon: icon, label: label, chev: chev })
        y = y + 140
    end for
    m.navUp.visible = m.navOffset > 0
    m.navDown.visible = last < list.Count() - 1
end sub

sub renderRows()
    try
        drawRows()
    catch e
        showError(e)
    end try
end sub

function rowHeightOf(r as object) as integer
    kind = Str_Of(r.kind)
    if kind = "header" then return 64
    if kind = "logo" then return 250
    if Str_Of(r.desc) = "" then return 92
    if Len(Str_Of(r.desc)) > 62 then return 128
    return 106
end function

function isFocusable(r as object) as boolean
    kind = Str_Of(r.kind)
    return kind <> "header" and kind <> "logo"
end function

sub drawRows()
    list = sections()
    if list.Count() = 0 then return
    section = list[m.sectionIndex]
    m.sectionTitle.text = section.label
    m.sectionSubtitle.text = Str_Of(section.subtitle)
    rows = section.rows
    if type(rows) <> "roArray" then rows = []
    if m.rowIndex >= rows.Count() then m.rowIndex = rows.Count() - 1
    if m.rowIndex < 0 then m.rowIndex = 0
    if rows.Count() > 0 and not isFocusable(rows[m.rowIndex]) then m.rowIndex = nextFocusable(rows, m.rowIndex, 1)
    if m.rowIndex < m.offset then m.offset = m.rowIndex
    if m.offset > 0 and m.offset = m.rowIndex
        if not isFocusable(rows[m.offset - 1]) then m.offset = m.offset - 1
    end if
    while true
        used = 0
        for i = m.offset to m.rowIndex
            used = used + rowHeightOf(rows[i]) + 12
        end for
        if used <= m.listHeight or m.offset >= m.rowIndex then exit while
        m.offset = m.offset + 1
    end while
    m.rows.removeChildrenIndex(m.rows.getChildCount(), 0)
    m.rowNodes = []
    y = 0
    last = m.offset - 1
    i = m.offset
    while i < rows.Count()
        r = rows[i]
        h = rowHeightOf(r)
        if y + h > m.listHeight then exit while
        drawRow(r, i, y, h)
        last = i
        y = y + h + 12
        i = i + 1
    end while
    m.moreUp.visible = m.offset > 0
    m.moreDown.visible = last < rows.Count() - 1
    paint()
end sub

sub drawRow(r as object, index as integer, y as integer, h as integer)
    width = 1112
    g = m.rows.createChild("Group")
    g.translation = [0, y]
    kind = Str_Of(r.kind)
    if kind = "header"
        t = g.createChild("Label")
        t.translation = [8, 18]
        t.width = width
        t.font = "font:MediumBoldSystemFont"
        t.font.size = 30
        t.color = "0xFFFFFFFF"
        t.text = Str_Of(r.label)
        m.rowNodes.Push({ index: index, header: true })
        return
    end if
    if kind = "logo"
        logo = g.createChild("Poster")
        logo.uri = "pkg:/images/wordmark.png"
        logo.width = 315
        logo.height = 100
        logo.translation = [Int((width - 315) / 2), 20]
        t = g.createChild("Label")
        t.translation = [0, 134]
        t.width = width
        t.horizAlign = "center"
        t.font = "font:SmallSystemFont"
        t.font.size = 24
        t.color = "0xB3B3B3FF"
        t.text = Str_Of(r.label)
        d = g.createChild("Label")
        d.translation = [0, 172]
        d.width = width
        d.horizAlign = "center"
        d.wrap = true
        d.maxLines = 2
        d.font = "font:SmallestSystemFont"
        d.font.size = 22
        d.color = "0x808080FF"
        d.text = Str_Of(r.desc)
        m.rowNodes.Push({ index: index, header: true })
        return
    end if
    bg = g.createChild("Poster")
    bg.uri = "pkg:/images/setrow.9.png"
    bg.width = width
    bg.height = h
    ring = g.createChild("Poster")
    ring.uri = "pkg:/images/setrow_ring.9.png"
    ring.width = width
    ring.height = h
    ring.visible = false
    hasDesc = Str_Of(r.desc) <> ""
    title = g.createChild("Label")
    title.font = "font:MediumSystemFont"
    title.font.size = 30
    title.text = Str_Of(r.label)
    title.width = 720
    desc = g.createChild("Label")
    desc.font = "font:SmallestSystemFont"
    desc.font.size = 22
    desc.text = Str_Of(r.desc)
    desc.width = 740
    desc.wrap = true
    desc.maxLines = 2
    if hasDesc
        title.translation = [36, 16]
        desc.translation = [36, 58]
    else
        title.translation = [36, 0]
        title.height = h
        title.vertAlign = "center"
    end if
    value = g.createChild("Label")
    value.width = 300
    value.height = h
    value.horizAlign = "right"
    value.vertAlign = "center"
    value.font = "font:SmallSystemFont"
    value.font.size = 26
    track = invalid
    knob = invalid
    chev = invalid
    if kind = "toggle"
        track = g.createChild("Poster")
        track.uri = "pkg:/images/toggle_track.png"
        track.width = 76
        track.height = 42
        track.translation = [width - 112, Int((h - 42) / 2)]
        knob = g.createChild("Poster")
        knob.uri = "pkg:/images/c/d32.png"
        knob.width = 32
        knob.height = 32
        if Bool_Of(r.on, false)
            knob.translation = [width - 112 + 39, Int((h - 32) / 2)]
        else
            knob.translation = [width - 112 + 5, Int((h - 32) / 2)]
        end if
    else
        value.text = Str_Of(r.value)
        if kind = "info"
            value.translation = [width - 336, 0]
        else
            value.translation = [width - 384, 0]
            chev = g.createChild("Poster")
            chev.uri = "pkg:/images/s/chevron_36.png"
            chev.width = 36
            chev.height = 36
            chev.translation = [width - 72, Int((h - 36) / 2)]
        end if
    end if
    m.rowNodes.Push({ index: index, bg: bg, ring: ring, title: title, desc: desc, value: value, track: track, knob: knob, chev: chev, on: Bool_Of(r.on, false), kind: kind })
end sub

sub paint()
    if m.navNodes = invalid then return
    focused = m.top.isInFocusChain()
    accent = m.top.accent
    for each n in m.navNodes
        active = n.index = m.sectionIndex
        if active and focused and m.zone = "nav"
            n.bg.blendColor = "0x2A2A2AFF"
            n.ring.visible = true
            n.ring.blendColor = "0xFFFFFFFF"
            n.label.color = "0xFFFFFFFF"
            if n.icon <> invalid then n.icon.blendColor = "0xFFFFFFFF"
            n.chev.blendColor = "0xFFFFFFFF"
        else if active
            n.bg.blendColor = "0x262626FF"
            n.ring.visible = false
            n.label.color = "0xFFFFFFFF"
            if n.icon <> invalid then n.icon.blendColor = "0xFFFFFFFF"
            n.chev.blendColor = "0xB3B3B3FF"
        else
            n.bg.blendColor = "0x111111FF"
            n.ring.visible = false
            n.label.color = "0xB3B3B3FF"
            if n.icon <> invalid then n.icon.blendColor = "0x9E9E9EFF"
            n.chev.blendColor = "0x808080FF"
        end if
    end for
    for each n in m.rowNodes
        if not Bool_Of(n.header, false)
            active = focused and m.zone = "rows" and n.index = m.rowIndex
            n.ring.visible = active
            if active
                n.bg.blendColor = "0x2E2E2EFF"
                n.ring.blendColor = "0xFFFFFFFF"
                n.title.color = "0xFFFFFFFF"
                n.desc.color = "0xC9C9C9FF"
                n.value.color = "0xFFFFFFFF"
                if n.chev <> invalid then n.chev.blendColor = "0xFFFFFFFF"
            else
                n.bg.blendColor = "0x161616FF"
                n.title.color = "0xF2F2F2FF"
                n.desc.color = "0x9E9E9EFF"
                n.value.color = "0xB3B3B3FF"
                if n.chev <> invalid then n.chev.blendColor = "0x9E9E9EFF"
            end if
            if n.track <> invalid
                if n.on
                    n.track.blendColor = accent
                    if n.knob <> invalid then n.knob.blendColor = Ui_Ink(accent)
                else
                    n.track.blendColor = "0x4D4D4DFF"
                    if n.knob <> invalid then n.knob.blendColor = "0xFFFFFFFF"
                end if
            end if
        end if
    end for
end sub

function currentRows() as object
    list = sections()
    if list.Count() = 0 then return []
    rows = list[m.sectionIndex].rows
    if type(rows) <> "roArray" then return []
    return rows
end function

function nextFocusable(rows as object, start as integer, dir as integer) as integer
    i = start
    while i >= 0 and i < rows.Count()
        if isFocusable(rows[i]) then return i
        i = i + dir
    end while
    return -1
end function

function hasFocusable(rows as object) as boolean
    return nextFocusable(rows, 0, 1) >= 0
end function

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    list = sections()
    if key = "back"
        if m.zone = "rows"
            m.zone = "nav"
            paint()
        else
            m.top.back = true
        end if
        return true
    end if
    if m.zone = "nav"
        if key = "up" and m.sectionIndex > 0
            m.sectionIndex = m.sectionIndex - 1
            m.rowIndex = 0
            m.offset = 0
            drawNav()
            renderRows()
        else if key = "down" and m.sectionIndex < list.Count() - 1
            m.sectionIndex = m.sectionIndex + 1
            m.rowIndex = 0
            m.offset = 0
            drawNav()
            renderRows()
        else if (key = "right" or key = "OK") and hasFocusable(currentRows())
            m.zone = "rows"
            m.rowIndex = nextFocusable(currentRows(), 0, 1)
            m.offset = 0
            renderRows()
        else if key = "left"
            m.top.leave = true
        end if
        return true
    end if
    rows = currentRows()
    if key = "up"
        target = nextFocusable(rows, m.rowIndex - 1, -1)
        if target >= 0
            m.rowIndex = target
            if m.rowIndex < m.offset then m.offset = m.rowIndex
            while m.offset > 0 and not isFocusable(rows[m.offset - 1])
                m.offset = m.offset - 1
            end while
            renderRows()
        end if
    else if key = "down"
        target = nextFocusable(rows, m.rowIndex + 1, 1)
        if target >= 0
            m.rowIndex = target
            renderRows()
        end if
    else if key = "left"
        m.zone = "nav"
        paint()
    else if key = "OK"
        if m.rowIndex < rows.Count()
            r = rows[m.rowIndex]
            if Str_Of(r.kind) <> "info" then m.top.event = { section: list[m.sectionIndex].id, row: Str_Of(r.id) }
        end if
    end if
    return true
end function

function Str_Of(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

function Bool_Of(v as dynamic, fallback as boolean) as boolean
    if v = invalid then return fallback
    if GetInterface(v, "ifBoolean") <> invalid then return v
    return fallback
end function

sub showError(e as object)
    text = Str_Of(e.message)
    if type(e.backtrace) = "roArray" and e.backtrace.Count() > 0
        b = e.backtrace[0]
        if type(b) = "roAssociativeArray" then text = text + "  " + Str_Of(b.function) + " " + Str(b.line_number).Trim()
    end if
    m.sectionTitle.text = "Error"
    m.sectionSubtitle.text = text
end sub
