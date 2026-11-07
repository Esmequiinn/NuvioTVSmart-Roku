sub init()
    m.stage = m.top.findNode("stage")
    m.art = m.top.findNode("art")
    m.shade = m.top.findNode("shade")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.genres = m.top.findNode("genres")
    m.pre = m.top.findNode("pre")
    m.step = m.top.findNode("step")
    m.motion = m.top.findNode("motion")
    m.motionScale = m.top.findNode("motionScale")
    m.motionMove = m.top.findNode("motionMove")
    m.artIn = m.top.findNode("artIn")
    m.textIn = m.top.findNode("textIn")
    m.textOut = m.top.findNode("textOut")
    m.artOut = m.top.findNode("artOut")
    m.title.font.size = 72
    m.genres.font.size = 30
    m.step.observeField("fire", "onStep")
    m.art.observeField("loadStatus", "onArt")
    m.logo.observeField("loadStatus", "onLogo")
    m.motions = [
        { s0: 1.0, s1: 1.06, x0: 0.0, x1: 0.0, y0: 0.0, y1: 0.0 }
        { s0: 1.07, s1: 1.01, x0: 0.0, x1: 0.0, y0: 0.0, y1: 0.0 }
        { s0: 1.06, s1: 1.06, x0: -0.025, x1: 0.025, y0: 0.0, y1: 0.0 }
        { s0: 1.06, s1: 1.06, x0: 0.025, x1: -0.025, y0: 0.0, y1: 0.0 }
        { s0: 1.06, s1: 1.06, x0: 0.0, x1: 0.0, y0: 0.02, y1: -0.02 }
        { s0: 1.02, s1: 1.08, x0: 0.0, x1: -0.025, y0: 0.0, y1: -0.02 }
        { s0: 1.02, s1: 1.08, x0: 0.0, x1: 0.025, y0: 0.0, y1: 0.02 }
    ]
    m.lastMotion = -1
    m.index = 0
    m.misses = 0
    m.phase = ""
end sub

function AmText(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub onActive()
    if m.top.active
        m.index = 0
        m.misses = 0
        m.top.visible = true
        m.top.setFocus(true)
        nextSlide()
    else
        stopAll()
        m.top.visible = false
    end if
end sub

sub onSlides()
    if m.top.active and m.phase = "empty" then nextSlide()
end sub

sub stopAll()
    m.step.control = "stop"
    for each a in [m.motion, m.artIn, m.textIn, m.textOut, m.artOut]
        a.control = "stop"
    end for
    m.phase = ""
    m.art.opacity = 0
    m.shade.opacity = 0
    m.logo.opacity = 0
    m.title.opacity = 0
    m.genres.opacity = 0
end sub

sub Am_Wait(seconds as float, phase as string)
    m.phase = phase
    m.step.control = "stop"
    m.step.duration = seconds
    m.step.control = "start"
end sub

sub nextSlide()
    if not m.top.active then return
    slides = m.top.slides
    if type(slides) <> "roArray" or slides.Count() = 0
        Am_Wait(1.0, "empty")
        return
    end if
    m.slide = slides[m.index mod slides.Count()]
    m.index = m.index + 1
    upcoming = slides[m.index mod slides.Count()]
    m.pre.uri = AmText(upcoming.background)
    m.loaded = false
    m.art.uri = ""
    m.art.uri = AmText(m.slide.background)
    m.logo.uri = AmText(m.slide.logo)
    m.logoReady = false
    m.title.text = AmText(m.slide.title)
    m.title.visible = AmText(m.slide.logo) = ""
    m.genres.text = AmText(m.slide.genres)
    Am_Wait(8.0, "loading")
    if m.art.loadStatus = "ready" then onArt()
end sub

sub onArt()
    if m.phase <> "loading" then return
    status = m.art.loadStatus
    if status = "ready"
        m.misses = 0
        showSlide()
    else if status = "failed"
        skipSlide()
    end if
end sub

sub skipSlide()
    m.misses = m.misses + 1
    slides = m.top.slides
    if type(slides) = "roArray" and m.misses >= slides.Count()
        m.misses = 0
        Am_Wait(15.0, "retry")
        return
    end if
    nextSlide()
end sub

sub onLogo()
    status = m.logo.loadStatus
    if status = "ready"
        bw = m.logo.bitmapWidth
        bh = m.logo.bitmapHeight
        if bw <= 0 or bh <= 0 then return
        scale = 920 / bw
        if bh * scale > 240 then scale = 240 / bh
        w = Int(bw * scale)
        h = Int(bh * scale)
        m.logo.width = w
        m.logo.height = h
        m.logo.translation = [704 - Int(w / 2), 880 - h]
        m.logoReady = true
        m.title.visible = false
    else if status = "failed"
        m.title.visible = true
    end if
end sub

sub showSlide()
    pick = Rnd(m.motions.Count()) - 1
    if pick = m.lastMotion then pick = (pick + 1) mod m.motions.Count()
    m.lastMotion = pick
    mo = m.motions[pick]
    m.motionScale.keyValue = [[mo.s0, mo.s0], [mo.s1, mo.s1]]
    m.motionMove.keyValue = [[mo.x0 * 1920, mo.y0 * 1080], [mo.x1 * 1920, mo.y1 * 1080]]
    m.stage.scale = [mo.s0, mo.s0]
    m.stage.translation = [mo.x0 * 1920, mo.y0 * 1080]
    m.motion.control = "stop"
    m.motion.control = "start"
    m.artIn.control = "start"
    Am_Wait(1.15, "text")
end sub

sub onStep()
    phase = m.phase
    if phase = "empty" or phase = "retry"
        nextSlide()
    else if phase = "loading"
        skipSlide()
    else if phase = "text"
        if not m.logoReady and AmText(m.slide.logo) <> "" then m.title.visible = true
        m.textIn.control = "start"
        Am_Wait(10.5, "hold")
    else if phase = "hold"
        m.textOut.control = "start"
        Am_Wait(0.45, "out")
    else if phase = "out"
        m.artOut.control = "start"
        Am_Wait(1.0, "black")
    else if phase = "black"
        m.motion.control = "stop"
        nextSlide()
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not m.top.active then return false
    if press then m.top.closed = true
    return true
end function
