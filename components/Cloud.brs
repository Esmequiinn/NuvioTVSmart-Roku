function Cloud_Providers() as object
    return [{ id: "torbox", name: "TorBox", short: "TB" }, { id: "realdebrid", name: "Real-Debrid", short: "RD" }, { id: "premiumize", name: "Premiumize", short: "PM" }]
end function

function Cloud_Connected(integ as object) as object
    out = []
    for each p in Cloud_Providers()
        key = Deb_Key(integ, p.id)
        if key <> "" then out.Push({ id: p.id, name: p.name, short: p.short, key: key })
    end for
    return out
end function

function Cloud_Account(id as string) as dynamic
    for each acc in Cloud_Connected(St_Integrations())
        if acc.id = id then return acc
    end for
    return invalid
end function

function Cloud_RdGet(acc as object, path as string) as object
    return Http_Request("GET", "https://api.real-debrid.com/rest/1.0" + path, Deb_Auth(acc), invalid, 20000)
end function

function Cloud_TbGet(acc as object, path as string) as object
    return Http_Request("GET", "https://api.torbox.app/v1/api" + path, Deb_Auth(acc), invalid, 20000)
end function

function Cloud_ListAll() as object
    integ = St_Integrations()
    items = []
    errors = []
    providers = []
    for each acc in Cloud_Connected(integ)
        providers.Push({ id: acc.id, name: acc.name })
        list = invalid
        if acc.id = "torbox"
            list = Cloud_TorboxList(acc)
        else if acc.id = "realdebrid"
            list = Cloud_RdList(acc)
        else if acc.id = "premiumize"
            list = Cloud_PmList(acc)
        end if
        if list = invalid
            errors.Push(L("No se pudo leer tu nube de {p}.").Replace("{p}", acc.name))
        else
            for each it in list
                it.provider = acc.id
                items.Push(it)
            end for
        end if
    end for
    if providers.Count() = 0 then return { ok: false, error: L("Conecta tu cuenta en Ajustes → Servicios conectados.") }
    items.SortBy("date", "r")
    return { ok: true, items: items, errors: errors, providers: providers }
end function

function Cloud_TorboxList(acc as object) as dynamic
    out = []
    ok = false
    for each kind in [["torrents", "torrent_id", "torrent"], ["usenet", "usenet_id", "usenet"], ["webdl", "web_id", "web"]]
        r = Cloud_TbGet(acc, "/" + kind[0] + "/mylist?bypass_cache=true")
        if r.code >= 200 and r.code < 300 then ok = true
        data = invalid
        if type(r.json) = "roAssociativeArray" then data = r.json.data
        if type(data) = "roArray"
            for each t in data
                if type(t) = "roAssociativeArray"
                    tid = Deb_TorboxId(t.id)
                    if tid = "" then tid = Deb_RawIdNear(r.body, Str_Of(t.hash))
                    name = Str_Of(t.name)
                    if name = "" then name = tid
                    ready = t.download_finished = true or t.download_present = true
                    files = []
                    if type(t.files) = "roArray"
                        for each f in t.files
                            if type(f) = "roAssociativeArray"
                                fname = Str_Of(f.short_name)
                                if fname = "" then fname = Deb_Base(Str_Of(f.name))
                                if Deb_IsVideo(fname) then files.Push({ id: Deb_TorboxId(f.id), name: fname, size: Deb_Num(f.size) })
                            end if
                        end for
                    end if
                    status = ""
                    if not ready then status = Str_Of(t.download_state)
                    if tid <> "" then out.Push({ id: tid, name: name, size: Deb_Num(t.size), kind: kind[0], param: kind[1], type: kind[2], status: status, files: files, date: Str_Of(t.created_at) })
                end if
            end for
        end if
    end for
    if not ok then return invalid
    return out
end function

function Cloud_RdList(acc as object) as dynamic
    r = Cloud_RdGet(acc, "/torrents?limit=500")
    if r.code = 204 then return []
    if type(r.json) <> "roArray" then return invalid
    out = []
    for each t in r.json
        if type(t) = "roAssociativeArray"
            ready = LCase(Str_Of(t.status)) = "downloaded"
            files = invalid
            status = ""
            if not ready
                files = []
                status = Str_Of(t.status)
            end if
            out.Push({ id: Str_Any(t.id), name: Str_Of(t.filename), size: Deb_Num(t.bytes), kind: "rd", type: "torrent", status: status, files: files, date: Str_Of(t.added) })
        end if
    end for
    return out
end function

