function Iptv_FavKey() as string
    return "iptvFavs_" + St_ActiveProfile().id
end function

function Iptv_Favs() as object
    v = St_Get(Iptv_FavKey(), invalid)
    if type(v) = "roArray" then return v
    return []
end function

function Iptv_Attr(line as string, name as string) as string
    q = Chr(34)
    key = name + "=" + q
    p = Instr(1, LCase(line), LCase(key))
    if p = 0 then return ""
    p = p + Len(key)
    e = Instr(p, line, q)
    if e = 0 then return ""
    return Mid(line, p, e - p).Trim()
end function

function Iptv_Server(url as string) as string
    a = url.Trim()
    if a = "" then return ""
    if Instr(1, a, "://") = 0 then a = "http://" + a
    while Right(a, 1) = "/"
        a = Left(a, Len(a) - 1)
    end while
    for each tail in ["/player_api.php", "/get.php"]
        p = Instr(1, LCase(a), tail)
        if p > 0 then a = Left(a, p - 1)
    end for
    return a
end function

function Iptv_Fetch(url as string, timeoutMs as integer) as object
    port = CreateObject("roMessagePort")
    t = Http_Transfer(url, port, "VLC/3.0.20 LibVLC/3.0.20")
    out = { code: 0, body: "" }
    if not t.AsyncGetToString() then return out
    msg = wait(timeoutMs, port)
    if type(msg) = "roUrlEvent"
        out.code = msg.GetResponseCode()
        out.body = msg.GetString()
    else
        t.AsyncCancel()
    end if
    return out
end function

function Iptv_FetchFile(url as string, path as string, timeoutMs as integer, info = invalid as dynamic) as integer
    port = CreateObject("roMessagePort")
    t = Http_Transfer(url, port, "VLC/3.0.20 LibVLC/3.0.20")
    if not t.AsyncGetToFile(path) then return 0
    clock = CreateObject("roTimespan")
    fs = CreateObject("roFileSystem")
    while clock.TotalMilliseconds() < timeoutMs
        msg = wait(10000, port)
        if type(msg) = "roUrlEvent" then return msg.GetResponseCode()
        if info <> invalid
            mb = 0
            st = fs.Stat(path)
            if st <> invalid and st.size <> invalid then mb = Int(st.size / 1048576)
            Iptv_Progress({ step: info.step, i: info.i, n: info.n, mb: mb })
        end if
    end while
    t.AsyncCancel()
    return 0
end function

function Iptv_PlayUrl(url as string) as string
    u = url.Trim()
    low = LCase(u)
    q = Instr(1, low, "?")
    path = low
    if q > 0 then path = Left(low, q - 1)
    if Right(path, 3) = ".ts"
        cut = Len(path) - 3
        return Left(u, cut) + ".m3u8" + Mid(u, Len(path) + 1)
    end if
    return u
end function

function Iptv_ParseM3u(path as string, lst as object, out as object, epgs as object) as integer
    fs = CreateObject("roFileSystem")
    st = fs.Stat(path)
    if st = invalid or st.size = invalid or st.size = 0 then return -1
    size = st.size
    ba = CreateObject("roByteArray")
    ba.ReadFile(path, 0, 2)
    if ba.Count() >= 2 and ba[0] = 31 and ba[1] = 139 then return -1
    state = { pending: invalid, count: 0, seen: false, lid: Str_Of(lst.id), group: L("Sin grupo") }
    offset = 0
    chunk = 262144
    while offset < size and (state.count < Iptv_MaxChannels() or (Vod_Building() and m.vod.total < Vod_MaxItems()))
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
        end if
        if cut < n then ba.ReadFile(path, offset, cut)
        offset = offset + cut
        Iptv_M3uLines(ba.ToAsciiString().Split(Chr(10)), state, out, epgs)
    end while
    if not state.seen then return -1
    return state.count
end function

function Iptv_MaxChannels() as integer
    return 20000
end function

