sub init()
    m.top.functionName = "serve"
end sub

sub serve()
    page = "pkg:/web/index-en.html"
    if m.global.uiLang = "es" then page = "pkg:/web/index.html"
    if m.global.uiLang = "pt" then page = "pkg:/web/index-pt.html"
    m.html = ReadAsciiFile(page)
    port = CreateObject("roMessagePort")
    addr = CreateObject("roSocketAddress")
    addr.SetPort(8888)
    listener = CreateObject("roStreamSocket")
    listener.SetMessagePort(port)
    listener.SetAddress(addr)
    listener.NotifyReadable(true)
    if not listener.Listen(8)
        m.top.status = "error"
        return
    end if
    m.top.status = "ready"

    clients = {}
    chunk = CreateObject("roByteArray")
    chunk[8191] = 0
    clock = CreateObject("roTimespan")

    while true
        msg = wait(250, port)
        if type(msg) = "roSocketEvent"
            sid = msg.GetSocketID()
            if sid = listener.GetID()
                if listener.IsReadable()
                    conn = listener.Accept()
                    if conn <> invalid
                        conn.SetMessagePort(port)
                        conn.NotifyReadable(true)
                        clients[Stri(conn.GetID())] = { sock: conn, data: CreateObject("roByteArray"), born: clock.TotalMilliseconds(), answered: false, closeAt: 0 }
                    end if
                end if
            else
                key = Stri(sid)
                client = clients[key]
                if client <> invalid
                    finished = false
                    if client.sock.IsReadable()
                        n = client.sock.Receive(chunk, 0, 8192)
                        if n > 0
                            if not client.answered
                                for i = 0 to n - 1
                                    client.data.Push(chunk[i])
                                end for
                                req = Srv_Parse(client.data.ToAsciiString())
                                if req <> invalid
                                    Srv_SafeRoute(client.sock, req)
                                    client.answered = true
                                    client.closeAt = clock.TotalMilliseconds() + 1500
                                end if
                            end if
                        else if n = 0
                            finished = true
                        else if not client.sock.eAgain()
                            finished = true
                        end if
                    end if
                    if finished
                        client.sock.Close()
                        clients.Delete(key)
                    end if
                end if
            end if
        end if
        now = clock.TotalMilliseconds()
        for each key in clients.Keys()
            client = clients[key]
            if (client.answered and now > client.closeAt) or now - client.born > 120000
                clients[key].sock.Close()
                clients.Delete(key)
            end if
        end for
    end while
end sub

function Srv_Parse(buf as string) as dynamic
    crlf = chr(13) + chr(10)
    headerEnd = Instr(1, buf, crlf + crlf)
    if headerEnd = 0 then return invalid
    head = Left(buf, headerEnd - 1)
    lines = head.Split(crlf)
    first = lines[0].Split(" ")
    if first.Count() < 2 then return { method: "GET", path: "/", body: "" }
    length = 0
    for each line in lines
        if LCase(Left(line, 15)) = "content-length:" then length = Mid(line, 16).Trim().ToInt()
    end for
    body = Mid(buf, headerEnd + 4)
    if Len(body) < length then return invalid
    path = first[1]
    q = Instr(1, path, "?")
    if q > 0 then path = Left(path, q - 1)
    return { method: UCase(first[0]), path: path, body: Left(body, length) }
end function

sub Srv_SafeRoute(sock as object, req as object)
    try
        Srv_Route(sock, req)
    catch e
        text = Str_Of(e.message)
        if type(e.backtrace) = "roArray" and e.backtrace.Count() > 0
            b = e.backtrace[e.backtrace.Count() - 1]
            if type(b) = "roAssociativeArray" then text = text + " (" + Str_Of(b.function) + " " + Str(b.line_number).Trim() + ")"
        end if
        Srv_Send(sock, "200 OK", "application/json; charset=utf-8", FormatJson({ ok: false, error: L("Error en el Roku: ") + text }))
    end try
end sub

