sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    result = invalid
    local = Trailer_List(m.top.localYt)
    if local.Count() = 0 and m.top.imdb <> "" then local = Trailer_TmdbLocal(m.top.imdb, m.top.kind)
    for each id in local
        if result = invalid then result = Trailer_YouTube(id)
    end for
    if result = invalid and m.top.imdb <> "" then result = Trailer_Imdb(m.top.imdb)
    if result = invalid
        for each url in Trailer_List(m.top.urls)
            if result = invalid and LCase(Left(url, 4)) = "http" then result = { url: url, format: Stream_Format(url), headers: [], source: "direct" }
        end for
    end if
    if result = invalid
        for each id in Trailer_List(m.top.ytIds)
            if result = invalid then result = Trailer_YouTube(id)
        end for
    end if
    if result = invalid then result = { url: "" }
    m.top.result = result
end sub

function Trailer_TmdbLocal(imdb as string, kind as string) as object
    out = []
    key = Key_Tmdb(St_Integrations())
    if key = "" then return out
    lang = Tmdb_Lang()
    short = LCase(Left(lang, 2))
    if short = "en" then return out
    r = Http_Request("GET", "https://api.themoviedb.org/3/find/" + imdb.Split(":")[0] + "?api_key=" + key + "&external_source=imdb_id", {}, invalid, 8000)
    d = r.json
    if type(d) <> "roAssociativeArray" then return out
    media = ""
    id = ""
    k = LCase(kind)
    order = ["movie_results", "tv_results"]
    if k = "series" or k = "tv" then order = ["tv_results", "movie_results"]
    for each field in order
        if id = "" and type(d[field]) = "roArray" and d[field].Count() > 0
            id = Str_Any(d[field][0].id)
            media = "movie"
            if field = "tv_results" then media = "tv"
        end if
    end for
    if id = "" then return out
    v = Http_Request("GET", "https://api.themoviedb.org/3/" + media + "/" + id + "/videos?api_key=" + key + "&language=" + lang, {}, invalid, 8000)
    list = v.json
    if type(list) <> "roAssociativeArray" or type(list.results) <> "roArray" then return out
    for each wanted in ["Trailer", "Teaser"]
        for each x in list.results
            if type(x) = "roAssociativeArray" and LCase(Str_Of(x.site)) = "youtube" and Str_Of(x.type) = wanted and Str_Of(x.key) <> "" and LCase(Str_Of(x.iso_639_1)) = short
                if out.Count() < 2 then out.Push(x.key)
            end if
        end for
    end for
    return out
end function

function Trailer_List(v as dynamic) as object
    out = []
    if type(v) <> "roArray" then return out
    for each x in v
        if IsStr(x) and x <> "" and out.Count() < 3 then out.Push(x)
    end for
    return out
end function

function Trailer_Imdb(imdb as string) as dynamic
    query = "query TitleTrailer($id: ID!) { title(id: $id) { primaryVideos(first: 1) { edges { node { id playbackURLs { url videoMimeType videoDefinition } } } } } }"
    lang = Tmdb_Lang()
    country = "US"
    if Len(lang) = 5 then country = Right(lang, 2)
    headers = { "x-imdb-client-name": "imdb-web-next-localized", "x-imdb-user-language": lang, "x-imdb-user-country": country }
    r = Http_Request("POST", "https://api.graphql.imdb.com/", headers, { query: query, variables: { id: imdb } }, 12000)
    d = r.json
    if type(d) <> "roAssociativeArray" or type(d.data) <> "roAssociativeArray" then return invalid
    t = d.data.title
    if type(t) <> "roAssociativeArray" or type(t.primaryVideos) <> "roAssociativeArray" or type(t.primaryVideos.edges) <> "roArray" then return invalid
    if t.primaryVideos.edges.Count() = 0 then return invalid
    node = t.primaryVideos.edges[0].node
    if type(node) <> "roAssociativeArray" or type(node.playbackURLs) <> "roArray" then return invalid
    ranks = { DEF_1080P: 5, DEF_720P: 4, DEF_480P: 3, DEF_SD: 2, DEF_AUTO: 1 }
    best = invalid
    bestRank = -1
    hls = ""
    for each p in node.playbackURLs
        if type(p) = "roAssociativeArray" and Str_Of(p.url) <> ""
            mime = UCase(Str_Of(p.videoMimeType))
            if mime = "M3U8"
                hls = p.url
            else if mime = "MP4"
                rank = ToInt(ranks[UCase(Str_Of(p.videoDefinition))], 0)
                if rank > bestRank
                    bestRank = rank
                    best = p.url
                end if
            end if
        end if
    end for
    if best <> invalid then return { url: best, format: "mp4", headers: [], source: "imdb" }
    if hls <> "" then return { url: hls, format: "hls", headers: [], source: "imdb" }
    return invalid
