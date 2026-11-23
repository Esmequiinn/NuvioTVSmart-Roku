function Plex_Headers(token as string) as object
    h = { "Accept": "application/json", "X-Plex-Client-Identifier": Srv_DeviceId(), "X-Plex-Product": "Nuvio Roku", "X-Plex-Version": App_Version(), "X-Plex-Platform": "Roku", "X-Plex-Device": "Roku", "X-Plex-Device-Name": "Nuvio Roku" }
    if token <> "" then h["X-Plex-Token"] = token
    return h
end function

function Plex_Mc(r as object) as dynamic
    if type(r.json) <> "roAssociativeArray" then return invalid
    mc = r.json.MediaContainer
    if type(mc) <> "roAssociativeArray" then return invalid
    return mc
end function

function Plex_List(mc as dynamic, key as string) as object
    if type(mc) <> "roAssociativeArray" then return []
    v = mc[key]
    if type(v) = "roArray" then return v
    if type(v) = "roAssociativeArray" then return [v]
    return []
end function

function Plex_Pin() as object
    r = Http_Request("POST", "https://plex.tv/api/v2/pins?strong=false", Plex_Headers(""), invalid, 15000)
    if type(r.json) <> "roAssociativeArray" or Str_Any(r.json.id) = "" then return { ok: false, error: L("No se pudo conectar con el servidor.") + " (HTTP " + r.code.ToStr() + ")" }
    return { ok: true, deviceCode: Str_Any(r.json.id), userCode: Str_Of(r.json.code), url: "https://plex.tv/link", interval: 3, expires: ToInt(r.json.expiresIn, 900) }
end function

function Plex_Poll(pinId as string) as object
    r = Http_Request("GET", "https://plex.tv/api/v2/pins/" + pinId, Plex_Headers(""), invalid, 15000)
    if r.code = 404 then return { ok: false, status: "failed", error: L("El código venció. Vuelve a intentarlo.") }
    if type(r.json) <> "roAssociativeArray" then return { ok: true, status: "pending" }
    token = Str_Of(r.json.authToken)
    if token = "" then return { ok: true, status: "pending" }
    res = Plex_Connect(token)
    if not Bool_Of(res.ok, false) then return { ok: false, status: "failed", error: Str_Of(res.error) }
    return { ok: true, status: "approved" }
end function

function Plex_Connect(token as string) as object
    user = Http_Request("GET", "https://plex.tv/api/v2/user", Plex_Headers(token), invalid, 15000)
    userName = ""
    if type(user.json) = "roAssociativeArray"
        userName = Str_Of(user.json.title)
        if userName = "" then userName = Str_Of(user.json.username)
    end if
    r = Http_Request("GET", "https://plex.tv/api/v2/resources?includeHttps=1&includeRelay=1", Plex_Headers(token), invalid, 20000)
    if type(r.json) <> "roArray" then return { ok: false, error: L("No se pudo conectar con el servidor.") + " (HTTP " + r.code.ToStr() + ")" }
    added = 0
    for each res in r.json
        if type(res) = "roAssociativeArray" and Instr(1, Str_Of(res.provides), "server") > 0
            access = Str_Of(res.accessToken)
            if access = "" then access = token
            uri = Plex_Reach(res.connections, access)
            if uri <> ""
                sv = { id: "plex:" + Str_Of(res.clientIdentifier), kind: "plex", address: uri, name: Str_Of(res.name), userId: "", userName: userName, token: access, on: true, libs: [] }
                old = Srv_Find(sv.id)
                if old <> invalid and old.on = false then sv.on = false
                libs = Plex_Libraries(sv)
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
                added = added + 1
            end if
        end if
    end for
    if added = 0 then return { ok: false, error: L("No encontramos un servidor de Plex que responda desde esta red.") }
    return { ok: true }
end function

function Plex_Reach(conns as dynamic, token as string) as string
    if type(conns) <> "roArray" then return ""
    ordered = []
    for tier = 0 to 2
        for each c in conns
            isLocal = Bool_Of(c.local, false)
            relay = Bool_Of(c.relay, false)
            if (tier = 0 and isLocal and not relay) or (tier = 1 and not isLocal and not relay) or (tier = 2 and relay) then ordered.Push(c)
        end for
    end for
    for each c in ordered
        uri = Str_Of(c.uri)
        if Right(uri, 1) = "/" then uri = Left(uri, Len(uri) - 1)
        if uri <> ""
            r = Http_Request("GET", uri + "/identity", Plex_Headers(token), invalid, 5000)
            if r.code >= 200 and r.code < 300 then return uri
        end if
    end for
    return ""
