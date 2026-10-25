sub init()
    m.frame = m.top.findNode("frame")
    m.name = m.top.findNode("name")
    m.mask = m.top.findNode("mask")
    m.art = m.top.findNode("art")
    m.shade = m.top.findNode("shade")
    m.cw = m.top.findNode("cw")
    m.badgeBg = m.top.findNode("badgeBg")
    m.badge = m.top.findNode("badge")
    m.kicker = m.top.findNode("kicker")
    m.cardTitle = m.top.findNode("cardTitle")
    m.cardSub = m.top.findNode("cardSub")
    m.track = m.top.findNode("track")
    m.bar = m.top.findNode("bar")
    m.ring = m.top.findNode("ring")
    m.watched = m.top.findNode("watched")
    m.watchedDot = m.top.findNode("watchedDot")
    m.seenRow = false
    m.body = m.top.findNode("body")
    paintRing()
    m.global.observeField("accent", "paintRing")
    if m.global.hasField("expandShift") then m.global.observeField("expandShift", "applyShift")
    m.badge.font.size = 19
    m.kicker.font.size = 22
    m.cardTitle.font.size = 27
    m.cardSub.font.size = 22
    m.landscape = false
    m.reported = false
    m.art.observeField("loadStatus", "onArtStatus")
end sub

sub onArtStatus()
    m.frame.visible = m.art.loadStatus <> "ready"
    if m.art.loadStatus <> "failed" then return
    item = m.top.itemContent
    if item = invalid or not item.hasField("fallback") then return
    if item.fallback <> "" and m.art.uri <> item.fallback then m.art.uri = item.fallback
end sub

function fieldOf(item as object, name as string) as string
    if not item.hasField(name) then return ""
    v = item.getField(name)
    if v = invalid or GetInterface(v, "ifString") = invalid then return ""
    return v
end function

sub applyShift()
    shift = m.global.expandShift
    dx = 0
    if shift > 0
        item = m.top.itemContent
        row = m.global.expandRow
        if item <> invalid and row <> invalid
            parent = item.getParent()
            if parent <> invalid and parent.isSameNode(row)
                if itemIndex(item, parent) > m.global.expandIndex then dx = shift
            end if
        end if
    end if
    m.body.translation = [dx, 0]
end sub

function itemIndex(item as object, parent as object) as integer
    if item.hasField("idx") then return item.idx
    if m.indexOf <> invalid and m.indexOf.isSameNode(item) then return m.indexCache
    idx = -1
    for i = 0 to parent.getChildCount() - 1
        if parent.getChild(i).isSameNode(item)
            idx = i
            exit for
        end if
    end for
    m.indexOf = item
    m.indexCache = idx
    return idx
end function

sub onContent()
    item = m.top.itemContent
    if item = invalid then return
    if m.global.hasField("expandShift") then applyShift()
    if item.hasField("watched") and (m.watchItem = invalid or not item.isSameNode(m.watchItem))
        if m.watchItem <> invalid then m.watchItem.unobserveFieldScoped("watched")
        m.watchItem = item
        item.observeFieldScoped("watched", "onWatched")
    end if
    onWatched()
    m.name.text = item.title
    m.art.uri = item.HDPosterUrl
    isFolder = fieldOf(item, "itemType") = "folder"
    if isFolder
        hide = item.hasField("hideTitle") and item.hideTitle = true
        m.cw.visible = false
        m.shade.visible = not hide
        m.name.visible = not hide
        m.name.maxLines = 1
        m.name.vertAlign = "bottom"
        m.name.color = "0xFFFFFFFF"
        m.name.translation = [12, m.top.height - 62]
        m.name.height = 50
        m.frame.visible = m.art.loadStatus <> "ready"
    else if m.landscape
        m.name.visible = false
        m.shade.visible = true
        m.cw.visible = true
        layoutCard(item)
    else
        m.name.visible = true
        m.name.maxLines = 5
        m.name.vertAlign = "center"
        m.name.color = "0xC9C9D6FF"
        m.name.translation = [14, 14]
        m.name.height = m.top.height - 28
        m.shade.visible = false
        m.cw.visible = false
    end if
    progress = 0.0
    if item.hasField("progress") then progress = item.progress
    if progress > 0.01
        m.track.visible = true
        m.bar.visible = true
        accent = "0x7C4DFFFF"
        if m.global.hasField("accent") then accent = m.global.accent
        m.bar.color = accent
        if progress > 1 then progress = 1
        m.bar.width = m.track.width * progress
    else
        m.track.visible = false
        m.bar.visible = false
    end if
end sub

