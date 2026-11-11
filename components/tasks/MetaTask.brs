sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    kind = m.top.kind
    id = m.top.metaId
    origId = id
    if LCase(Left(id, 5)) = "tmdb:"
        key = Key_Tmdb(St_Integrations())
        if key <> ""
            media = "movie"
            if LCase(kind) <> "movie" then media = "tv"
            num = Mid(id, 6).Split(":")[0]
            ext = Http_FetchJson("https://api.themoviedb.org/3/" + media + "/" + num + "/external_ids?api_key=" + key, 8000)
            if type(ext) = "roAssociativeArray" and Left(Str_Of(ext.imdb_id), 2) = "tt" then id = ext.imdb_id
        end if
    end if
    urls = []
    for each entry in m.top.manifests
        if Addon_Supports(entry.manifest, "meta", kind, id)
            urls.Push(Addon_ResourceUrl(entry.base, "meta", kind, id))
        end if
    end for
    if Left(id, 2) = "tt" then urls.Push(Addon_ResourceUrl("https://v3-cinemeta.strem.io", "meta", kind, id))
    results = Http_FetchJsonAll(urls, 15000)
    merged = { id: id, kind: kind }
    for each data in results
        if type(data) = "roAssociativeArray" and type(data.meta) = "roAssociativeArray"
            Meta_Merge(merged, data.meta)
        end if
    end for
    imdb = Addon_ImdbId(merged.raw)
    if imdb = "" and Left(id, 2) = "tt" then imdb = id
    merged.imdb = imdb
    merged.Delete("raw")
    integ = St_Integrations()
    if integ.tmdbEnabled and Key_Tmdb(integ) <> ""
        Tmdb_Enrich(merged, integ, kind, origId)
    end if
    if Str_Of(merged.logo) = "" then merged.logo = Img_Logo(merged.imdb)
    if Str_Of(merged.background) = "" then merged.background = Img_Background(merged.imdb)
    if integ.mdbEnabled and Mdb_Ready(integ) and merged.imdb <> ""
        merged.ratings = Mdb_Ratings(integ, kind, merged.imdb)
    end if
    if IsStr(merged.name) and Str_HasForeign(merged.name)
        one = [{ id: id, kind: kind, title: merged.name, original: merged.name }]
        if Str_Of(merged.imdb) <> "" then one[0].id = merged.imdb
        Names_Translate(one)
        merged.name = one[0].title
    end if
    merged = Str_CleanDeep(merged)
    m.top.meta = merged
    if m.top.withComments and Bool_Of(integ.traktComments, true) and Key_TraktId(integ) <> "" and Str_Of(merged.imdb) <> ""
        comments = Trakt_Comments(integ, kind, merged.imdb)
        if comments.Count() > 0 and Bool_Of(integ.traktTranslate, true) then Comments_Translate(comments)
        m.top.comments = Str_CleanDeep(comments)
    end if
end sub

