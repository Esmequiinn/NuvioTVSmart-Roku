sub init()
    m.heading = m.top.findNode("heading")
    m.clearBg = m.top.findNode("clearBg")
    m.clearText = m.top.findNode("clearText")
    m.list = m.top.findNode("list")
    m.heading.font.size = 36
    m.clearText.font.size = 26
    m.heading.text = L("Búsquedas recientes")
    m.clearText.text = L("Borrar historial")
    m.rowIndex = 0
    m.col = 0
    m.rows = []
    m.top.observeField("focusedChild", "paint")
end sub

sub build()
    m.list.removeChildrenIndex(m.list.getChildCount(), 0)
    m.rows = []
    items = m.top.items
    if items = invalid then items = []
    y = 0
    for each q in items
        g = m.list.createChild("Group")
        g.translation = [0, y]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/pill.9.png"
        bg.width = 812
        bg.height = 72
        icon = g.createChild("Poster")
        icon.uri = "pkg:/images/s/ic_history_32.png"
        icon.width = 32
        icon.height = 32
        icon.translation = [24, 20]
        text = g.createChild("Label")
        text.translation = [76, 0]
        text.width = 712
        text.height = 72
        text.vertAlign = "center"
        text.font = "font:SmallSystemFont"
        text.font.size = 28
        text.text = q
        xbg = g.createChild("Poster")
        xbg.uri = "pkg:/images/pill.9.png"
        xbg.width = 72
        xbg.height = 72
        xbg.translation = [828, 0]
        x = g.createChild("Poster")
        x.uri = "pkg:/images/s/ic_close_26.png"
        x.width = 26
        x.height = 26
        x.translation = [851, 23]
        m.rows.Push({ query: q, bg: bg, icon: icon, text: text, xbg: xbg, x: x })
        y = y + 84
    end for
    if m.rowIndex >= m.rows.Count() then m.rowIndex = m.rows.Count() - 1
    if m.rows.Count() = 0 then m.rowIndex = -1
    paint()
end sub

sub paint()
    focused = m.top.isInFocusChain()
    on = focused and m.rowIndex = -1
    if on
        m.clearBg.blendColor = "0xFFFFFFFF"
        m.clearText.color = "0x0C0C0FFF"
    else
        m.clearBg.blendColor = "0x1C1C22FF"
        m.clearText.color = "0xD8D8E0FF"
    end if
    for i = 0 to m.rows.Count() - 1
        r = m.rows[i]
        rowOn = focused and i = m.rowIndex
        if rowOn and m.col = 0
            r.bg.blendColor = "0xFFFFFFFF"
            r.text.color = "0x0C0C0FFF"
            r.icon.blendColor = "0x0C0C0FFF"
        else
            r.bg.blendColor = "0x1C1C22FF"
            r.text.color = "0xD8D8E0FF"
            r.icon.blendColor = "0x8E8E9CFF"
        end if
        if rowOn and m.col = 1
            r.xbg.blendColor = "0xFFFFFFFF"
            r.x.blendColor = "0x0C0C0FFF"
        else
            r.xbg.blendColor = "0x1C1C22FF"
            r.x.blendColor = "0x8E8E9CFF"
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "up"
        if m.rowIndex >= 0
            m.rowIndex = m.rowIndex - 1
            if m.rowIndex = -1 then m.col = 0
        end if
        paint()
        return true
    else if key = "down"
        if m.rowIndex < m.rows.Count() - 1 then m.rowIndex = m.rowIndex + 1
        paint()
        return true
    else if key = "right"
        if m.rowIndex >= 0 then m.col = 1
        paint()
        return true
    else if key = "left"
        if m.col = 1 and m.rowIndex >= 0
            m.col = 0
            paint()
        else
            m.top.event = { type: "left" }
        end if
        return true
    else if key = "OK"
        if m.rowIndex = -1
            m.top.event = { type: "clear" }
        else if m.rowIndex < m.rows.Count()
            q = m.rows[m.rowIndex].query
            if m.col = 1
                m.top.event = { type: "remove", query: q }
            else
                m.top.event = { type: "search", query: q }
            end if
        end if
        return true
    end if
    return false
end function
