function Vod_Pid() as string
    return Str_Of(St_ActiveProfile().id)
end function

function Vod_Pointer() as string
    return "cachefs:/iptv_vod_" + Vod_Pid() + ".txt"
end function

function Vod_Dir() as string
    return ReadAsciiFile(Vod_Pointer()).Trim()
end function

function Vod_Info() as dynamic
    if m.vodInfo <> invalid and m.vodInfoPid = Vod_Pid() then return m.vodInfo
    dir = Vod_Dir()
    if dir = "" then return invalid
    raw = ReadAsciiFile(dir + "groups.json")
    if raw = "" then return invalid
    j = ParseJson(raw)
    if type(j) <> "roAssociativeArray" or type(j.groups) <> "roArray" then return invalid
    j.dir = dir
    m.vodInfo = j
    m.vodInfoPid = Vod_Pid()
    return j
end function

function Vod_Group(gid as integer) as dynamic
    info = Vod_Info()
    if info = invalid then return invalid
    for each g in info.groups
        if ToInt(g.id, -1) = gid then return g
    end for
    return invalid
end function

function Vod_Key(text as string) as string
    if m.vodKeyRe = invalid
        m.vodKeyRe = CreateObject("roRegex", "[^a-z0-9]+", "")
        m.vodAccents = [["á", "a"], ["é", "e"], ["í", "i"], ["ó", "o"], ["ú", "u"], ["ü", "u"], ["ñ", "n"], ["à", "a"], ["è", "e"], ["ì", "i"], ["ò", "o"], ["ù", "u"], ["ç", "c"], ["ã", "a"], ["õ", "o"], ["ê", "e"], ["â", "a"], ["ô", "o"], ["ë", "e"], ["ï", "i"], ["ö", "o"], ["ä", "a"]]
    end if
    low = LCase(text)
    if m.vodPlainRe = invalid then m.vodPlainRe = CreateObject("roRegex", "^[a-z0-9 ]*$", "")
    if m.vodPlainRe.IsMatch(low) then return m.vodKeyRe.ReplaceAll(low, " ").Trim()
    for each pr in m.vodAccents
        if Instr(1, low, pr[0]) > 0 then low = low.Replace(pr[0], pr[1])
    end for
    return m.vodKeyRe.ReplaceAll(low, " ").Trim()
end function

function Vod_Score(want as string, got as string) as integer
    if got = "" then return 0
    if got = want then return 3
    words = want.Split(" ").Count()
    if words < 2 and Len(want) < 8 then return 0
    if Left(got, Len(want) + 1) = want + " " then return 2
    if Left(want, Len(got) + 1) = got + " " and got.Split(" ").Count() >= 2 then return 1
    return 0
end function

function Vod_Query(text as string) as string
    q = text
    for each mark in ["(", "[", " - ", " | ", ": T", " T1", " T2", " T3", " T4", " T5", " T6", " T7", " T8", " T9", " Temporada", " Season", " Ep.", " Episodio"]
        at = Instr(1, q, mark)
        if at > 3 then q = Left(q, at - 1)
    end for
    return q.Trim()
end function