function Iptv_IsVod(url as string) as boolean
    low = LCase(url)
    if Instr(1, low, "/movie/") > 0 or Instr(1, low, "/series/") > 0 then return true
    q = Instr(1, low, "?")
    if q > 0 then low = Left(low, q - 1)
    for each ext in [".mp4", ".mkv", ".avi", ".mov", ".wmv", ".m4v"]
        if Right(low, Len(ext)) = ext then return true
    end for
    return false
end function

sub Iptv_M3uLines(lines as object, state as object, out as object, epgs as object)
    for each raw in lines
        line = raw.Trim()
        if line = ""
        else if Left(line, 7) = "#EXTM3U"
            for each attr in ["url-tvg", "x-tvg-url", "tvg-url"]
                v = Iptv_Attr(line, attr)
                if v <> ""
                    for each one in v.Split(",")
                        if one.Trim() <> "" then epgs.Push(one.Trim())
                    end for
                end if
            end for
        else if Left(line, 7) = "#EXTINF"
            state.seen = true
            pieces = line.Split(Chr(34))
            last = pieces[pieces.Count() - 1]
            comma = Instr(1, last, ",")
            name = ""
            if comma > 0 then name = Mid(last, comma + 1).Trim()
            tvgName = Iptv_Attr(line, "tvg-name")
            if name = "" then name = tvgName
            state.pending = { n: name, l: Iptv_Attr(line, "tvg-logo"), g: Iptv_Attr(line, "group-title"), e: Iptv_Attr(line, "tvg-id"), t: Iptv_Attr(line, "tvg-id") }
            if state.pending.e = "" then state.pending.e = tvgName
        else if Left(line, 1) = "#"
            if state.pending <> invalid and Left(line, 8) = "#EXTGRP:" then state.pending.g = Mid(line, 9).Trim()
        else if state.pending <> invalid
            pending = state.pending
            state.pending = invalid
            if Iptv_IsVod(line)
                if Vod_Building() then Vod_AddM3u(pending, line)
            else if state.count < Iptv_MaxChannels()
                pending.u = line
                key = pending.e
                if key = "" then key = pending.n
                pending.k = state.lid + ":" + key + ":" + state.count.ToStr()
                pending.s = state.lid
                if pending.g = "" then pending.g = state.group
                out.Push(pending)
                state.count = state.count + 1
            end if
        end if
    end for
end sub

function Iptv_Xtream(lst as object, out as object, epgs as object) as integer
    base = Iptv_Server(Str_Of(lst.server))
    user = Str_Of(lst.user).EncodeUriComponent()
    pass = Str_Of(lst.pass).EncodeUriComponent()
    api = base + "/player_api.php?username=" + user + "&password=" + pass
    cats = {}
    r = Iptv_Fetch(api + "&action=get_live_categories", 30000)
    j = ParseJson(r.body)
    if type(j) = "roArray"
        for each c in j
            if type(c) = "roAssociativeArray" then cats[Str_Any(c.category_id)] = Str_Of(c.category_name)
        end for
    end if
    r = Iptv_Fetch(api + "&action=get_live_streams", 90000)
    j = ParseJson(r.body)
    if type(j) <> "roArray" then return -1
    lid = Str_Of(lst.id)
    count = 0
    for each s in j
        if type(s) = "roAssociativeArray"
            sid = Str_Any(s.stream_id)
            g = cats[Str_Any(s.category_id)]
            if g = invalid or g = "" then g = L("Sin grupo")
            out.Push({ k: lid + ":" + sid, n: Str_Of(s.name), l: Str_Of(s.stream_icon), g: g, e: Str_Of(s.epg_channel_id), t: Str_Of(s.epg_channel_id), s: lid, u: base + "/live/" + Str_Of(lst.user) + "/" + Str_Of(lst.pass) + "/" + sid + ".m3u8" })
            count = count + 1
            if count >= Iptv_MaxChannels() then exit for
        end if
    end for
    epgs.Push(base + "/xmltv.php?username=" + user + "&password=" + pass)
    return count
end function

