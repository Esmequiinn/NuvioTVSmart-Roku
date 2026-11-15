sub init()
    L_Texts(["heading", "subheading"])
    m.row = m.top.findNode("row")
    m.glow = m.top.findNode("glow")
    m.top.findNode("heading").font.size = 60
    m.items = []
    m.index = 0
end sub

sub build()
    m.row.removeChildrenIndex(m.row.getChildCount(), 0)
    m.items = []
    list = m.top.profiles
    if list = invalid then list = []
    entries = []
    for each p in list
        entries.Push({ id: p.id, name: Str_Glyphs(Str_Of(p.name)), color: p.color, avatar: Str_Of(p.avatar), pin: p.pin = true })
    end for
    if entries.Count() < 8 then entries.Push({ id: "__add", name: L("Agregar"), color: "3A3A46" })
    n = entries.Count()
    size = 220
    gap = 90
    if n * size + (n - 1) * gap > 1760
        gap = 56
        size = Int((1760 - (n - 1) * gap) / n)
        if size > 220 then size = 220
    end if
    k = size / 220
    total = n * size + (n - 1) * gap
    x = Int((1920 - total) / 2)
    for each e in entries
        g = m.row.createChild("Group")
        g.translation = [x, 0]
        ring = g.createChild("Poster")
        ring.uri = "pkg:/images/c/r244.png"
        ring.width = size + 24
        ring.height = size + 24
        ring.translation = [-12, -12]
        ring.visible = false
        circle = g.createChild("Poster")
        circle.uri = "pkg:/images/c/d220.png"
        circle.width = size
        circle.height = size
        circle.blendColor = "0x" + e.color + "FF"
        initial = g.createChild("Label")
        initial.width = size
        initial.height = size
        initial.horizAlign = "center"
        initial.vertAlign = "center"
        initial.font = "font:LargeBoldSystemFont"
        initial.font.size = Int(96 * k)
        initial.color = "0xFFFFFFFF"
        if e.id = "__add"
            initial.text = "+"
        else
            initial.text = UCase(Left(e.name, 1))
        end if
        if Str_Of(e.avatar) <> ""
            mask = g.createChild("MaskGroup")
            mask.maskUri = "pkg:/images/c/d220.png"
            Mask_Apply(mask, size, size)
            pic = mask.createChild("Poster")
            pic.width = size
            pic.height = size
            pic.loadWidth = 220
            pic.loadHeight = 220
            pic.loadDisplayMode = "scaleToZoom"
            pic.uri = Mask_Circle(e.avatar, 220)
        end if
        if e.pin = true
            badge = g.createChild("Poster")
            badge.uri = "pkg:/images/c/d64.png"
            b = Int(64 * k)
            badge.width = b
            badge.height = b
            badge.translation = [size - Int(60 * k), size - Int(60 * k)]
            badge.blendColor = "0x0C0C0FFF"
            lock = g.createChild("Poster")
            lock.uri = "pkg:/images/s/ic_lock_32.png"
            lock.width = Int(32 * k)
            lock.height = Int(32 * k)
            lock.translation = [size - Int(44 * k), size - Int(44 * k)]
            lock.blendColor = "0xFFFFFFFF"
        end if
        name = g.createChild("Label")
        pad = Int((gap - 10) / 2)
        if pad > 40 then pad = 40
        name.translation = [-pad, size + 34]
        name.width = size + pad * 2
        name.horizAlign = "center"
        name.font = "font:MediumBoldSystemFont"
        name.color = "0xB4B4C0FF"
        if k < 1 then name.font.size = Int(34 * k + 4)
        name.text = e.name
        m.items.Push({ id: e.id, ring: ring, name: name, color: e.color })
        x = x + size + gap
    end for
    if m.index >= m.items.Count() then m.index = 0
    paint()
end sub

sub paint()
    for i = 0 to m.items.Count() - 1
        focused = i = m.index
        m.items[i].ring.visible = focused
        if focused
            m.items[i].name.color = "0xFFFFFFFF"
            m.glow.blendColor = "0x" + m.items[i].color + "FF"
        else
            m.items[i].name.color = "0x8E8E9CFF"
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "left"
        if m.index > 0 then m.index = m.index - 1
        paint()
        return true
    else if key = "right"
        if m.index < m.items.Count() - 1 then m.index = m.index + 1
        paint()
        return true
    else if key = "OK"
        if m.items.Count() > 0 then m.top.selected = m.items[m.index].id
        return true
    end if
    return key <> "back"
end function