sub Srv_Route(sock as object, req as object)
    jsonType = "application/json; charset=utf-8"
    if req.method = "GET" and (req.path = "/" or req.path = "/index.html")
        Srv_Send(sock, "200 OK", "text/html; charset=utf-8", m.html)
    else if req.method = "GET" and req.path = "/api/state"
        Srv_Send(sock, "200 OK", jsonType, Srv_Json(Srv_State()))
    else if req.method = "POST" and req.path = "/api/action"
        body = ParseJson(req.body)
        rid = ""
        if type(body) = "roAssociativeArray" then rid = Str_Of(body.rid)
        if rid <> "" and rid = Str_Of(m.lastRid) and m.lastReply <> invalid
            Srv_Send(sock, "200 OK", jsonType, m.lastReply)
            return
        end if
        result = Srv_Apply(body)
        result.state = Srv_State()
        reply = Srv_Json(result)
        m.lastRid = rid
        m.lastReply = reply
        Srv_Send(sock, "200 OK", jsonType, reply)
        if result.reload then m.top.changed = result.what
    else if req.method = "GET" and req.path = "/favicon.ico"
        Srv_Send(sock, "204 No Content", "text/plain", "")
    else
        Srv_Send(sock, "404 Not Found", "text/plain", L("No encontrado"))
    end if
end sub

sub Srv_Send(sock as object, status as string, contentType as string, body as string)
    crlf = chr(13) + chr(10)
    payload = CreateObject("roByteArray")
    payload.FromAsciiString(body)
    head = "HTTP/1.1 " + status + crlf
    head = head + "Content-Type: " + contentType + crlf
    head = head + "Content-Length: " + payload.Count().ToStr() + crlf
    head = head + "Cache-Control: no-store" + crlf
    head = head + "Connection: close" + crlf + crlf
    headBytes = CreateObject("roByteArray")
    headBytes.FromAsciiString(head)
    Srv_Write(sock, headBytes)
    if payload.Count() > 0 then Srv_Write(sock, payload)
end sub

sub Srv_Write(sock as object, data as object)
    total = data.Count()
    sent = 0
    idle = 0
    while sent < total and idle < 400
        n = sock.Send(data, sent, total - sent)
        if n > 0
            sent = sent + n
            idle = 0
        else
            idle = idle + 1
            sleep(10)
        end if
    end while
end sub

function Srv_State() as object
    prefs = St_Prefs()
    settings = St_Settings()
    names = m.top.addonNames
    if names = invalid then names = {}
    addons = []
    for each url in St_Addons()
        name = ""
        if IsStr(names[url]) then name = names[url]
        addons.Push({ url: url, name: name })
    end for
    cats = []
    source = m.top.catalogs
    if type(source) = "roArray"
        for each c in source
            cats.Push({ key: c.key, name: c.name, kind: TypePlural(c.kind), addon: c.addon, hidden: prefs.hidden.DoesExist(c.key), status: Str_Of(c.status), count: ToInt(c.count, 0) })
        end for
    end if
    return {
        profiles: St_Profiles()
        active: St_ActiveProfile().id
        shared: settings.shared
        addons: addons
        catalogs: cats
        colors: St_Colors()
        rowSizes: St_RowSizes()
        prefs: { accent: prefs.accent, rowSize: prefs.rowSize, continueWatching: prefs.continueWatching, captions: prefs.captions, autoplayRegex: Str_Of(St_Pref("autoplayRegex")), autoplayMode: Str_Of(St_Pref("autoplayMode")), customPoster: Str_Of(St_Pref("customPoster")), badges: St_Badges(St_ActiveProfile().id).Count() }
        presets: Autoplay_Presets()
        history: St_Progress().Count()
        integrations: Srv_Integrations()
    }
end function