end function

function Trailer_YouTube(raw as string) as dynamic
    id = Trailer_YtId(raw)
    if id = "" then return invalid
    cfg = Yt_Config(false)
    notes = []
    stale = 0
    clients = Yt_Clients()
    for each c in clients
        r = Yt_Player(id, c, cfg)
        notes.Push(c.key + " " + r.note)
        if r.result <> invalid
            Yt_Note(id, notes)
            return r.result
        end if
        if r.note = "LOGIN_REQUIRED" then stale = stale + 1
    end for
    if stale = clients.Count()
        cfg = Yt_Config(true)
        for each c in clients
            r = Yt_Player(id, c, cfg)
            notes.Push(c.key + " " + r.note)
            if r.result <> invalid
                Yt_Note(id, notes)
                return r.result
            end if
        end for
    end if
    Yt_Note(id, notes)
    return invalid
end function

sub Yt_Note(id as string, notes as object)
    St_Set("trailerDiag", "YouTube " + id + ": " + notes.Join(", "))
end sub

function Yt_Clients() as object
    return [
        { key: "ios", id: "5", version: "20.10.1", agent: "com.google.ios.youtube/20.10.1 (iPhone16,2; U; CPU iOS 17_4 like Mac OS X)", context: [["clientName", "IOS"], ["clientVersion", "20.10.1"], ["deviceModel", "iPhone16,2"], ["osName", "iPhone"], ["osVersion", "17.4.0.21E219"], ["platform", "MOBILE"], ["hl", "en"], ["gl", "US"]] }
        { key: "visionos", id: "101", version: "1.02", agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_3) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15", context: [["clientName", "VISIONOS"], ["clientVersion", "1.02"], ["deviceMake", "Apple"], ["deviceModel", "RealityDevice17,1"], ["osName", "visionOS"], ["osVersion", "26.5.23O471"], ["hl", "en"], ["gl", "US"]] }
        { key: "android", id: "3", version: "20.10.35", agent: "com.google.android.youtube/20.10.35 (Linux; U; Android 14; en_US) gzip", context: [["clientName", "ANDROID"], ["clientVersion", "20.10.35"], ["osName", "Android"], ["osVersion", "14"], ["platform", "MOBILE"], ["androidSdkVersion", 34], ["hl", "en"], ["gl", "US"]] }
    ]
end function

function Yt_Body(id as string, context as object) as string
    parts = []
    for each pair in context
        parts.Push(FormatJson(pair[0]) + ":" + FormatJson(pair[1]))
    end for
    client = "{" + parts.Join(",") + "}"
    q = Chr(34)
    return "{" + q + "videoId" + q + ":" + FormatJson(id) + "," + q + "contentCheckOk" + q + ":true," + q + "racyCheckOk" + q + ":true," + q + "context" + q + ":{" + q + "client" + q + ":" + client + "}," + q + "playbackContext" + q + ":{" + q + "contentPlaybackContext" + q + ":{" + q + "html5Preference" + q + ":" + q + "HTML5_PREF_WANTS" + q + "}}}"
end function