function Tmdb_Enrich(merged as object, integ as object, kind as string, id as string) as boolean
    key = Key_Tmdb(integ)
    lang = Tmdb_Lang()
    lang2 = LCase(Left(lang, 2))
    media = "movie"
    if LCase(kind) <> "movie" then media = "tv"
    tmdbId = ""
    if LCase(Left(id, 5)) = "tmdb:"
        tmdbId = Mid(id, 6)
        cut = Instr(1, tmdbId, ":")
        if cut > 0 then tmdbId = Left(tmdbId, cut - 1)
    else if merged.imdb <> ""
        found = Http_FetchJson("https://api.themoviedb.org/3/find/" + merged.imdb + "?external_source=imdb_id&api_key=" + key, 10000)
        if type(found) = "roAssociativeArray"
            list = found.movie_results
            if media = "tv" then list = found.tv_results
            if type(list) = "roArray" and list.Count() > 0 then tmdbId = Str_Any(list[0].id)
            if tmdbId = "" and media = "movie" and type(found.tv_results) = "roArray" and found.tv_results.Count() > 0
                media = "tv"
                tmdbId = Str_Any(found.tv_results[0].id)
            end if
        end if
    end if
    if tmdbId = "" then return false
    url = "https://api.themoviedb.org/3/" + media + "/" + tmdbId + "?api_key=" + key + "&language=" + lang + "&append_to_response=images,external_ids,videos,credits,recommendations&include_image_language=" + lang2 + ",en,null&include_video_language=" + lang2 + ",en"
    d = Http_FetchJson(url, 12000)
    if type(d) <> "roAssociativeArray" then return false
    title = Str_Of(d.title)
    if title = "" then title = Str_Of(d.name)
    if title <> "" then merged.name = title
    if Str_Of(d.overview) <> "" then merged.description = d.overview
    if integ.tmdbArtwork
        if Str_Of(d.backdrop_path) <> "" then merged.background = "https://image.tmdb.org/t/p/w1280" + d.backdrop_path
        if Str_Of(d.poster_path) <> "" then merged.poster = "https://image.tmdb.org/t/p/w500" + d.poster_path
        logo = Tmdb_Logo(d.images, lang2)
        if logo <> "" then merged.logo = logo
    end if
    if type(d.genres) = "roArray" and d.genres.Count() > 0
        genres = []
        for each g in d.genres
            if genres.Count() < 3 and type(g) = "roAssociativeArray" then genres.Push(Str_Of(g.name))
        end for
        merged.genres = genres
    end if
    date = Str_Of(d.release_date)
    if date = "" then date = Str_Of(d.first_air_date)
    if date <> "" and Str_Of(merged.releaseInfo) = "" then merged.releaseInfo = Left(date, 4)
    runtime = ToInt(d.runtime, 0)
    if runtime = 0 and type(d.episode_run_time) = "roArray" and d.episode_run_time.Count() > 0 then runtime = ToInt(d.episode_run_time[0], 0)
    if runtime > 0 then merged.runtime = runtime.ToStr() + L(" min")
    if merged.imdb = "" and type(d.external_ids) = "roAssociativeArray" then merged.imdb = Str_Of(d.external_ids.imdb_id)
    merged.originalLanguage = Str_Of(d.original_language)
    Tmdb_Credits(merged, d, media)
    Tmdb_More(merged, d, media, key, lang)
    merged.tmdbId = tmdbId
    if type(d.videos) = "roAssociativeArray" and type(d.videos.results) = "roArray"
        local = []
        other = []
        region = UCase(Mid(lang, 4, 2))
        for each pass in [1, 2]
            for each kindWanted in ["Trailer", "Teaser"]
                for each v in d.videos.results
                    if type(v) = "roAssociativeArray" and LCase(Str_Of(v.site)) = "youtube" and Str_Of(v.type) = kindWanted and Str_Of(v.key) <> "" and LCase(Str_Of(v.iso_639_1)) = lang2 and lang2 <> "en"
                        sameRegion = region <> "" and UCase(Str_Of(v.iso_3166_1)) = region
                        if ((pass = 1 and sameRegion) or (pass = 2 and not sameRegion)) and local.Count() < 3 then local.Push(v.key)
                    end if
                end for
            end for
        end for
        for each kindWanted in ["Trailer", "Teaser"]
            for each v in d.videos.results
                if type(v) = "roAssociativeArray" and LCase(Str_Of(v.site)) = "youtube" and Str_Of(v.type) = kindWanted and Str_Of(v.key) <> ""
                    if LCase(Str_Of(v.iso_639_1)) = lang2 and lang2 <> "en"
                    else if other.Count() < 2
                        other.Push(v.key)
                    end if
                end if
            end for
        end for
        merged.trailerLocal = local
        if type(merged.trailerYt) <> "roArray" then merged.trailerYt = []
        for each k in other
            merged.trailerYt.Push(k)
        end for
    end if
    if media = "tv" then Tmdb_Episodes(merged, key, lang, tmdbId, d)
    return true
end function

sub Tmdb_More(merged as object, d as object, media as string, key as string, lang as string)
    kind = "movie"
    if media = "tv" then kind = "series"
    more = []
    if type(d.recommendations) = "roAssociativeArray" and type(d.recommendations.results) = "roArray"
        for each r in d.recommendations.results
            if more.Count() >= 15 then exit for
            it = Tmdb_Card(r, kind)
            if it <> invalid then more.Push(it)
        end for
    end if
    if more.Count() > 0 then merged.moreLike = more
    col = d.belongs_to_collection
    if media = "movie" and type(col) = "roAssociativeArray" and Str_Any(col.id) <> ""
        c = Http_FetchJson("https://api.themoviedb.org/3/collection/" + Str_Any(col.id) + "?api_key=" + key + "&language=" + lang, 8000)
        if type(c) = "roAssociativeArray" and type(c.parts) = "roArray"
            parts = []
            for each r in c.parts
                if type(r) = "roAssociativeArray" and Str_Of(r.release_date) <> "" then parts.Push(r)
            end for
            parts.SortBy("release_date")
            items = []
            for each r in parts
                it = Tmdb_Card(r, "movie")
                if it <> invalid then items.Push(it)
            end for
            if items.Count() > 1
                name = Str_Of(c.name)
                if name = "" then name = Str_Of(col.name)
                merged.collection = { name: name, items: items }
            end if
        end if
    end if
    merged.companies = Tmdb_Orgs(d.production_companies)
    if media = "tv" then merged.networks = Tmdb_Orgs(d.networks)
