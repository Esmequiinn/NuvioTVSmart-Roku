function Rate_Num(v as dynamic) as integer
    n = Deb_Num(v)
    if n <= 0 then return 0
    r = Int(n + 0.5)
    if r > 10 then r = 10
    return r
end function

sub Rate_Add(map as object, kind as string, ids as dynamic, season as integer, episode as integer, rating as dynamic)
    n = Rate_Num(rating)
    if n <= 0 then return
    for each key in Rate_Keys(kind, ids, season, episode)
        map[key] = n
    end for
end sub

function Rate_Load(force as boolean) as object
    integ = St_Integrations()
    source = Rate_Source(integ)
    if source = "" then return { ok: true, source: "" }
    cache = Rate_Cache()
    now = CreateObject("roDateTime").AsSeconds()
    if not force and Str_Of(cache.source) = source and now - ToInt(cache.at, 0) < 900 then return { ok: true, source: source }
    map = {}
    ok = false
    if source = "trakt"
        for each bucket in [["movies", "movie"], ["shows", "show"], ["episodes", "episode"]]
            r = Trakt_Get("/sync/ratings/" + bucket[0], integ)
            if type(r.json) = "roArray"
                ok = true
                for each row in r.json
                    if type(row) = "roAssociativeArray"
                        if bucket[1] = "episode"
                            ep = row.episode
                            sh = row.show
                            if type(ep) = "roAssociativeArray" and type(sh) = "roAssociativeArray" then Rate_Add(map, "series", sh.ids, ToInt(ep.season, 0), ToInt(ep.number, 0), row.rating)
                        else
                            it = row[bucket[1]]
                            if type(it) = "roAssociativeArray" then Rate_Add(map, bucket[1], it.ids, 0, 0, row.rating)
                        end if
                    end if
                end for
            end if
        end for
    else if source = "simkl"
        for each bucket in [["movies", "movie", "movie"], ["shows", "show", "series"], ["anime", "show", "series"]]
            r = Http_Request("GET", Simkl_Url("/sync/all-items/" + bucket[0], integ), { Authorization: "Bearer " + integ.simklToken }, invalid, 30000)
            if r.code >= 200 and r.code < 300 then ok = true
            if type(r.json) = "roAssociativeArray" and type(r.json[bucket[0]]) = "roArray"
                for each row in r.json[bucket[0]]
                    if type(row) = "roAssociativeArray"
                        it = row[bucket[1]]
                        if type(it) = "roAssociativeArray" then Rate_Add(map, bucket[2], it.ids, 0, 0, row.user_rating)
                    end if
                end for
            end if
        end for
    else if source = "mdblist"
        r = Mdb_Read("/sync/ratings?limit=1000", integ)
        j = r.json
        if type(j) = "roAssociativeArray"
            ok = true
            for each bucket in [["movies", "movie"], ["shows", "show"], ["episodes", "episode"]]
                list = j[bucket[0]]
                if type(list) = "roArray"
                    for each row in list
                        if type(row) = "roAssociativeArray"
                            value = row.rating_precise
                            if value = invalid then value = row.rating
                            if bucket[1] = "episode"
                                ep = row.episode
                                sh = row.show
                                if type(sh) <> "roAssociativeArray" and type(ep) = "roAssociativeArray" then sh = ep.show
                                if type(ep) = "roAssociativeArray" and type(sh) = "roAssociativeArray" then Rate_Add(map, "series", sh.ids, ToInt(ep.season, 0), ToInt(ep.number, ToInt(ep.episode, 0)), value)
                            else
                                it = row[bucket[1]]
                                if type(it) <> "roAssociativeArray" then it = row
                                Rate_Add(map, bucket[1], it.ids, 0, 0, value)
                            end if
                        end if
                    end for
                end if
            end for
        end if
    end if
    if not ok then return { ok: false, source: source }
    St_WriteFile(Rate_File(), { source: source, at: now, map: map })
    return { ok: true, source: source, changed: true }
end function

function Rate_Body(kind as string, ids as object, season as integer, episode as integer, rating as integer) as object
    clean = {}
    if Str_Of(ids.imdb) <> "" then clean.imdb = Str_Of(ids.imdb)
    if Str_Of(ids.tmdb) <> "" then clean.tmdb = Str_Of(ids.tmdb).ToInt()
    k = LCase(kind)
    show = k = "series" or k = "tv" or k = "show"
    if episode > 0
        ep = { number: episode }
        if rating > 0 then ep.rating = rating
        return { shows: [{ ids: clean, seasons: [{ number: season, episodes: [ep] }] }] }
    end if
    item = { ids: clean }
    if rating > 0 then item.rating = rating
    if show then return { shows: [item] }
    return { movies: [item] }
end function

