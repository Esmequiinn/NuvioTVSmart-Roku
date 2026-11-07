function Deb_Providers() as object
    return [{ id: "torbox", name: "TorBox", short: "TB" }, { id: "premiumize", name: "Premiumize", short: "PM" }]
end function

function Deb_Key(integ as object, id as string) as string
    if id = "torbox" then return Str_Of(integ.torboxKey).Trim()
    if id = "premiumize" then return Str_Of(integ.premiumizeKey).Trim()
    return ""
end function

function Deb_Name(id as string) as string
    for each p in Deb_Providers()
        if p.id = id then return p.name
    end for
    return id
end function

function Deb_Connected(integ as object) as object
    out = []
    for each p in Deb_Providers()
        key = Deb_Key(integ, p.id)
        if key <> "" then out.Push({ id: p.id, name: p.name, short: p.short, key: key })
    end for
    return out
end function

function Deb_Active(integ as object) as dynamic
    if not Bool_Of(integ.debridOn, false) then return invalid
    list = Deb_Connected(integ)
    if list.Count() = 0 then return invalid
    pick = Str_Of(integ.debridPick)
    for each x in list
        if x.id = pick then return x
    end for
    return list[0]
end function

function Deb_Auth(acc as object) as object
    return { Authorization: "Bearer " + acc.key }
end function

function Deb_PmUrl(acc as object, path as string) as string
    return "https://www.premiumize.me" + path + "?apikey=" + acc.key.EncodeUriComponent()
end function

function Deb_Form(fields as object) as string
    parts = []
    for each pair in fields
        parts.Push(pair[0].EncodeUriComponent() + "=" + Str_Of(pair[1]).EncodeUriComponent())
    end for
    return parts.Join("&")
end function

function Deb_Magnet(hash as string, sources as dynamic, filename as string) as string
    out = "magnet:?xt=urn:btih:" + hash
    if type(sources) = "roArray"
        for each src in sources
            v = Str_Of(src).Trim()
            if v <> "" and LCase(Left(v, 4)) <> "dht:"
                if LCase(Left(v, 8)) = "tracker:" then v = Mid(v, 9).Trim()
                if v <> "" then out = out + "&tr=" + v.EncodeUriComponent()
            end if
        end for
    end if
    return out
end function

function Deb_CheckCached(acc as object, hashes as object) as dynamic
    clean = []
    seen = {}
    for each h in hashes
        v = LCase(Str_Of(h).Trim())
        if v <> "" and not seen.DoesExist(v)
            seen[v] = true
            clean.Push(v)
        end if
    end for
    found = {}
    if clean.Count() = 0 then return found
    ok = false
    i = 0
    while i < clean.Count()
        chunk = []
        while i < clean.Count() and chunk.Count() < 100
            chunk.Push(clean[i])
            i = i + 1
        end while
        if acc.id = "torbox"
            headers = Deb_Auth(acc)
            headers["Content-Type"] = "application/json"
            r = Http_Request("POST", "https://api.torbox.app/v1/api/torrents/checkcached?format=object&list_files=false", headers, FormatJson({ hashes: chunk }), 15000)
            if r.code >= 200 and r.code < 300 and type(r.json) = "roAssociativeArray"
                ok = true
                data = r.json.data
                if type(data) = "roAssociativeArray"
                    for each k in data
                        item = data[k]
                        name = ""
                        size = 0
                        if type(item) = "roAssociativeArray"
                            name = Str_Of(item.name)
                            size = item.size
                        end if
                        found[LCase(k)] = { name: name, size: size }
                    end for
                end if
            end if
        else if acc.id = "premiumize"
            fields = []
            for each h in chunk
                fields.Push(["items[]", "magnet:?xt=urn:btih:" + h])
            end for
            headers = Deb_Auth(acc)
            headers["Content-Type"] = "application/x-www-form-urlencoded"
            r = Http_Request("POST", Deb_PmUrl(acc, "/api/cache/check"), headers, Deb_Form(fields), 15000)
            j = r.json
            if r.code >= 200 and r.code < 300 and type(j) = "roAssociativeArray" and LCase(Str_Of(j.status)) <> "error"
                ok = true
                if type(j.response) = "roArray"
                    for n = 0 to j.response.Count() - 1
                        if j.response[n] = true and n < chunk.Count()
                            name = ""
                            if type(j.filename) = "roArray" and n < j.filename.Count() then name = Str_Of(j.filename[n])
                            size = 0
                            if type(j.filesize) = "roArray" and n < j.filesize.Count() then size = j.filesize[n]
                            found[chunk[n]] = { name: name, size: size }
                        end if
                    end for
                end if
            end if
        end if
    end while
    if not ok then return invalid
    return found