function Vod_Clean(name as string) as object
    if m.vodTagRe = invalid
        m.vodTagRe = CreateObject("roRegex", "^\s*((\[[^\]]*\]|\|[^|]*\||\([A-Z]{2,4}\))\s*|[A-Z0-9]{2,5}(-[A-Z0-9]{2,4})?\s*[|:\-]\s+|[A-Z]{2,3}\|\s*)+", "")
        m.vodYearRe = CreateObject("roRegex", "[\(\[\s\-]((19|20)\d{2})[\)\]]?\s*$", "")
        m.vodYearAnyRe = CreateObject("roRegex", "\(((19|20)\d{2})\)", "")
        m.vodJunkRe = CreateObject("roRegex", "\s+(4k|uhd|fhd|hd|sd|hdr|1080p|720p|2160p|multi|dual|lat|latino|cast|sub|subs|vose|vos|esp|eng)(\s+|$)", "i")
        m.vodSpaceRe = CreateObject("roRegex", "\s{2,}", "")
        m.vodBracketRe = CreateObject("roRegex", "\[(?!(19|20)\d{2}\])[^\]]*\]", "")
    end if
    t = m.vodTagRe.ReplaceAll(name.Trim(), "")
    if Instr(1, t, "[") > 0 then t = m.vodBracketRe.ReplaceAll(t, " ").Trim()
    year = ""
    found = m.vodYearRe.Match(t)
    if found.Count() > 1
        year = found[1]
        t = m.vodYearRe.ReplaceAll(t, "")
    else
        found = m.vodYearAnyRe.Match(t)
        if found.Count() > 1
            year = found[1]
            t = m.vodYearAnyRe.ReplaceAll(t, " ")
        end if
    end if
    if m.vodJunkRe.IsMatch(t)
        t = m.vodJunkRe.ReplaceAll(t, " ")
        t = m.vodJunkRe.ReplaceAll(t, " ")
    end if
    t = m.vodSpaceRe.ReplaceAll(t, " ").Trim()
    while Len(t) > 0 and (Right(t, 1) = "-" or Right(t, 1) = "|" or Right(t, 1) = ":")
        t = Left(t, Len(t) - 1).Trim()
    end while
    if t = "" then t = name.Trim()
    return { title: t, year: year }
end function

function Vod_RefOf(kind as string, key as string, year as string) as string
    pre = "iptvm:"
    if kind = "series" then pre = "iptvs:"
    return pre + key.Replace(" ", "_") + "~" + year
end function

function Vod_IsRef(id as string) as boolean
    return Left(id, 6) = "iptvm:" or Left(id, 6) = "iptvs:"
end function

function Vod_Split(line as string) as object
    return line.Split(Chr(9))
end function

function Vod_Unpack(g as dynamic, field as string, value as string) as string
    if Left(value, 1) <> "~" or g = invalid then return value
    return Str_Of(g[field]) + Mid(value, 2)
end function

function Vod_Lines(gid as integer) as object
    if m.vodLines = invalid then m.vodLines = {}
    k = gid.ToStr()
    if not m.vodLines.DoesExist(k)
        if m.vodLines.Count() > 6 then m.vodLines = {}
        m.vodLines[k] = Vod_ReadGroup(gid, 0)
    end if
    return m.vodLines[k]
end function

sub Vod_Fill(hits as object)
    for each h in hits
        if h.name = invalid
            lines = Vod_Lines(h.gid)
            h.name = ""
            h.logo = ""
            h.tag = ""
            h.tmdb = ""
            if h.line >= 0 and h.line < lines.Count()
                f = Vod_Split(lines[h.line])
                if f.Count() >= 4
                    h.name = f[1]
                    h.logo = Vod_Unpack(Vod_Group(h.gid), "lb", f[3])
                    if f[0] = "E"
                        if f.Count() >= 8 then h.tag = f[7]
                    else
                        if f.Count() >= 6 then h.tag = f[5]
                        if f.Count() >= 7 then h.tmdb = f[6]
                    end if
                end if
            end if
        end if
    end for
end sub

function Vod_ReadGroup(gid as integer, maxBytes as integer) as object
    info = Vod_Info()
    if info = invalid then return []
    path = info.dir + "g" + gid.ToStr() + ".tsv"
    ba = CreateObject("roByteArray")
    if maxBytes > 0
        ba.ReadFile(path, 0, maxBytes)
        n = ba.Count()
        if n = 0 then return []
        cut = n
        if n >= maxBytes
            while cut > 0 and ba[cut - 1] <> 10
                cut = cut - 1
            end while
            if cut = 0 then return []
            if cut < n then ba.ReadFile(path, 0, cut)
        end if
        text = ba.ToAsciiString()
    else
        text = ReadAsciiFile(path)
    end if
    out = []
    for each ln in text.Split(Chr(10))
        if ln <> "" then out.Push(ln)
    end for
    return out
end function

function Vod_ItemMeta(g as object, f as object) as object
    kind = g.kind
    ref = Vod_RefOf(kind, Vod_Key(f[1]), f[2])
    return { id: ref, type: kind, name: f[1], poster: Vod_Unpack(g, "lb", f[3]), releaseInfo: f[2] }
