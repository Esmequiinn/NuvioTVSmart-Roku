sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    result = invalid
    local = Trailer_List(m.top.localYt)
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
    headers = { "x-imdb-client-name": "imdb-web-next-localized", "x-imdb-user-language": "es-MX", "x-imdb-user-country": "MX" }
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
    agent = "com.google.ios.youtube/20.10.1 (iPhone16,2; U; CPU iOS 17_4 like Mac OS X)"
    headers = { "User-Agent": agent, "X-Youtube-Client-Name": "5", "X-Youtube-Client-Version": "20.10.1", Origin: "https://www.youtube.com" }
    client = { clientName: "IOS", clientVersion: "20.10.1", deviceMake: "Apple", deviceModel: "iPhone16,2", osName: "iPhone", osVersion: "17.4.0.21E219", hl: "es", gl: "MX" }
    body = { context: { client: client }, videoId: id, contentCheckOk: true, racyCheckOk: true }
    r = Http_Request("POST", "https://www.youtube.com/youtubei/v1/player?prettyPrint=false", headers, body, 12000)
    d = r.json
    if type(d) <> "roAssociativeArray" or type(d.streamingData) <> "roAssociativeArray" then return invalid
    hls = Str_Of(d.streamingData.hlsManifestUrl)
    if hls <> "" then return { url: hls, format: "hls", headers: ["User-Agent: " + agent], source: "youtube" }
    if type(d.streamingData.formats) = "roArray"
        for each f in d.streamingData.formats
            if type(f) = "roAssociativeArray" and Str_Of(f.url) <> "" and Instr(1, Str_Of(f.mimeType), "video/mp4") > 0
                return { url: f.url, format: "mp4", headers: ["User-Agent: " + agent], source: "youtube" }
            end if
        end for
    end if
    return invalid
end function

function Trailer_YtId(raw as string) as string
    text = raw.Trim()
    if CreateObject("roRegex", "^[A-Za-z0-9_-]{11}$", "").IsMatch(text) then return text
    re = CreateObject("roRegex", "(?:youtu\.be/|youtube(?:-nocookie)?\.com/(?:.*v=|v/|embed/|shorts/|live/))([A-Za-z0-9_-]{11})", "i")
    found = re.Match(text)
    if found.Count() > 1 then return found[1]
    return ""
end function
