sub init()
    m.list = m.top.findNode("list")
    m.index = 0
    m.nodes = []
    m.top.observeField("focusedChild", "paint")
end sub

sub build()
    m.list.removeChildrenIndex(m.list.getChildCount(), 0)
    m.nodes = []
    chips = m.top.chips
    if chips = invalid then chips = []
    x = 0
    for each c in chips
        g = m.list.createChild("Group")
        g.translation = [x, 0]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/pill.9.png"
        bg.width = 460
        bg.height = 72
        cap = g.createChild("Label")
        cap.translation = [28, 0]
        cap.height = 72
        cap.vertAlign = "center"
        cap.font = "font:SmallSystemFont"
        cap.font.size = 24
        cap.text = c.label
        capW = cap.boundingRect().width
        value = g.createChild("Label")
        value.translation = [28 + capW + 14, 0]
        value.width = 460 - (28 + capW + 14) - 64
        value.height = 72
        value.vertAlign = "center"
        value.font = "font:SmallBoldSystemFont"
        value.font.size = 26
        value.text = c.value
        chev = g.createChild("Poster")
        chev.uri = "pkg:/images/s/chevron_36.png"
        chev.width = 28
        chev.height = 28
        chev.rotation = -1.5708
        chev.scaleRotateCenter = [14, 14]
        chev.translation = [406, 22]
        m.nodes.Push({ bg: bg, cap: cap, value: value, chev: chev })
        x = x + 484
    end for
    if m.index >= m.nodes.Count() then m.index = 0
    paint()
end sub

sub paint()
    focused = m.top.isInFocusChain()
    for i = 0 to m.nodes.Count() - 1
        n = m.nodes[i]
        if focused and i = m.index
            n.bg.blendColor = "0xFFFFFFFF"
            n.cap.color = "0x3A3A44FF"
            n.value.color = "0x0C0C0FFF"
            n.chev.blendColor = "0x0C0C0FFF"
        else
            n.bg.blendColor = "0x1C1C22FF"
            n.cap.color = "0x8E8E9CFF"
            n.value.color = "0xF2F2F7FF"
            n.chev.blendColor = "0x8E8E9CFF"
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left"
        if m.index > 0
            m.index = m.index - 1
            paint()
        else
            m.top.event = { type: "left" }
        end if
        return true
    else if key = "right"
        if m.index < m.nodes.Count() - 1 then m.index = m.index + 1
        paint()
        return true
    else if key = "down"
        m.top.event = { type: "down" }
        return true
    else if key = "up"
        return true
    else if key = "OK"
        chips = m.top.chips
        if chips <> invalid and m.index < chips.Count() then m.top.event = { type: "pick", id: chips[m.index].id }
        return true
    end if
    return false
end function