function Yt_Config(refresh as boolean) as object
    now = CreateObject("roDateTime").AsSeconds()
    saved = St_Get("ytConfig", invalid)
    if not refresh and type(saved) = "roAssociativeArray" and now - ToInt(saved.at, 0) < 21600 and Str_Of(saved.key) <> "" then return saved
    cfg = { key: "AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8", visitor: "", at: now }
    agent = "Mozilla/5.0 (Linux; Android 12; Android TV) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
    r = Http_Request("GET", "https://www.youtube.com/watch?v=dQw4w9WgXcQ&hl=en", { "User-Agent": agent, "Accept-Language": "en-US,en;q=0.9" }, invalid, 12000)
    if r.code = 200 and r.body <> ""
        key = CreateObject("roRegex", Chr(34) + "INNERTUBE_API_KEY" + Chr(34) + ":" + Chr(34) + "([^" + Chr(34) + "]+)" + Chr(34), "").Match(r.body)
        if key.Count() > 1 then cfg.key = key[1]
        visitor = CreateObject("roRegex", Chr(34) + "VISITOR_DATA" + Chr(34) + ":" + Chr(34) + "([^" + Chr(34) + "]+)" + Chr(34), "").Match(r.body)
        if visitor.Count() > 1 then cfg.visitor = visitor[1]
    else
        cfg.at = now - 21000
    end if
    St_Set("ytConfig", cfg)
    return cfg
end function

function Yt_Player(id as string, c as object, cfg as object) as object
    headers = { "User-Agent": c.agent, "X-Youtube-Client-Name": c.id, "X-Youtube-Client-Version": c.version, Origin: "https://www.youtube.com", "Accept-Language": "en-US,en;q=0.9" }
    if Str_Of(cfg.visitor) <> "" then headers["X-Goog-Visitor-Id"] = cfg.visitor
    headers["Content-Type"] = "application/json"
    r = Http_Request("POST", "https://www.youtube.com/youtubei/v1/player?key=" + Str_Of(cfg.key) + "&prettyPrint=false", headers, Yt_Body(id, c.context), 12000)
    out = { result: invalid, note: "HTTP " + r.code.ToStr() }
    d = r.json
    if type(d) <> "roAssociativeArray" then return out
    if type(d.error) = "roAssociativeArray"
        out.note = "HTTP " + r.code.ToStr() + " " + Str_Of(d.error.status) + " " + Left(Str_Of(d.error.message), 60)
        return out
    end if
    status = ""
    reason = ""
    if type(d.playabilityStatus) = "roAssociativeArray"
        status = Str_Of(d.playabilityStatus.status)
        reason = Str_Of(d.playabilityStatus.reason)
    end if
    if status <> "" and status <> "OK"
        out.note = (status + " " + Left(reason, 40)).Trim()
        return out
    end if
    sd = d.streamingData
    if type(sd) <> "roAssociativeArray"
        out.note = "HTTP " + r.code.ToStr() + " " + status + " sin video"
        return out
    end if
    playHeaders = ["User-Agent: " + c.agent]
    hls = Str_Of(sd.hlsManifestUrl)
    if hls <> ""
        out.note = "OK hls"
        out.result = { url: hls, format: "hls", headers: playHeaders, source: "youtube" }
        return out
    end if
    best = invalid
    if type(sd.formats) = "roArray"
        for each f in sd.formats
            if type(f) = "roAssociativeArray" and Str_Of(f.url) <> "" and Instr(1, Str_Of(f.mimeType), "video/mp4") > 0
                if best = invalid or ToInt(f.height, 0) > ToInt(best.height, 0) then best = f
            end if
        end for
    end if
    if best = invalid
        out.note = "sin formato"
        return out
    end if
    out.note = "OK mp4"
    out.result = { url: best.url, format: "mp4", headers: playHeaders, source: "youtube" }
    return out
end function

function Trailer_YtId(raw as string) as string
    text = raw.Trim()
    if CreateObject("roRegex", "^[A-Za-z0-9_-]{11}$", "").IsMatch(text) then return text
    re = CreateObject("roRegex", "(?:youtu\.be/|youtube(?:-nocookie)?\.com/(?:.*v=|v/|embed/|shorts/|live/))([A-Za-z0-9_-]{11})", "i")
    found = re.Match(text)
    if found.Count() > 1 then return found[1]
    return ""
end function
