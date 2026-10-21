sub init()
    L_Texts(["navTitle"])
    m.nav = m.top.findNode("nav")
    m.rows = m.top.findNode("rows")
    m.sectionTitle = m.top.findNode("sectionTitle")
    m.sectionSubtitle = m.top.findNode("sectionSubtitle")
    m.moreUp = m.top.findNode("moreUp")
    m.moreDown = m.top.findNode("moreDown")
    m.top.findNode("navTitle").font.size = 44
    m.sectionTitle.font.size = 48
    m.sectionIndex = 0
    m.rowIndex = 0
    m.offset = 0
    m.zone = "nav"
    m.visibleRows = 7
    m.rowHeight = 118
    m.navNodes = []
    m.rowNodes = []
    m.top.observeField("focusedChild", "paint")
end sub

sub onReset()
    m.sectionIndex = 0
    m.rowIndex = 0
    m.offset = 0
    m.zone = "nav"
    render()
end sub

function sections() as object
    model = m.top.model
    if model = invalid or type(model.sections) <> "roArray" then return []
    return model.sections
end function

sub render()
    list = sections()
    if list.Count() = 0 then return
    if m.sectionIndex >= list.Count() then m.sectionIndex = list.Count() - 1
    m.nav.removeChildrenIndex(m.nav.getChildCount(), 0)
    m.navNodes = []
    y = 0
    for each s in list
        g = m.nav.createChild("Group")
        g.translation = [0, y]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.width = 460
        pill.height = 70
        label = g.createChild("Label")
        label.translation = [32, 0]
        label.width = 400
        label.height = 70
        label.vertAlign = "center"
        label.font = "font:MediumSystemFont"
        label.text = s.label
        m.navNodes.Push({ pill: pill, label: label })
        y = y + 80
    end for
    renderRows()
end sub

sub renderRows()
    list = sections()
    if list.Count() = 0 then return
    section = list[m.sectionIndex]
    m.sectionTitle.text = section.label
    m.sectionSubtitle.text = Str_Of(section.subtitle)
    rows = section.rows
    if type(rows) <> "roArray" then rows = []
    if m.rowIndex >= rows.Count() then m.rowIndex = rows.Count() - 1
    if m.rowIndex < 0 then m.rowIndex = 0
    if m.rowIndex < m.offset then m.offset = m.rowIndex
    if m.rowIndex >= m.offset + m.visibleRows then m.offset = m.rowIndex - m.visibleRows + 1
    m.rows.removeChildrenIndex(m.rows.getChildCount(), 0)
    m.rowNodes = []
    last = m.offset + m.visibleRows - 1
    if last > rows.Count() - 1 then last = rows.Count() - 1
    y = 0
    for i = m.offset to last
        r = rows[i]
        g = m.rows.createChild("Group")
        g.translation = [0, y]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/pill.9.png"
        bg.width = 1220
        bg.height = m.rowHeight - 14
        title = g.createChild("Label")
        title.translation = [32, 14]
        title.width = 820
        title.font = "font:MediumSystemFont"
        title.text = Str_Of(r.label)
        desc = g.createChild("Label")
        desc.translation = [32, 58]
        desc.width = 860
        desc.font = "font:SmallestSystemFont"
        desc.text = Str_Of(r.desc)
        value = g.createChild("Label")
        value.translation = [860, 0]
        value.width = 330
        value.height = m.rowHeight - 14
        value.horizAlign = "right"
        value.vertAlign = "center"
        value.font = "font:SmallSystemFont"
        track = invalid
        knob = invalid
        if Str_Of(r.kind) = "toggle"
            track = g.createChild("Poster")
            track.uri = "pkg:/images/pill.9.png"
            track.width = 76
            track.height = 40
            track.translation = [1112, Int((m.rowHeight - 14 - 40) / 2)]
            knob = g.createChild("Poster")
            knob.uri = "pkg:/images/circle.png"
            knob.width = 30
            knob.height = 30
            if Bool_Of(r.on, false)
                knob.translation = [1153, Int((m.rowHeight - 14 - 30) / 2)]
            else
                knob.translation = [1117, Int((m.rowHeight - 14 - 30) / 2)]
            end if
        else
            value.text = Str_Of(r.value)
        end if
        m.rowNodes.Push({ bg: bg, title: title, desc: desc, value: value, track: track, knob: knob, on: Bool_Of(r.on, false), kind: Str_Of(r.kind) })
        y = y + m.rowHeight
    end for
    m.moreUp.visible = m.offset > 0
    m.moreDown.visible = last < rows.Count() - 1
    paint()
end sub

sub paint()
    if m.navNodes = invalid then return
    focused = m.top.isInFocusChain()
    accent = m.top.accent
    for i = 0 to m.navNodes.Count() - 1
        n = m.navNodes[i]
        if i = m.sectionIndex
            if focused and m.zone = "nav"
                n.pill.blendColor = "0xFFFFFFFF"
                n.label.color = "0x0C0C0FFF"
            else
                n.pill.blendColor = "0x2A2A33FF"
                n.label.color = "0xFFFFFFFF"
            end if
            n.pill.visible = true
        else
            n.pill.visible = false
            n.label.color = "0xA9A9B8FF"
        end if
    end for
    for i = 0 to m.rowNodes.Count() - 1
        n = m.rowNodes[i]
        active = focused and m.zone = "rows" and (m.offset + i) = m.rowIndex
        if active
            n.bg.blendColor = "0xFFFFFFFF"
            n.title.color = "0x0C0C0FFF"
            n.desc.color = "0x3A3A44FF"
            n.value.color = "0x0C0C0FFF"
        else
            n.bg.blendColor = "0x18181FFF"
            n.title.color = "0xF2F2F7FF"
            n.desc.color = "0x8E8E9CFF"
            n.value.color = "0xC9C9D6FF"
        end if
        if n.track <> invalid
            if n.on
                n.track.blendColor = accent
            else
                n.track.blendColor = "0x4A4A55FF"
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
            renderRows()
        else if key = "down" and m.sectionIndex < list.Count() - 1
            m.sectionIndex = m.sectionIndex + 1
            m.rowIndex = 0
            m.offset = 0
            renderRows()
        else if (key = "right" or key = "OK") and currentRows().Count() > 0
            m.zone = "rows"
            paint()
        end if
        return true
    end if
    rows = currentRows()
    if key = "up"
        if m.rowIndex > 0
            m.rowIndex = m.rowIndex - 1
            renderRows()
        end if
    else if key = "down"
        if m.rowIndex < rows.Count() - 1
            m.rowIndex = m.rowIndex + 1
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
