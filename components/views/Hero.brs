sub init()
    m.backdrop = m.top.findNode("backdrop")
    m.solid = m.top.findNode("solid")
    m.fadeLeft = m.top.findNode("fadeLeft")
    m.fadeBottom = m.top.findNode("fadeBottom")
    m.floor = m.top.findNode("floor")
    m.logo = m.top.findNode("logo")
    m.title = m.top.findNode("title")
    m.imdb = m.top.findNode("imdb")
    m.metaRow = m.top.findNode("metaRow")
    m.rating = m.top.findNode("rating")
    m.metaLine = m.top.findNode("metaLine")
    m.description = m.top.findNode("description")
    m.title.font.size = 64
    m.logo.observeField("loadStatus", "onLogoStatus")
    m.lastLogo = ""
    m.boxTop = 120
    m.boxHeight = 180
end sub

sub layout()
    if m.top.fullscreen
        m.backdrop.translation = [0, 0]
        m.backdrop.width = 1920
        m.backdrop.height = 1080
        m.solid.visible = false
        m.fadeLeft.translation = [0, 0]
        m.fadeLeft.width = 1400
        m.fadeLeft.height = 1080
        m.fadeBottom.translation = [0, 600]
        m.fadeBottom.height = 480
        m.floor.visible = false
        m.boxTop = 200
        m.boxHeight = 200
        m.logo.translation = [160, 200]
        m.logo.height = 200
        m.title.translation = [160, 250]
        m.top.findNode("metaRow").translation = [160, 440]
        m.description.translation = [160, 504]
        m.description.maxLines = 4
        m.description.height = 170
    end if
end sub

sub render()
    d = m.top.data
    if d = invalid then return
    m.title.text = textOf(d.title)
    logo = textOf(d.logo)
    if logo <> m.lastLogo
        m.lastLogo = logo
        m.logo.visible = false
        m.title.visible = true
        if logo <> ""
            m.logo.width = 620
            m.logo.height = m.boxHeight
            m.logo.uri = logo
        else
            m.logo.uri = ""
        end if
    end if
    rating = textOf(d.rating)
    m.imdb.visible = rating <> ""
    m.rating.visible = rating <> ""
    if rating <> ""
        m.metaRow.itemSpacings = [14]
        m.imdb.width = 84
    else
        m.metaRow.itemSpacings = [0]
        m.imdb.width = 0
    end if
    m.rating.text = rating
    m.metaLine.text = textOf(d.metaLine)
    m.description.text = textOf(d.description)
    bg = textOf(d.background)
    if bg <> m.backdrop.uri then m.backdrop.uri = bg
end sub

sub onLogoStatus()
    status = m.logo.loadStatus
    if status = "ready" and m.logo.uri <> ""
        bw = m.logo.bitmapWidth
        bh = m.logo.bitmapHeight
        if bw > 0 and bh > 0
            scale = 620 / bw
            if bh * scale > m.boxHeight then scale = m.boxHeight / bh
            m.logo.width = Int(bw * scale)
            m.logo.height = Int(bh * scale)
            m.logo.translation = [160, m.boxTop + m.boxHeight - m.logo.height]
        end if
        m.logo.visible = true
        m.title.visible = false
    else if status = "failed"
        m.logo.visible = false
        m.title.visible = true
    end if
end sub

function textOf(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub onVideoMode()
    m.backdrop.visible = not m.top.videoMode
end sub
