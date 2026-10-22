sub init()
    m.ring = m.top.findNode("ring")
    m.mask = m.top.findNode("mask")
    m.base = m.top.findNode("base")
    m.art = m.top.findNode("art")
    m.video = m.top.findNode("video")
    m.shade = m.top.findNode("shade")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.grow = m.top.findNode("grow")
    m.tween = m.top.findNode("tween")
    m.title.font.size = 26
    m.fromW = 200
    m.toW = 400
    m.tween.observeField("opacity", "onTween")
    m.logo.observeField("loadStatus", "onLogo")
    m.video.observeField("state", "onVideoState")
    m.logoReady = false
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
    m.logoReady = false
    m.logo.visible = false
    m.title.visible = false
    m.logo.uri = Str_Of(d.logo)
    m.video.visible = false
    m.video.control = "stop"
    if m.global.hasField("accent") then m.ring.blendColor = m.global.accent
    m.top.w = m.fromW
    m.top.visible = true
    m.tween.opacity = 0
    m.grow.control = "start"
end sub

sub onTween()
    m.top.w = m.fromW + (m.toW - m.fromW) * m.tween.opacity
    setShift(m.top.w - m.fromW)
end sub

sub setShift(v as float)
    if m.global.hasField("expandShift") then m.global.expandShift = v
end sub

sub layout()
    w = m.top.w
    h = m.top.h
    if w <= 0 or h <= 0 then return
    m.ring.translation = [-4, -4]
    m.ring.width = w + 8
    m.ring.height = h + 8
    m.mask.maskSize = [w, h]
    for each n in [m.base, m.art, m.video]
        n.width = w
        n.height = h
    end for
    shadeH = Int(h * 0.4)
    m.shade.width = w
    m.shade.height = shadeH
    m.shade.translation = [0, h - shadeH]
    pad = 16
    m.title.width = w - pad * 2
    m.title.height = 0
    m.title.maxLines = 2
    m.title.wrap = true
    tH = m.title.boundingRect().height
    if tH <= 0 then tH = 32
    m.title.translation = [pad, h - pad - tH]
    placeLogo()
    grown = w > m.fromW + 40
    m.title.visible = grown and not m.logoReady
    m.logo.visible = grown and m.logoReady
end sub

sub placeLogo()
    w = m.top.w
    h = m.top.h
    maxW = Int(m.toW * 0.62)
    maxH = 52
    bw = m.logo.bitmapWidth
    bh = m.logo.bitmapHeight
    if bw <= 0 or bh <= 0
        m.logo.width = maxW
        m.logo.height = maxH
    else
        scale = maxW / bw
        if bh * scale > maxH then scale = maxH / bh
        m.logo.width = Int(bw * scale)
        m.logo.height = Int(bh * scale)
    end if
    m.logo.translation = [16, h - 16 - m.logo.height]
end sub

sub onLogo()
    m.logoReady = m.logo.loadStatus = "ready" and m.logo.uri <> ""
    layout()
end sub

sub onOpen()
    if not m.top.open
        setShift(0)
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
