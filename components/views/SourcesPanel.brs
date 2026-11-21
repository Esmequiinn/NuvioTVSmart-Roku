sub init()
    m.heading = m.top.findNode("heading")
    m.closePill = m.top.findNode("closePill")
    m.closeLabel = m.top.findNode("closeLabel")
    m.info = m.top.findNode("info")
    m.chipsGroup = m.top.findNode("chips")
    m.listGroup = m.top.findNode("list")
    m.empty = m.top.findNode("empty")
    m.heading.text = L("Fuentes")
    m.closeLabel.text = L("Cerrar")
    m.empty.text = L("No hay fuentes de este complemento.")
    m.cardH = 156
    m.gap = 14
    m.slots = []
    for i = 0 to 4
        m.slots.Push(Card_Make())
    end for
    m.streams = []
    m.filtered = []
    m.chips = []
    m.chipIndex = 0
    m.index = 0
    m.first = 0
    m.zone = "list"
end sub

function Card_Make() as object
    g = m.listGroup.createChild("Group")
    bg = g.createChild("Poster")
    bg.uri = "pkg:/images/card.9.png"
    bg.width = 824
    bg.height = m.cardH
    ring = g.createChild("Poster")
    ring.uri = "pkg:/images/iring.9.png"
    ring.width = 824
    ring.height = m.cardH
    ring.visible = false
    addon = g.createChild("Label")
    addon.translation = [28, 18]
    addon.width = 600
    addon.font = "font:SmallestBoldSystemFont"
    name = g.createChild("Label")
    name.translation = [28, 46]
    name.width = 768
    name.font = "font:SmallBoldSystemFont"
    name.color = "0xFFFFFFFF"
    desc = g.createChild("Label")
    desc.translation = [28, 82]
    desc.width = 768
    desc.height = 40
    desc.wrap = false
    desc.font = "font:SmallestSystemFont"
    desc.color = "0xA9A9B8FF"
    now = g.createChild("Label")
    now.translation = [500, 18]
    now.width = 296
    now.horizAlign = "right"
    now.font = "font:SmallestBoldSystemFont"
    badges = g.createChild("Group")
    badges.translation = [28, 116]
    return { g: g, bg: bg, ring: ring, addon: addon, name: name, desc: desc, now: now, badges: badges, bound: -1 }
end function

function accent() as string
    if m.global.hasField("accent") and Str_Of(m.global.accent) <> "" then return m.global.accent
    return "0x7C4DFFFF"
end function

sub onData()
    d = m.top.data
    if type(d) <> "roAssociativeArray" then return
    m.streams = []
    if type(d.streams) = "roArray" then m.streams = d.streams
    m.current = ToInt(d.current, -1)
    m.info.text = Str_Of(d.info)
    names = []
    seen = {}
    for each s in m.streams
        a = Str_Of(s.addon)
        if a <> "" and not seen.DoesExist(a)
            seen[a] = true
            names.Push(a)
        end if
    end for
    m.chips = [{ id: "", label: L("Todas") }]
    for each a in names
        m.chips.Push({ id: a, label: a })
    end for
    Chips_Build()
    m.chipIndex = 0
    Apply_Filter()
    m.zone = "list"
    m.index = 0
    for i = 0 to m.filtered.Count() - 1
        if m.filtered[i] = m.current then m.index = i
    end for
    m.first = m.index - 1
    Fix_Window()
    paint()
end sub

sub Chips_Build()
    m.chipsGroup.removeChildrenIndex(m.chipsGroup.getChildCount(), 0)
    m.chipNodes = []
    x = 0
    for each c in m.chips
        g = m.chipsGroup.createChild("Group")
        g.translation = [x, 0]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.height = 58
        label = g.createChild("Label")
        label.font = "font:SmallestBoldSystemFont"
        label.text = Left(c.label, 28)
        label.height = 58
        label.vertAlign = "center"
        label.translation = [24, 0]
        w = Int(label.boundingRect().width) + 48
        pill.width = w
        m.chipNodes.Push({ g: g, pill: pill, label: label, x: x, w: w })
        x = x + w + 12
    end for
end sub

sub Apply_Filter()
    want = m.chips[m.chipIndex].id
    m.filtered = []
    for i = 0 to m.streams.Count() - 1
        if want = "" or Str_Of(m.streams[i].addon) = want then m.filtered.Push(i)
    end for
    m.empty.visible = m.filtered.Count() = 0
