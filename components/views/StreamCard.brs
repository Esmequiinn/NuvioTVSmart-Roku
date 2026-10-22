sub init()
    m.bg = m.top.findNode("bg")
    m.name = m.top.findNode("name")
    m.desc = m.top.findNode("desc")
    m.addonLogo = m.top.findNode("addonLogo")
    m.addonName = m.top.findNode("addonName")
    m.badges = m.top.findNode("badges")
    m.ring = m.top.findNode("ring")
    m.name.font.size = 30
    m.desc.font.size = 24
    m.addonName.font.size = 22
    m.images = []
end sub

sub onContent()
    item = m.top.itemContent
    if item = invalid then return
    top = item.place = "top"
    hasBadges = (type(item.chips) = "roArray" and item.chips.Count() > 0) or (type(item.badges) = "roArray" and item.badges.Count() > 0)
    y = 22
    if top and hasBadges then y = 66
    m.name.translation = [30, y]
    m.name.text = item.sname
    m.desc.translation = [310, y]
    lines = Int((172 - y) / 30)
    if lines < 1 then lines = 1
    m.desc.maxLines = lines
    m.desc.height = lines * 30
    m.desc.text = item.sdesc
    m.desc.visible = item.sdesc <> ""
    nameLines = 3
    if top and hasBadges then nameLines = 2
    m.name.maxLines = nameLines

    x = 30
    logo = CardText(item.slogo)
    m.addonLogo.visible = logo <> ""
    if logo <> ""
        m.addonLogo.uri = logo
        m.addonLogo.translation = [30, 184]
        x = 76
    end if
    m.addonName.text = item.saddon
    m.addonName.translation = [x, 184]
    nameWidth = Int(m.addonName.boundingRect().width)
    buildBadges(item)
    if top
        m.badges.translation = [30, 18]
    else
        m.badges.translation = [x + nameWidth + 26, 184]
    end if
    onFocus()
end sub

function CardText(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub buildBadges(item as object)
    m.badges.removeChildrenIndex(m.badges.getChildCount(), 0)
    m.images = []
    m.cursor = 0
    if type(item.badges) = "roArray"
        for each b in item.badges
            if CardText(b.i) <> ""
                img = m.badges.createChild("Poster")
                img.height = 34
                img.width = 34
                img.loadDisplayMode = "scaleToFit"
                img.loadHeight = 68
                img.translation = [m.cursor, 0]
                img.observeField("loadStatus", "onBadgeLoaded")
                img.uri = b.i
                m.images.Push(img)
                m.cursor = m.cursor + 34 + 10
            else
                addChip(CardText(b.n), CardText(b.c), CardText(b.t))
            end if
        end for
    end if
    if type(item.chips) = "roArray"
        for each c in item.chips
            addChip(c, "", "")
        end for
    end if
end sub

sub addChip(text as string, color as string, textColor as string)
    if text = "" then return
    g = m.badges.createChild("Group")
    g.translation = [m.cursor, 0]
    pill = g.createChild("Poster")
    pill.uri = "pkg:/images/pill.9.png"
    pill.height = 34
    if color <> "" then pill.blendColor = color else pill.blendColor = "0xFFFFFF26"
    label = g.createChild("Label")
    label.font = "font:SmallestBoldSystemFont"
    label.font.size = 20
    label.text = text
    label.height = 34
    label.vertAlign = "center"
    label.translation = [14, 0]
    if textColor <> "" then label.color = textColor else label.color = "0xFFFFFFFF"
    w = Int(label.boundingRect().width) + 28
    pill.width = w
    m.cursor = m.cursor + w + 10
end sub

sub onBadgeLoaded(event as object)
    img = event.getRoSGNode()
    if img.loadStatus <> "ready" or img.bitmapHeight <= 0 then return
    target = Int(img.bitmapWidth * 34 / img.bitmapHeight)
    if target < 20 then target = 20
    if target > 200 then target = 200
    if target = img.width then return
    delta = target - img.width
    img.width = target
    shift = false
    for i = 0 to m.badges.getChildCount() - 1
        child = m.badges.getChild(i)
        if shift
            child.translation = [child.translation[0] + delta, 0]
        else if child.isSameNode(img)
            shift = true
        end if
    end for
end sub

sub onFocus()
    focused = m.top.itemHasFocus or m.top.focusPercent > 0.5
    if m.global.hasField("accent") then m.ring.blendColor = m.global.accent
    m.ring.visible = m.top.itemHasFocus
    if focused
        m.bg.blendColor = "0xFFFFFF2E"
        m.addonName.color = "0xD4D4DCFF"
    else
        m.bg.blendColor = "0xFFFFFF12"
        m.addonName.color = "0x9A9AAAFF"
    end if
end sub
