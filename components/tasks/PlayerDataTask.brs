sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    mode = m.top.mode
    p = m.top.params
    if p = invalid then p = {}
    out = { mode: mode, tag: Str_Of(p.tag) }
    if mode = "skip"
        out.segments = Skip_Fetch(p)
    else if mode = "parental"
        out.items = Parental_Fetch(Str_Of(p.imdb))
    else if mode = "recs"
        out.items = Recs_Fetch(p)
    else if mode = "subs"
        parsed = Subs_Fetch(Str_Of(p.url))
        out.cues = parsed.cues
        out.error = parsed.error
        out.url = Str_Of(p.url)
    end if
    m.top.result = out
end sub

function Skip_Num(v as dynamic) as float
    if v = invalid then return -1
    if IsStr(v) then return v.ToFloat()
    return 0.0 + v
end function

function Skip_Seg(seg as dynamic, kind as string) as dynamic
    if type(seg) <> "roAssociativeArray" then return invalid
    s = Skip_Num(seg.start_sec)
    e = Skip_Num(seg.end_sec)
    if s < 0 and seg.start_ms <> invalid then s = Skip_Num(seg.start_ms) / 1000.0
    if e < 0 and seg.end_ms <> invalid then e = Skip_Num(seg.end_ms) / 1000.0
    if s < 0 or e <= s then return invalid
    return { type: kind, start: s, finish: e }
end function

function Skip_Fetch(p as object) as object
    out = []
    imdb = Str_Of(p.imdb)
    movie = Bool_Of(p.movie, false)
    season = ToInt(p.season, -1)
    episode = ToInt(p.episode, -1)
    if Left(imdb, 2) = "tt"
        url = "https://api.introdb.app/segments?imdb_id=" + imdb
        if movie
            url = url + "&is_movie=true"
        else if season >= 0 and episode >= 0
            url = url + "&season=" + season.ToStr() + "&episode=" + episode.ToStr()
        else
            url = ""
        end if
        if url <> ""
            d = Http_Request("GET", url, {}, invalid, 8000).json
            if type(d) = "roAssociativeArray"
                if movie
                    credits = Skip_Seg(d.outro, "credits")
                    scene = Skip_Seg(d.post_credits, "postcredits")
                    if credits <> invalid and scene <> invalid and scene.start < credits.finish and scene.finish > credits.start then credits.finish = scene.start
                    if credits <> invalid and credits.finish > credits.start then out.Push(credits)
                else
                    for each k in ["intro", "recap", "outro"]
                        seg = Skip_Seg(d[k], k)
                        if seg <> invalid then out.Push(seg)
                    end for
                end if
            end if
        end if
    end if
    mal = Str_Of(p.mal)
    if mal = "" and Str_Of(p.kitsu) <> "" then mal = Skip_KitsuToMal(Str_Of(p.kitsu))
    if mal <> "" and episode > 0
        have = {}
        for each seg in out
            have[seg.type] = true
        end for
        url = "https://api.aniskip.com/v2/skip-times/" + mal + "/" + episode.ToStr() + "?types[]=op&types[]=ed&types[]=recap&types[]=mixed-op&types[]=mixed-ed&episodeLength=0"
        d = Http_Request("GET", url, {}, invalid, 8000).json
        if type(d) = "roAssociativeArray" and d.found = true and type(d.results) = "roArray"
            for each r in d.results
                if type(r) = "roAssociativeArray" and type(r.interval) = "roAssociativeArray"
                    t = LCase(Str_Of(r.skipType))
                    kind = ""
                    if t = "op" or t = "mixed-op" then kind = "intro"
                    if t = "ed" or t = "mixed-ed" then kind = "outro"
                    if t = "recap" then kind = "recap"
                    s = Skip_Num(r.interval.startTime)
                    e = Skip_Num(r.interval.endTime)
                    if kind <> "" and not have.DoesExist(kind) and s >= 0 and e > s
                        have[kind] = true
                        out.Push({ type: kind, start: s, finish: e })
                    end if
                end if
            end for
        end if
    end if
    return out
