sub init()
    m.bg = m.top.findNode("bg")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.code = m.top.findNode("code")
    m.epTitle = m.top.findNode("epTitle")
    m.hint = m.top.findNode("hint")
    m.chipsGroup = m.top.findNode("chips")
    m.chipClip = m.top.findNode("chipClip")
    m.chipClip.clippingRect = [0, -10, 1130, 80]
    m.resumeRow = m.top.findNode("resumeRow")
    m.resumeDef = invalid
    m.grid = m.top.findNode("grid")
    m.status = m.top.findNode("status")
    m.footer = m.top.findNode("footer")
    m.title.font.size = 56
    m.zone = "grid"
    m.filter = ""
    m.chipIndex = 0
    m.chips = []
    m.shown = []
    m.autoFocus = true
    m.grid.observeField("itemSelected", "onSelect")
    m.logo.observeField("loadStatus", "onLogo")
    m.top.observeField("focusedChild", "onFocusChange")
end sub

sub onInfo()
    info = m.top.info
    if info = invalid then return
    m.filter = ""
    m.chipIndex = 1
    m.zone = "grid"
    m.autoFocus = true
    m.bg.uri = Txt(info.background)
    m.logo.visible = false
    m.title.visible = true
    m.title.text = Txt(info.title)
    m.logo.uri = Txt(info.logo)
    m.code.text = Txt(info.code)
    m.epTitle.text = Txt(info.episodeTitle)
    m.hint.text = L("Arriba para filtrar por addon.")
    m.grid.content = CreateObject("roSGNode", "ContentNode")
    m.shown = []
    buildChips()
    updateStatus()
end sub

