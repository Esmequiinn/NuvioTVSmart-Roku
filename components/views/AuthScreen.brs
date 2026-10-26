sub init()
    m.leftTitle = m.top.findNode("leftTitle")
    m.leftDesc = m.top.findNode("leftDesc")
    m.leftHint = m.top.findNode("leftHint")
    m.cardTitle = m.top.findNode("cardTitle")
    m.cardSub = m.top.findNode("cardSub")
    m.qrImage = m.top.findNode("qrImage")
    m.qrSpin = m.top.findNode("qrSpin")
    m.codeText = m.top.findNode("codeText")
    m.statusText = m.top.findNode("statusText")
    m.terms = m.top.findNode("terms")
    m.buttonsGroup = m.top.findNode("buttons")
    m.leftTitle.font.size = 60
    m.leftDesc.font.size = 32
    m.leftHint.font.size = 26
    m.cardTitle.font.size = 46
    m.cardSub.font.size = 26
    m.statusText.font.size = 26
    m.terms.font.size = 20
    m.codeText.font.size = 30
    m.qrSpin.poster.uri = "pkg:/images/spinner.png"
    m.qrSpin.poster.width = 96
    m.qrSpin.poster.height = 96
    m.qrSpin.poster.blendColor = "0x0D0D0DFF"
    m.index = 0
    m.buttons = []
    m.qrImage.observeField("loadStatus", "onQrStatus")
    render()
end sub

sub render()
    m.leftTitle.text = L("Iniciar sesión con QR")
    m.leftDesc.text = L("Usa tu teléfono para iniciar sesión con correo y contraseña. En la TV solo se usa el QR para que sea más rápido.")
    m.cardTitle.text = L("Inicio de sesión de cuenta")
    m.cardSub.text = L("Escanea el QR, aprueba en el navegador y luego vuelve aquí.")
    m.terms.text = L("Al registrarte o iniciar sesión, aceptas los Términos de Nuvio.")
    defs = [{ id: "refresh", label: L("Actualizar QR") }]
    if m.top.mode = "onboarding"
        defs.Push({ id: "skip", label: L("Continuar sin cuenta") })
    else
        defs.Push({ id: "back", label: L("Volver") })
    end if
    buildButtons(defs)
    onHint()
end sub

sub buildButtons(defs as object)
    m.buttonsGroup.removeChildrenIndex(m.buttonsGroup.getChildCount(), 0)
    m.buttons = []
    widths = []
    total = 0
    for each d in defs
        probe = CreateObject("roSGNode", "Label")
        probe.font = "font:MediumSystemFont"
        probe.font.size = 32
        probe.text = d.label
        w = Int(probe.boundingRect().width)
        if w <= 0 then w = Len(d.label) * 17
        w = w + 72
        widths.Push(w)
        total = total + w
    end for
    total = total + 16 * (defs.Count() - 1)
    x = Int((876 - total) / 2)
    for i = 0 to defs.Count() - 1
        g = m.buttonsGroup.createChild("Group")
        g.translation = [x, 0]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/pill.9.png"
        bg.width = widths[i]
        bg.height = 80
        label = g.createChild("Label")
        label.font = "font:MediumSystemFont"
        label.font.size = 32
        label.width = widths[i]
        label.height = 80
        label.horizAlign = "center"
        label.vertAlign = "center"
        label.text = defs[i].label
        m.buttons.Push({ id: defs[i].id, bg: bg, label: label })
        x = x + widths[i] + 16
    end for
    if m.index >= m.buttons.Count() then m.index = 0
    paint()
end sub

sub paint()
    for i = 0 to m.buttons.Count() - 1
        b = m.buttons[i]
        if i = m.index
            b.bg.blendColor = "0xFFFFFFFF"
            b.label.color = "0x0D0D0DFF"
        else
            b.bg.blendColor = "0x252525FF"
            b.label.color = "0xFFFFFFFF"
        end if
    end for
end sub

sub onQr()
    url = m.top.qr
    if url = ""
        m.qrImage.uri = ""
        m.qrSpin.visible = true
        m.qrSpin.control = "start"
        return
    end if
    m.qrImage.uri = "https://api.qrserver.com/v1/create-qr-code/?size=420x420&margin=0&data=" + url.EncodeUriComponent()
end sub

sub onQrStatus()
    if m.qrImage.loadStatus = "ready" or m.qrImage.loadStatus = "failed"
        m.qrSpin.visible = false
        m.qrSpin.control = "stop"
    end if
end sub

sub onCode()
    if m.top.code = ""
        m.codeText.text = ""
    else
        m.codeText.text = L("Código: ") + m.top.code
    end if
end sub

sub onStatus()
    m.statusText.text = m.top.status
end sub

sub onHint()
    if m.top.mode = "onboarding"
        m.leftHint.text = m.top.hint
    else
        m.leftHint.text = ""
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "left" and m.index > 0
        m.index = m.index - 1
        paint()
    else if key = "right" and m.index < m.buttons.Count() - 1
        m.index = m.index + 1
        paint()
    else if key = "OK" and m.index < m.buttons.Count()
        m.top.event = { type: m.buttons[m.index].id }
    else if key = "back"
        if m.top.mode = "onboarding" then m.top.event = { type: "exit" } else m.top.event = { type: "back" }
    end if
    return true
end function
