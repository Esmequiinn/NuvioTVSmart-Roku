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
        out.cues = Subs_Fetch(Str_Of(p.url))
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
        out.Push({ id: rid, kind: kind, name: Str_Glyphs(name), poster: "https://image.tmdb.org/t/p/w342" + r.poster_path, background: back })
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

function Subs_Fetch(url as string) as object
    cues = []
    if url = "" then return cues
    r = Http_Request("GET", url, {}, invalid, 15000)
    body = r.body
    if body = "" then return cues
    body = body.Replace(chr(13), "")
    timing = CreateObject("roRegex", "^\s*([0-9:.,]+)\s*-->\s*([0-9:.,]+)", "")
    tags = CreateObject("roRegex", "<[^>]*>|\{\\[^}]*\}", "")
    lines = body.Split(chr(10))
    i = 0
    n = lines.Count()
    while i < n
        found = timing.Match(lines[i])
        if found.Count() > 2
            s = Subs_Time(found[1])
            e = Subs_Time(found[2])
            text = []
            i = i + 1
            while i < n and lines[i].Trim() <> ""
                text.Push(tags.ReplaceAll(lines[i], "").Trim())
                i = i + 1
            end while
            if text.Count() > 0 and e > s then cues.Push({ s: s, e: e, t: text.Join(chr(10)) })
        else
            i = i + 1
        end if
    end while
    return cues
end function
