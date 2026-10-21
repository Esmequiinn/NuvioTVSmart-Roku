sub init()
    m.ring = m.top.findNode("ring")
    m.mask = m.top.findNode("mask")
    m.base = m.top.findNode("base")
    m.art = m.top.findNode("art")
    m.video = m.top.findNode("video")
    m.shade = m.top.findNode("shade")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.meta = m.top.findNode("meta")
    m.grow = m.top.findNode("grow")
    m.tween = m.top.findNode("tween")
    m.title.font.size = 34
    m.meta.font.size = 22
    m.fromW = 200
    m.toW = 400
    m.tween.observeField("opacity", "onTween")
    m.logo.observeField("loadStatus", "onLogo")
    m.video.observeField("state", "onVideoState")
    m.top.visible = false
end sub

sub onData()
    d = m.top.data
    if d = invalid then return
    m.fromW = d.fromW
    m.toW = d.toW
    m.top.translation = [d.x, d.y]
    m.top.h = d.h
    m.art.uri = Str_Of(d.background)
    m.title.text = Str_Of(d.title)
    m.meta.text = Str_Of(d.meta)
    m.logo.visible = false
    m.title.visible = true
    m.logo.uri = Str_Of(d.logo)
    m.video.visible = false
    m.video.control = "stop"
    m.top.w = m.fromW
    m.top.visible = true
    m.tween.opacity = 0
    m.grow.control = "start"
end sub

sub onTween()
    m.top.w = m.fromW + (m.toW - m.fromW) * m.tween.opacity
end sub

sub layout()
    w = m.top.w
    h = m.top.h
    if w <= 0 or h <= 0 then return
    m.ring.translation = [-7, -7]
    m.ring.width = w + 14
    m.ring.height = h + 14
    m.mask.maskSize = [w, h]
    for each n in [m.base, m.art, m.video]
        n.width = w
        n.height = h
    end for
    m.shade.width = w
    m.shade.height = Int(h * 0.7)
    m.shade.translation = [0, h - Int(h * 0.7)]
    pad = 22
    m.meta.width = w - pad * 2
    m.meta.translation = [pad, h - pad - 28]
    logoW = Int(w * 0.55)
    if logoW > 320 then logoW = 320
    m.logo.width = logoW
    m.logo.height = 72
    m.logo.translation = [pad, h - pad - 28 - 84]
    m.title.width = w - pad * 2
    m.title.height = 44
    m.title.translation = [pad, h - pad - 28 - 52]
    m.title.visible = not m.logo.visible and w > m.fromW + 40
    m.meta.visible = w > m.fromW + 40
end sub

sub onLogo()
    if m.logo.loadStatus = "ready" and m.logo.uri <> ""
        m.logo.visible = true
        m.title.visible = false
    end if
end sub

sub onOpen()
    if not m.top.open
        m.grow.control = "stop"
        m.video.control = "stop"
        m.video.visible = false
        m.top.visible = false
    end if
end sub

sub onTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = "" or not m.top.visible then return
    m.video.mute = m.top.muted
    m.video.content = Trailer_Content(t)
    m.video.control = "play"
end sub

sub onVideoState()
    state = m.video.state
    if state = "playing"
        m.video.visible = true
    else if state = "finished" or state = "error"
        m.video.visible = false
    end if
end sub
