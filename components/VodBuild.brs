function Vod_MaxItems() as integer
    return 25000
end function

sub Vod_Begin(sig as string)
    current = Vod_Dir()
    root = "cachefs:/iptv_vod_" + Vod_Pid()
    dir = root + "_a_"
    if current = dir then dir = root + "_b_"
    Vod_Clear(dir)
    m.vod = { dir: dir, sig: sig + "|2", groups: [], gidOf: {}, bufs: {}, sizes: {}, counts: {}, shows: {}, idx: [], idxSize: 0, total: 0, tmdb: 0, xtream: [] }
end sub

sub Vod_Clear(prefix as string)
    fs = CreateObject("roFileSystem")
    name = Mid(prefix, Len("cachefs:/") + 1)
    for each f in fs.GetDirectoryListing("cachefs:/")
        if Left(f, Len(name)) = name then fs.Delete("cachefs:/" + f)
    end for
end sub

function Vod_Building() as boolean
    return m.vod <> invalid
end function

function Vod_GroupId(name as string, kind as string, src as string, x as dynamic) as integer
    gk = kind + "|" + name
    if m.vod.gidOf.DoesExist(gk) then return m.vod.gidOf[gk]
    gid = m.vod.groups.Count()
    g = { id: gid, name: name, kind: kind, src: src, n: 0, ub: invalid, lb: invalid }
    if x <> invalid then g.x = x
    m.vod.groups.Push(g)
    m.vod.gidOf[gk] = gid
    gs = gid.ToStr()
    m.vod.bufs[gs] = []
    m.vod.sizes[gs] = 0
    m.vod.counts[gs] = 0
    m.vod.shows[gs] = {}
    return gid
end function

function Vod_Field(s as string) as string
    if Instr(1, s, Chr(9)) > 0 then s = s.Replace(Chr(9), " ")
    if Instr(1, s, Chr(13)) > 0 then s = s.Replace(Chr(13), "")
    return s
end function

function Vod_Base(url as string) as string
    q = Instr(1, url, "?")
    path = url
    if q > 0 then path = Left(url, q - 1)
    cut = 0
    p = Instr(1, path, "/")
    while p > 0
        cut = p
        p = Instr(p + 1, path, "/")
    end while
    if cut < 9 then return ""
    return Left(url, cut)
end function

function Vod_Pack(g as object, field as string, value as string) as string
    if value = "" then return ""
    base = g[field]
    if base = invalid
        base = Vod_Base(value)
        g[field] = base
    end if
    if base <> "" and Left(value, Len(base)) = base then return "~" + Mid(value, Len(base) + 1)
    return value
end function

sub Vod_Write(gid as integer, kind as string, letter as string, title as string, year as string, logo as string, tail as string, key as string, tmdb as string)
    v = m.vod
    if v.total >= Vod_MaxItems() or key = "" then return
    gs = gid.ToStr()
    g = v.groups[gid]
    line = v.counts[gs]
    text = letter + Chr(9) + Vod_Field(title) + Chr(9) + year + Chr(9) + Vod_Field(Vod_Pack(g, "lb", logo)) + Chr(9) + tail
    v.bufs[gs].Push(text)
    v.sizes[gs] = v.sizes[gs] + Len(text) + 1
    v.counts[gs] = line + 1
    v.total = v.total + 1
    k = "m"
    if kind = "series" then k = "s"
    sk = key + "~" + year
    shows = v.shows[gs]
    isNew = not shows.DoesExist(sk)
    if isNew
        shows[sk] = true
        g.n = g.n + 1
    end if
    if isNew or kind <> "series"
        row = key + "~" + year + Chr(9) + k + Chr(9) + gs + Chr(9) + line.ToStr()
        if tmdb <> ""
            row = row + Chr(9) + "T" + tmdb
            v.tmdb = v.tmdb + 1
        end if
        v.idx.Push(row)
        v.idxSize = v.idxSize + Len(row) + 1
        if v.idxSize > 65536 then Vod_FlushIdx()
    end if
    if v.sizes[gs] > 32768 then Vod_FlushGroup(gs)
end sub

sub Vod_Append(path as string, lines as object)
    if lines.Count() = 0 then return
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(lines.Join(Chr(10)) + Chr(10))
    if CreateObject("roFileSystem").Exists(path) then ba.AppendFile(path) else ba.WriteFile(path)
end sub

sub Vod_FlushGroup(gs as string)
    Vod_Append(m.vod.dir + "g" + gs + ".tsv", m.vod.bufs[gs])
    m.vod.bufs[gs] = []
    m.vod.sizes[gs] = 0
end sub

