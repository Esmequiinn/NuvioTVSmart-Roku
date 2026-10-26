sub init()
    m.logo = m.top.findNode("logo")
    m.instruction = m.top.findNode("instruction")
    m.qr = m.top.findNode("qr")
    m.spin = m.top.findNode("spin")
    m.code = m.top.findNode("code")
    m.url = m.top.findNode("url")
    m.expires = m.top.findNode("expires")
    m.statusText = m.top.findNode("statusText")
    m.buttonText = m.top.findNode("buttonText")
    m.instruction.font.size = 28
    m.code.font.size = 60
    m.url.font.size = 24
    m.expires.font.size = 24
    m.statusText.font.size = 24
    m.buttonText.font.size = 30
    m.buttonText.text = L("Cancelar")
    m.spin.poster.uri = "pkg:/images/spinner.png"
    m.spin.poster.width = 96
    m.spin.poster.height = 96
    m.spin.poster.blendColor = "0x0D0D0DFF"
    m.tick = m.top.findNode("tick")
    m.tick.observeField("fire", "onTick")
    m.qr.observeField("loadStatus", "onQrStatus")
    m.clock = CreateObject("roTimespan")
    m.expiresIn = 0
end sub

function Ta_Str(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function

sub onInfo()
    info = m.top.info
    if info = invalid then return
    service = Ta_Str(info.service)
    if service = "trakt"
        m.logo.uri = "pkg:/images/trakt_wordmark.png"
        m.logo.width = 162
        m.logo.height = 70
        m.instruction.text = L("Ve a trakt.tv/activate e ingresa este código:")
    else
        m.logo.uri = "pkg:/images/simkl_wordmark.png"
        m.logo.width = 293
        m.logo.height = 48
        m.instruction.text = L("Abre la página de verificación de Simkl e ingresa este código.")
    end if
    m.logo.translation = [Int((1000 - m.logo.width) / 2), 70 - Int(m.logo.height / 2)]
    userCode = Ta_Str(info.userCode)
    url = Ta_Str(info.url)
    m.code.text = userCode
    m.url.text = url
    m.qr.uri = ""
    if url <> ""
        target = url
        if service = "trakt" and userCode <> "" then target = url + "/" + userCode
        m.spin.visible = true
        m.spin.control = "start"
        m.qr.uri = "https://api.qrserver.com/v1/create-qr-code/?size=420x420&margin=0&data=" + target.EncodeUriComponent()
    else
        m.spin.visible = true
        m.spin.control = "start"
    end if
    m.expiresIn = 0
    if info.expires <> invalid then m.expiresIn = info.expires
    m.clock.Mark()
    onTick()
    if m.expiresIn > 0 then m.tick.control = "start" else m.tick.control = "stop"
end sub

sub onQrStatus()
    if m.qr.loadStatus = "ready" or m.qr.loadStatus = "failed"
        m.spin.visible = false
        m.spin.control = "stop"
    end if
end sub

sub onTick()
    if m.expiresIn <= 0
        m.expires.text = ""
        return
    end if
    remain = m.expiresIn - Int(m.clock.TotalSeconds())
    if remain < 0 then remain = 0
    mins = Int(remain / 60)
    secs = remain mod 60
    s = secs.ToStr()
    if secs < 10 then s = "0" + s
    m.expires.text = L("El código expira en {t}").Replace("{t}", mins.ToStr() + ":" + s)
end sub

sub onStatus()
    m.statusText.text = m.top.status
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "OK" or key = "back"
        m.tick.control = "stop"
        m.top.event = { type: "cancel" }
    end if
    return true
end function
