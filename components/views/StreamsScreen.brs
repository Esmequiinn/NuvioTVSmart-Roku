sub init()
    m.bg = m.top.findNode("bg")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.code = m.top.findNode("code")
    m.epTitle = m.top.findNode("epTitle")
    m.hint = m.top.findNode("hint")
    m.chipsGroup = m.top.findNode("chips")
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
    m.chipIndex = 0
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
    defs = []
    resume = Txt(m.top.resume)
    if resume <> ""
        if m.top.fromStart
            defs.Push({ id: "resume", label: L("Desde el inicio") })
        else
            defs.Push({ id: "resume", label: L("Continuar en ") + resume })
        end if
    end if
    list = streamList()
    defs.Push({ id: "all", label: L("Todos  ") + list.Count().ToStr() })
    counts = {}
    order = []
    for each s in list
        name = Txt(s.addon)
        if name <> ""
            if not counts.DoesExist(name)
                counts[name] = 0
                order.Push(name)
            end if
            counts[name] = counts[name] + 1
        end if
    end for
    if m.filter <> "" and not counts.DoesExist(m.filter) then m.filter = ""
    for each name in order
        defs.Push({ id: "addon", value: name, label: name + "  " + counts[name].ToStr() })
    end for
    if m.chipIndex >= defs.Count() then m.chipIndex = defs.Count() - 1
    m.chipsGroup.removeChildrenIndex(m.chipsGroup.getChildCount(), 0)
    m.chips = []
    x = 0
    for each d in defs
        g = m.chipsGroup.createChild("Group")
        g.translation = [x, 0]
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.height = 56
        label = g.createChild("Label")
        label.font = "font:SmallBoldSystemFont"
        label.font.size = 26
        label.text = d.label
        label.height = 56
        label.vertAlign = "center"
        label.translation = [26, 0]
        w = Int(label.boundingRect().width) + 52
        pill.width = w
        d.pill = pill
        d.text = label
        m.chips.Push(d)
        x = x + w + 14
        if x > 1110 then g.visible = false
    end for
    paintChips()
end sub

sub paintChips()
    if m.chips = invalid then return
    inChips = m.zone = "chips" and m.top.isInFocusChain()
    for i = 0 to m.chips.Count() - 1
        d = m.chips[i]
        selected = (d.id = "all" and m.filter = "") or (d.id = "addon" and d.value = m.filter)
        if inChips and i = m.chipIndex
            d.pill.blendColor = "0xFFFFFFFF"
            d.text.color = "0x0C0C0FFF"
        else if selected
            d.pill.blendColor = m.top.accent
            d.text.color = "0xFFFFFFFF"
        else
            d.pill.blendColor = "0xFFFFFF22"
            d.text.color = "0xE4E4ECFF"
        end if
    end for
    first = 0
    if inChips then first = m.chipIndex
    x = 0
    for i = 0 to m.chips.Count() - 1
        g = m.chips[i].pill.getParent()
        if i < first - 2
            g.visible = false
        else
            g.translation = [x, 0]
            g.visible = x + m.chips[i].pill.width <= 1110
            x = x + m.chips[i].pill.width + 14
        end if
    end for
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
    else
        m.zone = "chips"
    end if
    paintChips()
end sub

sub onSelect()
    if m.zone <> "grid" or not m.grid.hasFocus() then return
    index = m.grid.itemSelected
    if index < 0 or index >= m.shown.Count() then return
    m.top.event = { type: "play", index: m.shown[index] }
end sub

sub activateChip()
    if m.chipIndex < 0 or m.chipIndex >= m.chips.Count() then return
    d = m.chips[m.chipIndex]
    if d.id = "resume"
        m.top.event = { type: "toggleStart" }
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

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        m.top.event = { type: "back" }
        return true
    end if
    if m.zone = "grid"
        if key = "up" and m.chips.Count() > 0
            m.zone = "chips"
            m.autoFocus = false
            m.top.setFocus(true)
            paintChips()
            return true
        end if
        return key = "left" or key = "right" or key = "down" or key = "up"
    end if
    m.autoFocus = false
    if key = "left"
        if m.chipIndex > 0 then m.chipIndex = m.chipIndex - 1
        paintChips()
    else if key = "right"
        if m.chipIndex < m.chips.Count() - 1 then m.chipIndex = m.chipIndex + 1
        paintChips()
    else if key = "down"
        if m.shown.Count() > 0
            m.zone = "grid"
            m.grid.setFocus(true)
            paintChips()
        end if
    else if key = "OK"
        activateChip()
    end if
    return true
end function
