sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    mode = m.top.mode
    p = m.top.params
    if p = invalid then p = {}
    result = { ok: false, mode: mode, error: "" }
    if mode = "traktCode"
        result = Trakt_Code()
    else if mode = "traktPoll"
        result = Trakt_Poll(Str_Of(p.deviceCode))
    else if mode = "mdbCode"
        result = Mdb_Code()
    else if mode = "mdbPoll"
        result = Mdb_Poll(Str_Of(p.deviceCode))
    else if mode = "simklPin"
        result = Simkl_Pin()
    else if mode = "simklPoll"
        result = Simkl_Poll(Str_Of(p.userCode))
    else if mode = "scrobble"
        Scrobble_Send(Str_Of(p.action), p)
        result = { ok: true, mode: mode }
    else if mode = "nuvioQrStart"
        result = Nuvio_QrStart()
    else if mode = "nuvioQrPoll"
        result = Nuvio_QrPoll(Str_Of(p.code), Str_Of(p.nonce))
    else if mode = "nuvioEmail"
        result = Nuvio_EmailLogin(Str_Of(p.email), Str_Of(p.password))
    else if mode = "nuvioSync"
        result = Nuvio_Sync()
    else if mode = "nuvioProgress"
        result = Nuvio_ProgressRefresh()
    else if mode = "debTbStart"
        result = Deb_TorboxStart()
    else if mode = "debTbPoll"
        result = Deb_TorboxPoll(Str_Of(p.deviceCode))
    else if mode = "debKey"
        id = Str_Of(p.id)
        key = Str_Of(p.key)
        if key = "" or Deb_Validate(id, key)
            integ = St_Integrations()
            integ[id + "Key"] = key
            integ[id + "From"] = ""
            if key <> "" then integ["debridOn"] = true
            if Deb_Connected(integ).Count() = 0 then integ["debridOn"] = false
            St_SaveIntegrations(integ)
            result = { ok: true, key: key }
        else
            result = { ok: false, error: L("La clave no es válida.") }
        end if
    else if mode = "srvSignIn"
        result = Srv_SignIn(Str_Of(p.kind), Str_Of(p.address), Str_Of(p.user), Str_Of(p.pass))
    else if mode = "srvRefresh"
        Srv_Refresh(Str_Of(p.id))
        result = { ok: true }
    else if mode = "verifyPin"
        result = Nuvio_VerifyPin(ToInt(p.remote, 0), Str_Of(p.pin))
    else if mode = "nuvioPush"
        result = Nuvio_Push()
    else if mode = "nuvioServer"
        result = Nuvio_Discover(Str_Of(p.url))
    end if
    result.mode = mode
    m.top.result = result
end sub