function Txt(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub onLogo()
    if m.logo.loadStatus = "ready" and m.logo.uri <> ""
        m.logo.visible = true
        m.title.visible = false
    end if
end sub

sub onStreams()
    buildChips()
    buildGrid()
end sub

function streamList() as object
    list = m.top.streams
    if type(list) <> "roArray" then list = []
    return list
end function

sub buildChips()
    m.resumeRow.removeChildrenIndex(m.resumeRow.getChildCount(), 0)
    m.resumeDef = invalid
    resume = Txt(m.top.resume)
    if resume <> ""
        text = L("Continuar en ") + resume
        if m.top.fromStart then text = L("Desde el inicio")
        m.resumeDef = makeChip(m.resumeRow, { id: "resume", label: text }, 0)
    end if
    defs = [{ id: "refresh", label: "", icon: "pkg:/images/ic_replay.png" }, { id: "all", label: L("Todos") }]
    order = []
    seen = {}
    for each st in streamList()
        name = Txt(st.addon)
        if name <> "" and not seen.DoesExist(name)
            seen[name] = true
            order.Push(name)
        end if
    end for
    if m.filter <> "" and not seen.DoesExist(m.filter) then m.filter = ""
    for each name in order
        defs.Push({ id: "addon", value: name, label: name })
    end for
    if m.chipIndex >= defs.Count() then m.chipIndex = defs.Count() - 1
    m.chipsGroup.removeChildrenIndex(m.chipsGroup.getChildCount(), 0)
    m.chips = []
    x = 0
    for each d in defs
        c = makeChip(m.chipsGroup, d, x)
        m.chips.Push(c)
        x = x + c.width + 16
    end for
    paintChips()
end sub

function makeChip(parent as object, d as object, x as integer) as object
    g = parent.createChild("Group")
    g.translation = [x, 0]
    pill = g.createChild("Poster")
    pill.uri = "pkg:/images/pill64.9.png"
    pill.height = 64
    w = 0
    if Txt(d.icon) <> ""
        icon = g.createChild("Poster")
        icon.uri = d.icon.Replace("/images/", "/images/s/").Replace(".png", "_34.png")
        icon.width = 34
        icon.height = 34
        icon.translation = [21, 15]
        d.icon = icon
        w = 76
    else
        label = g.createChild("Label")
        label.font = "font:SmallBoldSystemFont"
        label.font.size = 28
        label.text = d.label
        label.height = 64
        label.vertAlign = "center"
        label.translation = [30, 0]
        w = Int(label.boundingRect().width) + 60
        if w < 90 then w = 90
        d.text = label
    end if
    pill.width = w
    d.pill = pill
    d.group = g
    d.width = w
    d.x = x
    return d
end function

sub paintChip(d as object, focused as boolean, selected as boolean)
    if focused
        bg = m.top.accent
        fg = Ui_Ink(bg)
    else if selected
        bg = "0xFFFFFFFF"
        fg = "0x0C0C0FFF"
    else
        bg = "0x26262BE6"
        fg = "0xF2F2F2FF"
    end if
    d.pill.blendColor = bg
    if d.text <> invalid then d.text.color = fg
    if type(d.icon) = "roSGNode" then d.icon.blendColor = fg
end sub

sub paintChips()
    if m.chips = invalid then return
    active = m.top.isInFocusChain()
    if m.resumeDef <> invalid then paintChip(m.resumeDef, active and m.zone = "resume", false)
    for i = 0 to m.chips.Count() - 1
        d = m.chips[i]
        selected = (d.id = "all" and m.filter = "") or (d.id = "addon" and d.value = m.filter)
        paintChip(d, active and m.zone = "chips" and i = m.chipIndex, selected)
    end for
    shift = 0
    if m.chips.Count() > 0
        idx = m.chipIndex
        if idx < 0 then idx = 0
        d = m.chips[idx]
        if d.x + d.width > 1110 then shift = d.x + d.width - 1110
    end if
    m.chipsGroup.translation = [-shift, 0]
end sub

sub buildGrid()
    list = streamList()
    info = m.top.info
    place = "bottom"
    showLogo = true
    if info <> invalid
        if Txt(info.place) = "top" then place = "top"
        if info.showLogo <> invalid
            if not info.showLogo then showLogo = false
        end if
    end if
    previous = -1
    current = m.grid.itemFocused
    if current >= 0 and current < m.shown.Count() then previous = m.shown[current]
    root = CreateObject("roSGNode", "ContentNode")
    m.shown = []
    for i = 0 to list.Count() - 1
        s = list[i]
        if m.filter = "" or Txt(s.addon) = m.filter
            node = root.createChild("ContentNode")
            logo = ""
            if showLogo then logo = Txt(s.logo)
            chips = s.chips
            if type(chips) <> "roArray" then chips = []
            badges = s.badges
            if type(badges) <> "roArray" then badges = []
            node.addFields({ sname: Txt(s.name), sdesc: Txt(s.desc), saddon: Txt(s.addon), slogo: logo, chips: chips, badges: badges, place: place })
            if node.sname = "" then node.sname = Txt(s.addon)
            m.shown.Push(i)
        end if
    end for
    m.grid.content = root
    target = 0
    for j = 0 to m.shown.Count() - 1
        if m.shown[j] = previous then target = j
    end for
    if m.shown.Count() > 0 then m.grid.jumpToItem = target
    if m.shown.Count() > 0 and m.autoFocus and m.top.isInFocusChain()
        m.zone = "grid"
        m.grid.setFocus(true)
    end if
    updateStatus()
    paintChips()
end sub

sub updateStatus()
    total = streamList().Count()
    if m.shown.Count() = 0
        m.status.visible = true
        if m.top.loading
            m.status.text = L("Buscando fuentes en tus addons...")
        else if total > 0
            m.status.text = L("No hay fuentes de este addon.")
        else if Txt(m.top.note) <> ""
            m.status.text = m.top.note
        else
            m.status.text = L("Ninguno de tus addons devolvió fuentes para este título.")
        end if
    else
        m.status.visible = false
    end if
    if m.top.loading
        m.footer.text = L("Buscando más fuentes...")
    else if total = 1
        m.footer.text = L("1 fuente")
    else
        m.footer.text = total.ToStr() + L(" fuentes")
    end if
end sub

sub onFocusChange()
    if not m.top.hasFocus()
        paintChips()
        return
    end if
    if m.zone = "grid" and m.shown.Count() > 0
        m.grid.setFocus(true)
    else if m.zone = "grid"
        m.zone = "chips"
    end if
    paintChips()
end sub

sub onSelect()
    if not m.grid.isInFocusChain() then return
    m.zone = "grid"
    index = m.grid.itemSelected
    playIndex(index)
end sub

sub playIndex(index as integer)
    if index < 0 or index >= m.shown.Count() then return
    m.top.event = { type: "play", index: m.shown[index] }
end sub

sub activateChip()
    if m.chipIndex < 0 or m.chipIndex >= m.chips.Count() then return
    d = m.chips[m.chipIndex]
    if d.id = "refresh"
        m.top.event = { type: "refresh" }
        return
    end if
    if d.id = "all"
        m.filter = ""
    else
        m.filter = d.value
    end if
    buildGrid()
    paintChips()
end sub

sub focusGrid()
    m.zone = "grid"
    m.grid.drawFocusFeedback = true
    m.grid.setFocus(true)
    paintChips()
end sub

sub focusChips(zone as string)
    m.zone = zone
    m.autoFocus = false
    m.grid.drawFocusFeedback = false
    m.grid.setFocus(false)
    m.top.setFocus(true)
    paintChips()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        m.top.event = { type: "back" }
        return true
    end if
    if m.zone = "grid"
        if key = "up"
            focusChips("chips")
            return true
        end if
        if key = "OK"
            playIndex(m.grid.itemFocused)
            return true
        end if
        return key = "left" or key = "right" or key = "down"
    end if
    m.autoFocus = false
    if m.zone = "resume"
        if key = "down"
            m.zone = "chips"
            paintChips()
        else if key = "OK"
            m.top.event = { type: "toggleStart" }
        end if
        return true
    end if
    if key = "left"
        if m.chipIndex > 0 then m.chipIndex = m.chipIndex - 1
        paintChips()
    else if key = "right"
        if m.chipIndex < m.chips.Count() - 1 then m.chipIndex = m.chipIndex + 1
        paintChips()
    else if key = "up"
        if m.resumeDef <> invalid
            m.zone = "resume"
            paintChips()
        end if
    else if key = "down"
        if m.shown.Count() > 0 then focusGrid()
    else if key = "OK"
        activateChip()
    end if
    return true
end function
