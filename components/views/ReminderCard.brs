sub init()
    m.box = m.top.findNode("box")
    m.logo = m.top.findNode("logo")
    m.head = m.top.findNode("head")
    m.title = m.top.findNode("title")
    m.line = m.top.findNode("line")
    m.slideIn = m.top.findNode("slideIn")
    m.slideOut = m.top.findNode("slideOut")
    m.stay = m.top.findNode("stay")
    m.stay.observeField("fire", "onStay")
    m.slideOut.observeField("state", "onOutState")
    m.queue = []
    m.busy = false
end sub

sub onShow()
    info = m.top.show
    if info = invalid then return
    m.queue.Push(info)
    if not m.busy then Card_Next()
end sub

sub Card_Next()
    if m.queue.Count() = 0
        m.busy = false
        return
    end if
    m.busy = true
    info = m.queue.Shift()
    m.logo.uri = Str_Of(info.logo)
    m.head.text = Str_Of(info.head)
    m.title.text = Str_Of(info.title)
    m.line.text = Str_Of(info.line)
    m.slideIn.control = "start"
    m.stay.control = "stop"
    m.stay.control = "start"
end sub

sub onStay()
    m.slideOut.control = "start"
end sub

sub onOutState()
    if m.slideOut.state = "stopped" then Card_Next()
end sub
