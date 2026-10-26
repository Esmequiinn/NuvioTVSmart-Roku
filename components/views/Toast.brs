sub init()
    m.box = m.top.findNode("box")
    m.bg = m.top.findNode("bg")
    m.label = m.top.findNode("label")
    m.label.font.size = 30
    m.timer = m.top.findNode("timer")
    m.timer.observeField("fire", "onTimer")
end sub

sub onText()
    text = m.top.text
    if text = "" then return
    m.label.width = 0
    m.label.height = 0
    m.label.text = text
    w = Int(m.label.boundingRect().width)
    est = Len(text) * 15
    if w < est then w = est
    if w > 1300 then w = 1300
    m.label.width = w
    m.label.height = 72
    m.label.translation = [36, 0]
    m.bg.width = w + 72
    m.bg.height = 72
    m.box.translation = [Int((1920 - w - 72) / 2), 940]
    m.top.findNode("hide").control = "stop"
    m.top.findNode("show").control = "start"
    m.timer.control = "stop"
    m.timer.control = "start"
end sub

sub onTimer()
    m.top.findNode("hide").control = "start"
end sub
