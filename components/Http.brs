function Http_Transfer(url as string, port as object, ua = "" as string) as object
    t = CreateObject("roUrlTransfer")
    t.SetUrl(url)
    t.SetPort(port)
    t.EnableEncodings(true)
    t.RetainBodyOnError(true)
    t.AddHeader("Accept", "application/json")
    if ua <> ""
        t.AddHeader("User-Agent", ua)
    else if Instr(1, url, "api.trakt.tv") > 0
        t.AddHeader("User-Agent", "NuvioTV-Roku/" + App_Version())
    else
        t.AddHeader("User-Agent", "Mozilla/5.0 (Roku) NuvioTV/1.0")
    end if
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
    return Http_FetchHook(urls, timeoutMs, metaLimit, 6, invalid)
end function

function Http_FetchHook(urls as object, timeoutMs as integer, metaLimit as integer, concurrency as integer, hook as dynamic) as object
    data = []
    diag = []
    codes = []
    for i = 0 to urls.Count() - 1
        data.Push(invalid)
        diag.Push(L("Sin respuesta"))
        codes.Push(0)
    end for
    port = CreateObject("roMessagePort")
    active = {}
    nextIndex = 0
    clock = CreateObject("roTimespan")
    while true
        while active.Count() < concurrency and nextIndex < urls.Count()
            job = urls[nextIndex]
            if type(job) = "roAssociativeArray"
                t = Http_Transfer(job.url, port)
                if type(job.headers) = "roAssociativeArray"
                    for each k in job.headers
                        t.AddHeader(k, job.headers[k])
                    end for
                end if
            else
                t = Http_Transfer(job, port)
            end if
            if t.AsyncGetToString()
                active[t.GetIdentity().ToStr()] = { transfer: t, index: nextIndex, started: clock.TotalMilliseconds() }
            else
                diag[nextIndex] = L("No se pudo iniciar la conexión")
            end if
            nextIndex = nextIndex + 1
        end while
        if active.Count() = 0 then exit while
        msg = wait(250, port)
        while msg <> invalid
            if type(msg) = "roUrlEvent" and msg.GetInt() = 1
                key = msg.GetSourceIdentity().ToStr()
                job = active[key]
                if job <> invalid
                    active.Delete(key)
                    code = msg.GetResponseCode()
                    codes[job.index] = code
                    if code = 200
                        body = msg.GetString()
                        parsed = invalid
                        if body <> "" then parsed = ParseJson(body)
                        body = invalid
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
                    if hook <> invalid then hook(job.index, data, diag)
                end if
            end if
            msg = port.GetMessage()
        end while
        if hook <> invalid then hook(-1, data, diag)
        now = clock.TotalMilliseconds()
        for each key in active.Keys()
            if now - active[key].started > timeoutMs
                active[key].transfer.AsyncCancel()
                diag[active[key].index] = L("Tardó demasiado en responder")
                index = active[key].index
                active.Delete(key)
                if hook <> invalid then hook(index, data, diag)
            end if
        end for
    end while
    return { data: data, diag: diag, codes: codes }
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
    ua = ""
    if headers.DoesExist("User-Agent") then ua = Str_Of(headers["User-Agent"])
    t = Http_Transfer(url, port, ua)
    t.SetRequest(method)
    for each k in headers
        if k <> "User-Agent" then t.AddHeader(k, headers[k])
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