function Srv_Apply(body as dynamic) as object
    res = { ok: true, error: "", message: "", reload: true, what: "data" }
    if type(body) <> "roAssociativeArray" or not IsStr(body.action)
        return Srv_Fail(res, L("Solicitud no válida."))
    end if
    act = body.action

    if act = "addAddon"
        if not St_AddAddon(body.url) then return Srv_Fail(res, L("La dirección no es válida o ese addon ya está agregado."))
        res.message = L("Addon agregado. El Roku está recargando los catálogos.")
    else if act = "removeAddon"
        if not St_RemoveAddon(ToInt(body.index, -1)) then return Srv_Fail(res, L("No se encontró ese addon."))
        res.message = L("Addon eliminado.")
    else if act = "moveAddon"
        St_MoveAddon(ToInt(body.index, -1), ToInt(body.delta, 0))
    else if act = "importCollection"
        added = Col_Import(Str_Of(body.source))
        if added = 0 then return Srv_Fail(res, L("No se encontraron addons nuevos en esa colección."))
        res.message = L("Se agregaron ") + added.ToStr() + " addons."
        if added = 1 then res.message = L("Se agregó 1 addon.")
    else if act = "setCatalogHidden"
        cats = m.top.catalogs
        if type(cats) <> "roArray" then cats = []
        St_SetCatalogHidden(cats, Str_Of(body.key), Bool_Of(body.hidden, false))
        m.top.catalogs = cats
    else if act = "moveCatalog"
        cats = m.top.catalogs
        if type(cats) <> "roArray" then cats = []
        St_MoveCatalog(cats, Str_Of(body.key), ToInt(body.delta, 0))
        m.top.catalogs = cats
    else if act = "addProfile"
        if St_AddProfile(Str_Of(body.name)) = invalid then return Srv_Fail(res, L("Escribe un nombre (máximo 8 perfiles)."))
        res.message = L("Perfil creado.")
        res.what = "profiles"
    else if act = "renameProfile"
        if not St_RenameProfile(Str_Of(body.id), Str_Of(body.name)) then return Srv_Fail(res, L("No se pudo cambiar el nombre."))
        res.what = "profiles"
    else if act = "deleteProfile"
        if not St_DeleteProfile(Str_Of(body.id)) then return Srv_Fail(res, L("Debe quedar al menos un perfil."))
        res.message = L("Perfil eliminado.")
    else if act = "useProfile"
        if not St_SetActiveProfile(Str_Of(body.id)) then return Srv_Fail(res, L("No se encontró ese perfil."))
        res.message = L("Perfil cambiado en el Roku.")
    else if act = "setShared"
        St_SetShared(Bool_Of(body.value, true))
    else if act = "setAccent"
        if not St_SetAccent(Str_Of(body.hex)) then return Srv_Fail(res, L("Color no válido."))
        res.what = "theme"
    else if act = "setRowSize"
        if not St_SetRowSize(ToInt(body.value, 40)) then return Srv_Fail(res, L("Cantidad no válida."))
    else if act = "setContinueWatching"
        St_SetFlag("continueWatching", Bool_Of(body.value, false))
    else if act = "setCaptions"
        St_SetFlag("captions", Bool_Of(body.value, false))
        res.what = "theme"
    else if act = "clearHistory"
        St_ClearProgress()
        res.message = L("Historial borrado.")
    else if act = "search"
        query = Str_Of(body.query).Trim()
        if query = "" then return Srv_Fail(res, L("Escribe qué quieres buscar."))
        m.top.searchQuery = query
        res.what = "search"
        res.message = L("Buscando en la tele...")
    else if act = "setIntegration"
        name = Str_Of(body.name)
        allowed = { tmdbKey: true, mdbKey: true }
        if not allowed.DoesExist(name) then return Srv_Fail(res, L("Ajuste no válido."))
        value = Str_Of(body.value).Trim()
        integ = St_Integrations()
        integ[name] = value
        if name = "tmdbKey" then integ.tmdbEnabled = value <> ""
        if name = "mdbKey"
            integ["mdbEnabled"] = value <> "" or Str_Of(integ.mdbRefresh) <> "" or Str_Of(integ.mdbAccess) <> ""
            integ["mdbFrom"] = "tv"
        end if
        St_SaveIntegrations(integ)
        res.message = L("Guardado.")
        res.what = "theme"
    else if act = "nuvioServer"
        url = Str_Of(body.url).Trim()
        key = Str_Of(body.key).Trim()
        if key <> ""
            integ = St_Integrations()
            integ.nuvioUrl = St_NormalizeUrl(url)
            integ.nuvioKey = key
            integ.nuvioAccess = ""
            integ.nuvioRefresh = ""
            St_SaveIntegrations(integ)
        else
            found = Nuvio_Discover(url)
            if not found.ok then return Srv_Fail(res, found.error)
        end if
        res.message = L("Servidor guardado. Ahora inicia sesión.")
        res.what = "theme"
    else if act = "setPref"
        name = Str_Of(body.name)
        value = Str_Of(body.value).Trim()
        if name = "autoplayRegex"
            if value <> "" and CreateObject("roRegex", value, "i") = invalid then return Srv_Fail(res, L("El patrón regex no es válido."))
            St_SetPref("autoplayRegex", value)
            if value <> "" then St_SetPref("autoplayMode", "regex")
        else if name = "autoplayMode"
            if value <> "manual" and value <> "first" and value <> "regex" then return Srv_Fail(res, L("Modo no válido."))
            St_SetPref("autoplayMode", value)
        else if name = "customPoster"
            St_SetPref("customPoster", value)
        else
            return Srv_Fail(res, L("Ajuste no válido."))
        end if
        res.message = L("Guardado.")
        res.what = "theme"
        if name = "customPoster" then res.what = "data"
    else if act = "importBadges"
        source = Str_Of(body.source).Trim()
        if source = "" then return Srv_Fail(res, L("Pega la dirección o el JSON de los badges."))
        raw = source
        if LCase(Left(source, 4)) = "http"
            r = Http_Request("GET", source, {}, invalid, 20000)
            if r.code <> 200 then return Srv_Fail(res, L("No se pudo descargar (") + r.code.ToStr() + ").")
            raw = r.body
        end if
        rules = Badge_Compact(raw)
        if rules.Count() = 0 then return Srv_Fail(res, L("No se encontraron badges válidos en ese JSON."))
        St_SaveBadges(St_ActiveProfile().id, rules)
        res.message = rules.Count().ToStr() + L(" badges importados.")
        res.what = "theme"
    else if act = "clearBadges"
        St_ClearBadges(St_ActiveProfile().id)
        res.message = L("Badges eliminados.")
        res.what = "theme"
    else if act = "nuvioOfficial"
        integ = St_Integrations()
        integ.nuvioUrl = Config_NuvioServer()
        integ.nuvioKey = ""
        integ.nuvioAccess = ""
        integ.nuvioRefresh = ""
        integ.nuvioEmail = ""
        St_SaveIntegrations(integ)
        res.message = L("Usando el servidor oficial de Nuvio.")
        res.what = "theme"
    else if act = "nuvioLogin"
        login = Nuvio_EmailLogin(Str_Of(body.email).Trim(), Str_Of(body.password))
        if not login.ok then return Srv_Fail(res, login.error)
        res.message = L("Sesión iniciada. El Roku está sincronizando tu cuenta.")
        res.what = "nuvioLogin"
    else if act = "nuvioLogout"
        integ = St_Integrations()
        integ.nuvioAccess = ""
        integ.nuvioRefresh = ""
        integ.nuvioEmail = ""
        St_SaveIntegrations(integ)
        res.what = "theme"
    else if act = "reload"
        res.message = L("Recargando catálogos en el Roku.")
    else
        return Srv_Fail(res, L("Acción desconocida."))
    end if
    return res
