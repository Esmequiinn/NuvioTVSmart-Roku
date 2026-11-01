function Srv_Kinds() as object
    return [{ id: "jellyfin", name: "Jellyfin" }, { id: "emby", name: "Emby" }]
end function

function Srv_KindName(kind as string) as string
    if kind = "emby" then return "Emby"
    return "Jellyfin"
end function

function Srv_List() as object
    list = St_Get("servers", invalid)
    out = []
    if type(list) = "roArray"
        for each s in list
            if type(s) = "roAssociativeArray" and Str_Of(s.id) <> "" then out.Push(s)
        end for
    end if
    return out
end function

sub Srv_Save(list as object)
    St_Set("servers", list)
end sub

function Srv_Find(id as string) as dynamic
    for each s in Srv_List()
        if s.id = id then return s
    end for
    return invalid
end function

sub Srv_Put(sv as object)
    list = Srv_List()
    out = []
    done = false
    for each s in list
        if s.id = sv.id
            out.Push(sv)
            done = true
        else
            out.Push(s)
        end if
    end for
    if not done then out.Push(sv)
    Srv_Save(out)
end sub

sub Srv_Remove(id as string)
    out = []
    for each s in Srv_List()
        if s.id <> id then out.Push(s)
    end for
    Srv_Save(out)
end sub

function Srv_J(aa as dynamic, key as string) as dynamic
    if type(aa) <> "roAssociativeArray" then return invalid
    v = aa[key]
    if v <> invalid then return v
    low = LCase(key)
    for each k in aa
        if LCase(k) = low then return aa[k]
    end for
    return invalid
end function

function Srv_Normalize(address as string) as string
    a = address.Trim()
    if a = "" then return ""
    if Instr(1, a, "://") = 0 then a = "http://" + a
    for each tail in ["/web/index.html", "/web/", "/web", "/"]
        if LCase(Right(a, Len(tail))) = tail then a = Left(a, Len(a) - Len(tail))
    end for
    if LCase(Right(a, 5)) = "/emby" then a = Left(a, Len(a) - 5)
    return a
end function

function Srv_Root(sv as object) as string
    if Str_Of(sv.kind) = "emby" then return sv.address + "/emby"
    return sv.address
end function

function Srv_DeviceId() as string
    return "nuvio-roku-" + CreateObject("roDeviceInfo").GetChannelClientId()
end function

function Srv_Headers(sv as object) as object
    q = Chr(34)
    value = "MediaBrowser Client=" + q + "Nuvio Roku" + q + ", Device=" + q + "Roku" + q + ", DeviceId=" + q + Srv_DeviceId() + q + ", Version=" + q + App_Version() + q
    if Str_Of(sv.token) <> "" then value = value + ", Token=" + q + sv.token + q
    h = {}
    if Str_Of(sv.kind) = "emby"
        h["X-Emby-Authorization"] = value
    else
        h["Authorization"] = value
    end if
    if Str_Of(sv.token) <> "" then h["X-Emby-Token"] = sv.token
    return h
end function

function Srv_Get(sv as object, path as string, query as object, timeoutMs as integer) as object
    parts = []
    for each pair in query
        if pair[1] <> invalid and Str_Any(pair[1]) <> "" then parts.Push(pair[0] + "=" + Str_Any(pair[1]).EncodeUriComponent())
    end for
    url = Srv_Root(sv) + path
    if parts.Count() > 0 then url = url + "?" + parts.Join("&")
    return Http_Request("GET", url, Srv_Headers(sv), invalid, timeoutMs)
end function

