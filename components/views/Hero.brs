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
    m.dotRow = m.top.findNode("dotRow")
    m.solidOn = true
    m.floorOn = true
    m.descBase = { y: 392, lines: 3, height: 130 }
    m.video = m.top.findNode("video")
    m.video.observeField("state", "onVideoState")
    m.title.font.size = 64
    m.logo.observeField("loadStatus", "onLogoStatus")
    m.bgNext = m.top.createChild("Poster")
    m.bgNext.width = 1
    m.bgNext.height = 1
    m.bgNext.opacity = 0.01
    m.bgNext.loadWidth = 1280
    m.bgNext.loadHeight = 720
    m.bgNext.loadDisplayMode = "scaleToZoom"
    m.bgNext.observeField("loadStatus", "onBgNext")
    m.bgWant = ""
    m.bgWait = m.top.createChild("Timer")
    m.bgWait.duration = 0.7
    m.bgWait.repeat = false
    m.bgWait.observeField("fire", "onBgWait")
    m.local = {}
    m.pending = {}
    m.cacheJobs = []
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
        return
    end if
    m.fadeBottom.height = 346
    m.boxTop = 120
    m.boxHeight = 180
    m.title.translation = [160, 150]
    m.title.height = 150
    m.metaRow.translation = [160, 330]
    m.descBase = { y: 392, lines: 3, height: 130 }
    m.backdrop.opacity = 1
    m.solidOn = true
    m.floorOn = true
    if m.top.bare
        m.backdrop.translation = [700, 0]
        m.backdrop.width = 1220
        m.backdrop.height = 686
        m.backdrop.opacity = 0.55
        m.fadeLeft.translation = [700, 0]
        m.fadeLeft.width = 900
        m.fadeLeft.height = 686
        m.fadeBottom.translation = [0, 380]
        m.fadeBottom.height = 306
        m.floor.translation = [0, 684]
        m.floor.height = 396
        m.solidOn = false
    else if m.top.wide
        m.backdrop.translation = [0, 0]
        m.backdrop.width = 1920
        m.backdrop.height = 1080
        m.fadeLeft.translation = [0, 0]
        m.fadeLeft.width = 1300
        m.fadeLeft.height = 1080
        m.fadeBottom.translation = [0, 560]
        m.fadeBottom.height = 520
        m.solidOn = false
        m.floorOn = false
    else
        m.backdrop.translation = [560, 0]
        m.backdrop.width = 1360
        m.backdrop.height = 765
        m.fadeLeft.translation = [560, 0]
        m.fadeLeft.width = 760
        m.fadeLeft.height = 765
        m.fadeBottom.translation = [0, 420]
        m.floor.translation = [0, 764]
        m.floor.height = 316
    end if
    m.solid.visible = m.solidOn and not m.top.immersive
    m.floor.visible = m.floorOn and not m.top.immersive
    text = 1.0
    if m.top.bare then text = 0.0
    for each node in [m.logo, m.title, m.metaRow, m.description, m.ratingsRow, m.dotRow]
        node.opacity = text
    end for
    m.logo.translation = [160, m.boxTop]
    m.logo.height = m.boxHeight
    Hero_VideoBox()
    Hero_Ratings(m.lastRatings)
    onLogoStatus()
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
    logo = localOf(Img_Sized(textOf(d.logo), "w500"))
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
    bg = localOf(Img_Sized(textOf(d.background), "w1280"))
    if bg = m.backdrop.uri then
        m.bgWant = ""
    else if bg = ""
        m.bgWant = ""
        m.backdrop.uri = ""
    else if bg <> m.bgWant
        m.bgWant = bg
        if m.backdrop.uri = "" then m.backdrop.uri = bg
        if m.bgNext.uri = bg and m.bgNext.loadStatus = "ready"
            m.backdrop.uri = bg
            m.bgWant = ""
            return
        end if
        m.bgNext.uri = bg
        m.bgWait.control = "stop"
        m.bgWait.control = "start"
    end if
end sub

sub onBgWait()
    if m.bgWant = "" then return
    m.backdrop.uri = m.bgWant
    m.bgWant = ""