function Iptv_Load(force as boolean) as object
    lists = Iptv_Lists()
    cache = "cachefs:/iptv_channels_" + Iptv_Pid() + ".json"
    if not force
        raw = ReadAsciiFile(cache)
        if raw <> ""
            j = ParseJson(raw)
            if type(j) = "roAssociativeArray" and type(j.channels) = "roArray" and Str_Of(j.sig) = Iptv_Sig(lists) and Abs(CreateObject("roDateTime").AsSeconds() - ToInt(j.at, 0)) < Iptv_Prefs().listHours * 3600 and Vod_Fresh(Iptv_Sig(lists))
                if type(j.listEpg) = "roAssociativeArray" then WriteAsciiFile("cachefs:/iptv_epgs_" + Iptv_Pid() + ".json", FormatJson(j.listEpg))
                return { ok: true, channels: j.channels, epgs: j.epgs, errors: [] }
            end if
        end if
    end if
    channels = []
    epgs = []
    errors = []
    listEpg = {}
    Vod_Begin(Iptv_Sig(lists))
    for each lst in lists
        if lst.on <> false
            extra = []
            n = 0
            if Str_Of(lst.type) = "xtream"
                n = Iptv_Xtream(lst, channels, extra)
                if n >= 0 then Vod_QueueXtream(lst)
            else
                tmp = "cachefs:/iptv_list.m3u"
                DeleteFile(tmp)
                code = Iptv_FetchFile(Iptv_RawUrl(Str_Of(lst.url)), tmp, 180000)
                if code >= 200 and code < 300 then n = Iptv_ParseM3u(tmp, lst, channels, extra) else n = -1
                DeleteFile(tmp)
                Dbg_Log("iptv list " + Str_Of(lst.name) + " code=" + code.ToStr() + " channels=" + n.ToStr())
            end if
            if n < 0 then errors.Push(Str_Of(lst.name))
            own = Iptv_GuideUrls(lst, { list: extra })
            listEpg[lst.id] = { custom: Str_Of(lst.epg).Trim() <> "", urls: own, list: extra }
            for each e in own
                dup = false
                for each prev in epgs
                    if prev = e then dup = true
                end for
                if not dup then epgs.Push(e)
            end for
        end if
    end for
    channels = Iptv_Merge(channels)
    WriteAsciiFile("cachefs:/iptv_epgs_" + Iptv_Pid() + ".json", FormatJson(listEpg))
    WriteAsciiFile(cache, FormatJson({ sig: Iptv_Sig(lists), at: CreateObject("roDateTime").AsSeconds(), channels: channels, epgs: epgs, listEpg: listEpg }))
    vodChanged = false
    if m.vod.xtream.Count() = 0 then vodChanged = Vod_Finish()
    return { ok: true, channels: channels, epgs: epgs, errors: errors, vodChanged: vodChanged }
end function

function Iptv_RawUrl(url as string) as string
    u = url.Trim()
    low = LCase(u)
    if Left(low, 19) = "https://github.com/" and Instr(1, low, "/blob/") > 0
        rest = Mid(u, 20)
        rest = rest.Replace("/blob/", "/")
        return "https://raw.githubusercontent.com/" + rest
    end if
    if Left(low, 19) = "https://github.com/" and Instr(1, low, "/raw/") > 0
        rest = Mid(u, 20)
        rest = rest.Replace("/raw/", "/")
        return "https://raw.githubusercontent.com/" + rest
    end if
    return u
end function

function Iptv_Merge(channels as object) as object
    merged = []
    byId = {}
    for each c in channels
        gid = LCase(Str_Of(c.t).Trim())
        if gid <> "" and byId.DoesExist(gid)
            merged[byId[gid]].a.Push({ u: c.u, n: c.n })
        else
            c.a = [{ u: c.u, n: c.n }]
            if gid <> "" then byId[gid] = merged.Count()
            merged.Push(c)
        end if
    end for
    return merged
end function