function Srv_SignIn(kind as string, address as string, user as string, pass as string) as object
    base = Srv_Normalize(address)
    if base = "" then return { ok: false, error: L("Escribe una dirección de servidor válida.") }
    sv = { kind: kind, address: base, token: "" }
    info = Http_Request("GET", Srv_Root(sv) + "/System/Info/Public", {}, invalid, 12000)
    if info.code = 0 then return { ok: false, error: L("No se pudo conectar con el servidor.") }
    if info.code < 200 or info.code >= 300 or type(info.json) <> "roAssociativeArray" then return { ok: false, error: L("No se pudo conectar con el servidor.") + " (HTTP " + info.code.ToStr() + ")" }
    product = LCase(Str_Of(Srv_J(info.json, "ProductName")))
    if kind = "emby" and Instr(1, product, "jellyfin") > 0 then return { ok: false, error: L("Ese servidor es de Jellyfin. Agrégalo como Jellyfin.") }
    q = Chr(34)
    body = "{" + q + "Username" + q + ":" + FormatJson(user) + "," + q + "Pw" + q + ":" + FormatJson(pass) + "}"
    headers = Srv_Headers(sv)
    headers["Content-Type"] = "application/json"
    r = Http_Request("POST", Srv_Root(sv) + "/Users/AuthenticateByName", headers, body, 15000)
    if r.code = 401 or r.code = 403 then return { ok: false, error: L("Usuario o contraseña incorrectos.") }
    token = Str_Of(Srv_J(r.json, "AccessToken"))
    u = Srv_J(r.json, "User")
    if token = "" or type(u) <> "roAssociativeArray" then return { ok: false, error: L("No se pudo conectar con el servidor.") + " (HTTP " + r.code.ToStr() + ")" }
    name = Str_Of(Srv_J(info.json, "ServerName"))
    if name = "" then name = Srv_KindName(kind)
    sid = Str_Of(Srv_J(r.json, "ServerId"))
    if sid = "" then sid = Str_Of(Srv_J(info.json, "Id"))
    if sid = "" then sid = base
    sv = { id: kind + ":" + sid + ":" + Str_Of(Srv_J(u, "Id")), kind: kind, address: base, name: name, userId: Str_Of(Srv_J(u, "Id")), userName: Str_Of(Srv_J(u, "Name")), token: token, on: true, libs: [] }
    old = Srv_Find(sv.id)
    libs = Srv_Libraries(sv)
    if old <> invalid and type(old.libs) = "roArray"
        offs = {}
        for each lb in old.libs
            if lb.on = false then offs[Str_Of(lb.id)] = true
        end for
        for each lb in libs
            if offs.DoesExist(lb.id) then lb.on = false
        end for
    end if
    sv.libs = libs
    Srv_Put(sv)
    return { ok: true, id: sv.id, name: name }
end function

function Srv_Libraries(sv as object) as object
    if Str_Of(sv.kind) = "emby"
        r = Srv_Get(sv, "/Users/" + sv.userId + "/Views", [], 15000)
    else
        r = Srv_Get(sv, "/UserViews", [["userId", sv.userId]], 15000)
    end if
    out = []
    items = Srv_J(r.json, "Items")
    if type(items) <> "roArray" then return out
    for each v in items
        ct = LCase(Str_Of(Srv_J(v, "CollectionType")))
        kind = ""
        if ct = "movies" then kind = "movie"
        if ct = "tvshows" then kind = "series"
        if kind <> "" then out.Push({ id: Str_Of(Srv_J(v, "Id")), name: Str_Of(Srv_J(v, "Name")), kind: kind, on: true })
    end for
    return out
end function

sub Srv_Refresh(id as string)
    sv = Srv_Find(id)
    if sv = invalid then return
    libs = Srv_Libraries(sv)
    if libs.Count() = 0 then return
    offs = {}
    if type(sv.libs) = "roArray"
        for each lb in sv.libs
            if lb.on = false then offs[Str_Of(lb.id)] = true
        end for
    end if
    for each lb in libs
        if offs.DoesExist(lb.id) then lb.on = false
    end for
    sv.libs = libs
    Srv_Put(sv)
end sub

function Srv_ItemsPath(sv as object) as string
    if Str_Of(sv.kind) = "emby" then return "/Users/" + sv.userId + "/Items"
    return "/Items"
