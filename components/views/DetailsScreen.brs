sub init()
    L_Texts(["trailerHint"])
    m.hero = m.top.findNode("hero")
    m.buttonRow = m.top.findNode("buttonRow")
    m.statusLabel = m.top.findNode("statusLabel")
    m.buttons = []
    m.index = 0
    m.top.observeField("focusedChild", "paint")
    m.video = m.top.findNode("trailerVideo")
    m.trailerHint = m.top.findNode("trailerHint")
    m.trailerTimer = m.top.findNode("trailerTimer")
    m.trailerTimer.observeField("fire", "startTrailer")
    m.video.observeField("state", "onTrailerState")
    m.top.observeField("visible", "onVisible")
end sub

sub onTrailer()
    stopTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = "" then return
    delay = ToInt(t.delay, 7)
    if delay < 1 then delay = 1
    m.trailerTimer.duration = delay
    m.trailerTimer.control = "start"
end sub

sub startTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = "" or not m.top.visible or not m.top.isInFocusChain() then return
    m.video.content = Trailer_Content(t)
    m.video.control = "play"
end sub

sub onTrailerState()
    state = m.video.state
    if state = "playing"
        m.video.visible = true
        m.hero.videoMode = true
        m.trailerHint.visible = true
        m.top.trailerPlaying = true
    else if state = "finished" or state = "error" or state = "stopped"
        endTrailer()
    end if
end sub

sub stopTrailer()
    m.trailerTimer.control = "stop"
    if m.video.state <> "none" and m.video.state <> "stopped" then m.video.control = "stop"
    endTrailer()
end sub

sub endTrailer()
    m.video.visible = false
    m.hero.videoMode = false
    m.trailerHint.visible = false
    m.top.trailerPlaying = false
end sub

sub onVisible()
    if not m.top.visible then stopTrailer()
end sub

sub onFocusIndex()
    m.index = m.top.focusIndex
    paint()
end sub

sub render()
    m.hero.data = m.top.data
end sub

sub onStatus()
    m.statusLabel.text = m.top.status
end sub

sub buildButtons()
    m.buttonRow.removeChildrenIndex(m.buttonRow.getChildCount(), 0)
    m.buttons = []
    defs = m.top.buttons
    if defs = invalid then defs = []
    for each d in defs
        g = m.buttonRow.createChild("Group")
        pill = g.createChild("Poster")
        pill.uri = "pkg:/images/pill.9.png"
        pill.height = 76
        icon = g.createChild("Poster")
        icon.uri = d.icon
        icon.width = 36
        icon.height = 36
        icon.translation = [28, 20]
        label = g.createChild("Label")
        label.font = "font:MediumBoldSystemFont"
        label.text = d.label
        label.translation = [80, 0]
        label.height = 76
        label.vertAlign = "center"
        width = Int(label.boundingRect().width) + 112
        if d.label = ""
            width = 76
            icon.translation = [20, 20]
        end if
        pill.width = width
        m.buttons.Push({ id: d.id, pill: pill, icon: icon, label: label })
    end for
    if m.index >= m.buttons.Count() then m.index = 0
    paint()
end sub

sub paint()
    focused = m.top.isInFocusChain()
    for i = 0 to m.buttons.Count() - 1
        b = m.buttons[i]
        if focused and i = m.index
            b.pill.blendColor = "0xFFFFFFFF"
            b.icon.blendColor = "0x0C0C0FFF"
            b.label.color = "0x0C0C0FFF"
        else
            b.pill.blendColor = "0xFFFFFF33"
            b.icon.blendColor = "0xFFFFFFFF"
            b.label.color = "0xFFFFFFFF"
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
        if m.index < m.buttons.Count() - 1 then m.index = m.index + 1
        paint()
        return true
    else if key = "OK"
        if m.buttons.Count() > 0
            id = m.buttons[m.index].id
            if id <> "library" then stopTrailer()
            m.top.selected = id
        end if
        return true
    else if key = "back"
        if m.top.trailerPlaying
            stopTrailer()
            return true
        end if
        stopTrailer()
        m.top.back = true
        return true
    end if
    return key = "up" or key = "down"
end function