end function

function Skip_KitsuToMal(kitsu as string) as string
    d = Http_Request("GET", "https://kitsu.io/api/edge/anime/" + kitsu + "/mappings?filter[externalSite]=myanimelist/anime", {}, invalid, 8000).json
    if type(d) = "roAssociativeArray" and type(d.data) = "roArray"
        for each item in d.data
            if type(item) = "roAssociativeArray" and type(item.attributes) = "roAssociativeArray"
                if Str_Of(item.attributes.externalSite) = "myanimelist/anime" then return Str_Any(item.attributes.externalId)
            end if
        end for
    end if
    return ""
end function

function Parental_Fetch(imdb as string) as object
    out = []
    if Left(imdb, 2) <> "tt" then return out
    d = Http_Request("GET", "https://api.tiffara.com/titles/" + imdb.Split(":")[0] + "/parentsGuide", {}, invalid, 8000).json
    if type(d) <> "roAssociativeArray" or type(d.parentsGuide) <> "roArray" then return out
    names = { "SEXUAL_CONTENT": "nudity", "VIOLENCE": "violence", "PROFANITY": "profanity", "ALCOHOL_DRUGS": "alcohol", "FRIGHTENING_INTENSE_SCENES": "frightening" }
    found = {}
    for each c in d.parentsGuide
        if type(c) = "roAssociativeArray" and names.DoesExist(UCase(Str_Of(c.category))) and type(c.severityBreakdowns) = "roArray"
            none = 0
            best = ""
            bestVotes = -1
            for each b in c.severityBreakdowns
                if type(b) = "roAssociativeArray"
                    level = LCase(Str_Of(b.severityLevel))
                    votes = ToInt(b.voteCount, 0)
                    if level = "none"
                        none = votes
                    else if votes > bestVotes
                        best = level
                        bestVotes = votes
                    end if
                end if
            end for
            if best <> "" and bestVotes > none then found[names[UCase(Str_Of(c.category))]] = best
        end if
    end for
    for each k in ["nudity", "violence", "profanity", "alcohol", "frightening"]
        if found.DoesExist(k) then out.Push({ kind: k, level: found[k] })
    end for
    return out
end function

