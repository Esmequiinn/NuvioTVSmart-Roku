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
    m.ratingsRow = m.top.findNode("ratingsRow")
    m.descBase = { y: 392, lines: 3, height: 130 }
    m.video = m.top.findNode("video")
    m.video.observeField("state", "onVideoState")
    m.title.font.size = 64
    m.logo.observeField("loadStatus", "onLogoStatus")
    m.lastLogo = ""
    m.boxTop = 120
    m.boxHeight = 180
    m.full = false
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
        m.descBase = { y: 504, lines: 4, height: 170 }
        Hero_Ratings(m.lastRatings)
    end if
end sub

sub Hero_Ratings(list as dynamic)
    m.lastRatings = list
    m.ratingsRow.removeChildrenIndex(m.ratingsRow.getChildCount(), 0)
    base = m.descBase
    hasImdb = false
    if type(list) = "roArray" and list.Count() > 0
        for each r in list
            pair = m.ratingsRow.createChild("LayoutGroup")
            pair.layoutDirection = "horiz"
            pair.itemSpacings = [10]
            pair.vertAlignment = "center"
            icon = pair.createChild("Poster")
            icon.uri = textOf(r.icon)
            icon.loadDisplayMode = "scaleToFit"
            if textOf(r.source) = "imdb"
                hasImdb = true
                icon.width = 72
                icon.height = 36
            else
                icon.width = 28
                icon.height = 28
            end if
            value = pair.createChild("Label")
            value.font = "font:SmallSystemFont"
            value.color = "0xC9C9D4FF"
            value.text = textOf(r.value)
        end for
        m.ratingsRow.visible = true
        m.ratingsRow.translation = [160, base.y]
        m.description.translation = [160, base.y + 58]
        m.description.maxLines = base.lines - 1
        m.description.height = base.height - 40
    else
        m.ratingsRow.visible = false
        m.description.translation = [160, base.y]
        m.description.maxLines = base.lines
        m.description.height = base.height
    end if
    m.hideImdb = hasImdb
end sub

sub render()
    d = m.top.data
    if d = invalid then return
    m.title.text = textOf(d.title)
    logo = textOf(d.logo)
    if d.logoPending = true then logo = ""
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
    Hero_Ratings(d.ratings)
    rating = textOf(d.rating)
    if m.hideImdb then rating = ""
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

sub onTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = ""
        if m.video.state <> "none" and m.video.state <> "stopped" then m.video.control = "stop"
        m.video.visible = false
        m.backdrop.visible = not m.top.videoMode
        Hero_Immersive(false)
        return
    end if
    m.full = Bool_Of(t.full, false)
    Hero_VideoBox()
    m.video.mute = m.top.muted
    m.video.content = Trailer_Content(t)
    m.video.control = "play"
end sub

sub onVideoState()
    state = m.video.state
    if state = "playing"
        m.video.visible = true
        m.backdrop.visible = false
        if m.full then Hero_Immersive(true)
    else if state = "finished" or state = "error" or state = "stopped"
        m.video.visible = false
        m.backdrop.visible = not m.top.videoMode
        Hero_Immersive(false)
    end if
end sub

sub Hero_VideoBox()
    m.video.translation = m.backdrop.translation
    m.video.width = m.backdrop.width
    m.video.height = m.backdrop.height
end sub

sub Hero_Immersive(on as boolean)
    if on = m.top.immersive then return
    if on
        m.video.translation = [0, 0]
        m.video.width = 1920
        m.video.height = 1080
    else
        Hero_VideoBox()
    end if
    m.solid.visible = not on and not m.top.fullscreen
    m.floor.visible = not on and not m.top.fullscreen
    m.fadeLeft.visible = not on
    m.fadeBottom.visible = not on
    m.metaRow.visible = not on
    m.description.visible = not on
    m.ratingsRow.visible = not on and m.ratingsRow.getChildCount() > 0
    m.top.immersive = on
end sub

sub onVideoMode()
    m.backdrop.visible = not m.top.videoMode
end sub