end function

function Srv_UserQuery(sv as object) as object
    if Str_Of(sv.kind) = "emby" then return []
    return [["userId", sv.userId]]
end function

function Srv_Ids(item as object) as object
    ids = Srv_J(item, "ProviderIds")
    out = { imdb: "", tmdb: "" }
    if type(ids) <> "roAssociativeArray" then return out
    out.imdb = Str_Any(Srv_J(ids, "Imdb")).Trim()
    out.tmdb = Str_Any(Srv_J(ids, "Tmdb")).Trim()
    return out
end function

function Srv_Image(sv as object, itemId as string, kind as string, width as integer) as string
    return Srv_Root(sv) + "/Items/" + itemId + "/Images/" + kind + "?maxWidth=" + width.ToStr() + "&quality=90"
end function

function Srv_Match(sv as object, lib as object, imdb as string, tmdb as string, title as string) as string
    itemType = "Movie"
    if lib.kind = "series" then itemType = "Series"
    q = Srv_UserQuery(sv)
    q.Append([["parentId", lib.id], ["recursive", "true"], ["includeItemTypes", itemType], ["fields", "ProviderIds"], ["enableImages", "false"], ["enableUserData", "false"], ["limit", "20"]])
    if Str_Of(sv.kind) = "emby"
        ids = []
        if imdb <> "" then ids.Push("imdb." + imdb)
        if tmdb <> "" then ids.Push("tmdb." + tmdb)
        if ids.Count() = 0 then return ""
        q.Push(["anyProviderIdEquals", ids.Join(",")])
    else
        if title = "" then return ""
        q.Push(["searchTerm", title])
    end if
    r = Srv_Get(sv, Srv_ItemsPath(sv), q, 15000)
    items = Srv_J(r.json, "Items")
    if type(items) <> "roArray" then return ""
    for each it in items
        ids = Srv_Ids(it)
        if (imdb <> "" and LCase(ids.imdb) = LCase(imdb)) or (tmdb <> "" and ids.tmdb = tmdb) then return Str_Of(Srv_J(it, "Id"))
    end for
    return ""
end function

function Srv_Episode(sv as object, seriesId as string, season as integer, episode as integer) as string
    q = Srv_UserQuery(sv)
    if q.Count() = 0 then q = [["userId", sv.userId]]
    q.Append([["season", season.ToStr()], ["enableImages", "false"], ["enableUserData", "false"]])
    r = Srv_Get(sv, "/Shows/" + seriesId + "/Episodes", q, 15000)
    items = Srv_J(r.json, "Items")
    if type(items) <> "roArray" then return ""
    for each it in items
        if ToInt(Srv_J(it, "ParentIndexNumber"), -1) = season and ToInt(Srv_J(it, "IndexNumber"), -1) = episode and Str_Of(Srv_J(it, "LocationType")) <> "Virtual" then return Str_Of(Srv_J(it, "Id"))
    end for
    return ""
end function

function Srv_Info(sv as object, itemId as string) as dynamic
    q = Srv_UserQuery(sv)
    q.Push(["fields", "MediaSources,Path"])
    if Str_Of(sv.kind) = "emby"
        r = Srv_Get(sv, "/Users/" + sv.userId + "/Items/" + itemId, [["fields", "MediaSources,Path"]], 15000)
    else
        r = Srv_Get(sv, "/Items/" + itemId, q, 15000)
    end if
    if type(r.json) <> "roAssociativeArray" then return invalid
    return r.json
end function