end function

function Plex_Get(sv as object, path as string, timeoutMs as integer) as object
    return Http_Request("GET", sv.address + path, Plex_Headers(Str_Of(sv.token)), invalid, timeoutMs)
end function

function Plex_Libraries(sv as object) as object
    out = []
    for each d in Plex_List(Plex_Mc(Plex_Get(sv, "/library/sections", 15000)), "Directory")
        t = Str_Of(d.type)
        kind = ""
        if t = "movie" then kind = "movie"
        if t = "show" then kind = "series"
        if kind <> "" then out.Push({ id: Str_Any(d.key), name: Str_Of(d.title), kind: kind, on: true })
    end for
    return out
end function

function Plex_Ids(it as object) as object
    out = { imdb: "", tmdb: "" }
    for each g in Plex_List(it, "Guid")
        gid = Str_Of(g.id)
        if Left(gid, 7) = "imdb://" then out.imdb = Mid(gid, 8)
        if Left(gid, 7) = "tmdb://" then out.tmdb = Mid(gid, 8)
    end for
    return out
end function

function Plex_Image(sv as object, path as string, width as integer, height as integer) as string
    if path = "" then return ""
    return sv.address + "/photo/:/transcode?width=" + width.ToStr() + "&height=" + height.ToStr() + "&minSize=1&upscale=1&url=" + path.EncodeUriComponent() + "&X-Plex-Token=" + Str_Of(sv.token).EncodeUriComponent()
end function

function Plex_LibraryRow(sv as object, lib as object, limit as integer) as dynamic
    if limit < 10 then limit = 20
    r = Plex_Get(sv, "/library/sections/" + lib.id + "/all?sort=addedAt:desc&includeGuids=1&X-Plex-Container-Start=0&X-Plex-Container-Size=" + limit.ToStr(), 20000)
    out = []
    for each it in Plex_List(Plex_Mc(r), "Metadata")
        ids = Plex_Ids(it)
        mid = ""
        if Left(ids.imdb, 2) = "tt" then mid = ids.imdb
        if mid = "" and ids.tmdb <> "" then mid = "tmdb:" + ids.tmdb
        if mid <> ""
            genres = []
            for each g in Plex_List(it, "Genre")
                genres.Push(Str_Of(g.tag))
            end for
            meta = { id: mid, type: lib.kind, name: Str_Of(it.title), poster: Plex_Image(sv, Str_Of(it.thumb), 342, 513), background: Plex_Image(sv, Str_Of(it.art), 1280, 720), releaseInfo: Str_Any(it.year), genres: genres, description: Str_OneLine(Str_Of(it.summary)) }
            out.Push(Catalog_ItemData(meta, lib.kind, ""))
        end if
    end for
    if out.Count() = 0 then return invalid
    return { key: "srv:" + sv.id + ":" + lib.id, name: lib.name + "  ·  " + sv.name, kind: lib.kind, shape: "poster", items: out }
end function

function Plex_Match(sv as object, lib as object, imdb as string, tmdb as string, title as string) as string
    tries = []
    if imdb <> "" then tries.Push("guid=" + ("imdb://" + imdb).EncodeUriComponent())
    if tmdb <> "" then tries.Push("guid=" + ("tmdb://" + tmdb).EncodeUriComponent())
    if title <> "" then tries.Push("title=" + title.EncodeUriComponent())
    for each q in tries
        r = Plex_Get(sv, "/library/sections/" + lib.id + "/all?includeGuids=1&" + q, 15000)
        for each it in Plex_List(Plex_Mc(r), "Metadata")
            ids = Plex_Ids(it)
            if (imdb <> "" and LCase(ids.imdb) = LCase(imdb)) or (tmdb <> "" and ids.tmdb = tmdb) then return Str_Any(it.ratingKey)
        end for
    end for
    return ""
end function

