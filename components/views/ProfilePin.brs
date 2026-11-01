sub init()
    L_Texts(["forgot"])
    m.heading = m.top.findNode("heading")
    m.heading.font.size = 52
    m.support = m.top.findNode("support")
    m.boxGroup = m.top.findNode("boxes")
    m.keyGroup = m.top.findNode("keys")
    m.value = ""
    m.failed = false
    m.keyIndex = 0
    m.boxes = []
    size = 130
    gap = 26
    x = Int((1920 - (4 * size + 3 * gap)) / 2)
    for i = 0 to 3
        g = m.boxGroup.createChild("Group")
        g.translation = [x + i * (size + gap), 0]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/card.9.png"
        bg.width = size
        bg.height = size
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/iring.9.png"
        ring.width = size
        ring.height = size
        dot = g.createChild("Poster")
        dot.uri = "pkg:/images/c/d32.png"
        dot.width = 32
        dot.height = 32
        dot.translation = [Int((size - 32) / 2), Int((size - 32) / 2)]
        dot.blendColor = "0xFFFFFFFF"
        m.boxes.Push({ bg: bg, ring: ring, dot: dot })
    end for
    labels = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "del", "0", "back"]
    m.keys = []
    w = 170
    h = 92
    gx = 22
    gy = 18
    x0 = Int((1920 - (3 * w + 2 * gx)) / 2)
    for i = 0 to labels.Count() - 1
        col = i mod 3
        row = Int(i / 3)
        g = m.keyGroup.createChild("Group")
        g.translation = [x0 + col * (w + gx), row * (h + gy)]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.width = w
        pill.height = h
        icon = invalid
        lb = invalid
        if labels[i] = "del" or labels[i] = "back"
            icon = g.createChild("Poster")
            sz = 36
            if labels[i] = "del" then icon.uri = "pkg:/images/s/ic_backspace_36.png" else icon.uri = "pkg:/images/s/ic_close_26.png"
            if labels[i] = "back" then sz = 26
            icon.width = sz
            icon.height = sz
            icon.translation = [Int((w - sz) / 2), Int((h - sz) / 2)]
        else
            lb = g.createChild("Label")
            lb.width = w
            lb.height = h
            lb.horizAlign = "center"
            lb.vertAlign = "center"
            lb.font = "font:MediumBoldSystemFont"
            lb.font.size = 40
            lb.text = labels[i]
        end if
        m.keys.Push({ id: labels[i], pill: pill, icon: icon, label: lb })
    end for
    paint()
end sub

sub reset()
    m.value = ""
    m.failed = false
    m.keyIndex = 0
    m.heading.text = L("Ingresa tu PIN para entrar a") + " " + m.top.name + "."
    paint()
    paintSupport()
end sub

sub onError()
    if m.top.error = "" then return
    m.failed = true
    m.value = ""
    paint()
    paintSupport()
end sub

sub paintSupport()
    if m.top.working
        m.support.text = L("Verificando...")
        m.support.color = "0xA9A9B8FF"
    else if m.failed and m.top.error <> ""
        m.support.text = m.top.error
        m.support.color = "0xFF8E8EFF"
    else
        m.support.text = L("Usa las flechas y OK para escribir los 4 dígitos.")
        m.support.color = "0xA9A9B8FF"
    end if
end sub

sub paint()
    for i = 0 to 3
        b = m.boxes[i]
        filled = i < Len(m.value)
        active = i = Len(m.value) and Len(m.value) < 4
        b.dot.visible = filled
        if m.failed
            b.bg.blendColor = "0x311818C2"
            b.ring.blendColor = "0xE35D5DFF"
        else if filled
            b.bg.blendColor = "0xFFFFFF12"
            b.ring.blendColor = "0xFFFFFFEB"
        else if active
            b.bg.blendColor = "0xFFFFFF0A"
            b.ring.blendColor = "0xFFFFFFFF"
        else
            b.bg.blendColor = "0x00000000"
            b.ring.blendColor = "0xFFFFFF80"
        end if
    end for
    for i = 0 to m.keys.Count() - 1
        k = m.keys[i]
        on = i = m.keyIndex
        if on then k.pill.blendColor = "0xFFFFFFFF" else k.pill.blendColor = "0xFFFFFF1F"
        ink = "0xFFFFFFFF"
        if on then ink = "0x0C0C0FFF"
        if k.label <> invalid then k.label.color = ink
        if k.icon <> invalid then k.icon.blendColor = ink
    end for
end sub

sub padPress(id as string)
    if m.top.working then return
    if id = "back"
        m.top.cancel = true
        return
    end if
    if id = "del"
        if Len(m.value) > 0 then m.value = Left(m.value, Len(m.value) - 1)
    else if Len(m.value) < 4
        if m.failed
            m.failed = false
            m.top.error = ""
        end if
        m.value = m.value + id
    end if
    paint()
    paintSupport()
    if Len(m.value) = 4
        submitted = m.value
        m.value = ""
        m.top.pin = submitted
        paint()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    col = m.keyIndex mod 3
    if key = "left"
        if col > 0 then m.keyIndex = m.keyIndex - 1
    else if key = "right"
        if col < 2 then m.keyIndex = m.keyIndex + 1
    else if key = "up"
        if m.keyIndex >= 3 then m.keyIndex = m.keyIndex - 3
    else if key = "down"
        if m.keyIndex < 9 then m.keyIndex = m.keyIndex + 3
    else if key = "OK"
        padPress(m.keys[m.keyIndex].id)
        return true
    else if key = "replay" or key = "rewind"
        padPress("del")
        return true
    else if key = "back"
        m.top.cancel = true
        return true
    end if
    paint()
    return true
end function