function Recs_Fetch(p as object) as object
    out = []
    key = Key_Tmdb(St_Integrations())
    if key = "" then return out
    lang = Tmdb_Lang()
    media = "movie"
    if Bool_Of(p.series, false) then media = "tv"
    id = Str_Of(p.tmdb)
    imdb = Str_Of(p.imdb)
    if id = "" and Left(imdb, 2) = "tt"
        d = Http_Request("GET", "https://api.themoviedb.org/3/find/" + imdb.Split(":")[0] + "?api_key=" + key + "&external_source=imdb_id", {}, invalid, 8000).json
        if type(d) = "roAssociativeArray"
            list = d[media + "_results"]
            if type(list) = "roArray" and list.Count() > 0 then id = Str_Any(list[0].id)
        end if
    end if
    if id = "" then return out
    d = Http_Request("GET", "https://api.themoviedb.org/3/" + media + "/" + id + "/recommendations?api_key=" + key + "&language=" + lang, {}, invalid, 8000).json
    if type(d) <> "roAssociativeArray" or type(d.results) <> "roArray" then return out
    picks = []
    for each r in d.results
        if type(r) = "roAssociativeArray" and Str_Of(r.poster_path) <> "" and picks.Count() < 6 then picks.Push(r)
    end for
    urls = []
    for each r in picks
        urls.Push("https://api.themoviedb.org/3/" + media + "/" + Str_Any(r.id) + "/external_ids?api_key=" + key)
    end for
    for each r in picks
        urls.Push("https://api.themoviedb.org/3/" + media + "/" + Str_Any(r.id) + "/images?api_key=" + key + "&include_image_language=" + Left(lang, 2) + ",en,null")
    end for
    ext = Http_Fetch(urls, 8000, 0).data
    for i = 0 to picks.Count() - 1
        r = picks[i]
        rid = "tmdb:" + Str_Any(r.id)
        if type(ext[i]) = "roAssociativeArray" and Str_Of(ext[i].imdb_id) <> "" then rid = ext[i].imdb_id
        name = Str_Of(r.title)
        if name = "" then name = Str_Of(r.name)
        kind = "movie"
        if media = "tv" then kind = "series"
        back = ""
        if Str_Of(r.backdrop_path) <> "" then back = "https://image.tmdb.org/t/p/w1280" + r.backdrop_path
        logo = ""
        imgs = ext[picks.Count() + i]
        if type(imgs) = "roAssociativeArray" and type(imgs.logos) = "roArray"
            best = invalid
            for each lg in imgs.logos
                if type(lg) = "roAssociativeArray" and Str_Of(lg.file_path) <> ""
                    code = Str_Of(lg.iso_639_1)
                    if best = invalid then best = lg
                    if code = Left(lang, 2) and Str_Of(best.iso_639_1) <> Left(lang, 2) then best = lg
                end if
            end for
            if best <> invalid then logo = "https://image.tmdb.org/t/p/w500" + Str_Of(best.file_path).Replace(".svg", ".png")
        end if
        year = Left(Str_Of(r.release_date), 4)
        if year = "" then year = Left(Str_Of(r.first_air_date), 4)
        rating = ""
        v10 = Int(Val(Str_Any(r.vote_average)) * 10 + 0.5)
        if v10 > 0 then rating = Int(v10 / 10).ToStr() + "." + (v10 mod 10).ToStr()
        out.Push({ id: rid, kind: kind, name: Str_Glyphs(name), poster: "https://image.tmdb.org/t/p/w342" + r.poster_path, background: back, logo: logo, overview: Str_OneLine(Str_Of(r.overview)), year: year, rating: rating })
    end for
    return out
end function

function Subs_Time(text as string) as float
    t = text.Trim().Replace(",", ".")
    parts = t.Split(":")
    total = 0.0
    for each part in parts
        total = total * 60 + part.ToFloat()
    end for
    return total
end function

function Subs_DecodeEntities(text as string) as string
    s = text
    s = s.Replace("&nbsp;", " ")
    s = s.Replace("&#160;", " ")
    s = s.Replace("&quot;", chr(34))
    s = s.Replace("&#34;", chr(34))
    s = s.Replace("&#39;", "'")
    s = s.Replace("&#039;", "'")
    s = s.Replace("&apos;", "'")
    s = s.Replace("&lsquo;", "'")
    s = s.Replace("&rsquo;", "'")
    s = s.Replace("&ldquo;", chr(34))
    s = s.Replace("&rdquo;", chr(34))
    s = s.Replace("&lt;", "<")
    s = s.Replace("&#60;", "<")
    s = s.Replace("&gt;", ">")
    s = s.Replace("&#62;", ">")
    s = s.Replace("&#38;", "&")
    s = s.Replace("&amp;", "&")
    return s
end function

function Subs_CleanLines(rawLines as object, assRe as object, tagRe as object) as object
    out = []
    for each raw in rawLines
        s = raw.Replace("\N", chr(10)).Replace("\n", chr(10))
        s = assRe.ReplaceAll(s, "")
        s = tagRe.ReplaceAll(s, "")
        s = Subs_DecodeEntities(s)
        for each part in s.Split(chr(10))
            clean = part.Trim()
            if clean <> "" then out.Push(clean)
        end for
    end for
    return out
end function