end sub

function Tmdb_Card(r as dynamic, kind as string) as dynamic
    if type(r) <> "roAssociativeArray" or Str_Of(r.poster_path) = "" then return invalid
    name = Str_Of(r.title)
    if name = "" then name = Str_Of(r.name)
    date = Str_Of(r.release_date)
    if date = "" then date = Str_Of(r.first_air_date)
    back = ""
    if Str_Of(r.backdrop_path) <> "" then back = "https://image.tmdb.org/t/p/w1280" + r.backdrop_path
    return { id: "tmdb:" + Str_Any(r.id), kind: kind, name: name, year: Left(date, 4), poster: "https://image.tmdb.org/t/p/w342" + r.poster_path, background: back }
end function

function Tmdb_Orgs(list as dynamic) as object
    out = []
    if type(list) <> "roArray" then return out
    for each c in list
        if out.Count() >= 8 then exit for
        if type(c) = "roAssociativeArray" and Str_Of(c.name) <> ""
            logo = ""
            path = Str_Of(c.logo_path)
            if path <> "" then logo = "https://image.tmdb.org/t/p/w185" + path.Replace(".svg", ".png")
            out.Push({ id: Str_Any(c.id), name: Str_Of(c.name), logo: logo })
        end if
    end for
    return out
end function

function Tmdb_Logo(images as dynamic, lang2 as string) as string
    if type(images) <> "roAssociativeArray" or type(images.logos) <> "roArray" then return ""
    best = ""
    fallback = ""
    for each entry in images.logos
        if type(entry) = "roAssociativeArray" and IsStr(entry.file_path)
            code = Str_Of(entry.iso_639_1)
            if code = lang2 and best = "" then best = entry.file_path
            if code = "en" and fallback = "" then fallback = entry.file_path
            if fallback = "" and code = "" then fallback = entry.file_path
        end if
    end for
    if best = "" then best = fallback
    if best = "" then return ""
    return "https://image.tmdb.org/t/p/w500" + Left(best, Len(best) - 4) + ".png"
end function

sub Tmdb_Credits(merged as object, d as object, media as string)
    credits = d.credits
    if type(credits) <> "roAssociativeArray" then return
    cast = []
    if type(credits.cast) = "roArray"
        for each c in credits.cast
            if cast.Count() >= 16 then exit for
            if type(c) = "roAssociativeArray" and Str_Of(c.name) <> ""
                photo = ""
                if Str_Of(c.profile_path) <> "" then photo = "https://image.tmdb.org/t/p/w185" + c.profile_path
                cast.Push({ id: Str_Any(c.id), name: Str_Of(c.name), role: Str_Of(c.character), photo: photo })
            end if
        end for
    end if
    if cast.Count() > 0 then merged.cast = cast
    people = []
    if media = "tv" and type(d.created_by) = "roArray"
        for each c in d.created_by
            if type(c) = "roAssociativeArray" and people.Count() < 3 then people.Push(Str_Of(c.name))
        end for
        if people.Count() > 0 then merged.creators = people
    else if type(credits.crew) = "roArray"
        for each c in credits.crew
            if type(c) = "roAssociativeArray" and Str_Of(c.job) = "Director" and people.Count() < 3 then people.Push(Str_Of(c.name))
        end for
        if people.Count() > 0 then merged.directors = people
    end if
end sub

