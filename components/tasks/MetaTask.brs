sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    kind = m.top.kind
    id = m.top.metaId
    urls = []
    for each entry in m.top.manifests
        if Addon_Supports(entry.manifest, "meta", kind, id)
            urls.Push(Addon_ResourceUrl(entry.base, "meta", kind, id))
        end if
    end for
    if Left(id, 2) = "tt" then urls.Push(Addon_ResourceUrl("https://v3-cinemeta.strem.io", "meta", kind, id))
    results = Http_FetchJsonAll(urls, 10000)
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
        Tmdb_Enrich(merged, integ, kind, id)
    end if
    if Str_Of(merged.logo) = "" then merged.logo = Img_Logo(merged.imdb)
    if Str_Of(merged.background) = "" then merged.background = Img_Background(merged.imdb)
    if integ.mdbEnabled and integ.mdbKey <> "" and merged.imdb <> ""
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
    url = "https://api.themoviedb.org/3/" + media + "/" + tmdbId + "?api_key=" + key + "&language=" + lang + "&append_to_response=images,external_ids,videos,credits&include_image_language=" + lang2 + ",en,null&include_video_language=" + lang2 + ",en"
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
    data = Http_FetchJson("https://api.mdblist.com/imdb/" + media + "/" + imdb + "?apikey=" + integ.mdbKey, 10000)
    out = []
    if type(data) <> "roAssociativeArray" or type(data.ratings) <> "roArray" then return out
    show = integ.mdbShow
    labels = { imdb: "IMDb", tomatoes: "Rotten Tomatoes", popcorn: L("Audiencia"), audience: L("Audiencia"), metacritic: "Metacritic", letterboxd: "Letterboxd", tmdb: "TMDB", trakt: "Trakt" }
    for each r in data.ratings
        if type(r) = "roAssociativeArray"
            source = LCase(Str_Of(r.source))
            key = source
            if key = "popcorn" then key = "audience"
            value = Str_Any(r.value)
            if value <> "" and value <> "0" and labels.DoesExist(source) and Bool_Of(show[key], false)
                text = value
                if key = "tomatoes" or key = "audience" then text = value + "%"
                if key = "tmdb" or key = "trakt" then text = value + "%"
                out.Push({ source: key, label: labels[source], value: text })
            end if
        end if
    end for
    return out
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