end function

function Vod_CatKey(g as object) as string
    return "iptv:" + Left(Str_Of(g.kind), 1) + ":" + Str_Of(g.name)
end function

function Vod_Catalogs(hidden as object) as object
    out = []
    info = Vod_Info()
    if info = invalid then return out
    for each g in info.groups
        key = Vod_CatKey(g)
        out.Push({ key: key, name: "IPTV - " + Str_Of(g.name), kind: g.kind, id: Str_Any(g.id), addon: "IPTV", base: "iptv:", hidden: hidden.DoesExist(key), status: "ok", count: ToInt(g.n, 0), genres: [], skip: true, filter: "", needsExtra: false })
    end for
    return out
end function

function Vod_Row(cat as object, limit as integer) as object
    row = { key: cat.key, name: cat.name, kind: cat.kind, shape: "poster", items: [] }
    g = Vod_Group(ToInt(cat.id, -1))
    if g = invalid then return row
    if limit < 10 then limit = 20
    seen = {}
    for each ln in Vod_ReadGroup(ToInt(g.id, 0), 65536)
        f = Vod_Split(ln)
        if f.Count() >= 4
            meta = Vod_ItemMeta(g, f)
            if not seen.DoesExist(meta.id)
                seen[meta.id] = true
                it = Catalog_ItemData(meta, g.kind, "")
                it.background = ""
                row.items.Push(it)
                if row.items.Count() >= limit then exit for
            end if
        end if
    end for
    if row.items.Count() > 0 and ToInt(g.n, 0) > row.items.Count() then row.items.Push({ title: L("Ver todo"), kind: "seeall", metaId: "", poster: "", gridKey: cat.key })
    return row
end function

function Vod_Page(gid as integer, skip as integer, limit as integer) as object
    out = { items: [], count: 0 }
    g = Vod_Group(gid)
    if g = invalid then return out
    seen = {}
    u = 0
    for each ln in Vod_Lines(gid)
        f = Vod_Split(ln)
        if f.Count() >= 4
            meta = Vod_ItemMeta(g, f)
            if not seen.DoesExist(meta.id)
                seen[meta.id] = true
                if u >= skip
                    it = Catalog_ItemData(meta, g.kind, "")
                    it.background = ""
                    out.items.Push(it)
                    if out.items.Count() >= limit then exit for
                end if
                u = u + 1
            end if
        end if
    end for
    out.count = out.items.Count()
    return out
end function

function Vod_ScanIndex(needle as string, limitEach as integer, mode as string) as object
    out = { movie: [], series: [] }
    info = Vod_Info()
    if info = invalid or needle = "" then return out
    path = info.dir + "idx.tsv"
    st = CreateObject("roFileSystem").Stat(path)
    if st = invalid or st.size = invalid then return out
    size = st.size
    ba = CreateObject("roByteArray")
    offset = 0
    chunk = 262144
    nl = Chr(10)
    seen = {}
    exact = mode = "exact"
    if exact then pat = nl + needle else pat = needle
    while offset < size
        want = chunk
        if offset + want > size then want = size - offset
        ba.ReadFile(path, offset, want)
        n = ba.Count()
        if n = 0 then exit while
        cut = n
        if offset + n < size
            while cut > 0 and ba[cut - 1] <> 10
                cut = cut - 1
            end while
            if cut = 0 then cut = n
            if cut < n then ba.ReadFile(path, offset, cut)
        end if
        offset = offset + cut
        text = nl + ba.ToAsciiString()
        p = Instr(1, text, pat)
        while p > 0
            if exact
                ls = p + 1
            else
                ls = p
                while ls > 1 and Mid(text, ls - 1, 1) <> nl
                    ls = ls - 1
                end while
            end if
            le = Instr(ls, text, nl)
            if le = 0 then le = Len(text) + 1
            f = Vod_Split(Mid(text, ls, le - ls))
            if f.Count() >= 4
                okKey = true
                if mode = "contains" then okKey = Instr(1, f[0], needle) > 0
                if okKey
                    kind = "movie"
                    if f[1] = "s" then kind = "series"
                    if out[kind].Count() < limitEach
                        tilde = Instr(1, f[0], "~")
                        ref = Vod_RefOf(kind, Left(f[0], tilde - 1), Mid(f[0], tilde + 1))
                        if mode <> "contains" or not seen.DoesExist(ref)
                            seen[ref] = true
                            out[kind].Push({ key: f[0], kind: kind, gid: ToInt(f[2], 0), line: ToInt(f[3], 0), name: invalid, logo: "", ref: ref })
                        end if
                    end if
                end if
            end if
            if out.movie.Count() >= limitEach and out.series.Count() >= limitEach then return out
            p = Instr(le, text, pat)
        end while
    end while
    return out