sub layoutCard(item as object)
    w = m.top.width
    h = m.top.height
    if w <= 0 or h <= 0 then return
    pad = 22
    badge = fieldOf(item, "badge")
    m.badge.text = badge
    m.badgeBg.visible = badge <> ""
    m.badge.visible = badge <> ""
    if badge <> ""
        m.badge.width = 0
        m.badge.height = 0
        bw = m.badge.boundingRect().width
        if bw <= 0 then bw = Len(badge) * 10
        bw = bw + 30
        if bw > w - 32 then bw = w - 32
        m.badgeBg.width = bw
        m.badgeBg.height = 40
        m.badgeBg.translation = [w - 15 - bw, 15]
        m.badge.width = bw
        m.badge.height = 40
        m.badge.translation = [w - 15 - bw, 15]
    end if
    kicker = fieldOf(item, "kicker")
    subText = fieldOf(item, "subtitle")
    m.kicker.text = kicker
    m.cardTitle.text = item.title
    m.cardSub.text = subText
    m.kicker.visible = kicker <> ""
    m.cardSub.visible = subText <> ""
    textW = w - pad * 2
    m.kicker.width = textW
    m.cardTitle.width = textW
    m.cardSub.width = textW
    y = h - pad
    if subText <> ""
        y = y - 30
        m.cardSub.translation = [pad, y]
    end if
    y = y - 38
    m.cardTitle.translation = [pad, y]
    if kicker <> ""
        y = y - 30
        m.kicker.translation = [pad, y]
    end if
end sub

sub onSize()
    w = m.top.width
    h = m.top.height
    if w <= 0 or h <= 0 then return
    m.landscape = w > h
    m.frame.width = w
    m.frame.height = h
    if m.landscape
        m.mask.maskUri = "pkg:/images/mask_landscape.png"
    else if w = h
        m.mask.maskUri = "pkg:/images/mask_square.png"
    else
        m.mask.maskUri = "pkg:/images/mask_poster.png"
    end if
    m.mask.maskSize = [w, h]
    m.ring.width = w
    m.ring.height = h
    m.art.width = w
    m.art.height = h
    m.art.loadWidth = w
    m.art.loadHeight = h
    m.shade.width = w
    m.shade.height = h
    m.shade.translation = [0, 0]
    m.name.width = w - 28
    m.name.height = h - 28
    if m.landscape
        m.track.width = w - 40
        m.track.height = 6
        m.track.color = "0x0000004D"
        m.track.translation = [20, h - 14]
        m.bar.height = 6
        m.bar.translation = [20, h - 14]
    else
        m.track.width = w - 24
        m.track.height = 6
        m.track.color = "0xFFFFFF40"
        m.track.translation = [12, h - 14]
        m.bar.height = 6
        m.bar.translation = [12, h - 14]
    end if
    onContent()
end sub

sub paintRing()
    if m.global.hasField("accent")
        m.ring.blendColor = m.global.accent
        m.watchedDot.blendColor = m.global.accent
    end if
end sub

sub Gif_Update(focused as boolean)
    item = m.top.itemContent
    url = ""
    if focused and item <> invalid then url = fieldOf(item, "gif")
    if url <> ""
        low = LCase(url)
        if Instr(1, low, ".gif") = 0 and Instr(1, low, ".webp") = 0 and Instr(1, low, ".mp4") = 0 then url = ""
    end if
    if url = ""
        if m.gif <> invalid
            m.gif.control = "pause"
            m.mask.removeChild(m.gif)
            m.gif = invalid
        end if
        return
    end if
    if m.gif <> invalid and m.gif.uri = url then return
    if m.gif = invalid
        m.gif = CreateObject("roSGNode", "AnimatedImage")
        if m.gif = invalid then return
        m.gif.visible = false
        m.gif.observeField("state", "onGifState")
        m.mask.appendChild(m.gif)
    end if
    w = Int(m.top.width)
    h = Int(m.top.height)
    m.gif.width = w
    m.gif.height = h
    m.gif.loadWidth = w
    m.gif.loadHeight = h
    m.gif.loadDisplayMode = "scaleToZoom"
    low = LCase(url)
    if Instr(1, low, ".mp4") > 0
        m.gif.mimeType = "video/mp4"
        m.gif.uri = url
    else
        m.gif.mimeType = "video/webp"
        m.gif.uri = "https://wsrv.nl/?url=" + url.EncodeUriComponent() + "&n=-1&output=webp&w=" + w.ToStr() + "&h=" + h.ToStr() + "&fit=cover"
    end if
    m.gif.control = "loop"
end sub

sub onGifState()
    if m.gif = invalid then return
    st = m.gif.state
    m.gif.visible = st <> "downloading" and st <> "init" and st <> "error" and st <> ""
end sub

sub onWatched()
    item = m.top.itemContent
    show = false
    if item <> invalid and item.hasField("watched") then show = item.watched = true
    m.watched.visible = show and not m.landscape
    m.watched.translation = [m.top.width - 44, 10]
end sub

sub onItemFocus()
    item = m.top.itemHasFocus or m.top.focusPercent >= 0.99
    m.ring.visible = item and m.top.rowHasFocus and m.top.rowListHasFocus
    if not m.seenRow and (m.top.rowHasFocus or m.top.rowListHasFocus) then m.seenRow = true
    if not m.seenRow then m.ring.visible = item
    focused = m.ring.visible
    Gif_Update(focused)
    if focused = m.reported then return
    m.reported = focused
    if focused and not m.landscape and m.global.hasField("focusCard") then m.global.focusCard = m.top
end sub