end sub

sub Fix_Window()
    visible = m.slots.Count()
    if m.index < m.first then m.first = m.index
    if m.index > m.first + visible - 2 then m.first = m.index - visible + 2
    maxFirst = m.filtered.Count() - visible
    if m.first > maxFirst then m.first = maxFirst
    if m.first < 0 then m.first = 0
end sub

sub Bind(slot as object, idx as integer)
    s = m.streams[idx]
    slot.addon.text = UCase(Str_Of(s.addon))
    slot.name.text = Str_Of(s.name)
    slot.desc.text = Str_Of(s.desc)
    if idx = m.current then slot.now.text = L("Reproduciendo") else slot.now.text = ""
    slot.badges.removeChildrenIndex(slot.badges.getChildCount(), 0)
    x = 0
    if type(s.badges) = "roArray"
        for each b in s.badges
            if type(b) = "roAssociativeArray" and Str_Of(b.i) <> "" and x < 640
                p = slot.badges.createChild("Poster")
                p.uri = Str_Of(b.i)
                p.height = 28
                p.width = 84
                p.loadHeight = 56
                p.loadDisplayMode = "scaleToFit"
                p.translation = [x, 0]
                x = x + 92
            end if
        end for
    end if
    slot.bound = idx
end sub

sub paint()
    ac = accent()
    for i = 0 to m.slots.Count() - 1
        slot = m.slots[i]
        row = m.first + i
        if row < m.filtered.Count()
            idx = m.filtered[row]
            if slot.bound <> idx then Bind(slot, idx)
            slot.g.visible = true
            slot.g.translation = [0, i * (m.cardH + m.gap)]
            focused = m.zone = "list" and row = m.index
            slot.ring.visible = focused
            slot.ring.blendColor = ac
            if focused then slot.bg.blendColor = "0x2C2C36FF" else slot.bg.blendColor = "0x1E1E26FF"
            slot.addon.color = ac
            slot.now.color = ac
        else
            slot.g.visible = false
            slot.bound = -1
        end if
    end for
    for i = 0 to m.chipNodes.Count() - 1
        n = m.chipNodes[i]
        active = i = m.chipIndex
        if m.zone = "chips" and active
            n.pill.blendColor = "0xFFFFFFFF"
            n.label.color = "0x0C0C0FFF"
        else if active
            n.pill.blendColor = ac
            n.label.color = "0xFFFFFFFF"
        else
            n.pill.blendColor = "0xFFFFFF22"
            n.label.color = "0xFFFFFFFF"
        end if
    end for
    if m.chipNodes.Count() > 0
        c = m.chipNodes[m.chipIndex]
        shift = 0
        if c.x + c.w > 800 then shift = c.x + c.w - 800
        m.chipsGroup.translation = [-shift, 0]
    end if
    if m.zone = "close"
        m.closePill.blendColor = "0xFFFFFFFF"
        m.closeLabel.color = "0x0C0C0FFF"
    else
        m.closePill.blendColor = "0xFFFFFF22"
        m.closeLabel.color = "0xFFFFFFFF"
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        m.top.result = { action: "close" }
        return true
    end if
    if m.zone = "close"
        if key = "down"
            m.zone = "chips"
        else if key = "OK"
            m.top.result = { action: "close" }
        end if
    else if m.zone = "chips"
        if key = "left" or key = "right"
            ni = m.chipIndex
            if key = "left" then ni = ni - 1 else ni = ni + 1
            if ni >= 0 and ni < m.chips.Count()
                m.chipIndex = ni
                Apply_Filter()
                m.index = 0
                m.first = 0
            end if
        else if key = "up"
            m.zone = "close"
        else if key = "down" or key = "OK"
            if m.filtered.Count() > 0 then m.zone = "list"
        end if
    else
        if key = "up"
            if m.index > 0
                m.index = m.index - 1
            else
                m.zone = "chips"
            end if
        else if key = "down"
            if m.index < m.filtered.Count() - 1 then m.index = m.index + 1
        else if key = "OK"
            if m.filtered.Count() > 0 then m.top.result = { action: "pick", index: m.filtered[m.index] }
        end if
        Fix_Window()
    end if
    paint()
    return true
end function
