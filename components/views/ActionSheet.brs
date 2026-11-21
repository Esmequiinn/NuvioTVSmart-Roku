sub init()
    m.scrim = m.top.findNode("scrim")
    m.panel = m.top.findNode("panel")
    m.bg = m.top.findNode("bg")
    m.border = m.top.findNode("border")
    m.title = m.top.findNode("title")
    m.subtitle = m.top.findNode("subtitle")
    m.clip = m.top.findNode("clip")
    m.rows = m.top.findNode("rows")
    m.title.font.size = 40
    m.subtitle.font.size = 26
    m.items = []
    m.nodes = []
    m.index = 0
    m.first = 0
    m.visibleRows = 1
    m.step = 100
    m.cards = false
    m.pooled = false
    m.leftAction = "close"
    m.pad = 44
    m.rowH = 100
    m.gap = 0
    m.sheetW = 820
end sub

function Sheet_Str(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub Sheet_BindRow(slot as object, it as object)
    label = Sheet_Str(it.label)
    badge = Sheet_Str(it.badge)
    swatch = Sheet_Str(it.swatch)
    hasSwatch = swatch <> "" and not m.tv and slot.dot <> invalid
    if slot.dot <> invalid
        slot.dot.visible = hasSwatch
        if hasSwatch then slot.dot.blendColor = "0x" + swatch + "FF"
    end if
    textX = m.pad
    if m.cards then textX = m.pad + 36
    if hasSwatch then textX = textX + 60
    iconUri = Sheet_Str(it.icon)
    if it.checked = true then iconUri = "pkg:/images/ic_check_s.png"
    isChevron = false
    if iconUri = "" and it.chevron = true
        iconUri = "pkg:/images/s/chevron_36.png"
        isChevron = true
    else if iconUri <> ""
        iconUri = iconUri.Replace("/images/", "/images/s/").Replace(".png", "_44.png")
    end if
    if m.tv then iconUri = ""
    inner = m.sheetW - m.pad * 2
    rightReserve = 40
    if iconUri <> "" then rightReserve = rightReserve + 60
    if badge <> "" then rightReserve = rightReserve + 220
    if m.tv
        slot.label.translation = [m.pad + 24, 0]
        slot.label.width = inner - 48
        slot.label.horizAlign = "center"
        slot.label.font.size = 32
    else
        slot.label.translation = [textX, 0]
        w = inner - rightReserve - (textX - m.pad)
        if w < 120 then w = 120
        slot.label.width = w
        slot.label.horizAlign = "left"
        slot.label.font.size = 34
    end if
    slot.label.text = label
    if slot.badge <> invalid
        if badge <> "" and not m.tv
            badgeRight = m.sheetW - m.pad - 12
            if m.cards then badgeRight = m.sheetW - m.pad - 36
            if iconUri <> "" then badgeRight = badgeRight - 58
            slot.badge.width = 210
            slot.badge.translation = [badgeRight - 210, 0]
            slot.badge.text = badge
            slot.badge.visible = true
        else
            slot.badge.visible = false
        end if
    end if
    if slot.icon <> invalid
        if iconUri <> ""
            sz = 44
            if isChevron then sz = 34
            right = m.sheetW - m.pad - sz
            if m.cards then right = m.sheetW - m.pad - sz - 28
            slot.icon.width = sz
            slot.icon.height = sz
            slot.icon.translation = [right, Int((m.rowH - sz) / 2)]
            slot.icon.uri = iconUri
            slot.icon.visible = true
        else
            slot.icon.visible = false
        end if
    end if
    slot.danger = it.danger = true and not m.tv
    slot.checked = it.checked = true
end sub

function Sheet_MakeRow(withDivider as boolean, withSwatch as boolean) as object
    g = m.rows.createChild("Group")
    div = invalid
    if withDivider
        div = g.createChild("Rectangle")
        div.width = m.sheetW - m.pad * 2
        div.height = 2
        div.translation = [m.pad, -1]
        div.color = "0x2C2C30FF"
    end if
    hl = g.createChild("Poster")
    hl.uri = "pkg:/images/row.9.png"
    if m.cards
        hl.width = m.sheetW - m.pad * 2
        hl.height = m.rowH
        hl.translation = [m.pad, 0]
        hl.visible = true
    else
        hl.width = m.sheetW - 28
        hl.height = m.rowH - 12
        hl.translation = [14, 6]
        hl.visible = false
    end if
    dot = invalid
    if withSwatch
        dot = g.createChild("Poster")
        dot.uri = "pkg:/images/c/d40.png"
        dot.width = 40
        dot.height = 40
        dotX = m.pad
        if m.cards then dotX = m.pad + 36
        dot.translation = [dotX, Int((m.rowH - 40) / 2)]
        dot.visible = false
    end if
    label = g.createChild("Label")
    label.font = "font:MediumBoldSystemFont"
    label.font.size = 34
    label.height = m.rowH
    label.vertAlign = "center"
    label.wrap = false
    badge = g.createChild("Label")
    badge.font = "font:SmallSystemFont"
    badge.font.size = 24
    badge.height = m.rowH
    badge.vertAlign = "center"
    badge.horizAlign = "right"
    badge.wrap = false
    badge.visible = false
    icon = g.createChild("Poster")
    icon.visible = false
    return { g: g, div: div, hl: hl, dot: dot, label: label, badge: badge, icon: icon, danger: false, checked: false }
end function

sub render()
    cfg = m.top.config
    if cfg = invalid then return
    m.items = []
    if type(cfg.items) = "roArray" then m.items = cfg.items
    m.tv = Sheet_Str(cfg.style) = "tv"
    m.cards = Sheet_Str(cfg.style) = "cards" or m.tv
    m.leftAction = Sheet_Str(cfg.leftAction)
    if m.leftAction = "" then m.leftAction = "close"
    if m.scrim <> invalid
        m.scrim.height = 1080
        m.scrim.visible = cfg.previewBottom <> true
    end if
    width = 820
    if m.tv then width = 1040
    if cfg.width <> invalid then width = cfg.width
    m.sheetW = width
    pad = 44
    rowH = 100
    gap = 0
    if m.cards
        pad = 56
        rowH = 92
        gap = 14
    end if
    if cfg.compact = true and m.cards
        pad = 48
        rowH = 72
        gap = 10
    end if
    if m.tv
        pad = 52
        rowH = 84
        gap = 22
    end if
    m.pad = pad
    m.rowH = rowH
    m.gap = gap
    m.step = rowH + gap
    m.title.width = width - pad * 2
    m.subtitle.width = width - pad * 2
    m.title.text = Sheet_Str(cfg.title)
    m.subtitle.text = Sheet_Str(cfg.subtitle)
    y = 40
    if m.cards then y = 52
    if m.title.text <> ""
        m.title.translation = [pad, y]
        y = y + 58
    end if
    if m.subtitle.text <> ""
        m.subtitle.translation = [pad, y]
        perLine = Int((width - pad * 2) / 13)
        lines = 0
        for each part in m.subtitle.text.Split(chr(10))
            n = Int((Len(part) + perLine - 1) / perLine)
            if n < 1 then n = 1
            lines = lines + n
        end for
        if lines > 10 then lines = 10
        m.subtitle.maxLines = lines
        m.subtitle.height = 36 * lines
        y = y + 36 * lines + 6
    end if
    if m.title.text <> "" or m.subtitle.text <> "" then y = y + 22 else y = 18
    available = 1080 - 120 - y - 24
    m.visibleRows = Int((available + gap) / m.step)
    if m.visibleRows < 1 then m.visibleRows = 1
    if m.visibleRows > m.items.Count() then m.visibleRows = m.items.Count()
    m.clip.translation = [0, y]
    listH = m.visibleRows * m.step - gap
    if listH < 0 then listH = 0
    m.clip.clippingRect = [0, 0, width, listH]
    m.rows.removeChildrenIndex(m.rows.getChildCount(), 0)
    m.nodes = []
    m.pooled = m.items.Count() > 24
    if m.pooled
        poolCount = m.visibleRows + 2
        if poolCount > m.items.Count() then poolCount = m.items.Count()
        for slotIdx = 0 to poolCount - 1
            slot = Sheet_MakeRow(not m.cards, true)
            slot.g.translation = [0, slotIdx * m.step]
            m.nodes.Push(slot)
        end for
    else
        ry = 0
        for i = 0 to m.items.Count() - 1
            it = m.items[i]
            slot = Sheet_MakeRow(not m.cards and i > 0, Sheet_Str(it.swatch) <> "" and not m.tv)
            slot.g.translation = [0, ry]
            Sheet_BindRow(slot, it)
            m.nodes.Push(slot)
            ry = ry + m.step
        end for
    end if
    height = y + listH + 30
    if m.cards then height = height + 14
    m.bg.width = width
    m.bg.height = height
    m.border.width = width
    m.border.height = height
    panelY = Int((1080 - height) / 2)
    if cfg.y <> invalid
        panelY = cfg.y
        if panelY < 20 then panelY = 20
    end if
    m.panel.translation = [Int((1920 - width) / 2), panelY]
    m.index = 0
    if cfg.focus <> invalid and cfg.focus >= 0 and cfg.focus < m.items.Count() then m.index = cfg.focus
    m.first = 0
    paint()
end sub

sub paint()
    if m.items.Count() = 0
        m.rows.translation = [0, 0]
        m.top.focusIndex = 0
        return
    end if
    if m.index < 0 then m.index = 0
    if m.index >= m.items.Count() then m.index = m.items.Count() - 1
    if m.index < m.first then m.first = m.index
    if m.index >= m.first + m.visibleRows then m.first = m.index - m.visibleRows + 1
    maxFirst = m.items.Count() - m.visibleRows
    if maxFirst < 0 then maxFirst = 0
    if m.first > maxFirst then m.first = maxFirst
    if m.first < 0 then m.first = 0
    m.top.focusIndex = m.index
    if m.pooled
        m.rows.translation = [0, 0]
        for slotIdx = 0 to m.nodes.Count() - 1
            n = m.nodes[slotIdx]
            itemIdx = m.first + slotIdx
            if itemIdx < m.items.Count()
                n.g.visible = true
                if n.div <> invalid then n.div.visible = not m.cards and itemIdx > 0
                Sheet_BindRow(n, m.items[itemIdx])
                Sheet_PaintSlot(n, itemIdx = m.index)
            else
                n.g.visible = false
            end if
        end for
    else
        m.rows.translation = [0, -m.first * m.step]
        for i = 0 to m.nodes.Count() - 1
            Sheet_PaintSlot(m.nodes[i], i = m.index)
        end for
    end if
end sub

sub Sheet_PaintSlot(n as object, active as boolean)
    if m.cards
        if active
            n.hl.blendColor = "0xFFFFFFFF"
        else if m.tv
            n.hl.blendColor = "0x242424FF"
        else if n.checked
            n.hl.blendColor = "0x3A3A3EFF"
        else
            n.hl.blendColor = "0x26262AFF"
        end if
    else
        n.hl.visible = active
        if active then n.hl.blendColor = "0xFFFFFFFF"
    end if
    if active
        if n.danger then n.label.color = "0xC2185BFF" else n.label.color = "0x0D0D0DFF"
        if n.badge <> invalid then n.badge.color = "0x383840FF"
        if n.icon <> invalid and n.icon.visible
            if n.danger then n.icon.blendColor = "0xC2185BFF" else n.icon.blendColor = "0x0D0D0DFF"
        end if
    else
        if n.danger then n.label.color = "0xE0839CFF" else n.label.color = "0xF2F2F2FF"
        if n.badge <> invalid then n.badge.color = "0xA6A6B2FF"
        if n.icon <> invalid and n.icon.visible
            if n.danger then n.icon.blendColor = "0xE0839CFF" else n.icon.blendColor = "0xF2F2F2FF"
        end if
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "options"
        m.top.closed = true
        return true
    end if
    if key = "back" or (key = "left" and m.cards)
        if m.leftAction = "back"
            m.top.chosen = "__back__"
        else
            m.top.closed = true
        end if
        return true
    end if
    if key = "up" and m.index > 0
        m.index = m.index - 1
        paint()
    else if key = "down" and m.index < m.items.Count() - 1
        m.index = m.index + 1
        paint()
    else if key = "rewind" and m.index > 0
        m.index = m.index - m.visibleRows
        if m.index < 0 then m.index = 0
        paint()
    else if key = "fastforward" and m.index < m.items.Count() - 1
        m.index = m.index + m.visibleRows
        if m.index > m.items.Count() - 1 then m.index = m.items.Count() - 1
        paint()
    else if key = "OK" and m.index < m.items.Count()
        m.top.chosen = Sheet_Str(m.items[m.index].id)
    end if
    return true
end function