function Cloud_RdFiles(acc as object, tid as string) as dynamic
    r = Cloud_RdGet(acc, "/torrents/info/" + tid)
    j = r.json
    if type(j) <> "roAssociativeArray" or type(j.files) <> "roArray" then return invalid
    links = j.links
    if type(links) <> "roArray" then links = []
    out = []
    n = 0
    for each f in j.files
        if type(f) = "roAssociativeArray" and ToInt(f.selected, 0) = 1
            link = ""
            if n < links.Count() then link = Str_Of(links[n])
            n = n + 1
            name = Deb_Base(Str_Of(f.path))
            if link <> "" and Deb_IsVideo(name) then out.Push({ id: link, name: name, size: Deb_Num(f.bytes) })
        end if
    end for
    return out
end function

function Cloud_PmList(acc as object) as dynamic
    r = Http_Request("GET", Deb_PmUrl(acc, "/api/item/listall"), Deb_Auth(acc), invalid, 30000)
    j = r.json
    if type(j) <> "roAssociativeArray" or LCase(Str_Of(j.status)) = "error" then return invalid
    if type(j.files) <> "roArray" then return []
    groups = {}
    order = []
    for each f in j.files
        if type(f) = "roAssociativeArray"
            path = Str_Of(f.path).Replace("\", "/")
            name = Str_Of(f.name)
            if name = "" then name = Deb_Base(path)
            if Deb_IsVideo(name)
                top = name
                parts = path.Split("/")
                clean = []
                for each part in parts
                    if part <> "" then clean.Push(part)
                end for
                if clean.Count() > 1 then top = clean[0]
                if not groups.DoesExist(top)
                    groups[top] = { id: top, name: top, size: 0.0, kind: "pm", type: "files", status: "", files: [], date: Str_Any(f.created_at) }
                    order.Push(top)
                end if
                g = groups[top]
                g.files.Push({ id: Str_Any(f.id), name: name, size: Deb_Num(f.size) })
                g.size = g.size + Deb_Num(f.size)
            end if
        end if
    end for
    out = []
    for each k in order
        out.Push(groups[k])
    end for
    return out
end function

function Cloud_Files(id as string, item as object) as object
    acc = Cloud_Account(id)
    if acc = invalid then return { ok: false, error: L("Conecta tu cuenta en Ajustes → Servicios conectados.") }
    if type(item.files) = "roArray" then return { ok: true, files: item.files }
    files = invalid
    if id = "realdebrid" then files = Cloud_RdFiles(acc, Str_Of(item.id))
    if files = invalid then return { ok: false, error: L("No se pudieron leer los archivos.") }
    return { ok: true, files: files }
end function

function Cloud_Link(id as string, item as object, file as object) as object
    acc = Cloud_Account(id)
    fail = { ok: false, error: L("{p} no pudo preparar este archivo.").Replace("{p}", Deb_Name(id)) }
    if acc = invalid then return { ok: false, error: L("Conecta tu cuenta en Ajustes → Servicios conectados.") }
    url = ""
    if id = "torbox"
        q = "?token=" + acc.key.EncodeUriComponent() + "&" + Str_Of(item.param) + "=" + Str_Of(item.id) + "&file_id=" + Str_Of(file.id) + "&redirect=false"
        r = Cloud_TbGet(acc, "/" + Str_Of(item.kind) + "/requestdl" + q)
        if type(r.json) = "roAssociativeArray" then url = Str_Of(r.json.data)
    else if id = "realdebrid"
        headers = Deb_Auth(acc)
        headers["Content-Type"] = "application/x-www-form-urlencoded"
        r = Http_Request("POST", "https://api.real-debrid.com/rest/1.0/unrestrict/link", headers, Deb_Form([["link", Str_Of(file.id)]]), 20000)
        if type(r.json) = "roAssociativeArray" then url = Str_Of(r.json.download)
    else if id = "premiumize"
        r = Http_Request("GET", Deb_PmUrl(acc, "/api/item/details") + "&id=" + Str_Of(file.id).EncodeUriComponent(), Deb_Auth(acc), invalid, 20000)
        if type(r.json) = "roAssociativeArray"
            url = Str_Of(r.json.stream_link)
            if url = "" then url = Str_Of(r.json.link)
        end if
    end if
    if LCase(Left(url, 4)) <> "http" then return fail
    return { ok: true, url: url, file: Str_Of(file.name) }
end function

function Cloud_Size(bytes as dynamic) as string
    b = Deb_Num(bytes)
    if b <= 0 then return ""
    gb = b / 1073741824.0
    if gb >= 1 then return Str(Int(gb * 10 + 0.5) / 10.0).Trim() + " GB"
    mb = Int(b / 1048576.0 + 0.5)
    if mb < 1 then mb = 1
    return mb.ToStr() + " MB"
end function