end sub

sub onPreload()
    list = m.top.preload
    if type(list) <> "roArray" then return
    urls = []
    for each entry in list
        url = textOf(entry.url)
        if url <> ""
            if entry.kind = "logo" then url = Img_Sized(url, "w500") else url = Img_Sized(url, "w1280")
            if Left(url, 4) = "http" and not m.local.DoesExist(url) and not m.pending.DoesExist(url)
                m.pending[url] = true
                urls.Push(url)
            end if
        end if
    end for
    if urls.Count() = 0 then return
    if m.cacheJobs.Count() >= 3
        old = m.cacheJobs.Shift()
        old.cancel = true
    end if
    task = CreateObject("roSGNode", "PosterCacheTask")
    task.quick = true
    task.urls = urls
    task.observeField("result", "onCacheDone")
    task.control = "RUN"
    m.cacheJobs.Push(task)
end sub

sub onCacheDone(event as object)
    task = event.getRoSGNode()
    for i = 0 to m.cacheJobs.Count() - 1
        if m.cacheJobs[i].isSameNode(task)
            m.cacheJobs.Delete(i)
            exit for
        end if
    end for
    for each url in task.urls
        m.pending.Delete(url)
    end for
    found = task.result
    if type(found) <> "roAssociativeArray" then return
    for each k in found
        m.local[k] = found[k]
    end for
    if m.local.Count() > 400 then m.local = found
end sub

function Hero_Local(url as dynamic) as string
    u = Str_Of(url)
    if u <> "" and m.local.DoesExist(u) then return m.local[u]
    return ""
end function

function localOf(url as string) as string
    if url <> "" and m.local.DoesExist(url) then return m.local[url]
    return url
end function

sub onBgNext()
    status = m.bgNext.loadStatus
    if m.bgWant = "" or m.bgNext.uri <> m.bgWant then return
    if status = "ready" or status = "failed"
        m.bgWait.control = "stop"
        m.backdrop.uri = m.bgWant
        m.bgWant = ""
    end if
end sub

sub onLogoStatus()
    status = m.logo.loadStatus
    if status = "ready" and m.logo.uri <> ""
        bw = m.logo.bitmapWidth
        bh = m.logo.bitmapHeight
        if bw > 0 and bh > 0
            maxH = m.boxHeight
            if bw < bh * 1.6 then maxH = Int(m.boxHeight * 1.35)
            scale = 620 / bw
            if bh * scale > maxH then scale = maxH / bh
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
        m.wantVideo = false
        m.video.control = "stop"
        m.video.visible = false
        m.backdrop.visible = not m.top.videoMode
        Hero_Immersive(false)
        return
    end if
    m.wantVideo = true
    m.full = Bool_Of(t.full, false)
    Hero_VideoBox()
    m.video.mute = m.top.muted
    m.video.content = Trailer_Content(t)
    m.video.control = "play"
end sub

sub onVideoState()
    state = m.video.state
    if state = "playing" and not Bool_Of(m.wantVideo, false)
        m.video.control = "stop"
        return
    end if
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
    m.solid.visible = not on and not m.top.fullscreen and m.solidOn
    m.floor.visible = not on and not m.top.fullscreen and m.floorOn
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

sub onDots()
    d = m.top.dots
    count = 0
    index = 0
    if type(d) = "roAssociativeArray"
        if d.count <> invalid then count = d.count
        if d.index <> invalid then index = d.index
    end if
    if count < 2 then count = 0
    while m.dotRow.getChildCount() > count
        m.dotRow.removeChildIndex(m.dotRow.getChildCount() - 1)
    end while
    while m.dotRow.getChildCount() < count
        dot = m.dotRow.createChild("Poster")
        dot.uri = "pkg:/images/c/d20.png"
        dot.width = 12
        dot.height = 12
    end while
    for i = 0 to count - 1
        dot = m.dotRow.getChild(i)
        if i = index then dot.blendColor = "0xFFFFFFFF" else dot.blendColor = "0xFFFFFF59"
    end for
end sub
