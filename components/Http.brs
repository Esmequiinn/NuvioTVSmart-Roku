function Http_Transfer(url as string, port as object) as object
    t = CreateObject("roUrlTransfer")
    t.SetUrl(url)
    t.SetPort(port)
    t.EnableEncodings(true)
    t.RetainBodyOnError(true)
    t.AddHeader("Accept", "application/json")
    t.AddHeader("User-Agent", "Mozilla/5.0 (Roku) NuvioTV/1.0")
    if LCase(Left(url, 6)) = "https:"
        t.SetCertificatesFile("common:/certs/ca-bundle.crt")
        t.InitClientCertificates()
    end if
    return t
end function

function Http_FetchJsonAll(urls as object, timeoutMs as integer) as object
    return Http_Fetch(urls, timeoutMs, 0).data
end function

function Http_FetchJson(url as string, timeoutMs as integer) as dynamic
    return Http_Fetch([url], timeoutMs, 0).data[0]
end function

function Http_Fetch(urls as object, timeoutMs as integer, metaLimit as integer) as object
    data = []
    diag = []
    for i = 0 to urls.Count() - 1
        data.Push(invalid)
        diag.Push(L("Sin respuesta"))
    end for
    port = CreateObject("roMessagePort")
    active = {}
    nextIndex = 0
    clock = CreateObject("roTimespan")
    while true
        while active.Count() < 4 and nextIndex < urls.Count()
            t = Http_Transfer(urls[nextIndex], port)
            if t.AsyncGetToString()
                active[t.GetIdentity().ToStr()] = { transfer: t, index: nextIndex, started: clock.TotalMilliseconds() }
            else
                diag[nextIndex] = L("No se pudo iniciar la conexión")
            end if
            nextIndex = nextIndex + 1
        end while
        if active.Count() = 0 then exit while
        msg = wait(500, port)
        if type(msg) = "roUrlEvent" and msg.GetInt() = 1
            key = msg.GetSourceIdentity().ToStr()
            job = active[key]
            if job <> invalid
                active.Delete(key)
                code = msg.GetResponseCode()
                if code = 200
                    body = msg.GetString()
                    parsed = invalid
                    if body <> "" then parsed = ParseJson(body)
                    if parsed = invalid
                        diag[job.index] = L("Respuesta no es JSON válido")
                    else
                        if metaLimit > 0 then parsed = Http_TrimMetas(parsed, metaLimit)
                        data[job.index] = parsed
                        diag[job.index] = "ok"
                    end if
                else if code < 0
                    diag[job.index] = L("Error de red: ") + msg.GetFailureReason()
                else
                    diag[job.index] = L("Error HTTP ") + code.ToStr()
                end if
            end if
        end if
        now = clock.TotalMilliseconds()
        for each key in active.Keys()
            if now - active[key].started > timeoutMs
                active[key].transfer.AsyncCancel()
                diag[active[key].index] = L("Tardó demasiado en responder")
                active.Delete(key)
            end if
        end for
    end while
    return { data: data, diag: diag }
end function

function Http_TrimMetas(parsed as dynamic, limit as integer) as dynamic
    if type(parsed) <> "roAssociativeArray" or type(parsed.metas) <> "roArray" then return parsed
    keep = ["id", "imdb_id", "type", "name", "poster", "posterShape", "background", "description", "releaseInfo", "released", "imdbRating", "genres", "logo", "runtime"]
    out = []
    for each meta in parsed.metas
        if out.Count() >= limit then exit for
        if type(meta) = "roAssociativeArray"
            slim = {}
            for each k in keep
                if meta.DoesExist(k) then slim[k] = meta[k]
            end for
            out.Push(slim)
        end if
    end for
    return { metas: out }
end function

function Http_Request(method as string, url as string, headers as object, body as dynamic, timeoutMs as integer) as object
    port = CreateObject("roMessagePort")
    t = Http_Transfer(url, port)
    t.SetRequest(method)
    for each k in headers
        t.AddHeader(k, headers[k])
    end for
    payload = ""
    if body <> invalid
        if IsStr(body)
            payload = body
        else
            payload = FormatJson(body)
        end if
        t.AddHeader("Content-Type", "application/json")
    end if
    started = false
    if method = "GET"
        started = t.AsyncGetToString()
    else
        started = t.AsyncPostFromString(payload)
    end if
    result = { code: 0, body: "", json: invalid }
    if not started then return result
    msg = wait(timeoutMs, port)
    if type(msg) = "roUrlEvent"
        result.code = msg.GetResponseCode()
        result.body = msg.GetString()
        if result.body <> "" then result.json = ParseJson(result.body)
    else
        t.AsyncCancel()
    end if
    return result
end function