function Subs_Parse(raw as string) as object
    if raw = "" then return { cues: [], error: "" }
    text = raw
    if Left(text, 1) = chr(65279) then text = Mid(text, 2)
    bom3 = chr(239) + chr(187) + chr(191)
    if Left(text, 3) = bom3 then text = Mid(text, 4)
    text = text.Replace(chr(13), "")
    trimmed = text.Trim()
    if trimmed = "" then return { cues: [], error: "" }
    lowHead = LCase(Left(trimmed, 512))
    hasArrow = Instr(1, text, "-->") > 0
    if not hasArrow
        if Left(lowHead, 9) = "<!doctype" or Left(lowHead, 5) = "<html" or Left(lowHead, 5) = "<?xml" or Left(lowHead, 1) = "{"
            return { cues: [], error: "invalid_subtitle" }
        end if
    end if
    timing = CreateObject("roRegex", "^\s*((?:\d+:)?\d{1,2}:\d{2}(?:[.,]\d{1,3})?)\s*-->\s*((?:\d+:)?\d{1,2}:\d{2}(?:[.,]\d{1,3})?)", "")
    assRe = CreateObject("roRegex", "\{\\[^}]*\}", "")
    tagRe = CreateObject("roRegex", "<[^>]*>", "")
    lines = text.Split(chr(10))
    rawCues = []
    i = 0
    n = lines.Count()
    while i < n
        cur = lines[i].Trim()
        upper = UCase(cur)
        if upper = "NOTE" or upper = "STYLE" or upper = "REGION" or Left(upper, 5) = "NOTE " or Left(upper, 6) = "STYLE " or Left(upper, 7) = "REGION " or Left(upper, 6) = "WEBVTT"
            i = i + 1
            while i < n and lines[i].Trim() <> ""
                i = i + 1
            end while
        else
            found = timing.Match(lines[i])
            if found.Count() > 2
                s = Subs_Time(found[1])
                e = Subs_Time(found[2])
                block = []
                i = i + 1
                while i < n and lines[i].Trim() <> ""
                    block.Push(lines[i])
                    i = i + 1
                end while
                cleaned = Subs_CleanLines(block, assRe, tagRe)
                if cleaned.Count() > 0 and e > s then rawCues.Push({ s: s, e: e, t: cleaned.Join(chr(10)) })
            else
                i = i + 1
            end if
        end if
    end while
    if rawCues.Count() = 0 then return { cues: [], error: "invalid_subtitle" }
    outOfOrder = false
    for k = 1 to rawCues.Count() - 1
        if rawCues[k].s < rawCues[k - 1].s
            outOfOrder = true
            exit for
        end if
    end for
    if outOfOrder
        rawCues = Subs_SortCues(rawCues)
    end if
    cues = []
    for each cur in rawCues
        if cues.Count() > 0
            prev = cues[cues.Count() - 1]
            if Abs(cur.s - prev.s) < 0.05 and cur.s < prev.e
                if cur.e > prev.e then prev.e = cur.e
                if Instr(1, prev.t, cur.t) = 0 then prev.t = prev.t + chr(10) + cur.t
            else
                cues.Push(cur)
            end if
        else
            cues.Push(cur)
        end if
    end for
    return { cues: cues, error: "" }
end function

function Subs_SortCues(list as object) as object
    n = list.Count()
    if n < 2 then return list
    cur = list
    width = 1
    while width < n
        nxt = []
        i = 0
        while i < n
            midIdx = i + width
            if midIdx > n then midIdx = n
            rightEnd = i + width * 2
            if rightEnd > n then rightEnd = n
            li = i
            ri = midIdx
            while li < midIdx and ri < rightEnd
                if cur[li].s <= cur[ri].s
                    nxt.Push(cur[li])
                    li = li + 1
                else
                    nxt.Push(cur[ri])
                    ri = ri + 1
                end if
            end while
            while li < midIdx
                nxt.Push(cur[li])
                li = li + 1
            end while
            while ri < rightEnd
                nxt.Push(cur[ri])
                ri = ri + 1
            end while
            i = rightEnd
        end while
        cur = nxt
        width = width * 2
    end while
    return cur
end function

function Subs_Fetch(url as string) as object
    if url = "" then return { cues: [], error: "" }
    r = Http_Request("GET", url, {}, invalid, 15000)
    if r.code >= 400 then return { cues: [], error: "invalid_subtitle" }
    if Str_Of(r.body) = "" then return { cues: [], error: "invalid_subtitle" }
    return Subs_Parse(r.body)
end function