sub Vod_FlushIdx()
    Vod_Append(m.vod.dir + "idx.tsv", m.vod.idx)
    m.vod.idx = []
    m.vod.idxSize = 0
end sub

function Vod_EpMatch(name as string, isSeries as boolean) as dynamic
    if m.vodEpRes = invalid
        sep = "[\s._\-\[\(]"
        m.vodEpRes = [
            CreateObject("roRegex", "^(.*?)" + sep + "*[Ss](\d{1,2})[\s._\-]*[Ee](\d{1,3})(?!\d)", ""),
            CreateObject("roRegex", "^(.*?)" + sep + "+[Tt](\d{1,2})[\s._\-]*[EeCc](\d{1,3})(?!\d)", ""),
            CreateObject("roRegex", "^(.*?)" + sep + "+(\d{1,2})[xX](\d{2,3})(?!\d)", ""),
            CreateObject("roRegex", "^(.*?)" + sep + "*(?:temporada|temp\.?|season)\s*(\d{1,2})[\s,._\-:]*(?:cap\S{1,2}tulo|cap\.?|episodio|episode|ep\.?|e)\s*(\d{1,3})(?!\d)", "i")
        ]
        m.vodEpOnly = CreateObject("roRegex", "^(.*?)" + sep + "+(?:cap\S{1,2}tulo|cap\.?|episodio|episode|ep\.?|e)\s*(\d{1,3})(?!\d)", "i")
    end if
    for each re in m.vodEpRes
        found = re.Match(name)
        if found.Count() > 3 and found[1].Trim() <> "" then return { show: found[1].Trim(), s: ToInt(found[2], 1), e: ToInt(found[3], 0) }
    end for
    if isSeries
        found = m.vodEpOnly.Match(name)
        if found.Count() > 2 and found[1].Trim() <> "" then return { show: found[1].Trim(), s: 1, e: ToInt(found[2], 0) }
    end if
    return invalid
end function

sub Vod_AddM3u(entry as object, url as string)
    if m.vod.total >= Vod_MaxItems() then return
    name = Str_Of(entry.n)
    kind = "movie"
    seriesUrl = Instr(1, LCase(url), "/series/") > 0
    ep = Vod_EpMatch(name, seriesUrl)
    if ep <> invalid or seriesUrl then kind = "series"
    group = Str_Of(entry.g)
    if group = "" then group = L("Sin grupo")
    gid = Vod_GroupId(group, kind, "m3u", invalid)
    g = m.vod.groups[gid]
    if kind = "series"
        show = name
        s = 1
        e = 0
        if ep <> invalid
            show = ep.show
            s = ep.s
            e = ep.e
        end if
        clean = Vod_Clean(show)
        Vod_Write(gid, kind, "E", clean.title, clean.year, Str_Of(entry.l), Vod_Field(Vod_Pack(g, "ub", url)) + Chr(9) + s.ToStr() + Chr(9) + e.ToStr() + Chr(9) + Vod_Tag(name), Vod_Key(clean.title), "")
    else
        clean = Vod_Clean(name)
        Vod_Write(gid, kind, "M", clean.title, clean.year, Str_Of(entry.l), Vod_Field(Vod_Pack(g, "ub", url)) + Chr(9) + Vod_Tag(name) + Chr(9), Vod_Key(clean.title), "")
    end if
end sub

sub Vod_QueueXtream(lst as object)
    if m.vod <> invalid then m.vod.xtream.Push(lst)
end sub