end function

function Srv_Fail(res as object, text as string) as object
    res.ok = false
    res.error = text
    res.reload = false
    return res
end function

function Srv_Integrations() as object
    integ = St_Integrations()
    return {
        tmdbKey: Srv_Mask(integ.tmdbKey)
        mdbKey: Srv_Mask(integ.mdbKey)
        traktClientId: Srv_Mask(integ.traktClientId)
        traktSecret: Srv_Mask(integ.traktSecret)
        simklClientId: Srv_Mask(integ.simklClientId)
        nuvioUrl: integ.nuvioUrl
        nuvioConfigured: integ.nuvioUrl <> ""
        nuvioOfficial: integ.nuvioUrl <> "" and integ.nuvioUrl = Config_NuvioServer()
        nuvioEmail: integ.nuvioEmail
        nuvioLogged: integ.nuvioAccess <> ""
        traktUser: integ.traktUser
        traktConnected: integ.traktToken <> ""
        simklConnected: integ.simklToken <> ""
    }
end function

function Srv_Mask(value as string) as string
    if value = "" then return ""
    if Len(value) <= 6 then return "••••"
    return Left(value, 3) + "••••" + Right(value, 3)
end function

function Srv_Json(v as object) as string
    out = FormatJson(Srv_Clean(v, 0))
    if out = invalid or out = "" then out = FormatJson({ ok: false, error: L("Error en el Roku: ") + "json" })
    return out
end function

function Srv_Clean(v as dynamic, depth as integer) as dynamic
    if v = invalid then return invalid
    if depth > 12 then return invalid
    t = type(v)
    if t = "roAssociativeArray"
        out = {}
        for each k in v
            c = Srv_Clean(v[k], depth + 1)
            if c <> invalid or v[k] = invalid then out[k] = c
        end for
        return out
    end if
    if t = "roArray" or t = "roList"
        out = []
        for each item in v
            c = Srv_Clean(item, depth + 1)
            if c <> invalid then out.Push(c)
        end for
        return out
    end if
    if IsStr(v)
        text = "" + v
        clean = CreateObject("roRegex", "[\x00-\x08\x0B\x0C\x0E-\x1F]", "")
        return clean.ReplaceAll(text, "")
    end if
    if IsBool(v) then return v
    if GetInterface(v, "ifInt") <> invalid then return v
    if GetInterface(v, "ifLongInt") <> invalid then return CDbl(v)
    if GetInterface(v, "ifFloat") <> invalid or GetInterface(v, "ifDouble") <> invalid then return v
    return invalid
end function