end function

function Deb_IsVideo(name as string) as boolean
    low = LCase(name)
    for each ext in [".mp4", ".mkv", ".webm", ".avi", ".mov", ".m4v", ".ts", ".m2ts", ".wmv", ".flv"]
        if Right(low, Len(ext)) = ext then return true
    end for
    return false
end function

function Deb_Base(path as string) as string
    p = path.Replace("\", "/")
    parts = p.Split("/")
    return parts[parts.Count() - 1]
end function

function Deb_Pick(files as object, d as object) as dynamic
    playable = []
    for each f in files
        if f.video then playable.Push(f)
    end for
    if playable.Count() = 0 then return invalid
    name = LCase(Deb_Base(Str_Of(d.file)))
    if name <> ""
        for each f in playable
            if LCase(Deb_Base(f.path)) = name then return f
        end for
    end if
    s = ToInt(d.s, -1)
    e = ToInt(d.e, -1)
    if s >= 0 and e > 0
        rx = CreateObject("roRegex", "(^|[^a-z0-9])(s0*" + s.ToStr() + "e0*" + e.ToStr() + "|0*" + s.ToStr() + "x0*" + e.ToStr() + ")([^0-9]|$)", "i")
        hits = []
        for each f in playable
            if rx.IsMatch(Deb_Base(f.path)) then hits.Push(f)
        end for
        if hits.Count() = 1 then return hits[0]
        if hits.Count() > 1
            best = hits[0]
            for each f in hits
                if f.size > best.size then best = f
            end for
            return best
        end if
        if name <> "" then return invalid
    end if
    idx = ToInt(d.idx, -1)
    if idx >= 0 and idx < files.Count() and files[idx].video then return files[idx]
    best = playable[0]
    for each f in playable
        if f.size > best.size then best = f
    end for
    return best
end function

function Deb_Num(v as dynamic) as double
    if v = invalid then return 0
    return Val(Str_Any(v))
end function

function Deb_Resolve(integ as object, d as object) as object
    acc = invalid
    for each x in Deb_Connected(integ)
        if x.id = Str_Of(d.provider) then acc = x
    end for
    if acc = invalid then acc = Deb_Active(integ)
    if acc = invalid then return { ok: false, error: L("Conecta tu cuenta de TorBox o Premiumize en Ajustes.") }
    magnet = Deb_Magnet(Str_Of(d.hash), d.sources, Str_Of(d.file))
    if acc.id = "torbox" then return Deb_TorboxResolve(acc, magnet, d)
    return Deb_PmResolve(acc, magnet, d)
end function

function Deb_TorboxResolve(acc as object, magnet as string, d as object) as object
    boundary = "----NuvioRoku" + CreateObject("roDateTime").AsSeconds().ToStr()
    crlf = chr(13) + chr(10)
    body = ""
    for each pair in [["magnet", magnet], ["add_only_if_cached", "true"], ["allow_zip", "false"]]
        body = body + "--" + boundary + crlf + "Content-Disposition: form-data; name=" + chr(34) + pair[0] + chr(34) + crlf + "Content-Type: text/plain; charset=utf-8" + crlf + crlf + pair[1] + crlf
    end for
    body = body + "--" + boundary + "--" + crlf
    headers = Deb_Auth(acc)
    headers["Content-Type"] = "multipart/form-data; boundary=" + boundary
    r = Http_Request("POST", "https://api.torbox.app/v1/api/torrents/createtorrent", headers, body, 20000)
    if r.code = 409 then return { ok: false, error: L("Este torrent ya no está en la caché de TorBox.") }
    if r.code = 401 or r.code = 403 then return Deb_TorboxFail(r, 1, L("TorBox no aceptó tu cuenta. Vuelve a vincularla en Ajustes."))
    if type(r.json) <> "roAssociativeArray" or r.json.success = false or type(r.json.data) <> "roAssociativeArray" then return Deb_TorboxFail(r, 1, "")
    tid = Deb_RawId(Str_Of(r.body), "torrent_id")
    if tid = "" then tid = Deb_TorboxId(r.json.data.torrent_id)
    if tid = "" then tid = Deb_TorboxId(r.json.data.id)
    hash = LCase(Str_Of(r.json.data.hash))
    if hash = "" then hash = LCase(Str_Of(d.hash))
    if tid = "" and hash = "" then return Deb_TorboxFail(r, 1, "")
    item = invalid
    t = { code: 0, body: "", json: invalid }
    for tries = 1 to 3
        if tid <> ""
            t = Http_Request("GET", "https://api.torbox.app/v1/api/torrents/mylist?id=" + tid + "&bypass_cache=true", Deb_Auth(acc), invalid, 15000)
            if type(t.json) = "roAssociativeArray" and type(t.json.data) = "roAssociativeArray" then item = t.json.data
        end if
        if item = invalid
            t = Http_Request("GET", "https://api.torbox.app/v1/api/torrents/mylist?bypass_cache=true", Deb_Auth(acc), invalid, 20000)
            item = Deb_TorboxFind(t.json, tid, hash)
            if item <> invalid and tid = "" and hash <> "" then tid = Deb_RawIdNear(Str_Of(t.body), hash)
        end if
        if item <> invalid and type(item.files) = "roArray" and item.files.Count() > 0 then exit for
        item = invalid
        sleep(800)
    end for
    if item = invalid then return Deb_TorboxFail(t, 2, "")
    if tid = "" then tid = Deb_TorboxId(item.id)
    if tid = "" then tid = Deb_TorboxId(item.torrent_id)
    if tid = ""
        raw = "id=" + type(item.id) + ":" + Left(Deb_Raw(item.id), 24) + " torrent_id=" + type(r.json.data.torrent_id) + ":" + Left(Deb_Raw(r.json.data.torrent_id), 24)
        return { ok: false, error: L("TorBox no pudo preparar este enlace.") + chr(10) + "(" + L("paso") + " 3 · " + raw + ")" }
    end if
    files = []
    for each f in item.files
        if type(f) = "roAssociativeArray"
            path = Str_Of(f.name)
            if path = "" then path = Str_Of(f.absolute_path)
            if path = "" then path = Str_Of(f.short_name)
            video = Left(LCase(Str_Of(f.mimetype)), 6) = "video/" or Deb_IsVideo(path)
            fid = Deb_TorboxId(f.id)
            if fid = "" then fid = Str_Any(f.id)
            files.Push({ id: fid, path: path, size: Deb_Num(f.size), video: video })
        end if
    end for
    pick = Deb_Pick(files, d)
    if pick = invalid or pick.id = "" then return { ok: false, error: L("TorBox no encontró el video de este episodio dentro del torrent.") }
    dl = Http_Request("GET", "https://api.torbox.app/v1/api/torrents/requestdl?token=" + acc.key.EncodeUriComponent() + "&torrent_id=" + tid + "&file_id=" + pick.id + "&zip_link=false&redirect=false&append_name=false", Deb_Auth(acc), invalid, 15000)
    url = ""
    if type(dl.json) = "roAssociativeArray" then url = Str_Of(dl.json.data)
    if LCase(Left(url, 4)) <> "http" then return Deb_TorboxFail(dl, 3, "")
    return { ok: true, url: url, file: Deb_Base(pick.path) }
end function

function Deb_TorboxFail(r as object, stage as integer, text as string) as object
    msg = text
    if msg = ""
        msg = L("TorBox no pudo preparar este enlace.")
        detail = ""
        if type(r.json) = "roAssociativeArray"
            if type(r.json.detail) = "roArray" and r.json.detail.Count() > 0 and type(r.json.detail[0]) = "roAssociativeArray"
                x = r.json.detail[0]
                where = ""
                if type(x.loc) = "roArray" then where = Str_Any(x.loc[x.loc.Count() - 1]) + ": "
                detail = where + Str_Of(x.msg)
            else
                detail = Str_Of(r.json.detail)
            end if
            if detail = "" then detail = Str_Of(r.json.error)
        end if
        if detail <> "" then msg = msg + chr(10) + "TorBox: " + Left(detail, 160)
    end if
    msg = msg + chr(10) + "(" + L("paso") + " " + stage.ToStr() + " · " + r.code.ToStr() + ")"
    return { ok: false, error: msg }
end function

function Deb_PmResolve(acc as object, magnet as string, d as object) as object
    fail = { ok: false, error: L("Premiumize no pudo preparar este enlace.") }
    headers = Deb_Auth(acc)
    headers["Content-Type"] = "application/x-www-form-urlencoded"
    r = Http_Request("POST", Deb_PmUrl(acc, "/api/transfer/directdl"), headers, Deb_Form([["src", magnet]]), 20000)
    j = r.json
    if type(j) <> "roAssociativeArray" then return fail
    if LCase(Str_Of(j.status)) = "error" then return { ok: false, error: L("Este torrent ya no está en la caché de Premiumize.") }
    if type(j.content) <> "roArray" then return fail
    files = []
    for each f in j.content
        if type(f) = "roAssociativeArray"
            link = Str_Of(f.link)
            path = Str_Of(f.path)
            files.Push({ id: link, path: path, size: Deb_Num(f.size), video: link <> "" and Deb_IsVideo(path) })
        end if
    end for
    pick = Deb_Pick(files, d)
    if pick = invalid or LCase(Left(pick.id, 4)) <> "http" then return fail
    return { ok: true, url: pick.id, file: Deb_Base(pick.path) }
end function

function Deb_TorboxStart() as object
    r = Http_Request("GET", "https://api.torbox.app/v1/api/user/auth/device/start?app=Nuvio", {}, invalid, 15000)
    d = invalid
    if type(r.json) = "roAssociativeArray" then d = r.json.data
    if type(d) <> "roAssociativeArray" or Str_Of(d.device_code) = "" then return { ok: false, error: L("TorBox respondió con error ") + r.code.ToStr() + "." }
    url = Str_Of(d.verification_url)
    qr = Str_Of(d.friendly_verification_url)
    if qr = "" then qr = url
    return { ok: true, deviceCode: Str_Of(d.device_code), userCode: Str_Of(d.code), url: url, qr: qr, interval: ToInt(d.interval, 5), expires: 600 }
end function

function Deb_TorboxPoll(deviceCode as string) as object
    r = Http_Request("POST", "https://api.torbox.app/v1/api/user/auth/device/token", { "Content-Type": "application/json" }, FormatJson({ device_code: deviceCode }), 15000)
    token = ""
    if type(r.json) = "roAssociativeArray" and type(r.json.data) = "roAssociativeArray" then token = Str_Of(r.json.data.access_token)
    if token <> ""
        integ = St_Integrations()
        integ["torboxKey"] = token
        integ["torboxFrom"] = ""
        integ["debridOn"] = true
        St_SaveIntegrations(integ)
        return { ok: true, status: "approved" }
    end if
    text = ""
    if type(r.json) = "roAssociativeArray" then text = LCase(Str_Of(r.json.error) + " " + Str_Of(r.json.detail))
    if Instr(1, text, "expire") > 0 or Instr(1, text, "denied") > 0 then return { ok: false, status: "failed", error: L("El código expiró o fue rechazado.") }
    return { ok: true, status: "pending" }
end function

function Deb_Validate(id as string, key as string) as boolean
    acc = { id: id, key: key }
    if id = "torbox"
        r = Http_Request("GET", "https://api.torbox.app/v1/api/user/me", Deb_Auth(acc), invalid, 12000)
        return r.code >= 200 and r.code < 300
    end if
    r = Http_Request("GET", Deb_PmUrl(acc, "/api/account/info"), Deb_Auth(acc), invalid, 12000)
    return r.code >= 200 and r.code < 300 and type(r.json) = "roAssociativeArray" and LCase(Str_Of(r.json.status)) <> "error"
end function

function Deb_TorboxId(v as dynamic) as string
    if v = invalid then return ""
    text = ""
    if IsStr(v)
        text = v
    else if GetInterface(v, "ifToStr") <> invalid
        text = v.ToStr()
    end if
    found = CreateObject("roRegex", "^\s*([0-9]+)(\.0*)?\s*$", "").Match(text)
    if found.Count() > 1 then return found[1]
    return ""
end function

function Deb_TorboxFind(j as dynamic, tid as string, hash as string) as dynamic
    if type(j) <> "roAssociativeArray" or type(j.data) <> "roArray" then return invalid
    for each it in j.data
        if type(it) = "roAssociativeArray"
            if tid <> "" and Deb_TorboxId(it.id) = tid then return it
            if hash <> "" and LCase(Str_Of(it.hash)) = hash then return it
        end if
    end for
    return invalid
end function

function Deb_Raw(v as dynamic) as string
    if v = invalid then return "invalid"
    if IsStr(v) then return v
    if GetInterface(v, "ifToStr") <> invalid then return v.ToStr()
    return FormatJson(v)
end function

function Deb_RawId(body as string, field as string) as string
    found = CreateObject("roRegex", chr(34) + field + chr(34) + "\s*:\s*" + chr(34) + "?([0-9]+)", "").Match(body)
    if found.Count() > 1 then return found[1]
    return ""
end function

function Deb_RawIdNear(body as string, hash as string) as string
    low = LCase(body)
    at = Instr(1, low, chr(34) + hash + chr(34))
    if at = 0 then return ""
    start = at - 4000
    if start < 1 then start = 1
    before = Mid(body, start, at - start)
    matches = CreateObject("roRegex", chr(34) + "id" + chr(34) + "\s*:\s*" + chr(34) + "?([0-9]+)", "").MatchAll(before)
    if matches.Count() > 0 then return matches[matches.Count() - 1][1]
    return ""
end function