sub Tmdb_Episodes(merged as object, key as string, lang as string, tmdbId as string, show as object)
    numbers = []
    if type(show.seasons) = "roArray"
        for each s in show.seasons
            if type(s) = "roAssociativeArray"
                n = ToInt(s.season_number, -1)
                if n >= 0 and numbers.Count() < 12 then numbers.Push(n)
            end if
        end for
    end if
    if numbers.Count() = 0 then return
    urls = []
    for each n in numbers
        urls.Push("https://api.themoviedb.org/3/tv/" + tmdbId + "/season/" + n.ToStr() + "?api_key=" + key + "&language=" + lang)
    end for
    seasons = Http_FetchJsonAll(urls, 15000)
    byKey = {}
    built = []
    imdb = Str_Of(merged.imdb)
    for each sd in seasons
        if type(sd) = "roAssociativeArray" and type(sd.episodes) = "roArray"
            for each e in sd.episodes
                if type(e) = "roAssociativeArray"
                    sn = ToInt(e.season_number, 0)
                    en = ToInt(e.episode_number, 0)
                    still = ""
                    if Str_Of(e.still_path) <> "" then still = "https://image.tmdb.org/t/p/w780" + e.still_path
                    info = { name: Str_Of(e.name), overview: Str_Of(e.overview), thumbnail: still, released: Str_Of(e.air_date), runtime: ToInt(e.runtime, 0) }
                    byKey["s" + sn.ToStr() + "e" + en.ToStr()] = info
                    if imdb <> "" then built.Push({ id: imdb + ":" + sn.ToStr() + ":" + en.ToStr(), season: sn, episode: en, name: info.name, title: "", overview: info.overview, description: "", released: info.released, thumbnail: still, runtime: info.runtime })
                end if
            end for
        end if
    end for
    if type(merged.videos) = "roArray" and merged.videos.Count() > 0
        for each v in merged.videos
            k = "s" + ToInt(v.season, -1).ToStr() + "e" + ToInt(v.episode, -1).ToStr()
            info = byKey[k]
            if info <> invalid
                if info.name <> "" then v.name = info.name
                if info.overview <> "" then v.overview = info.overview
                if info.thumbnail <> "" then v.thumbnail = info.thumbnail
                if info.runtime > 0 then v.runtime = info.runtime
                if Str_Of(v.released) = "" then v.released = info.released
            end if
        end for
    else if built.Count() > 0
        merged.videos = built
    end if
end sub

function Mdb_Ratings(integ as object, kind as string, imdb as string) as object
    media = "movie"
    if LCase(kind) <> "movie" then media = "show"
    path = "/imdb/" + media + "/" + imdb
    data = Mdb_Get(path, integ, 10000, path + "/").json
    out = []
    if type(data) <> "roAssociativeArray" or type(data.ratings) <> "roArray" then return out
    found = {}
    alias = { popcorn: "audience", audience: "audience", tomatoesaudience: "audience" }
    for each r in data.ratings
        if type(r) = "roAssociativeArray"
            source = LCase(Str_Of(r.source))
            if alias.DoesExist(source) then source = alias[source]
            value = Mdb_Num(r.value)
            if source = "letterboxd" and Mdb_Num(r.score) >= 0 then value = Mdb_Num(r.score) / 20
            top = 100
            if source = "imdb" then top = 10
            if source = "letterboxd" then top = 5
            if value > 0 and value <= top and not found.DoesExist(source) then found[source] = value
        end if
    end for
    show = integ.mdbShow
    for each key in ["imdb", "trakt", "tmdb", "tomatoes", "audience", "letterboxd", "metacritic"]
        if found.DoesExist(key) and Bool_Of(show[key], false)
            value = found[key]
            icon = "pkg:/images/s/mdb_" + key + ".png"
            if key = "tomatoes" and value < 60 then icon = "pkg:/images/s/mdb_tomatoes_rotten.png"
            if key = "audience" and value < 60 then icon = "pkg:/images/s/mdb_audience_stale.png"
            decimal = key = "imdb" or key = "tmdb" or key = "letterboxd"
            out.Push({ source: key, icon: icon, value: Mdb_Fmt(value, decimal) })
        end if
    end for
    return out
end function

function Mdb_Num(v as dynamic) as float
    if v = invalid then return -1
    t = type(v)
    if t = "roInt" or t = "Integer" or t = "roInteger" or t = "LongInteger" or t = "roLongInteger" or t = "Float" or t = "roFloat" or t = "Double" or t = "roDouble" then return v
    if IsStr(v) and v <> "" then return Val(v)
    return -1
end function

function Mdb_Fmt(value as float, decimal as boolean) as string
    tenths = Int(value * 10 + 0.5)
    whole = Int(tenths / 10)
    rest = tenths - whole * 10
    if decimal or rest <> 0 then return whole.ToStr() + "." + rest.ToStr()
    return whole.ToStr()