function Iptv_Sig(lists as object) as string
    parts = ["v3"]
    for each lst in lists
        parts.Push(Str_Of(lst.id) + "|" + Str_Of(lst.url) + "|" + Str_Of(lst.server) + "|" + Str_Of(lst.user) + "|" + Str_Of(lst.epg) + "|" + Bool_Of(lst.on, true).ToStr())
    end for
    return parts.Join(",")
end function

function Iptv_Shard(id as string) as integer
    h = 0
    for i = 1 to Len(id)
        h = (h * 31 + Asc(Mid(id, i, 1))) mod 65521
    end for
    return h mod 128
end function

function Iptv_Unescape(s as string) as string
    if Instr(1, s, "&") = 0 then return s
    out = s.Replace("&lt;", "<").Replace("&gt;", ">").Replace("&quot;", Chr(34)).Replace("&apos;", "'").Replace("&#39;", "'").Replace("&#039;", "'")
    p = Instr(1, out, "&#")
    while p > 0
        e = Instr(p, out, ";")
        if e = 0 or e - p > 8 then exit while
        code = Mid(out, p + 2, e - p - 2)
        n = 0
        if LCase(Left(code, 1)) = "x" then n = Val(Mid(code, 2), 16) else n = Val(code)
        if n > 0 then out = Left(out, p - 1) + Chr(n) + Mid(out, e + 1) else exit while
        p = Instr(p, out, "&#")
    end while
    return out.Replace("&amp;", "&")
end function

function Iptv_Tag(block as string, tag as string) as string
    p = Instr(1, block, "<" + tag)
    if p = 0 then return ""
    s = Instr(p, block, ">")
    if s = 0 then return ""
    if Mid(block, s - 1, 1) = "/" then return ""
    e = Instr(s, block, "</" + tag + ">")
    if e = 0 then return ""
    v = Mid(block, s + 1, e - s - 1)
    if Left(v, 9) = "<![CDATA[" then v = Mid(v, 10, Len(v) - 12)
    return Iptv_Unescape(v.Trim())
end function

function Iptv_Time(v as string, dt as object) as integer
    t = v.Trim()
    if Len(t) < 14 then return 0
    dt.FromISO8601String(Mid(t, 1, 4) + "-" + Mid(t, 5, 2) + "-" + Mid(t, 7, 2) + "T" + Mid(t, 9, 2) + ":" + Mid(t, 11, 2) + ":" + Mid(t, 13, 2) + "Z")
    secs = dt.AsSeconds()
    rest = Mid(t, 15).Trim()
    if Len(rest) >= 5
        sign = Left(rest, 1)
        off = Mid(rest, 2, 2).ToInt() * 3600 + Mid(rest, 4, 2).ToInt() * 60
        if sign = "+" then secs = secs - off
        if sign = "-" then secs = secs + off
    end if
    return secs
end function

