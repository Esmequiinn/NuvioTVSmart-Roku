sub init()
    m.frame = m.top.findNode("frame")
    m.name = m.top.findNode("name")
    m.mask = m.top.findNode("mask")
    m.art = m.top.findNode("art")
    m.shade = m.top.findNode("shade")
    m.cardTitle = m.top.findNode("cardTitle")
    m.cardSub = m.top.findNode("cardSub")
    m.track = m.top.findNode("track")
    m.bar = m.top.findNode("bar")
    m.landscape = false
    m.reported = false
    m.art.observeField("loadStatus", "onArtStatus")
end sub

sub onArtStatus()
    if m.art.loadStatus <> "failed" then return
    item = m.top.itemContent
    if item = invalid or not item.hasField("fallback") then return
    if item.fallback <> "" and m.art.uri <> item.fallback then m.art.uri = item.fallback
end sub

sub onContent()
    item = m.top.itemContent
    if item = invalid then return
    m.name.text = item.title
    m.art.uri = item.HDPosterUrl
    if m.landscape
        m.name.visible = false
        m.shade.visible = true
        m.cardTitle.visible = true
        m.cardSub.visible = true
        m.cardTitle.text = item.title
        subText = ""
        if item.hasField("episodeLabel") then subText = item.episodeLabel
        if subText = "" then subText = item.description
        m.cardSub.text = subText
    else
        m.name.visible = true
        m.shade.visible = false
        m.cardTitle.visible = false
        m.cardSub.visible = false
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

sub onSize()
    w = m.top.width
    h = m.top.height
    if w <= 0 or h <= 0 then return
    m.landscape = w > h
    m.frame.width = w
    m.frame.height = h
    if m.landscape
        m.mask.maskUri = "pkg:/images/mask_landscape.png"
    else
        m.mask.maskUri = "pkg:/images/mask_poster.png"
    end if
    m.mask.maskSize = [w, h]
    m.art.width = w
    m.art.height = h
    m.art.loadWidth = w
    m.art.loadHeight = h
    m.shade.width = w
    m.shade.height = Int(h * 0.6)
    m.shade.translation = [0, h - Int(h * 0.6)]
    m.name.width = w - 28
    m.name.height = h - 28
    m.cardTitle.width = w - 32
    m.cardTitle.translation = [16, h - 84]
    m.cardSub.width = w - 32
    m.cardSub.translation = [16, h - 48]
    m.track.width = w - 24
    m.track.translation = [12, h - 14]
    m.bar.translation = [12, h - 14]
    onContent()
end sub

sub onItemFocus()
    focused = m.top.itemHasFocus or m.top.focusPercent >= 0.99
    if focused = m.reported then return
    m.reported = focused
    if focused and not m.landscape and m.global.hasField("focusCard") then m.global.focusCard = m.top
end sub
