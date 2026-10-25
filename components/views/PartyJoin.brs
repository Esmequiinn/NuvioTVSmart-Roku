sub init()
    m.top.findNode("title").font.size = 60
    m.subtitle = m.top.findNode("subtitle")
    m.subtitle.font.size = 30
    m.subtitle.text = L("Únete a tus amigos con un código de party")
    m.seats = m.top.findNode("seats")
    m.joinTitle = m.top.findNode("joinTitle")
    m.joinTitle.font.size = 56
    m.joinTitle.text = L("Unirse a una Watch Party")
    m.joinDesc = m.top.findNode("joinDesc")
    m.joinDesc.font.size = 30
    m.joinDesc.text = L("Ingresa el código de 6 caracteres que compartió tu amigo.")
    m.slots = m.top.findNode("slots")
    m.status = m.top.findNode("status")
    m.status.font.size = 28
    m.top.findNode("note1").font.size = 24
    m.top.findNode("note1").text = L("Las Watch Parties son experimentales y es posible que no funcionen como se espera.")
    m.top.findNode("note2").font.size = 24
    m.top.findNode("note2").text = L("Para organizar una party, iníciala desde el reproductor.")
    m.keysGroup = m.top.findNode("keys")
    m.code = ""
    m.row = 0
    m.col = 0
    m.layout = [
        ["A", "B", "C", "D", "E", "F", "G", "H"]
        ["J", "K", "L", "M", "N", "P", "Q", "R"]
        ["S", "T", "U", "V", "W", "X", "Y", "Z"]
        ["2", "3", "4", "5", "6", "7", "8", "9"]
        ["back", "join"]
    ]
    buildKeys()
    buildSlots()
end sub

sub onReset()
    m.code = ""
    m.row = 0
    m.col = 0
    m.top.status = ""
    buildSlots()
    paint()
end sub

sub onProfile()
    p = m.top.profile
    m.seats.removeChildrenIndex(m.seats.getChildCount(), 0)
    if p = invalid then return
    av = m.seats.createChild("Avatar")
    av.size = 128
    av.name = Str_Of(p.name)
    av.color = Str_Of(p.color)
    av.avatar = Str_Of(p.avatar)
    for i = 1 to 2
        seat = m.seats.createChild("Poster")
        seat.uri = "pkg:/images/seat.png"
        seat.width = 128
        seat.height = 128
        seat.blendColor = "0x808080FF"
        seat.translation = [i * 92, 0]
    end for
end sub

sub onStatus()
    m.status.text = m.top.status
end sub

sub buildKeys()
    m.keysGroup.removeChildrenIndex(m.keysGroup.getChildCount(), 0)
    m.keyNodes = []
    size = 88
    gap = 16
    for r = 0 to m.layout.Count() - 1
        rowNodes = []
        x = 0
        for c = 0 to m.layout[r].Count() - 1
            k = m.layout[r][c]
            w = size
            if k = "back" then w = size * 2 + gap
            if k = "join" then w = size * 6 + gap * 5
            g = m.keysGroup.createChild("Group")
            g.translation = [x, r * (size + gap)]
            bg = g.createChild("Poster")
            bg.uri = "pkg:/images/card.9.png"
            bg.width = w
            bg.height = size
            lbl = invalid
            icon = invalid
            if k = "back"
                icon = g.createChild("Poster")
                icon.uri = "pkg:/images/s/ic_backspace_44.png"
                icon.width = 44
                icon.height = 44
                icon.translation = [Int((w - 44) / 2), 22]
            else
                lbl = g.createChild("Label")
                lbl.font = "font:MediumBoldSystemFont"
                lbl.font.size = 34
                lbl.width = w
                lbl.height = size
                lbl.horizAlign = "center"
                lbl.vertAlign = "center"
                if k = "join" then lbl.text = L("Unirse") else lbl.text = k
            end if
            rowNodes.Push({ key: k, bg: bg, label: lbl, icon: icon })
            x = x + w + gap
        end for
        m.keyNodes.Push(rowNodes)
    end for
    paint()
end sub

sub buildSlots()
    m.slots.removeChildrenIndex(m.slots.getChildCount(), 0)
    m.slotNodes = []
    for i = 0 to 5
        g = m.slots.createChild("Group")
        g.translation = [i * 140, 0]
        lbl = g.createChild("Label")
        lbl.font = "font:LargeBoldSystemFont"
        lbl.font.size = 64
        lbl.width = 114
        lbl.height = 80
        lbl.horizAlign = "center"
        lbl.vertAlign = "center"
        lbl.color = "0xFFFFFFFF"
        line = g.createChild("Rectangle")
        line.translation = [0, 92]
        line.width = 114
        line.height = 4
        m.slotNodes.Push({ label: lbl, line: line })
    end for
    paintSlots()
end sub

sub paintSlots()
    for i = 0 to 5
        n = m.slotNodes[i]
        if i < Len(m.code) then n.label.text = Mid(m.code, i + 1, 1) else n.label.text = ""
        if i = Len(m.code) then n.line.color = "0xFFFFFFFF" else n.line.color = "0x3A3A3AFF"
    end for
end sub

function canJoin() as boolean
    return Len(m.code) = 6 and not m.top.busy
end function

sub paint()
    if m.keyNodes = invalid then return
    for r = 0 to m.keyNodes.Count() - 1
        for c = 0 to m.keyNodes[r].Count() - 1
            n = m.keyNodes[r][c]
            active = r = m.row and c = m.col
            enabled = true
            if n.key = "join" then enabled = canJoin()
            if active
                n.bg.blendColor = "0xFFFFFFFF"
                if n.label <> invalid then n.label.color = "0x0D0D0DFF"
                if n.icon <> invalid then n.icon.blendColor = "0x0D0D0DFF"
            else
                n.bg.blendColor = "0x1C1C1CFF"
                color = "0xE6E6E6FF"
                if not enabled then color = "0x6F6F6FFF"
                if n.label <> invalid then n.label.color = color
                if n.icon <> invalid then n.icon.blendColor = color
            end if
        end for
    end for
end sub

sub pressKey(k as string)
    if k = "back"
        if Len(m.code) > 0 then m.code = Left(m.code, Len(m.code) - 1)
    else if k = "join"
        if canJoin() then m.top.event = { type: "join", code: m.code }
        return
    else if Len(m.code) < 6
        m.code = m.code + k
        if Len(m.code) = 6
            m.row = 4
            m.col = 1
        end if
    end if
    m.top.status = ""
    paintSlots()
    paint()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "back"
        m.top.event = { type: "back" }
        return true
    end if
    if key = "up" and m.row > 0
        if m.row = 4
            if m.col = 1 then m.col = 4 else m.col = 0
        end if
        m.row = m.row - 1
    else if key = "down" and m.row < m.layout.Count() - 1
        m.row = m.row + 1
        if m.row = 4
            if m.col <= 1 then m.col = 0 else m.col = 1
        end if
    else if key = "left" and m.col > 0
        m.col = m.col - 1
    else if key = "right" and m.col < m.layout[m.row].Count() - 1
        m.col = m.col + 1
    else if key = "OK"
        pressKey(m.layout[m.row][m.col])
        return true
    else if key = "replay" or key = "rewind"
        pressKey("back")
        return true
    end if
    paint()
    return true
end function

function Str_Of(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function