end function

sub Meta_Merge(target as object, meta as object)
    if target.raw = invalid then target.raw = meta
    if Addon_ImdbId(target.raw) = "" and Addon_ImdbId(meta) <> "" then target.raw = meta
    fields = ["name", "description", "poster", "background", "logo", "releaseInfo", "runtime", "imdbRating"]
    for each f in fields
        current = Str_Any(target[f])
        incoming = Str_Any(meta[f])
        if current = "" and incoming <> "" then target[f] = incoming
    end for
    if target.genres = invalid and type(meta.genres) = "roArray" and meta.genres.Count() > 0
        genres = []
        for each g in meta.genres
            if IsStr(g) and genres.Count() < 3 then genres.Push(g)
        end for
        target.genres = genres
    end if
    if target.cast = invalid and type(meta.cast) = "roArray" and meta.cast.Count() > 0
        cast = []
        for each c in meta.cast
            if IsStr(c) and cast.Count() < 16 then cast.Push({ name: c, role: "", photo: "" })
        end for
        if cast.Count() > 0 then target.cast = cast
    end if
    if target.directors = invalid and type(meta.director) = "roArray" and meta.director.Count() > 0
        people = []
        for each c in meta.director
            if IsStr(c) and people.Count() < 3 then people.Push(c)
        end for
        if people.Count() > 0 then target.directors = people
    end if
    if target.videos = invalid and type(meta.videos) = "roArray" and meta.videos.Count() > 0
        videos = []
        for each v in meta.videos
            if type(v) = "roAssociativeArray" and IsStr(v.id)
                videos.Push({
                    id: v.id
                    season: v.season
                    episode: v.episode
                    name: Str_Of(v.name)
                    title: Str_Of(v.title)
                    overview: Str_Of(v.overview)
                    description: Str_Of(v.description)
                    released: Str_Of(v.released)
                    thumbnail: Str_Of(v.thumbnail)
                })
            end if
        end for
        target.videos = videos
    end if
    if type(target.trailerYt) <> "roArray" then target.trailerYt = []
    if type(target.trailerUrls) <> "roArray" then target.trailerUrls = []
    for each list in [meta.trailers, meta.trailerStreams]
        if type(list) = "roArray"
            for each t in list
                if type(t) = "roAssociativeArray"
                    yt = Str_Of(t.ytId)
                    if yt = "" then yt = Str_Of(t.source)
                    url = Str_Of(t.url)
                    if url <> "" and Instr(1, url, "youtu") = 0 and target.trailerUrls.Count() < 3
                        target.trailerUrls.Push(url)
                    else if url <> "" and yt = ""
                        yt = url
                    end if
                    if yt <> "" and target.trailerYt.Count() < 3 then target.trailerYt.Push(yt)
                end if
            end for
        end if
    end for
    hints = meta.behaviorHints
    if type(hints) = "roAssociativeArray" and target.defaultVideoId = invalid
        if IsStr(hints.defaultVideoId) then target.defaultVideoId = hints.defaultVideoId
    end if
end sub

function Trakt_Comments(integ as object, kind as string, imdb as string) as object
    media = "movies"
    if LCase(kind) <> "movie" then media = "shows"
    headers = { "trakt-api-version": "2", "trakt-api-key": Key_TraktId(integ) }
    r = Http_Request("GET", "https://api.trakt.tv/" + media + "/" + imdb + "/comments/likes?limit=20", headers, invalid, 10000)
    out = []
    if type(r.json) <> "roArray" then return out
    for each c in r.json
        if type(c) = "roAssociativeArray"
            text = Str_Of(c.comment).Trim()
            if text <> ""
                user = ""
                if type(c.user) = "roAssociativeArray"
                    user = Str_Of(c.user.name)
                    if user = "" then user = Str_Of(c.user.username)
                end if
                if user = "" then user = "Trakt"
                rating = 0
                if type(c.user_stats) = "roAssociativeArray" then rating = ToInt(c.user_stats.rating, 0)
                out.Push({ user: user, text: text, spoiler: Bool_Of(c.spoiler, false), review: Bool_Of(c.review, false), likes: ToInt(c.likes, 0), rating: rating, date: Left(Str_Of(c.created_at), 10) })
            end if
        end if
    end for
    return out