function Plex_Episode(sv as object, showKey as string, season as integer, episode as integer) as string
    seasonKey = ""
    for each s in Plex_List(Plex_Mc(Plex_Get(sv, "/library/metadata/" + showKey + "/children", 15000)), "Metadata")
        if ToInt(s.index, -1) = season then seasonKey = Str_Any(s.ratingKey)
    end for
    if seasonKey = "" then return ""
    for each e in Plex_List(Plex_Mc(Plex_Get(sv, "/library/metadata/" + seasonKey + "/children", 15000)), "Metadata")
        if ToInt(e.index, -1) = episode then return Str_Any(e.ratingKey)
    end for
    return ""
end function

function Plex_ItemStreams(sv as object, itemKey as string) as object
    out = []
    items = Plex_List(Plex_Mc(Plex_Get(sv, "/library/metadata/" + itemKey, 15000)), "Metadata")
    if items.Count() = 0 then return out
    it = items[0]
    token = Str_Of(sv.token).EncodeUriComponent()
    title = Str_Of(it.title)
    mi = 0
    for each media in Plex_List(it, "Media")
        parts = Plex_List(media, "Part")
        if parts.Count() > 0
            part = parts[0]
            file = Str_Of(part.file).Replace("\", "/")
            if file <> "" then file = file.Split("/")[file.Split("/").Count() - 1]
            srvSubs = []
            for each st in Plex_List(part, "Stream")
                if ToInt(st.streamType, 0) = 3 and Str_Of(st.key) <> ""
                    codec = LCase(Str_Of(st.codec))
                    ext = ""
                    if codec = "srt" or codec = "subrip" then ext = "srt"
                    if codec = "vtt" or codec = "webvtt" then ext = "vtt"
                    if codec = "ass" or codec = "ssa" then ext = codec
                    if ext <> ""
                        subTitle = Str_Of(st.displayTitle)
                        if subTitle = "" then subTitle = Str_Of(st.title)
                        srvSubs.Push({ url: sv.address + Str_Of(st.key) + "?X-Plex-Token=" + token, lang: Str_Of(st.languageCode), title: subTitle, SubFormat: ext, forced: Bool_Of(st.forced, false), hearingImpaired: Bool_Of(st.hearingImpaired, false) })
                    end if
                end if
            end for
            res = LCase(Str_Any(media.videoResolution))
            if res = "4k" then res = "4K" else if res = "sd" then res = "SD" else if res <> "" then res = res + "p"
            details = []
            if res <> "" then details.Push(res)
            if Str_Of(media.videoCodec) <> "" then details.Push(UCase(Str_Of(media.videoCodec)))
            if Str_Of(media.container) <> "" then details.Push(UCase(Str_Of(media.container)))
            size = Val(Str_Any(part.size))
            if size > 0 then details.Push(Srv_Gb(size))
            direct = sv.address + Str_Of(part.key) + "?X-Plex-Token=" + token
            session = Srv_DeviceId() + "-" + itemKey + "-" + mi.ToStr()
            hls = sv.address + "/video/:/transcode/universal/start.m3u8?path=" + ("/library/metadata/" + itemKey).EncodeUriComponent() + "&mediaIndex=" + mi.ToStr() + "&partIndex=0&protocol=hls&fastSeek=1&directPlay=0&directStream=1&directStreamAudio=1&subtitles=none&videoResolution=1920x1080&maxVideoBitrate=20000&session=" + session.EncodeUriComponent() + "&X-Plex-Session-Identifier=" + session.EncodeUriComponent() + "&X-Plex-Client-Identifier=" + Srv_DeviceId().EncodeUriComponent() + "&X-Plex-Product=Nuvio%20Roku&X-Plex-Platform=Roku&X-Plex-Device=Roku&X-Plex-Token=" + token
            out.Push({ url: direct, name: sv.name, desc: title + chr(10) + L("Original") + "  ·  " + details.Join("  ·  "), filename: file, kind: "direct", subtitles: srvSubs })
            out.Push({ url: hls, name: sv.name, desc: title + chr(10) + L("Convertido por el servidor (HLS)"), filename: file, kind: "hls", subtitles: srvSubs })
        end if
        mi = mi + 1
    end for
    return out
end function
