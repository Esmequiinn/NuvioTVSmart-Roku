sub init()
    m.ring = m.top.findNode("ring")
    m.disc = m.top.findNode("disc")
    m.initial = m.top.findNode("initial")
    m.mask = m.top.findNode("mask")
    m.pic = m.top.findNode("pic")
    m.pic.observeField("loadStatus", "onPic")
    render()
end sub

sub render()
    size = m.top.size
    if size <= 0 then size = 96
    m.disc.width = size
    m.disc.height = size
    m.disc.uri = Av_Disc(size)
    m.mask.maskUri = Av_Disc(size)
    color = m.top.color
    if color = "" then color = "7C5CFF"
    if Left(color, 1) = "#" then color = Mid(color, 2)
    if Left(color, 2) <> "0x" then color = "0x" + color
    if Len(color) = 8 then color = color + "FF"
    m.disc.blendColor = color
    m.initial.width = size
    m.initial.height = size
    m.initial.font.size = Int(size * 0.44)
    name = m.top.name
    if name = "" then m.initial.text = "" else m.initial.text = UCase(Left(name, 1))
    ring = m.top.ringColor
    if ring <> ""
        m.ring.visible = true
        m.ring.blendColor = ring
        m.ring.width = size + 8
        m.ring.height = size + 8
        m.ring.uri = Av_Disc(size + 8)
        m.ring.translation = [-4, -4]
    else
        m.ring.visible = false
    end if
    m.mask.maskSize = [size, size]
    m.pic.width = size
    m.pic.height = size
    m.pic.loadWidth = size * 2
    m.pic.loadHeight = size * 2
    if m.pic.uri <> m.top.avatar then m.pic.uri = m.top.avatar
    onPic()
end sub

sub onPic()
    m.mask.visible = m.top.avatar <> "" and m.pic.loadStatus = "ready"
end sub

function Av_Disc(size as integer) as string
    known = { "64": true, "72": true, "96": true, "104": true, "128": true, "132": true, "136": true, "140": true }
    if known.DoesExist(size.ToStr()) then return "pkg:/images/c/d" + size.ToStr() + ".png"
    return "pkg:/images/dot.png"
end function
