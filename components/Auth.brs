function Auth_ShouldGate() as boolean
    if St_Integrations().nuvioAccess <> "" then return false
    if Bool_Of(St_Get("authSeen", false), false) then return false
    return St_Integrations().nuvioUrl <> "" or Config_NuvioServer() <> ""
end function

sub Auth_Open(mode as string)
    m.auth.mode = mode
    url = Net_ServerUrl()
    hint = ""
    if url <> "" then hint = L("Sin cuenta también puedes agregar addons desde tu celular en {url} o desde Ajustes en esta TV.").Replace("{url}", url)
    m.auth.hint = hint
    m.auth.visible = true
    m.auth.setFocus(true)
    Auth_StartQr()
end sub

sub Auth_Close()
    m.loginTimer.control = "stop"
    m.login = invalid
    m.loginPoll = invalid
    m.auth.visible = false
    m.auth.qr = ""
end sub

sub Auth_StartQr()
    m.loginTimer.control = "stop"
    m.loginPoll = invalid
    m.login = { service: "nuvio", screen: true }
    m.auth.qr = ""
    m.auth.code = ""
    m.auth.status = L("Generando QR...")
    m.authTask = CreateObject("roSGNode", "AccountTask")
    m.authTask.mode = "nuvioQrStart"
    m.authTask.observeField("result", "onAuthStarted")
    m.authTask.control = "RUN"
end sub

sub onAuthStarted(event as object)
    task = event.getRoSGNode()
    if m.authTask = invalid or not task.isSameNode(m.authTask) then return
    m.authTask = invalid
    if not m.auth.visible or m.login = invalid then return
    r = task.result
    if not Bool_Of(r.ok, false)
        m.auth.status = L("QR no disponible. Actualiza para volver a intentarlo.")
        m.auth.qr = ""
        return
    end if
    m.login.code = Str_Of(r.code)
    m.login.userCode = Str_Of(r.userCode)
    m.login.nonce = Str_Of(r.nonce)
    m.login.anon = Str_Of(r.anon)
    m.login.url = Str_Of(r.url)
    m.auth.qr = m.login.url
    m.auth.code = m.login.userCode
    m.auth.status = L("Esperando aprobación en tu teléfono...")
    interval = ToInt(r.interval, 3)
    if interval < 3 then interval = 3
    m.loginTimer.duration = interval
    m.loginTimer.control = "start"
end sub

sub onAuthEvent()
    ev = m.auth.event
    if ev = invalid then return
    kind = Str_Of(ev.type)
    if kind = "refresh"
        Auth_StartQr()
    else if kind = "skip" or kind = "exit"
        St_Set("authSeen", true)
        Auth_Close()
        showProfiles()
    else if kind = "back"
        Auth_Close()
        focusCurrent()
    end if
end sub

sub Auth_Approved()
    onboarding = m.auth.mode = "onboarding"
    St_Set("authSeen", true)
    Auth_Close()
    refreshSettings()
    if onboarding
        showProfiles()
        m.syncToast = true
        startQuietSync()
        Toast_Show(L("Sesión iniciada. Sincronizando con Nuvio..."))
    else
        focusCurrent()
        startNuvioSync()
    end if
end sub