function Iptv_Epg(force as boolean, epgs as object, wanted as object) as object
    base = "cachefs:/iptv_epg_" + Iptv_Pid() + "/"
    stamp = base + "at.json"
    now = CreateObject("roDateTime").AsSeconds()
    sig = epgs.Join(",")
    if not force
        j = ParseJson(ReadAsciiFile(stamp))
        if type(j) = "roAssociativeArray" and Str_Of(j.sig) = sig and Abs(now - ToInt(j.at, 0)) < Iptv_Prefs().epgHours * 3600 and Str_Of(j.dir) <> "" and Iptv_EpgHasData(Str_Of(j.dir))
            WriteAsciiFile("tmp:/iptv_epg_dir_" + Iptv_Pid() + ".txt", Str_Of(j.dir))
            return { ok: true, cached: true, count: ToInt(j.count, 0) }
        end if
    end if
    fs = CreateObject("roFileSystem")
    pointer = "tmp:/iptv_epg_dir_" + Iptv_Pid() + ".txt"
    old = Iptv_EpgDir()
    hasOld = Iptv_EpgHasData(old)
    if hasOld then Iptv_Progress({ step: "ready" })
    if not fs.Exists(base) then fs.CreateDirectory(base)
    dir = base + "a/"
    if old = dir then dir = base + "b/"
    if not fs.Exists(base)
        dir = "tmp:/iptv_epg_" + Iptv_Pid() + "_a/"
        if old = dir then dir = "tmp:/iptv_epg_" + Iptv_Pid() + "_b/"
    end if
    Iptv_ClearDir(dir)
    if not fs.Exists(dir) then fs.CreateDirectory(dir)
    if not fs.Exists(dir)
        dir = "tmp:/iptv_epg_" + Iptv_Pid() + "_t/"
        Iptv_ClearDir(dir)
        fs.CreateDirectory(dir)
    end if
    fromT = now - 10800
    toT = now + 86400
    total = 0
    failed = []
    stats = {}
    nUrls = epgs.Count()
    i = 0
    for each url in epgs
        i = i + 1
        m.epgStep = { i: i, n: nUrls }
        Iptv_Progress({ step: "get", i: i, n: nUrls })
        big = "tmp:/"
        if fs.Exists("cachefs:/") or fs.Exists(base) then big = "cachefs:/"
        low = LCase(url)
        q = Instr(1, low, "?")
        if q > 0 then low = Left(low, q - 1)
        file = big + "iptv_epg_src.xml"
        if Right(low, 3) = ".gz" then file = "tmp:/iptv_epg_src.gz"
        fs.Delete("tmp:/iptv_epg_src.gz")
        fs.Delete(big + "iptv_epg_src.xml")
        code = Iptv_FetchFile(Iptv_RawUrl(url), file, 900000, { step: "get", i: i, n: nUrls })
        if code >= 200 and code < 300 and Iptv_IsGzip(file)
            Iptv_Progress({ step: "unzip", i: i, n: nUrls })
            plain = big + "iptv_epg_plain.xml"
            fs.Delete(plain)
            code = Iptv_FetchFile("http://127.0.0.1:8888/gz?f=" + file.EncodeUriComponent(), plain, 900000, { step: "unzip", i: i, n: nUrls })
            fs.Delete(file)
            file = plain
        end if
        n = -1
        cut = false
        if code >= 200 and code < 300
            cut = not Iptv_XmlComplete(file)
            n = Iptv_EpgParse(file, dir, wanted, fromT, toT)
        end if
        if n < 0 then failed.Push(url) else total = total + n
        stats[url] = { n: n, code: code, ch: ToInt(m.epgMatched, 0), cut: cut }
        fs.Delete(file)
        if total > 0 and not hasOld
            WriteAsciiFile(pointer, dir)
            Iptv_Progress({ step: "ready" })
        end if
    end for
    WriteAsciiFile("cachefs:/iptv_epgstat_" + Iptv_Pid() + ".json", FormatJson({ at: now, stats: stats }))
    if total > 0 or not hasOld
        WriteAsciiFile(pointer, dir)
        if Left(dir, 8) = "cachefs:" then WriteAsciiFile(stamp, FormatJson({ sig: sig, at: now, count: total, dir: dir }))
        if old <> dir then Iptv_ClearDir(old)
    else
        Iptv_ClearDir(dir)
    end if
    return { ok: true, count: total, failed: failed }
end function

sub Iptv_Progress(info as object)
    if m.top <> invalid and m.top.hasField("progress") then m.top.progress = info
end sub

sub Iptv_ClearDir(dir as string)
    fs = CreateObject("roFileSystem")
    if not fs.Exists(dir) then return
    for each f in fs.GetDirectoryListing(dir)
        if Right(f, 4) = ".tsv" then fs.Delete(dir + f)
    end for
end sub

function Iptv_EpgHasData(dir as string) as boolean
    fs = CreateObject("roFileSystem")
    if not fs.Exists(dir) then return false
    for each f in fs.GetDirectoryListing(dir)
        if Right(f, 4) = ".tsv" then return true
    end for
    return false
end function

