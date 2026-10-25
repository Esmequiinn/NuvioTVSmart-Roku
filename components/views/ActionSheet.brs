sub init()
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
end sub

function Sheet_Str(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub render()
    cfg = m.top.config
    if cfg = invalid then return
    m.items = []
    if type(cfg.items) = "roArray" then m.items = cfg.items
    m.tv = Sheet_Str(cfg.style) = "tv"
    m.cards = Sheet_Str(cfg.style) = "cards" or m.tv
    width = 820
    if m.tv then width = 1040
    if cfg.width <> invalid then width = cfg.width
    pad = 44
    rowH = 100
    gap = 0
    if m.cards
        pad = 56
        rowH = 92
        gap = 14
    end if
    if m.tv
        pad = 52
        rowH = 84
        gap = 22
    end if
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
    ry = 0
    inner = width - pad * 2
    for i = 0 to m.items.Count() - 1
        it = m.items[i]
        g = m.rows.createChild("Group")
        g.translation = [0, ry]
        if not m.cards and i > 0
            line = g.createChild("Rectangle")
            line.width = inner
            line.height = 2
            line.translation = [pad, -1]
            line.color = "0x2C2C30FF"
        end if
        hl = g.createChild("Poster")
        hl.uri = "pkg:/images/row.9.png"
        if m.cards
            hl.width = inner
            hl.height = rowH
            hl.translation = [pad, 0]
            hl.visible = true
        else
            hl.width = width - 28
            hl.height = rowH - 12
            hl.translation = [14, 6]
            hl.visible = false
        end if
        label = g.createChild("Label")
        label.font = "font:MediumBoldSystemFont"
        label.font.size = 34
        textX = pad
        if m.cards then textX = pad + 36
        label.translation = [textX, 0]
        label.width = inner - 80 - (textX - pad)
        if m.tv
            label.translation = [pad + 24, 0]
            label.width = inner - 48
            label.horizAlign = "center"
            label.font.size = 32
        end if
        label.height = rowH
        label.vertAlign = "center"
        label.wrap = false
        label.text = Sheet_Str(it.label)
        iconUri = Sheet_Str(it.icon)
        if it.checked = true then iconUri = "pkg:/images/ic_check_s.png"
        if m.tv then iconUri = ""
        icon = invalid
        if iconUri <> ""
            icon = g.createChild("Poster")
            icon.uri = iconUri.Replace("/images/", "/images/s/").Replace(".png", "_44.png")
            icon.width = 44
            icon.height = 44
            right = width - pad - 44
            if m.cards then right = width - pad - 44 - 28
            icon.translation = [right, Int((rowH - 44) / 2)]
        end if
        danger = it.danger = true and not m.tv
        m.nodes.Push({ hl: hl, label: label, icon: icon, danger: danger, checked: it.checked = true })
        ry = ry + m.step
    end for
    height = y + listH + 30
    if m.cards then height = height + 14
    m.bg.width = width
    m.bg.height = height
    m.border.width = width
    m.border.height = height
    m.panel.translation = [Int((1920 - width) / 2), Int((1080 - height) / 2)]
    m.index = 0
    if cfg.focus <> invalid and cfg.focus >= 0 and cfg.focus < m.items.Count() then m.index = cfg.focus
    m.first = 0
    paint()
end sub

sub paint()
    if m.index < m.first then m.first = m.index
    if m.index >= m.first + m.visibleRows then m.first = m.index - m.visibleRows + 1
    m.rows.translation = [0, -m.first * m.step]
    for i = 0 to m.nodes.Count() - 1
        n = m.nodes[i]
        active = i = m.index
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
            if n.icon <> invalid
                if n.danger then n.icon.blendColor = "0xC2185BFF" else n.icon.blendColor = "0x0D0D0DFF"
            end if
        else
            if n.danger then n.label.color = "0xE0839CFF" else n.label.color = "0xF2F2F2FF"
            if n.icon <> invalid
                if n.danger then n.icon.blendColor = "0xE0839CFF" else n.icon.blendColor = "0xF2F2F2FF"
            end if
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "back" or key = "options" or (key = "left" and m.cards)
        m.top.closed = true
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