sub Vod_Xtream(lst as object)
    base = Iptv_Server(Str_Of(lst.server))
    x = { base: base, user: Str_Of(lst.user), pass: Str_Of(lst.pass) }
    api = base + "/player_api.php?username=" + x.user.EncodeUriComponent() + "&password=" + x.pass.EncodeUriComponent()
    for each mode in ["vod", "series"]
        r = Iptv_Fetch(api + "&action=get_" + mode + "_categories", 30000)
        cats = ParseJson(r.body)
        r = invalid
        if type(cats) = "roArray"
            done = 0
            for each c in cats
                if m.vod.total >= Vod_MaxItems() or done >= 150 then exit for
                if type(c) = "roAssociativeArray"
                    done = done + 1
                    cid = Str_Any(c.category_id)
                    cname = Str_Of(c.category_name)
                    if mode = "vod" then action = "get_vod_streams" else action = "get_series"
                    r = Iptv_Fetch(api + "&action=" + action + "&category_id=" + cid.EncodeUriComponent(), 60000)
                    list = ParseJson(r.body)
                    r = invalid
                    if type(list) = "roArray" and list.Count() > 0
                        kind = "movie"
                        if mode = "series" then kind = "series"
                        gid = Vod_GroupId(cname, kind, "xtream", x)
                        g = m.vod.groups[gid]
                        n = 0
                        for each s in list
                            if n >= 2000 or m.vod.total >= Vod_MaxItems() then exit for
                            if type(s) = "roAssociativeArray"
                                n = n + 1
                                rawName = Str_Of(s.name)
                                clean = Vod_Clean(rawName)
                                tmdb = Vod_Digits(Str_Any(s.tmdb))
                                if tmdb = "" then tmdb = Vod_Digits(Str_Any(s.tmdb_id))
                                year = Left(Str_Any(s.year), 4)
                                if ToInt(year, 0) < 1900 then year = Left(Str_Any(s.releaseDate), 4)
                                if ToInt(year, 0) < 1900 then year = clean.year
                                key = Vod_Key(clean.title)
                                if mode = "vod"
                                    ext = Str_Of(s.container_extension)
                                    if ext = "" then ext = "mp4"
                                    url = base + "/movie/" + x.user + "/" + x.pass + "/" + Str_Any(s.stream_id) + "." + ext
                                    Vod_Write(gid, kind, "M", clean.title, year, Str_Of(s.stream_icon), Vod_Field(Vod_Pack(g, "ub", url)) + Chr(9) + Vod_Tag(rawName) + Chr(9) + tmdb, key, tmdb)
                                else
                                    Vod_Write(gid, kind, "S", clean.title, year, Str_Of(s.cover), Str_Any(s.series_id) + Chr(9) + Vod_Tag(rawName) + Chr(9) + tmdb, key, tmdb)
                                end if
                            end if
                        end for
                    end if
                    list = invalid
                end if
            end for
        end if
        cats = invalid
    end for
end sub

function Vod_Finish() as boolean
    v = m.vod
    if v = invalid then return false
    for each lst in v.xtream
        Vod_Xtream(lst)
    end for
    for each gs in v.bufs
        Vod_FlushGroup(gs)
    end for
    Vod_FlushIdx()
    kept = []
    names = []
    for each g in v.groups
        if g.n > 0
            if g.ub = invalid then g.ub = ""
            if g.lb = invalid then g.lb = ""
            kept.Push(g)
            names.Push(g.kind + "|" + g.name)
        end if
    end for
    shape = names.Join(Chr(10))
    old = Vod_Info()
    oldShape = ""
    if old <> invalid then oldShape = Str_Of(old.shape)
    WriteAsciiFile(v.dir + "groups.json", FormatJson({ sig: v.sig, at: CreateObject("roDateTime").AsSeconds(), total: v.total, tmdb: v.tmdb, shape: shape, groups: kept }))
    WriteAsciiFile(Vod_Pointer(), v.dir)
    m.vodInfo = invalid
    m.vodLines = invalid
    m.vod = invalid
    Dbg_Log("vod built groups=" + kept.Count().ToStr() + " items=" + v.total.ToStr())
    return shape <> oldShape
end function

function Vod_Digits(v as string) as string
    t = v.Trim()
    if t = "" or t = "0" then return ""
    for i = 1 to Len(t)
        ch = Mid(t, i, 1)
        if ch < "0" or ch > "9" then return ""
    end for
    return t
end function

function Vod_Tag(raw as string) as string
    if m.vodTagTok = invalid
        m.vodTagTok = { "4K": "4K", "UHD": "4K", "2160P": "4K", "FHD": "1080p", "1080P": "1080p", "HD": "HD", "720P": "720p", "SD": "SD", "HDR": "HDR", "LAT": "LAT", "LATINO": "LAT", "CAST": "CAST", "ES": "ES", "EN": "EN", "SUB": "SUB", "SUBS": "SUB", "VOSE": "SUB", "DUAL": "DUAL", "MULTI": "MULTI" }
        m.vodTagSplit = CreateObject("roRegex", "[^A-Za-z0-9]+", "")
    end if
    out = []
    seen = {}
    for each tok in m.vodTagSplit.Split(raw)
        if tok <> "" and tok = UCase(tok) and m.vodTagTok.DoesExist(tok)
            v = m.vodTagTok[tok]
            if not seen.DoesExist(v)
                seen[v] = true
                out.Push(v)
                if out.Count() >= 3 then exit for
            end if
        end if
    end for
    return out.Join(" · ")
end function

function Vod_Fresh(sig as string) as boolean
    info = Vod_Info()
    if info = invalid then return false
    if Str_Of(info.sig) <> sig + "|2" then return false
    return Abs(CreateObject("roDateTime").AsSeconds() - ToInt(info.at, 0)) < Iptv_Prefs().listHours * 3600
end function
