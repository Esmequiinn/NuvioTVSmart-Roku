sub init()
    m.title = m.top.findNode("title")
    m.version = m.top.findNode("version")
    m.notesLabel = m.top.findNode("notesLabel")
    m.notes = m.top.findNode("notes")
    m.qr = m.top.findNode("qr")
    m.qrBack = m.top.findNode("qrBack")
    m.scan = m.top.findNode("scan")
    m.ok = m.top.findNode("ok")
    m.title.font.size = 46
    m.version.font.size = 28
    m.notesLabel.font.size = 28
    m.notes.font.size = 26
    m.scan.font.size = 22
    m.ok.font.size = 30
    m.title.text = L("Actualización disponible")
    m.notesLabel.text = L("Novedades")
    m.scan.text = L("Escanea el código para descargar la nueva versión")
    m.ok.text = L("Aceptar")
    m.top.observeField("focusedChild", "onFocus")
end sub

sub onInfo()
    info = m.top.info
    if info = invalid then return
    v = info.version
    if v = invalid then v = ""
    m.version.text = L("Versión ") + v
    notes = info.notes
    if notes = invalid or notes = "" then notes = L("Sin cambios")
    m.notes.text = notes
    url = info.url
    if url = invalid then url = ""
    m.qr.visible = url <> ""
    m.qrBack.visible = url <> ""
    m.scan.visible = url <> ""
    if url <> "" then m.qr.uri = "https://api.qrserver.com/v1/create-qr-code/?size=420x420&margin=0&data=" + url.EncodeUriComponent()
end sub

sub onFocus()
    if m.top.hasFocus() then m.notes.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return true
    if key = "OK" or key = "back"
        m.top.event = { type: "close" }
    end if
    return true
end function