function Iptv_XmlComplete(file as string) as boolean
    info = CreateObject("roFileSystem").Stat(file)
    if info = invalid or info.size = invalid then return false
    size = info.size
    want = 256
    if size < want then want = size
    ba = CreateObject("roByteArray")
    ba.ReadFile(file, size - want, want)
    return Instr(1, LCase(ba.ToAsciiString()), "</tv>") > 0
end function

function Iptv_IsGzip(file as string) as boolean
    head = CreateObject("roByteArray")
    head.ReadFile(file, 0, 2)
    return head.Count() >= 2 and head[0] = 31 and head[1] = 139
end function

function Iptv_EpgParse(file as string, dir as string, wanted as object, fromT as integer, toT as integer) as integer
    m.epgMatched = 0
    matched = {}
    ba = CreateObject("roByteArray")
    head = CreateObject("roByteArray")
    head.ReadFile(file, 0, 2)
    if head.Count() >= 2 and head[0] = 31 and head[1] = 139 then return -1
    size = CreateObject("roFileSystem").Stat(file).size
    if size = invalid then return -1
    dt = CreateObject("roDateTime")
    bufs = []
    sizes = []
    for i = 0 to 127
        bufs.Push([])
        sizes.Push(0)
    end for
    alias = {}
    chCache = {}
    offset = 0
    carry = ""
    count = 0
    chunk = 524288
    lastPct = 0
    q = Chr(34)
    while offset < size
        want = chunk
        if offset + want > size then want = size - offset
        ba.ReadFile(file, offset, want)
        n = ba.Count()
        if n = 0 then exit while
        cut = n
        if offset + n < size
            while cut > 0 and ba[cut - 1] <> 62
                cut = cut - 1
            end while
            if cut = 0 then cut = n
        end if
        if cut < n then ba.ReadFile(file, offset, cut)
        s = carry + ba.ToAsciiString()
        offset = offset + cut
        pct = Int(offset * 100.0 / size)
        if pct >= lastPct + 5
            lastPct = pct
            st0 = m.epgStep
            if st0 = invalid then st0 = { i: 1, n: 1 }
            Iptv_Progress({ step: "read", i: st0.i, n: st0.n, pct: pct })
        end if
        p = 1
        carry = ""
        cst = Instr(1, s, "<channel ")
        while true
            if cst > 0 and cst < p then cst = Instr(p, s, "<channel ")
            st = Instr(p, s, "<programme")
            if cst > 0 and (st = 0 or cst < st)
                cen = Instr(cst, s, "</channel>")
                if cen = 0
                    carry = Mid(s, cst)
                    exit while
                end if
                cblock = Mid(s, cst, cen - cst)
                p = cen + 10
                cid = LCase(Iptv_Unescape(Iptv_Attr(Left(cblock, Instr(1, cblock, ">")), "id")))
                if cid <> "" and not wanted.DoesExist(cid)
                    dn = Instr(1, cblock, "<display-name")
                    while dn > 0
                        ds = Instr(dn, cblock, ">")
                        de = Instr(dn, cblock, "</display-name>")
                        if ds = 0 or de = 0 then exit while
                        nm = LCase(Iptv_Unescape(Mid(cblock, ds + 1, de - ds - 1).Trim()))
                        if wanted.DoesExist(nm)
                            alias[cid] = nm
                            chCache = {}
                            exit while
                        end if
                        dn = Instr(de, cblock, "<display-name")
                    end while
                end if
            else
                if st = 0 then exit while
                gt = Instr(st, s, ">")
                if gt = 0
                    carry = Mid(s, st)
                    exit while
                end if
                attrs = Mid(s, st, gt - st + 1)
                raw = Iptv_Attr(attrs, "channel")
                if chCache.DoesExist(raw)
                    ch = chCache[raw]
                else
                    ch = LCase(Iptv_Unescape(raw))
                    if alias.DoesExist(ch) then ch = alias[ch]
                    if not wanted.DoesExist(ch) then ch = ""
                    chCache[raw] = ch
                end if
                keep = false
                if ch <> ""
                    stop1 = Iptv_Time(Iptv_Attr(attrs, "stop"), dt)
                    if stop1 > fromT
                        start1 = Iptv_Time(Iptv_Attr(attrs, "start"), dt)
                        keep = start1 < toT and stop1 > start1
                    end if
                end if
                if keep
                    en = Instr(gt, s, "</programme>")
                    if en = 0
                        carry = Mid(s, st)
                        exit while
                    end if
                    block = Mid(s, st, en - st)
                    p = en + 12
                    title = Iptv_Tag(block, "title").Replace(Chr(9), " ").Replace(Chr(10), " ")
                    desc = Iptv_Tag(block, "desc").Replace(Chr(9), " ").Replace(Chr(10), " ").Replace(Chr(13), "")
                    if Len(desc) > 320 then desc = Left(desc, 317) + "..."
                    if not matched.DoesExist(ch)
                        matched[ch] = true
                        m.epgMatched = m.epgMatched + 1
                    end if
                    sh = Iptv_Shard(ch)
                    icon = ""
                    ip = Instr(1, block, "<icon")
                    if ip > 0
                        ie = Instr(ip, block, ">")
                        if ie > 0 then icon = Iptv_Unescape(Iptv_Attr(Mid(block, ip, ie - ip + 1), "src"))
                    end if
                    cat = Iptv_Tag(block, "category").Replace(Chr(9), " ").Replace(Chr(10), " ")
                    ep = Iptv_Tag(block, "episode-num").Replace(Chr(9), " ").Replace(Chr(10), " ")
                    if Len(ep) > 24 then ep = ""
                    if Instr(1, ep, ".") > 0 and Instr(1, LCase(ep), "s") = 0 then ep = Iptv_XmltvEp(ep)
                    entry = ch + Chr(9) + start1.ToStr() + Chr(9) + stop1.ToStr() + Chr(9) + title + Chr(9) + desc + Chr(9) + icon + Chr(9) + cat + Chr(9) + ep + Chr(10)
                    bufs[sh].Push(entry)
                    sizes[sh] = sizes[sh] + Len(entry)
                    if sizes[sh] > 65536
                        Iptv_Flush(dir, sh, bufs[sh].Join(""))
                        bufs[sh] = []
                        sizes[sh] = 0
                    end if
                    count = count + 1
                else
                    p = gt + 1
                end if
            end if
        end while
    end while
    for i = 0 to 127
        if bufs[i].Count() > 0 then Iptv_Flush(dir, i, bufs[i].Join(""))
    end for
    return count
