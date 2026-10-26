function Mask_Mode() as string
    mode = "auto"
    if m.global <> invalid and m.global.hasField("corners") and m.global.corners <> invalid then mode = m.global.corners
    return mode
end function

function Mask_On() as boolean
    mode = Mask_Mode()
    if mode = "off" then return false
    if mode = "full" or mode = "hd" then return true
    return LCase(CreateObject("roDeviceInfo").GetGraphicsPlatform()) <> "directfb"
end function

function Mask_Scale() as float
    mode = Mask_Mode()
    if mode = "full" then return 1.0
    if mode = "hd" then return 1280.0 / 1920.0
    k = 1.0
    res = CreateObject("roDeviceInfo").GetUIResolution()
    if type(res) = "roAssociativeArray" and res.width <> invalid and res.width > 0 and res.width < 1920 then k = res.width / 1920.0
    return k
end function

sub Mask_Apply(node as object, w as dynamic, h as dynamic)
    k = Mask_Scale()
    node.maskSize = [Int(w * k + 0.5), Int(h * k + 0.5)]
    if not Mask_On() then node.maskUri = ""
end sub

function Mask_Circle(url as string, size as integer) as string
    if url = "" or Mask_On() or LCase(Left(url, 4)) <> "http" then return url
    if Instr(1, url, "wsrv.nl") > 0 then return url
    return "https://wsrv.nl/?url=" + url.EncodeUriComponent() + "&w=" + size.ToStr() + "&h=" + size.ToStr() + "&fit=cover&mask=circle&output=png"
end function

sub Mask_Caps(parent as object, w as integer, h as integer, radius as integer, color as string)
    caps = parent.findNode("maskCaps")
    if Mask_On() and Mask_Scale() > 0.99
        if caps <> invalid then caps.visible = false
        return
    end if
    if caps = invalid
        caps = parent.createChild("Group")
        caps.id = "maskCaps"
        for each name in ["tl", "tr", "bl", "br"]
            p = caps.createChild("Poster")
            p.id = "cap_" + name
            p.uri = "pkg:/images/cap_" + name + ".png"
        end for
    end if
    caps.visible = true
    spots = { tl: [0, 0], tr: [w - radius, 0], bl: [0, h - radius], br: [w - radius, h - radius] }
    for each name in spots
        p = caps.findNode("cap_" + name)
        p.width = radius
        p.height = radius
        p.translation = spots[name]
        p.blendColor = color
    end for
end sub

function Mask_NeedCaps() as boolean
    return not Mask_On() or Mask_Scale() < 0.99
end function