end function

function Vod_Year(h as object) as string
    return Mid(h.key, Instr(1, h.key, "~") + 1)
end function

function Vod_Search(query as string, limit as integer) as object
    rows = []
    q = Vod_Key(query)
    if Len(q) < 2 then return rows
    found = Vod_ScanIndex(q, limit, "contains")
    for each kind in ["movie", "series"]
        metas = []
        Vod_Fill(found[kind])
        for each h in found[kind]
            metas.Push({ id: h.ref, type: kind, name: h.name, poster: h.logo, releaseInfo: Vod_Year(h) })
        end for
        if metas.Count() > 0 then rows.Push({ kind: kind, metas: metas })
    end for
    return rows
end function

function Vod_Find(ref as string) as object
    kind = "movie"
    if Left(ref, 6) = "iptvs:" then kind = "series"
    body = Mid(ref, 7)
    tilde = Instr(1, body, "~")
    if tilde = 0 then return []
    key = Left(body, tilde - 1).Replace("_", " ")
    year = Mid(body, tilde + 1)
    k = "m"
    if kind = "series" then k = "s"
    hits = Vod_ScanIndex(key + "~" + year + Chr(9) + k + Chr(9), 12, "exact")
    Vod_Fill(hits[kind])
    return hits[kind]
end function

function Vod_FindTmdb(id as string, kind as string) as object
    if id = "" then return []
    info = Vod_Info()
    if info = invalid or ToInt(info.tmdb, 0) = 0 then return []
    hits = Vod_ScanIndex(Chr(9) + "T" + id + Chr(10), 12, "tmdb")
    Vod_Fill(hits[kind])
    return hits[kind]
end function

function Vod_FindByTitle(title as string, kind as string, year as string) as object
    clean = Vod_Clean(title)
    key = Vod_Key(clean.title)
    if key = "" then return []
    hits = Vod_ScanIndex(key + "~", 24, "exact")
    Vod_Fill(hits[kind])
    out = []
    for each h in hits[kind]
        y = Vod_Year(h)
        if year = "" or y = "" or y = year then out.Push(h)
    end for
    return out
end function

function Vod_Map() as object
    if m.vodMap <> invalid and m.vodMapPid = Vod_Pid() then return m.vodMap
    j = ParseJson(ReadAsciiFile("cachefs:/iptv_vodmap_" + Vod_Pid() + ".json"))
    if type(j) <> "roAssociativeArray" then j = {}
    m.vodMap = j
    m.vodMapPid = Vod_Pid()
    return j
end function

sub Vod_Trim(map as object)
    if map.Count() < 3000 then return
    keep = {}
    for each k in map
        if Left(k, 4) = "fix:" then keep[k] = map[k]
    end for
    map.Clear()
    map.Append(keep)
end sub

sub Vod_SaveMap(map as object)
    WriteAsciiFile("cachefs:/iptv_vodmap_" + Vod_Pid() + ".json", FormatJson(map))
    m.vodMap = map
end sub

