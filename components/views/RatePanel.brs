sub init()
    m.card = m.top.findNode("card")
    m.cardBg = m.top.findNode("cardBg")
    m.kicker = m.top.findNode("kicker")
    m.title = m.top.findNode("title")
    m.subtitle = m.top.findNode("subtitle")
    m.scoreBox = m.top.findNode("scoreBox")
    m.score = m.top.findNode("score")
    m.scoreMax = m.top.findNode("scoreMax")
    m.starsBox = m.top.findNode("starsBox")
    m.starsPill = m.top.findNode("starsPill")
    m.starsRing = m.top.findNode("starsRing")
    m.starsGroup = m.top.findNode("stars")
    m.syncs = m.top.findNode("syncs")
    m.buttonsGroup = m.top.findNode("buttons")
    m.score.font.size = 96
    m.stars = []
    for i = 0 to 4
        p = m.starsGroup.createChild("Poster")
        p.width = 72
        p.height = 72
        p.translation = [i * 90, 0]
        m.stars.Push(p)
    end for
    m.starsPill.width = 4 * 90 + 72 + 72
    m.starsRing.width = m.starsPill.width
    m.value = 0
    m.current = 0
    m.zone = "stars"
    m.btnIndex = 0
    m.btns = []
end sub

sub onData()
    d = m.top.data
    if type(d) <> "roAssociativeArray" then return
    m.current = ToInt(d.value, 0)
    m.value = m.current
    m.zone = "stars"
    m.kicker.text = UCase(Str_Of(d.kicker))
    m.title.text = Str_Of(d.title)
    m.subtitle.text = Str_Of(d.subtitle)
    m.syncs.text = L("Se sincroniza con {p}").Replace("{p}", Str_Of(d.provider))
    y = 86 + Int(m.title.boundingRect().height) + 6
    m.subtitle.translation = [60, y]
    m.subtitle.visible = m.subtitle.text <> ""
    if m.subtitle.visible then y = y + 40
    m.scoreY = y + 24
    m.starsY = m.scoreY + 130
    m.starsBox.translation = [Int((840 - m.starsPill.width) / 2), m.starsY]
    m.syncs.translation = [60, m.starsY + 136]
    buildButtons()
    h = m.starsY + 136 + 40 + 40 + 76 + 48
    m.cardBg.height = h
    m.card.translation = [540, Int((1080 - h) / 2)]
    paint()
end sub

sub buildButtons()
    m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
    m.btns = []
    defs = []
    if m.current > 0 then defs.Push({ id: "remove", label: L("Quitar calificación") })
    defs.Push({ id: "save", label: L("Guardar") })
    gap = 20
    total = 720
    w = Int((total - gap * (defs.Count() - 1)) / defs.Count())
    x = 60
    for each d in defs
        g = m.buttonsGroup.createChild("Group")
        g.translation = [x, m.starsY + 136 + 80]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.width = w
        pill.height = 76
        label = g.createChild("Label")
        label.width = w
        label.height = 76
        label.horizAlign = "center"
        label.vertAlign = "center"
        label.font = "font:SmallBoldSystemFont"
        label.text = d.label
        m.btns.Push({ id: d.id, pill: pill, label: label })
        x = x + w + gap
    end for
    m.btnIndex = m.btns.Count() - 1
end sub

function accent() as string
    if m.global.hasField("accent") and Str_Of(m.global.accent) <> "" then return m.global.accent
    return "0xFFFFFFFF"
end function

sub paint()
    v = m.value
    if v > 0 then m.score.text = v.ToStr() else m.score.text = "–"
    if v > 0 then m.score.color = "0xFFFFFFFF" else m.score.color = "0x77778AFF"
    sw = Int(m.score.boundingRect().width)
    mw = Int(m.scoreMax.boundingRect().width)
    m.score.translation = [0, 0]
    m.scoreMax.translation = [sw + 6, 50]
    m.scoreBox.translation = [Int((840 - sw - 6 - mw) / 2), m.scoreY]
    gold = "0xFFC83CFF"
    for i = 0 to 4
        full = (i + 1) * 2
        p = m.stars[i]
        if v >= full
            p.uri = "pkg:/images/star_full.png"
            p.blendColor = gold
        else if v = full - 1
            p.uri = "pkg:/images/star_half.png"
            p.blendColor = gold
        else
            p.uri = "pkg:/images/star_empty.png"
            p.blendColor = "0x6E6E80FF"
        end if
    end for
    onStars = m.zone = "stars"
    m.starsRing.visible = onStars
    m.starsRing.blendColor = accent()
    if onStars then m.starsPill.blendColor = "0xFFFFFF26" else m.starsPill.blendColor = "0xFFFFFF00"
    canSave = m.value > 0 and m.value <> m.current
    for i = 0 to m.btns.Count() - 1
        b = m.btns[i]
        active = m.zone = "buttons" and i = m.btnIndex
        enabled = b.id <> "save" or canSave
        if active
            b.pill.blendColor = "0xFFFFFFFF"
            b.label.color = "0x0C0C0FFF"
        else if b.id = "save" and enabled
            b.pill.blendColor = accent()
            b.label.color = "0xFFFFFFFF"
        else
            b.pill.blendColor = "0xFFFFFF22"
            if enabled then b.label.color = "0xFFFFFFFF" else b.label.color = "0x77778AFF"
        end if
    end for
end sub

sub finish(action as string)
    m.top.result = { action: action, value: m.value }
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        finish("cancel")
        return true
    end if
    if m.zone = "stars"
        if key = "left" or key = "right"
            nv = m.value
            if key = "left" then nv = nv - 1 else nv = nv + 1
            if nv < 1 then nv = 1
            if nv > 10 then nv = 10
            m.value = nv
            paint()
        else if key = "down"
            m.zone = "buttons"
            m.btnIndex = m.btns.Count() - 1
            paint()
        else if key = "OK"
            if m.value > 0 and m.value <> m.current then finish("save")
        end if
        return true
    end if
    if key = "up"
        m.zone = "stars"
        paint()
    else if key = "left"
        if m.btnIndex > 0 then m.btnIndex = m.btnIndex - 1
        paint()
    else if key = "right"
        if m.btnIndex < m.btns.Count() - 1 then m.btnIndex = m.btnIndex + 1
        paint()
    else if key = "OK"
        id = m.btns[m.btnIndex].id
        if id = "remove"
            finish("remove")
        else if m.value > 0 and m.value <> m.current
            finish("save")
        end if
    end if
    return true
end function