end function

sub Iptv_Flush(dir as string, shard as integer, text as string)
    ba = CreateObject("roByteArray")
    ba.FromAsciiString(text)
    path = dir + "s" + shard.ToStr() + ".tsv"
    if CreateObject("roFileSystem").Exists(path) then ba.AppendFile(path) else ba.WriteFile(path)
end sub

function Iptv_EpgDir() as string
    d = ReadAsciiFile("tmp:/iptv_epg_dir_" + Iptv_Pid() + ".txt")
    if d <> "" then return d
    j = ParseJson(ReadAsciiFile("cachefs:/iptv_epg_" + Iptv_Pid() + "/at.json"))
    if type(j) = "roAssociativeArray" and Str_Of(j.dir) <> "" then return Str_Of(j.dir)
    return "cachefs:/iptv_epg_" + Iptv_Pid() + "/a/"
end function

function Iptv_XmltvEp(v as string) as string
    parts = v.Split(".")
    if parts.Count() < 2 then return ""
    s = parts[0].Trim()
    e = parts[1].Trim()
    sl = Instr(1, s, "/")
    if sl > 0 then s = Left(s, sl - 1)
    sl = Instr(1, e, "/")
    if sl > 0 then e = Left(e, sl - 1)
    if s = "" or e = "" then return ""
    return "T" + (s.ToInt() + 1).ToStr() + ":E" + (e.ToInt() + 1).ToStr()