function Vod_TmdbSearch(query as string, kind as string, year as string) as object
    out = []
    key = Key_Tmdb(St_Integrations())
    if key = "" or query = "" then return out
    media = "movie"
    yearField = "year"
    if kind = "series"
        media = "tv"
        yearField = "first_air_date_year"
    end if
    url = "https://api.themoviedb.org/3/search/" + media + "?api_key=" + key + "&language=" + Tmdb_Lang() + "&query=" + query.EncodeUriComponent()
    if year <> "" then url = url + "&" + yearField + "=" + year
    j = Http_FetchJson(url, 10000)
    if type(j) = "roAssociativeArray" and type(j.results) = "roArray"
        for each r in j.results
            if type(r) = "roAssociativeArray"
                name = Str_Of(r.title)
                if name = "" then name = Str_Of(r.name)
                date = Str_Of(r.release_date)
                if date = "" then date = Str_Of(r.first_air_date)
                out.Push({ id: "tmdb:" + Str_Any(r.id), name: name, year: Left(date, 4), names: [Str_Of(r.title), Str_Of(r.name), Str_Of(r.original_title), Str_Of(r.original_name)] })
            end if
        end for
    end if
    return out
end function

function Vod_CinemetaSearch(query as string, kind as string) as object
    out = []
    if query = "" then return out
    media = "movie"
    if kind = "series" then media = "series"
    j = Http_FetchJson("https://v3-cinemeta.strem.io/catalog/" + media + "/top/search=" + query.EncodeUriComponent() + ".json", 10000)
    if type(j) = "roAssociativeArray" and type(j.metas) = "roArray"
        for each r in j.metas
            if type(r) = "roAssociativeArray" and Left(Str_Of(r.id), 2) = "tt"
                out.Push({ id: Str_Of(r.id), name: Str_Of(r.name), year: Left(Str_Any(r.releaseInfo), 4), names: [Str_Of(r.name)] })
            end if
        end for
    end if
    return out
end function

function Vod_Best(list as object, want as string, year as string, loose as boolean) as string
    best = ""
    bestScore = 0
    n = 0
    for each r in list
        n = n + 1
        if n > 10 then exit for
        score = 0
        for each nm in r.names
            sc = Vod_Score(want, Vod_Key(nm))
            if sc > score then score = sc
        end for
        if score > 0 and year <> "" and r.year = year then score = score + 1
        if score > bestScore
            best = r.id
            bestScore = score
        end if
    end for
    if best = "" and loose and list.Count() = 1 then best = list[0].id
    return best
end function

function Vod_Resolve(ref as string, kind as string) as string
    map = Vod_Map()
    if map.DoesExist("fix:" + ref) then return Str_Of(map["fix:" + ref])
    if map.DoesExist(ref)
        v = Str_Of(map[ref])
        if v = "-" then return ""
        return v
    end if
    hits = Vod_Find(ref)
    if hits.Count() = 0 then return ""
    found = ""
    for each h in hits
        if found = "" and h.tmdb <> "" then found = "tmdb:" + h.tmdb
    end for
    year = Vod_Year(hits[0])
    query = Vod_Query(hits[0].name)
    want = Vod_Key(query)
    if found = "" and want <> "" and year <> "" then found = Vod_Best(Vod_TmdbSearch(query, kind, year), want, year, true)
    if found = "" and want <> "" then found = Vod_Best(Vod_TmdbSearch(query, kind, ""), want, year, false)
    if found = "" and want <> "" then found = Vod_Best(Vod_CinemetaSearch(query, kind), want, year, false)
    Vod_Trim(map)
    if found = "" then map[ref] = "-" else map[ref] = found
    if found <> "" then map[found] = ref
    Vod_SaveMap(map)
    Dbg_Log("vod resolve " + ref + " -> " + found)
    return found
end function

function Vod_Candidates(query as string, kind as string) as object
    clean = Vod_Clean(query)
    list = Vod_TmdbSearch(clean.title, kind, clean.year)
    if list.Count() = 0 and clean.year <> "" then list = Vod_TmdbSearch(clean.title, kind, "")
    if list.Count() = 0 then list = Vod_CinemetaSearch(clean.title, kind)
    out = []
    for each r in list
        if out.Count() >= 8 then exit for
        out.Push({ id: r.id, name: r.name, year: r.year })
    end for
    return out
end function