function Rate_Send(p as object) as object
    integ = St_Integrations()
    source = Rate_Source(integ)
    if source = "" then return { ok: false, error: L("Elige dónde guardar tus calificaciones en Ajustes → Seguimiento.") }
    kind = Str_Of(p.kind)
    season = ToInt(p.season, 0)
    episode = ToInt(p.episode, 0)
    rating = ToInt(p.rating, 0)
    ids = Rate_IdsFor(Str_Of(p.metaId))
    if ids.Count() = 0 then return { ok: false, error: L("No se pudo actualizar tu calificación en {p}.").Replace("{p}", Rate_Name(source)) }
    if episode > 0 and not Rate_Episodes(source) then return { ok: false, error: L("No se pudo actualizar tu calificación en {p}.").Replace("{p}", Rate_Name(source)) }
    body = Rate_Body(kind, ids, season, episode, rating)
    path = "/sync/ratings"
    if rating <= 0 then path = "/sync/ratings/remove"
    r = { code: 0, json: invalid }
    if source = "trakt"
        r = Trakt_Send("POST", path, integ, body)
    else if source = "simkl"
        r = Http_Request("POST", Simkl_Url(path, integ), { Authorization: "Bearer " + integ.simklToken }, body, 15000)
    else if source = "mdblist"
        r = Mdb_Send("POST", path, integ, body)
    end if
    failed = r.code < 200 or r.code >= 300
    if not failed and type(r.json) = "roAssociativeArray" and type(r.json.not_found) = "roAssociativeArray"
        for each k in r.json.not_found
            v = r.json.not_found[k]
            if type(v) = "roArray" and v.Count() > 0 then failed = true
        end for
    end if
    if failed then return { ok: false, error: L("No se pudo actualizar tu calificación en {p}.").Replace("{p}", Rate_Name(source)) }
    Rate_Remember(kind, Str_Of(p.metaId), season, episode, rating)
    return { ok: true, rating: rating, source: source }
end function

function Watch_Push() as object
    pid = St_ActiveProfile().id
    ops = St_ReadFile("trackops_" + pid)
    if type(ops) <> "roArray" or ops.Count() = 0 then return { ok: true, sent: 0 }
    integ = St_Integrations()
    targets = []
    if Str_Of(integ.traktToken) <> "" then targets.Push("trakt")
    if Str_Of(integ.simklToken) <> "" then targets.Push("simkl")
    if Str_Of(integ.mdbRefresh) <> "" or Str_Of(integ.mdbAccess) <> "" then targets.Push("mdblist")
    if targets.Count() = 0
        St_WriteFile("trackops_" + pid, [])
        return { ok: true, sent: 0 }
    end if
    adds = Watch_Body(ops, "add")
    dels = Watch_Body(ops, "del")
    failed = []
    for each t in targets
        ok = true
        for each job in [{ body: dels, remove: true }, { body: adds, remove: false }]
            if job.body.Count() > 0 and ok
                r = { code: 0 }
                if t = "trakt"
                    path = "/sync/history"
                    if job.remove then path = "/sync/history/remove"
                    r = Trakt_Send("POST", path, integ, job.body)
                else if t = "simkl"
                    path = "/sync/history"
                    if job.remove then path = "/sync/history/remove"
                    r = Http_Request("POST", Simkl_Url(path, integ), { Authorization: "Bearer " + integ.simklToken }, job.body, 15000)
                else
                    path = "/sync/watched"
                    if job.remove then path = "/sync/watched/remove"
                    r = Mdb_Send("POST", path, integ, job.body)
                end if
                if r.code < 200 or r.code >= 300 then ok = false
            end if
        end for
        if not ok then failed.Push(t)
    end for
    St_WriteFile("trackops_" + pid, [])
    return { ok: failed.Count() = 0, failed: failed, sent: ops.Count() }
end function

function Watch_Body(ops as object, op as string) as object
    movies = []
    shows = {}
    order = []
    for each o in ops
        if type(o) = "roAssociativeArray" and o.op = op
            ids = Rate_IdsFor(Str_Of(o.id))
            if ids.Count() > 0
                clean = {}
                if Str_Of(ids.imdb) <> "" then clean.imdb = Str_Of(ids.imdb)
                if Str_Of(ids.tmdb) <> "" then clean.tmdb = Str_Of(ids.tmdb).ToInt()
                s = ToInt(o.season, -1)
                e = ToInt(o.episode, -1)
                k = LCase(Str_Of(o.kind))
                if s >= 0 and e > 0
                    key = Str_Of(o.id).Split(":")[0]
                    if not shows.DoesExist(key)
                        shows[key] = { ids: clean, seasons: {} }
                        order.Push(key)
                    end if
                    seasons = shows[key].seasons
                    sk = s.ToStr()
                    if not seasons.DoesExist(sk) then seasons[sk] = []
                    item = { number: e }
                    if op = "add" then item.watched_at = Watch_Iso(ToInt(o.at, 0))
                    seasons[sk].Push(item)
                else if k = "series" or k = "tv" or k = "show"
                    key = Str_Of(o.id).Split(":")[0]
                    if not shows.DoesExist(key)
                        shows[key] = { ids: clean, seasons: {}, whole: true }
                        order.Push(key)
                    end if
                else
                    item = { ids: clean }
                    if op = "add" then item.watched_at = Watch_Iso(ToInt(o.at, 0))
                    movies.Push(item)
                end if
            end if
        end if
    end for
    list = []
    for each key in order
        sh = shows[key]
        entry = { ids: sh.ids }
        seasons = []
        for each sk in sh.seasons
            seasons.Push({ number: sk.ToInt(), episodes: sh.seasons[sk] })
        end for
        if seasons.Count() > 0 then entry.seasons = seasons
        list.Push(entry)
    end for
    out = {}
    if movies.Count() > 0 then out.movies = movies
    if list.Count() > 0 then out.shows = list
    return out
end function

function Watch_Iso(at as integer) as string
    d = CreateObject("roDateTime")
    if at > 0 then d.FromSeconds(at)
    return Left(d.ToISOString(), 19) + ".000Z"
end function
