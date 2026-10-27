sub init()
    m.title = m.top.findNode("title")
    m.title.font.size = 40
    m.closeBg = m.top.findNode("closeBg")
    m.closeText = m.top.findNode("closeText")
    m.closeText.font.size = 28
    m.body = m.top.findNode("body")
    m.width = 944
    m.items = []
    m.index = 0
    m.mode = ""
end sub

function Pp_Str(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub render()
    st = m.top.state
    if st = invalid then return
    m.title.text = "Watch Party"
    m.closeText.text = L("Cerrar")
    keep = ""
    if m.index > 0 and m.index <= m.items.Count() then keep = m.items[m.index - 1].id
    m.body.removeChildrenIndex(m.body.getChildCount(), 0)
    m.items = []
    mode = Pp_Str(st.mode)
    if mode = "invite"
        renderInvite(st)
    else if mode = "party"
        renderParty(st)
    else
        renderStart(st)
    end if
    if mode <> m.mode
        m.mode = mode
        m.index = 1
        if m.items.Count() = 0 then m.index = 0
    else
        m.index = 0
        for i = 0 to m.items.Count() - 1
            if m.items[i].id = keep then m.index = i + 1
        end for
        if m.index = 0 and m.items.Count() > 0 then m.index = 1
    end if
    paint()
end sub

function addLabel(text as string, x as integer, y as integer, w as integer, size as integer, color as string, bold as boolean, center as boolean) as object
    lbl = m.body.createChild("Label")
    if bold then lbl.font = "font:MediumBoldSystemFont" else lbl.font = "font:MediumSystemFont"
    lbl.font.size = size
    lbl.color = color
    lbl.translation = [x, y]
    lbl.width = w
    lbl.wrap = true
    lbl.maxLines = 3
    if center then lbl.horizAlign = "center"
    lbl.text = text
    return lbl
end function

function lineCount(text as string, w as integer, size as integer) as integer
    per = Int(w / (size * 0.5))
    if per < 1 then per = 1
    n = Int((Len(text) + per - 1) / per)
    if n < 1 then n = 1
    if n > 3 then n = 3
    return n
end function

function addButton(id as string, label as string, x as integer, y as integer, w as integer, primary as boolean) as integer
    g = m.body.createChild("Group")
    g.translation = [x, y]
    bg = g.createChild("Poster")
    bg.uri = "pkg:/images/pill.9.png"
    bg.width = w
    bg.height = 84
    ring = g.createChild("Poster")
    ring.uri = "pkg:/images/focus_ring.9.png"
    ring.width = w
    ring.height = 84
    ring.visible = false
    lbl = g.createChild("Label")
    lbl.font = "font:MediumSystemFont"
    lbl.font.size = 30
    lbl.width = w
    lbl.height = 84
    lbl.horizAlign = "center"
    lbl.vertAlign = "center"
    lbl.text = label
    m.items.Push({ id: id, kind: "button", primary: primary, bg: bg, ring: ring, label: lbl, y: y, h: 84 })
    return y + 84
end function

function addRow(id as string, icon as string, title as string, desc as string, y as integer, toggle as dynamic) as integer
    h = 96
    if desc <> "" then h = 124
    g = m.body.createChild("Group")
    g.translation = [0, y]
    bg = g.createChild("Poster")
    bg.uri = "pkg:/images/setrow.9.png"
    bg.width = m.width
    bg.height = h
    ring = g.createChild("Poster")
    ring.uri = "pkg:/images/setrow_ring.9.png"
    ring.width = m.width
    ring.height = h
    ring.visible = false
    x = 36
    ic = invalid
    if icon <> ""
        ic = g.createChild("Poster")
        ic.uri = icon.Replace("/images/", "/images/s/").Replace(".png", "_40.png")
        ic.width = 40
        ic.height = 40
        ic.translation = [36, Int((h - 40) / 2)]
        x = 100
    end if
    t = g.createChild("Label")
    t.font = "font:MediumSystemFont"
    t.font.size = 30
    t.width = m.width - x - 160
    t.text = title
    d = invalid
    if desc <> ""
        t.translation = [x, 18]
        d = g.createChild("Label")
        d.font = "font:SmallestSystemFont"
        d.font.size = 22
        d.width = m.width - x - 160
        d.wrap = true
        d.maxLines = 2
        d.translation = [x, 60]
        d.text = desc
    else
        t.translation = [x, 0]
        t.height = h
        t.vertAlign = "center"
    end if
    track = invalid
    knob = invalid
    if toggle <> invalid
        track = g.createChild("Poster")
        track.uri = "pkg:/images/toggle_track.png"
        track.width = 76
        track.height = 42
        track.translation = [m.width - 112, Int((h - 42) / 2)]
        knob = g.createChild("Poster")
        knob.uri = "pkg:/images/c/d32.png"
        knob.width = 32
        knob.height = 32
        if toggle = true then knob.translation = [m.width - 73, Int((h - 32) / 2)] else knob.translation = [m.width - 107, Int((h - 32) / 2)]
    end if
    m.items.Push({ id: id, kind: "row", bg: bg, ring: ring, label: t, desc: d, icon: ic, track: track, on: toggle = true, y: y, h: h })
    return y + h
end function

function codeSlots(code as string, y as integer, slotW as integer, size as integer) as integer
    gap = 18
    total = slotW * 6 + gap * 5
    x = Int((m.width - total) / 2)
    for i = 0 to 5
        ch = ""
        if i < Len(code) then ch = Mid(code, i + 1, 1)
        lbl = m.body.createChild("Label")
        lbl.font = "font:LargeBoldSystemFont"
        lbl.font.size = size
        lbl.color = "0xFFFFFFFF"
        lbl.translation = [x, y]
        lbl.width = slotW
        lbl.height = size + 20
        lbl.horizAlign = "center"
        lbl.vertAlign = "center"
        lbl.text = ch
        line = m.body.createChild("Rectangle")
        line.translation = [x, y + size + 30]
        line.width = slotW
        line.height = 4
        line.color = "0x4D4D4DFF"
        x = x + slotW + gap
    end for
    return y + size + 40
end function

sub renderStart(st as object)
    y = 120
    seats = m.body.createChild("Group")
    av = seats.createChild("Avatar")
    av.size = 132
    av.name = Pp_Str(st.profileName)
    av.color = Pp_Str(st.profileColor)
    av.avatar = Pp_Str(st.profileAvatar)
    for i = 1 to 2
        seat = seats.createChild("Poster")
        seat.uri = "pkg:/images/seat.png"
        seat.width = 132
        seat.height = 132
        seat.blendColor = "0x808080FF"
        seat.translation = [i * 96, 0]
    end for
    seats.translation = [Int((m.width - 132 - 192) / 2), y]
    y = y + 172
    addLabel(L("Ver juntos"), 0, y, m.width, 48, "0xFFFFFFFF", true, true)
    y = y + 74
    desc = L("Invita a tus amigos. Cada uno reproduce desde sus propias fuentes y todos se mantienen sincronizados.")
    addLabel(desc, 40, y, m.width - 80, 28, "0xB3B3B3FF", false, true)
    y = y + 40 * lineCount(desc, m.width - 80, 28) + 40
    if st.signedIn = true
        y = addButton("start", L("Iniciar Watch Party"), Int((m.width - 460) / 2), y, 460, true) + 40
    else
        note = L("Inicia sesión en tu cuenta de Nuvio para usar las Watch Parties.")
        addLabel(note, 40, y, m.width - 80, 28, "0xE0839CFF", false, true)
        y = y + 40 * lineCount(note, m.width - 80, 28) + 30
    end if
    exp = L("Las Watch Parties son experimentales y es posible que no funcionen como se espera.")
    addLabel(exp, 40, y, m.width - 80, 24, "0x808080FF", false, true)
end sub

sub renderParty(st as object)
    y = 0
    media = Pp_Str(st.mediaTitle)
    if media <> ""
        addLabel(media, 0, y, m.width, 36, "0xFFFFFFFF", true, false)
        y = y + 52
        ep = Pp_Str(st.episode)
        if ep <> ""
            addLabel(ep, 0, y, m.width, 26, "0xB3B3B3FF", false, false)
            y = y + 40
        end if
        y = y + 16
    end if
    addLabel(L("Código de la party"), 0, y, m.width, 26, "0xB3B3B3FF", false, true)
    y = y + 44
    y = codeSlots(Pp_Str(st.code), y, 96, 64) + 30
    members = st.members
    if type(members) <> "roArray" then members = []
    maxMembers = 8
    if st.maxMembers <> invalid then maxMembers = st.maxMembers
    addLabel(L("{n} de {m} plazas").Replace("{n}", members.Count().ToStr()).Replace("{m}", maxMembers.ToStr()), 0, y, m.width, 26, "0xB3B3B3FF", false, false)
    y = y + 46
    for each mem in members
        g = m.body.createChild("Group")
        g.translation = [0, y]
        av = g.createChild("Avatar")
        av.size = 64
        av.name = Pp_Str(mem.name)
        av.color = Pp_Str(mem.color)
        av.avatar = Pp_Str(mem.avatar)
        av.translation = [8, 8]
        nm = g.createChild("Label")
        nm.font = "font:MediumSystemFont"
        nm.font.size = 30
        nm.color = "0xFFFFFFFF"
        nm.translation = [96, 6]
        name = Pp_Clean(Pp_Str(mem.name))
        if mem.you = true then name = name + "  (" + L("Tú") + ")"
        nm.text = name
        status = g.createChild("Label")
        status.font = "font:SmallestSystemFont"
        status.font.size = 22
        status.color = "0x9E9E9EFF"
        status.translation = [96, 46]
        status.text = Pp_Str(mem.status)
        if mem.host = true
            w = Int(nm.boundingRect().width)
            if w <= 0 then w = Len(name) * 16
            badgeW = 150
            bg = g.createChild("Poster")
            bg.uri = "pkg:/images/pill40.9.png"
            bg.width = badgeW
            bg.height = 40
            bg.blendColor = m.top.accent
            bg.translation = [96 + w + 18, 8]
            bl = g.createChild("Label")
            bl.font = "font:SmallestBoldSystemFont"
            bl.font.size = 22
            bl.color = Ui_Ink(m.top.accent)
            bl.width = badgeW
            bl.height = 40
            bl.horizAlign = "center"
            bl.vertAlign = "center"
            bl.translation = [96 + w + 18, 8]
            bl.text = L("Anfitrión")
        end if
        y = y + 88
    end for
    if members.Count() < maxMembers
        y = addRow("invite", "pkg:/images/ic_add_r.png", L("Invitar a un amigo"), "", y + 8, invalid) + 24
    else
        y = y + 16
    end if
    if st.isHost = true
        y = addRow("hostOnly", "", L("Solo yo controlo la reproducción"), L("Los demás pueden seguir pausando o retrocediendo solo para ellos."), y, st.hostOnly = true) + 14
    else if st.hostOnly = true
        g = m.body.createChild("Group")
        g.translation = [0, y]
        ic = g.createChild("Poster")
        ic.uri = "pkg:/images/s/ic_lock_32.png"
        ic.width = 32
        ic.height = 32
        ic.blendColor = "0x9E9E9EFF"
        ic.translation = [0, 4]
        t = g.createChild("Label")
        t.font = "font:SmallSystemFont"
        t.font.size = 26
        t.color = "0x9E9E9EFF"
        t.translation = [46, 0]
        t.text = L("Solo el anfitrión puede controlar la reproducción")
        y = y + 56
    end if
    y = addRow("leave", "pkg:/images/ic_logout.png", L("Salir de la party"), "", y, invalid) + 14
    if st.isHost = true and members.Count() > 1
        y = addRow("end", "pkg:/images/ic_stop.png", L("Terminar para todos"), "", y, invalid) + 14
    end if
    addLabel(L("Las Watch Parties son experimentales y es posible que no funcionen como se espera."), 0, y + 16, m.width, 24, "0x808080FF", false, false)
end sub

sub renderInvite(st as object)
    y = 20
    addLabel(L("Invitar a un amigo"), 0, y, m.width, 40, "0xFFFFFFFF", true, true)
    y = y + 80
    back = m.body.createChild("Poster")
    back.uri = "pkg:/images/card.9.png"
    back.width = 380
    back.height = 380
    back.translation = [Int((m.width - 380) / 2), y]
    qr = m.body.createChild("Poster")
    qr.width = 340
    qr.height = 340
    qr.loadWidth = 420
    qr.loadHeight = 420
    qr.translation = [Int((m.width - 340) / 2), y + 20]
    qr.uri = "https://api.qrserver.com/v1/create-qr-code/?size=420x420&margin=0&data=" + Pp_Str(st.inviteLink).EncodeUriComponent()
    y = y + 410
    addLabel(L("Escanea con un celular para unirte"), 0, y, m.width, 28, "0xB3B3B3FF", false, true)
    y = y + 56
    y = codeSlots(Pp_Str(st.code), y, 100, 68) + 30
    share = L("O comparte el código. Tus amigos pueden ingresarlo en Watch Party en cualquier app de Nuvio.")
    addLabel(share, 40, y, m.width - 80, 24, "0x9E9E9EFF", false, true)
end sub

sub paint()
    focusClose = m.index = 0
    if focusClose
        m.closeBg.blendColor = "0xFFFFFFFF"
        m.closeText.color = "0x0D0D0DFF"
    else
        m.closeBg.blendColor = "0x2A2A2AFF"
        m.closeText.color = "0xFFFFFFFF"
    end if
    for i = 0 to m.items.Count() - 1
        it = m.items[i]
        active = m.index = i + 1
        if it.kind = "button"
            if active
                it.bg.blendColor = "0xFFFFFFFF"
                it.label.color = "0x0D0D0DFF"
            else if it.primary
                it.bg.blendColor = "0x3A3A3AFF"
                it.label.color = "0xFFFFFFFF"
            else
                it.bg.blendColor = "0x2A2A2AFF"
                it.label.color = "0xFFFFFFFF"
            end if
            it.ring.visible = false
        else
            it.ring.visible = active
            if active then it.bg.blendColor = "0x2E2E2EFF" else it.bg.blendColor = "0x222222FF"
            it.label.color = "0xFFFFFFFF"
            if it.desc <> invalid then it.desc.color = "0xA6A6A6FF"
            if it.icon <> invalid then it.icon.blendColor = "0xFFFFFFFF"
            if it.track <> invalid
                if it.on then it.track.blendColor = m.top.accent else it.track.blendColor = "0x4D4D4DFF"
            end if
        end if
    end for
    target = 0
    if m.index > 0
        it = m.items[m.index - 1]
        bottom = it.y + it.h
        if bottom > 860 then target = 860 - bottom
    end if
    m.body.translation = [48, target]
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "back"
        if m.mode = "invite" then m.top.event = { type: "inviteBack" } else m.top.event = { type: "close" }
        return true
    end if
    if key = "up" and m.index > 0
        m.index = m.index - 1
        paint()
    else if key = "down" and m.index < m.items.Count()
        m.index = m.index + 1
        paint()
    else if key = "OK"
        if m.index = 0
            if m.mode = "invite" then m.top.event = { type: "inviteBack" } else m.top.event = { type: "close" }
        else
            m.top.event = { type: m.items[m.index - 1].id }
        end if
    end if
    return true
end function

function Pp_Clean(text as string) as string
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(text)
    if ba.Count() = Len(text) then return text
    out = ""
    n = Len(text)
    for i = 1 to n
        cp = Asc(Mid(text, i, 1))
        if cp < 8192 or cp = 8226 then out = out + Chr(cp)
    end for
    return out.Trim()
end function