end function

function Iptv_Guide(ids as object, shift = 0 as integer) as object
    dir = Iptv_EpgDir()
    byShard = {}
    for each id in ids
        if id <> ""
            k = Iptv_Shard(LCase(id)).ToStr()
            if not byShard.DoesExist(k) then byShard[k] = {}
            byShard[k][LCase(id)] = true
        end if
    end for
    out = {}
    for each k in byShard
        want = byShard[k]
        text = ReadAsciiFile(dir + "s" + k + ".tsv")
        if text <> ""
            for each line in text.Split(Chr(10))
                t1 = Instr(1, line, Chr(9))
                if t1 > 0
                    ch = Left(line, t1 - 1)
                    if want.DoesExist(ch)
                        f = line.Split(Chr(9))
                        if f.Count() >= 4
                            if not out.DoesExist(ch) then out[ch] = []
                            pr = { a: f[1].ToInt() + shift, b: f[2].ToInt() + shift, t: f[3], d: "" }
                            if f.Count() >= 5 then pr.d = f[4]
                            if f.Count() >= 6 and f[5] <> "" then pr.i = f[5]
                            if f.Count() >= 7 and f[6] <> "" then pr.c = f[6]
                            if f.Count() >= 8 and f[7] <> "" then pr.e = f[7]
                            out[ch].Push(pr)
                        end if
                    end if
                end if
            end for
        end if
    end for
    for each ch in out
        out[ch].SortBy("a")
        clean = []
        lastA = -1
        for each pr in out[ch]
            if pr.a <> lastA then clean.Push(pr)
            lastA = pr.a
        end for
        out[ch] = clean
    end for
    return out
end function

function Iptv_Art(titles as object) as object
    out = {}
    key = Key_Tmdb(St_Integrations())
    if key = "" then return out
    path = "cachefs:/iptv_art2.json"
    cache = ParseJson(ReadAsciiFile(path))
    if type(cache) <> "roAssociativeArray" or cache.Count() > 1500 then cache = {}
    now = CreateObject("roDateTime").AsSeconds()
    lang = Tmdb_Lang()
    changed = false
    asked = 0
    for each t in titles
        q = Vod_Query(Str_Of(t))
        norm = Vod_Key(q)
        if Len(norm) >= 3
            c = cache[norm]
            if type(c) = "roAssociativeArray" and (Str_Of(c.p) <> "" or now - ToInt(c.at, 0) < 259200)
                out[t] = c
            else if asked < 10
                asked = asked + 1
                j = Http_FetchJson("https://api.themoviedb.org/3/search/multi?api_key=" + key + "&language=" + lang + "&include_adult=false&query=" + q.EncodeUriComponent(), 6000)
                c = { p: "", b: "", at: now }
                if type(j) = "roAssociativeArray" and type(j.results) = "roArray"
                    n = 0
                    best = invalid
                    bestScore = 0
                    for each r in j.results
                        n = n + 1
                        if n > 10 then exit for
                        kind = Str_Of(r.media_type)
                        if (kind = "movie" or kind = "tv") and Str_Of(r.poster_path) <> ""
                            score = 0
                            for each nm in [Str_Of(r.title), Str_Of(r.name), Str_Of(r.original_title), Str_Of(r.original_name)]
                                sc = Vod_Score(norm, Vod_Key(nm))
                                if sc > score then score = sc
                            end for
                            if score > bestScore
                                best = r
                                bestScore = score
                            end if
                            if score >= 3 then exit for
                        end if
                    end for
                    if best <> invalid
                        c.p = "https://image.tmdb.org/t/p/w342" + Str_Of(best.poster_path)
                        if Str_Of(best.backdrop_path) <> "" then c.b = "https://image.tmdb.org/t/p/w1280" + Str_Of(best.backdrop_path)
                    end if
                end if
                cache[norm] = c
                changed = true
                out[t] = c
            end if
        end if
    end for
    if changed then WriteAsciiFile(path, FormatJson(cache))
    return out
end function