sub Vod_Fix(ref as string, id as string)
    map = Vod_Map()
    Vod_Trim(map)
    old = Str_Of(map["fix:" + ref])
    if old = "" then old = Str_Of(map[ref])
    if old <> "" and old <> "-" and Str_Of(map[old]) = ref then map.Delete(old)
    map.Delete(ref)
    map.Delete("fix:" + ref)
    if id <> ""
        map["fix:" + ref] = id
        map[id] = ref
    end if
    Vod_SaveMap(map)
end sub

sub Vod_Link(ref as string, ids as object)
    map = Vod_Map()
    Vod_Trim(map)
    changed = false
    for each one in ids
        v = Str_Of(one)
        if v <> "" and Str_Of(map[v]) <> ref
            map[v] = ref
            changed = true
        end if
    end for
    if changed then Vod_SaveMap(map)
end sub

function Vod_Episodes(hit as object) as object
    g = Vod_Group(hit.gid)
    out = []
    if g = invalid then return out
    if Str_Of(g.src) = "xtream"
        lines = Vod_Lines(hit.gid)
        if hit.line < 0 or hit.line >= lines.Count() then return out
        f = Vod_Split(lines[hit.line])
        if f.Count() < 5 then return out
        x = g.x
        api = Str_Of(x.base) + "/player_api.php?username=" + Str_Of(x.user).EncodeUriComponent() + "&password=" + Str_Of(x.pass).EncodeUriComponent()
        j = Http_FetchJson(api + "&action=get_series_info&series_id=" + f[4], 20000)
        if type(j) <> "roAssociativeArray" or type(j.episodes) <> "roAssociativeArray" then return out
        for each sk in j.episodes
            list = j.episodes[sk]
            if type(list) = "roArray"
                for each ep in list
                    if type(ep) = "roAssociativeArray"
                        ext = Str_Of(ep.container_extension)
                        if ext = "" then ext = "mp4"
                        thumb = ""
                        if type(ep.info) = "roAssociativeArray" then thumb = Str_Of(ep.info.movie_image)
                        out.Push({ s: ToInt(ep.season, ToInt(sk, 1)), e: ToInt(ep.episode_num, 0), title: Str_Of(ep.title), thumb: thumb, url: Str_Of(x.base) + "/series/" + Str_Of(x.user) + "/" + Str_Of(x.pass) + "/" + Str_Any(ep.id) + "." + ext })
                    end if
                end for
            end if
        end for
        return out
    end if
    want = hit.key.Split("~")[0]
    for each ln in Vod_Lines(hit.gid)
        f = Vod_Split(ln)
        if f.Count() >= 7
            if Vod_Key(f[1]) = want then out.Push({ s: ToInt(f[5], 1), e: ToInt(f[6], 0), title: "", thumb: "", url: Vod_Unpack(g, "ub", f[4]) })
        end if
    end for
    return out
end function

function Vod_Meta(ref as string, kind as string, withEpisodes as boolean) as object
    hits = Vod_Find(ref)
    meta = { id: ref, kind: kind, name: "", poster: "", background: "", description: "", videos: [], iptv: ref }
    if hits.Count() = 0 then return meta
    meta.name = hits[0].name
    meta.poster = hits[0].logo
    year = Vod_Year(hits[0])
    if year <> "" then meta.releaseInfo = year
    if kind = "series" and withEpisodes
        seen = {}
        for each h in hits
            for each ep in Vod_Episodes(h)
                vid = ref + ":" + ep.s.ToStr() + ":" + ep.e.ToStr()
                if not seen.DoesExist(vid)
                    seen[vid] = true
                    title = ep.title
                    if title = "" then title = L("Episodio ") + ep.e.ToStr()
                    meta.videos.Push({ id: vid, season: ep.s, episode: ep.e, name: title, title: title, thumbnail: ep.thumb })
                end if
            end for
        end for
    end if
    return meta
end function

sub Vod_AddHits(all as object, seen as object, hits as object)
    for each h in hits
        k = h.gid.ToStr() + ":" + h.line.ToStr()
        if not seen.DoesExist(k)
            seen[k] = true
            all.Push(h)
        end if
    end for