function Srv_Streams(title as string, kind as string, ids as object) as object
    out = []
    servers = Srv_List()
    if servers.Count() = 0 then return out
    imdb = ""
    tmdb = ""
    season = -1
    episode = -1
    for each vid in ids
        parts = Str_Of(vid).Split(":")
        if Left(parts[0], 2) = "tt" and imdb = "" then imdb = parts[0]
        if LCase(parts[0]) = "tmdb" and parts.Count() > 1 and tmdb = "" then tmdb = parts[1]
        if parts.Count() >= 3 and season < 0
            n = parts.Count()
            season = parts[n - 2].ToInt()
            episode = parts[n - 1].ToInt()
        end if
    end for
    if imdb = "" and tmdb = "" then return out
    series = LCase(kind) <> "movie"
    for each sv in servers
        if sv.on <> false and type(sv.libs) = "roArray"
            found = ""
            for each lib in sv.libs
                if found = "" and lib.on <> false and (lib.kind = "series") = series then found = Srv_Match(sv, lib, imdb, tmdb, title)
            end for
            if found <> "" and series
                if season >= 0 and episode > 0 then found = Srv_Episode(sv, found, season, episode) else found = ""
            end if
            if found <> ""
                info = Srv_Info(sv, found)
                for each s in Srv_ItemStreams(sv, found, info)
                    out.Push(s)
                end for
            end if
        end if
    end for
    return out
end function

function Srv_ItemStreams(sv as object, itemId as string, info as dynamic) as object
    sources = Srv_J(info, "MediaSources")
    if type(sources) <> "roArray" or sources.Count() = 0 then sources = [{ Id: itemId }]
    out = []
    for each src in sources
        sid = Str_Of(Srv_J(src, "Id"))
        if sid = "" then sid = itemId
        container = LCase(Str_Of(Srv_J(src, "Container")))
        size = Val(Str_Any(Srv_J(src, "Size")))
        name = Str_Of(Srv_J(src, "Name"))
        if name = "" then name = Str_Of(Srv_J(info, "Name"))
        path = Str_Of(Srv_J(src, "Path"))
        file = path.Replace("\", "/")
        if file <> "" then file = file.Split("/")[file.Split("/").Count() - 1]
        video = ""
        height = 0
        streams = Srv_J(src, "MediaStreams")
        if type(streams) = "roArray"
            for each ms in streams
                if LCase(Str_Of(Srv_J(ms, "Type"))) = "video" and video = ""
                    video = UCase(Str_Of(Srv_J(ms, "Codec")))
                    height = ToInt(Srv_J(ms, "Height"), 0)
                end if
            end for
        end if
        res = ""
        if height >= 2000 then res = "4K" else if height >= 1000 then res = "1080p" else if height >= 700 then res = "720p" else if height > 0 then res = height.ToStr() + "p"
        details = []
        if res <> "" then details.Push(res)
        if video <> "" then details.Push(video)
        if container <> "" then details.Push(UCase(container))
        if size > 0 then details.Push(Srv_Gb(size))
        token = sv.token.EncodeUriComponent()
        direct = Srv_Root(sv) + "/Videos/" + itemId + "/stream?static=true&mediaSourceId=" + sid.EncodeUriComponent() + "&deviceId=" + Srv_DeviceId().EncodeUriComponent() + "&api_key=" + token
        hls = Srv_Root(sv) + "/Videos/" + itemId + "/master.m3u8?mediaSourceId=" + sid.EncodeUriComponent() + "&deviceId=" + Srv_DeviceId().EncodeUriComponent() + "&api_key=" + token + "&VideoCodec=h264,hevc&AudioCodec=aac,ac3,eac3,mp3&TranscodingMaxAudioChannels=6&SegmentContainer=ts&MaxStreamingBitrate=40000000&BreakOnNonKeyFrames=True"
        out.Push({ url: direct, name: sv.name, desc: name + chr(10) + L("Original") + "  ·  " + details.Join("  ·  "), filename: file, kind: "direct" })
        out.Push({ url: hls, name: sv.name, desc: name + chr(10) + L("Convertido por el servidor (HLS)"), filename: file, kind: "hls" })
    end for
    return out
end function

function Srv_Gb(size as double) as string
    tenths = Int(size / 107374182.4 + 0.5)
    return Int(tenths / 10).ToStr() + "." + (tenths mod 10).ToStr() + " GB"
end function
