function Mdb_Ready(integ as object) as boolean
    return Str_Of(integ.mdbKey) <> "" or Str_Of(integ.mdbRefresh) <> "" or Str_Of(integ.mdbAccess) <> ""
end function

function Mdb_Now() as integer
    return CreateObject("roDateTime").AsSeconds()
end function

function Mdb_Form(fields as object) as string
    parts = []
    for each k in fields
        parts.Push(k + "=" + Str_Of(fields[k]).EncodeUriComponent())
    end for
    return parts.Join("&")
end function

function Mdb_Post(path as string, fields as object) as object
    headers = { "Content-Type": "application/x-www-form-urlencoded" }
    return Http_Request("POST", "https://api.mdblist.com" + path, headers, Mdb_Form(fields), 15000)
end function

sub Mdb_SaveTokens(integ as object, json as object)
    fresh = St_Integrations()
    refresh = Str_Of(json.refresh_token)
    if refresh = "" then refresh = Str_Of(integ.mdbRefresh)
    expires = Mdb_Now() + ToInt(json.expires_in, 3600)
    for each target in [integ, fresh]
        target["mdbAccess"] = Str_Of(json.access_token)
        target["mdbRefresh"] = refresh
        target["mdbExpires"] = expires
    end for
    St_SaveIntegrations(fresh)
end sub

sub Mdb_ClearTokens(integ as object)
    fresh = St_Integrations()
    for each target in [integ, fresh]
        target["mdbAccess"] = ""
        target["mdbRefresh"] = ""
        target["mdbExpires"] = 0
        target["mdbUser"] = ""
        if Str_Of(target.mdbKey) = "" then target["mdbEnabled"] = false
    end for
    St_SaveIntegrations(fresh)
end sub

function Mdb_Token(integ as object) as string
    if Str_Of(integ.mdbAccess) <> "" and ToInt(integ.mdbExpires, 0) - Mdb_Now() > 60 then return integ.mdbAccess
    if Str_Of(integ.mdbRefresh) = "" then return Str_Of(integ.mdbAccess)
    r = Mdb_Post("/oauth/token/", { client_id: Config_MdbClientId(), grant_type: "refresh_token", refresh_token: integ.mdbRefresh })
    if r.code >= 200 and r.code < 300 and type(r.json) = "roAssociativeArray" and Str_Of(r.json.access_token) <> ""
        Mdb_SaveTokens(integ, r.json)
        return integ.mdbAccess
    end if
    err = ""
    if type(r.json) = "roAssociativeArray" then err = Str_Of(r.json.error)
    Mdb_Note(integ, L("renovar sesión") + ": HTTP " + r.code.ToStr() + " " + err)
    if err = "invalid_grant" or err = "invalid_token" then Mdb_ClearTokens(integ)
    return ""
end function

function Mdb_Get(path as string, integ as object, timeoutMs as integer, accountPath = "" as string) as object
    key = Str_Of(integ.mdbKey)
    if key <> ""
        url = "https://api.mdblist.com" + path
        sep = "?"
        if Instr(1, url, "?") > 0 then sep = "&"
        return Http_Request("GET", url + sep + "apikey=" + key, {}, invalid, timeoutMs)
    end if
    if accountPath <> "" then path = accountPath
    url = "https://api.mdblist.com" + path
    token = Mdb_Token(integ)
    if token = ""
        Mdb_Note(integ, L("sin sesión"))
        return { code: 0, body: "", json: invalid }
    end if
    r = Http_Request("GET", url, { Authorization: "Bearer " + token }, invalid, timeoutMs)
    if r.code = 401
        integ["mdbExpires"] = 0
        token = Mdb_Token(integ)
        if token <> "" then r = Http_Request("GET", url, { Authorization: "Bearer " + token }, invalid, timeoutMs)
    end if
    Mdb_Note(integ, "HTTP " + r.code.ToStr())
    return r
end function

sub Mdb_Note(integ as object, text as string)
    if Str_Of(integ.mdbLast) = text then return
    integ["mdbLast"] = text
    fresh = St_Integrations()
    fresh["mdbLast"] = text
    St_SaveIntegrations(fresh)
end sub

function Mdb_Code() as object
    if Config_MdbClientId() = "" then return { ok: false, error: L("MDBList no está disponible en esta versión del canal.") }
    r = Mdb_Post("/oauth/device-authorization/", { client_id: Config_MdbClientId(), scope: "write" })
    if r.code < 200 or r.code >= 300 or type(r.json) <> "roAssociativeArray" then return { ok: false, error: L("MDBList respondió con error ") + r.code.ToStr() + "." }
    j = r.json
    code = Str_Of(j.user_code)
    url = Str_Of(j.verification_uri)
    qr = Str_Of(j.verification_uri_complete)
    if qr = "" and url <> ""
        sep = "?"
        if Instr(1, url, "?") > 0 then sep = "&"
        qr = url + sep + "user_code=" + code.EncodeUriComponent()
    end if
    return { ok: true, userCode: code, deviceCode: Str_Of(j.device_code), url: url, qr: qr, interval: ToInt(j.interval, 5), expires: ToInt(j.expires_in, 600) }
end function

function Mdb_Poll(deviceCode as string) as object
    r = Mdb_Post("/oauth/token/", { client_id: Config_MdbClientId(), grant_type: "urn:ietf:params:oauth:grant-type:device_code", device_code: deviceCode, scope: "write" })
    if r.code >= 200 and r.code < 300 and type(r.json) = "roAssociativeArray" and Str_Of(r.json.access_token) <> ""
        integ = St_Integrations()
        Mdb_SaveTokens(integ, r.json)
        name = ""
        me = Mdb_Get("/user", integ, 10000)
        if type(me.json) = "roAssociativeArray"
            name = Str_Of(me.json.username)
            if name = "" then name = Str_Of(me.json.name)
        end if
        fresh = St_Integrations()
        fresh["mdbUser"] = name
        fresh["mdbEnabled"] = true
        St_SaveIntegrations(fresh)
        return { ok: true, status: "approved" }
    end if
    err = ""
    if type(r.json) = "roAssociativeArray" then err = Str_Of(r.json.error)
    if err = "authorization_pending" then return { ok: true, status: "pending" }
    if err = "slow_down" or r.code = 429 then return { ok: true, status: "slow" }
    if r.code = 0 then return { ok: true, status: "pending" }
    if err = "access_denied" then return { ok: false, status: "failed", error: L("Rechazaste el acceso en MDBList.") }
    return { ok: false, status: "failed", error: L("El código expiró o fue rechazado.") }
end function