end sub

function Vod_Streams(title as string, kind as string, ids as object) as object
    out = []
    info = Vod_Info()
    if info = invalid then return out
    map = Vod_Map()
    series = LCase(kind) <> "movie"
    k = "movie"
    if series then k = "series"
    refs = []
    tmdbIds = []
    imdb = ""
    season = -1
    episode = -1
    for each vid in ids
        parts = Str_Of(vid).Split(":")
        if parts.Count() >= 3 and season < 0
            n = parts.Count()
            season = ToInt(parts[n - 2], -1)
            episode = ToInt(parts[n - 1], -1)
        end if
        if Vod_IsRef(Str_Of(vid))
            refs.Push(parts[0] + ":" + parts[1])
        else
            base = parts[0]
            if LCase(base) = "tmdb" and parts.Count() > 1
                base = "tmdb:" + parts[1]
                tmdbIds.Push(parts[1])
            end if
            if Left(base, 2) = "tt" then imdb = base
            if map.DoesExist(base) and Vod_IsRef(Str_Of(map[base])) then refs.Push(Str_Of(map[base]))
        end if
    end for
    for each r in refs
        if map.DoesExist("fix:" + r)
            fixed = Str_Of(map["fix:" + r])
            if Left(fixed, 5) = "tmdb:" then tmdbIds.Push(Mid(fixed, 6))
        end if
    end for
    if tmdbIds.Count() = 0 and imdb <> "" and ToInt(info.tmdb, 0) > 0
        key = Key_Tmdb(St_Integrations())
        if key <> ""
            media = "movie_results"
            if series then media = "tv_results"
            j = Http_FetchJson("https://api.themoviedb.org/3/find/" + imdb + "?external_source=imdb_id&api_key=" + key, 8000)
            if type(j) = "roAssociativeArray" and type(j[media]) = "roArray" and j[media].Count() > 0 then tmdbIds.Push(Str_Any(j[media][0].id))
        end if
    end if
    hits = []
    seenHit = {}
    for each r in refs
        Vod_AddHits(hits, seenHit, Vod_Find(r))
    end for
    for each t in tmdbIds
        Vod_AddHits(hits, seenHit, Vod_FindTmdb(t, k))
    end for
    if hits.Count() = 0 and title <> "" then Vod_AddHits(hits, seenHit, Vod_FindByTitle(title, k, ""))
    seen = {}
    epCount = 0
    for each h in hits
        g = Vod_Group(h.gid)
        gname = ""
        if g <> invalid then gname = Str_Of(g.name)
        desc = gname
        if h.tag <> "" then desc = h.tag + Chr(10) + gname
        desc = desc + Chr(10) + h.name
        if series
            if season >= 0 and episode > 0
                eps = Vod_Episodes(h)
                epCount = epCount + eps.Count()
                for each ep in eps
                    if ep.s = season and ep.e = episode and not seen.DoesExist(ep.url)
                        seen[ep.url] = true
                        out.Push({ name: "IPTV", desc: desc, url: ep.url, filename: Vod_File(ep.url) })
                    end if
                end for
            end if
        else
            lines = Vod_Lines(h.gid)
            if h.line >= 0 and h.line < lines.Count()
                f = Vod_Split(lines[h.line])
                if f.Count() >= 5
                    url = Vod_Unpack(g, "ub", f[4])
                    if not seen.DoesExist(url)
                        seen[url] = true
                        out.Push({ name: "IPTV", desc: desc, url: url, filename: Vod_File(url) })
                    end if
                end if
            end if
        end if
    end for
    Dbg_Log("vod streams " + k + " ids=" + FormatJson(ids) + " refs=" + FormatJson(refs) + " tmdb=" + FormatJson(tmdbIds) + " hits=" + hits.Count().ToStr() + " eps=" + epCount.ToStr() + " found=" + out.Count().ToStr())
    return out
end function

function Vod_File(url as string) as string
    u = url
    q = Instr(1, u, "?")
    if q > 0 then u = Left(u, q - 1)
    parts = u.Split("/")
    return parts[parts.Count() - 1]
end function