end function

function Comments_Lang() as string
    ui = ""
    if m.global <> invalid and m.global.hasField("uiLang") then ui = LCase(Str_Of(m.global.uiLang))
    if ui = "" or ui = "auto" then ui = LCase(Left(CreateObject("roDeviceInfo").GetCurrentLocale(), 2))
    if ui = "" then ui = "en"
    return Left(ui, 2)
end function

sub Comments_Translate(list as object)
    lang = Comments_Lang()
    port = CreateObject("roMessagePort")
    jobs = {}
    failed = []
    for i = 0 to list.Count() - 1
        if i >= 12 then exit for
        c = list[i]
        t = CreateObject("roUrlTransfer")
        t.SetUrl("https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" + lang + "&dt=t")
        t.SetPort(port)
        t.SetCertificatesFile("common:/certs/ca-bundle.crt")
        t.AddHeader("Content-Type", "application/x-www-form-urlencoded;charset=UTF-8")
        t.AddHeader("User-Agent", "Mozilla/5.0")
        if t.AsyncPostFromString("q=" + Left(Str_Of(c.text), 1800).EncodeUriComponent())
            jobs[Stri(t.GetIdentity()).Trim()] = { t: t, index: i }
        end if
    end for
    clock = CreateObject("roTimespan")
    while jobs.Count() > 0 and clock.TotalMilliseconds() < 9000
        msg = wait(500, port)
        if type(msg) = "roUrlEvent"
            key = Stri(msg.GetSourceIdentity()).Trim()
            job = jobs[key]
            if job <> invalid
                jobs.Delete(key)
                if msg.GetResponseCode() <> 200
                    failed.Push(job.index)
                else
                    data = ParseJson(msg.GetString())
                    if type(data) = "roArray" and data.Count() > 2 and type(data[0]) = "roArray"
                        source = LCase(Left(Str_Of(data[2]), 2))
                        if source <> "" and source <> lang
                            out = ""
                            for each seg in data[0]
                                if type(seg) = "roArray" and seg.Count() > 0 and IsStr(seg[0]) then out = out + seg[0]
                            end for
                            if out.Trim() <> ""
                                c = list[job.index]
                                c.original = c.text
                                c.text = out.Trim()
                                c.translated = true
                            end if
                        end if
                    end if
                end if
            end if
        end if
    end while
    for each key in jobs
        jobs[key].t.AsyncCancel()
        failed.Push(jobs[key].index)
    end for
    if failed.Count() > 0 then Comments_Fallback(list, failed, lang)
end sub

sub Comments_Fallback(list as object, failed as object, lang as string)
    port = CreateObject("roMessagePort")
    jobs = {}
    for each index in failed
        c = list[index]
        t = CreateObject("roUrlTransfer")
        t.SetUrl("https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=auto&tl=" + lang + "&q=" + Left(Str_Of(c.text), 1500).EncodeUriComponent())
        t.SetPort(port)
        t.SetCertificatesFile("common:/certs/ca-bundle.crt")
        t.AddHeader("User-Agent", "Mozilla/5.0")
        if t.AsyncGetToString() then jobs[Stri(t.GetIdentity()).Trim()] = { t: t, index: index }
    end for
    clock = CreateObject("roTimespan")
    while jobs.Count() > 0 and clock.TotalMilliseconds() < 6000
        msg = wait(500, port)
        if type(msg) = "roUrlEvent"
            key = Stri(msg.GetSourceIdentity()).Trim()
            job = jobs[key]
            if job <> invalid
                jobs.Delete(key)
                data = invalid
                if msg.GetResponseCode() = 200 then data = ParseJson(msg.GetString())
                text = ""
                source = ""
                if type(data) = "roArray" and data.Count() > 0
                    first = data[0]
                    if IsStr(first)
                        text = first
                    else if type(first) = "roArray" and first.Count() > 0 and IsStr(first[0])
                        text = first[0]
                        if first.Count() > 1 then source = LCase(Left(Str_Of(first[1]), 2))
                    end if
                end if
                if text.Trim() <> "" and source <> lang
                    c = list[job.index]
                    if text.Trim() <> Str_Of(c.text).Trim()
                        c.original = c.text
                        c.text = text.Trim()
                        c.translated = true
                    end if
                end if
            end if
        end if
    end while
    for each key in jobs
        jobs[key].t.AsyncCancel()
    end for
end sub
