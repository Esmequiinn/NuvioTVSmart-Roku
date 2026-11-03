function Trakt_Get(path as string, integ as object) as object
    url = "https://api.trakt.tv" + path
    r = Http_Request("GET", url, Trakt_Headers(integ, true), invalid, 20000)
    if r.code = 401 and Trakt_Renew(integ) then r = Http_Request("GET", url, Trakt_Headers(integ, true), invalid, 20000)
    return r
end function

function Trakt_Send(method as string, path as string, integ as object, body as dynamic) as object
    url = "https://api.trakt.tv" + path
    r = Http_Request(method, url, Trakt_Headers(integ, true), body, 15000)
    if r.code = 401 and Trakt_Renew(integ) then r = Http_Request(method, url, Trakt_Headers(integ, true), body, 15000)
    return r
end function

function Trakt_Renew(integ as object) as boolean
    if Str_Of(integ.traktRefresh) = "" or Key_TraktSecret(integ) = "" then return false
    body = { refresh_token: integ.traktRefresh, client_id: Key_TraktId(integ), client_secret: Key_TraktSecret(integ), redirect_uri: "urn:ietf:wg:oauth:2.0:oob", grant_type: "refresh_token" }
    r = Http_Request("POST", "https://api.trakt.tv/oauth/token", Trakt_Headers(integ, false), body, 15000)
    if r.code <> 200 or type(r.json) <> "roAssociativeArray" or Str_Of(r.json.access_token) = "" then return false
    fresh = St_Integrations()
    for each target in [integ, fresh]
        target["traktToken"] = Str_Of(r.json.access_token)
        if Str_Of(r.json.refresh_token) <> "" then target["traktRefresh"] = Str_Of(r.json.refresh_token)
    end for
    St_SaveIntegrations(fresh)
    return true
end function

function Mdb_Send(method as string, path as string, integ as object, body as dynamic) as object
    url = "https://api.mdblist.com" + path
    token = Mdb_Token(integ)
    if token <> "" then return Http_Request(method, url, { Authorization: "Bearer " + token }, body, 15000)
    key = Str_Of(integ.mdbKey)
    if key = "" then return { code: 0, body: "", json: invalid }
    sep = "?"
    if Instr(1, url, "?") > 0 then sep = "&"
    return Http_Request(method, url + sep + "apikey=" + key, {}, body, 15000)
end function

function Mdb_Read(path as string, integ as object) as object
    token = Mdb_Token(integ)
    if token <> ""
        r = Http_Request("GET", "https://api.mdblist.com" + path, { Authorization: "Bearer " + token }, invalid, 20000)
        if r.code <> 401 then return r
    end if
    return Mdb_Get(path, integ, 20000)
end function

function Track_Time(text as string) as integer
    if text = "" then return 0
    dt = CreateObject("roDateTime")
    dt.FromISO8601String(Left(text, 19) + "Z")
    return dt.AsSeconds()
end function

function Track_Id(ids as dynamic) as string
    if type(ids) <> "roAssociativeArray" then return ""
    if Left(Str_Of(ids.imdb), 2) = "tt" then return ids.imdb
    if ids.tmdb <> invalid and Str_Any(ids.tmdb) <> "" then return "tmdb:" + Str_Any(ids.tmdb)
    return ""
end function

function Track_Poster(id as string, direct as string) as string
    if direct <> ""
        if Left(direct, 1) = "/" then return "https://image.tmdb.org/t/p/w500" + direct
        if LCase(Left(direct, 4)) = "http" then return direct
        return "https://" + direct
    end if
    if Left(id, 2) = "tt" then return "https://images.metahub.space/poster/medium/" + id + "/img"
    return ""
end function

function Track_Image(images as dynamic, key as string) as string
    if type(images) <> "roAssociativeArray" or type(images[key]) <> "roArray" or images[key].Count() = 0 then return ""
    return Str_Of(images[key][0])
end function

function Track_Playback(source as string, integ as object) as object
    r = invalid
    if source = "trakt" then r = Trakt_Get("/sync/playback?extended=full,images", integ)
    if source = "mdblist" then r = Mdb_Read("/sync/playback", integ)
    out = []
    if r = invalid or type(r.json) <> "roArray" then return invalid
    for each row in r.json
        e = Track_PlaybackEntry(row, source)
        if e <> invalid then out.Push(e)
    end for
    return out
end function

function Track_PlaybackEntry(row as dynamic, source as string) as dynamic
    if type(row) <> "roAssociativeArray" then return invalid
    kind = LCase(Str_Of(row["type"]))
    progress = 0.0
    if row.progress <> invalid then progress = 0.0 + row.progress
    if progress < 1 or progress > 95 then return invalid
    updated = Track_Time(Str_Of(row.paused_at))
    if updated = 0 then updated = Track_Time(Str_Of(row.updated_at))
    if kind = "movie"
        mv = row.movie
        if type(mv) <> "roAssociativeArray" then return invalid
        id = Track_Id(mv.ids)
        if id = "" then return invalid
        dur = ToInt(mv.runtime, 0) * 60
        if dur <= 0 then dur = 6000
        return { metaId: id, videoId: id, kind: "movie", title: Str_Of(mv.title), poster: Track_Poster(id, Track_Image(mv.images, "poster")), background: Img_Background(id), episode: "", position: Int(dur * progress / 100), duration: dur, updated: updated, remote: source, remoteId: Str_Any(row.id) }
    end if
    if kind = "episode"
        show = row.show
        ep = row.episode
        if type(show) <> "roAssociativeArray" or type(ep) <> "roAssociativeArray" then return invalid
        id = Track_Id(show.ids)
        s = ToInt(ep.season, -1)
        n = ToInt(ep.number, ToInt(ep.episode, -1))
        if id = "" or s < 0 or n < 1 then return invalid
        dur = ToInt(ep.runtime, ToInt(show.runtime, 0)) * 60
        if dur <= 0 then dur = 2700
        label = L("T") + s.ToStr() + ":E" + n.ToStr()
        if Str_Of(ep.title) <> "" then label = label + "  " + Str_Of(ep.title)
        vid = id + ":" + s.ToStr() + ":" + n.ToStr()
        return { metaId: id, videoId: vid, kind: "series", title: Str_Of(show.title), poster: Track_Poster(id, Track_Image(show.images, "poster")), background: Img_Background(id), episode: label, altIds: [vid], position: Int(dur * progress / 100), duration: dur, season: s, ep: n, updated: updated, remote: source, remoteId: Str_Any(row.id) }
    end if
    return invalid
end function

function Track_History(source as string, integ as object) as object
    watched = {}
    if source = "trakt"
        r = Trakt_Get("/sync/history/episodes?limit=100", integ)
        if type(r.json) = "roArray"
            for each row in r.json
                if type(row) = "roAssociativeArray" and type(row.show) = "roAssociativeArray" and type(row.episode) = "roAssociativeArray"
                    id = Track_Id(row.show.ids)
                    at = Track_Time(Str_Of(row.watched_at))
                    if id <> "" then Track_MarkSeen(watched, id, ToInt(row.episode.season, -1), ToInt(row.episode.number, -1), at)
                end if
            end for
        end if
    else if source = "mdblist"
        r = Mdb_Read("/sync/watched?limit=100", integ)
        j = r.json
        if type(j) = "roAssociativeArray"
            if type(j.episodes) = "roArray"
                for each row in j.episodes
                    if type(row) = "roAssociativeArray" and type(row.episode) = "roAssociativeArray"
                        show = row.show
                        if type(show) <> "roAssociativeArray" then show = row.episode.show
                        if type(show) = "roAssociativeArray"
                            at = Track_Time(Str_Of(row.watched_at))
                            if at = 0 then at = Track_Time(Str_Of(row.last_watched_at))
                            Track_MarkSeen(watched, Track_Id(show.ids), ToInt(row.episode.season, -1), ToInt(row.episode.number, ToInt(row.episode.episode, -1)), at)
                        end if
                    end if
                end for
            end if
            if type(j.shows) = "roArray"
                for each row in j.shows
                    if type(row) = "roAssociativeArray" and type(row.show) = "roAssociativeArray" and type(row.seasons) = "roArray"
                        id = Track_Id(row.show.ids)
                        for each season in row.seasons
                            if type(season) = "roAssociativeArray" and type(season.episodes) = "roArray"
                                for each ep in season.episodes
                                    if type(ep) = "roAssociativeArray"
                                        at = Track_Time(Str_Of(ep.last_watched_at))
                                        if at = 0 then at = Track_Time(Str_Of(row.last_watched_at))
                                        Track_MarkSeen(watched, id, ToInt(season.number, -1), ToInt(ep.number, -1), at)
                                    end if
                                end for
                            end if
                        end for
                    end if
                end for
            end if
        end if
    end if
    return watched
end function

sub Track_MarkSeen(watched as object, id as string, s as integer, e as integer, at as integer)
    if Left(id, 2) <> "tt" or s < 0 or e < 1 then return
    key = St_WatchedKey(id, s, e)
    old = watched[key]
    if old = invalid or at > ToInt(old.at, 0) then watched[key] = { at: at }
end sub

function Track_LibraryRows(source as string, integ as object) as dynamic
    rows = []
    if source = "trakt"
        r = Trakt_Get("/sync/watchlist?extended=full,images&sort_by=added&sort_how=desc", integ)
        if type(r.json) <> "roArray" then return invalid
        rows.Push({ key: "watchlist", title: L("Watchlist de Trakt"), items: Track_TraktItems(r.json) })
        lists = Trakt_Get("/users/me/lists", integ)
        if type(lists.json) = "roArray"
            for each lst in lists.json
                if rows.Count() >= 7 then exit for
                if type(lst) = "roAssociativeArray" and type(lst.ids) = "roAssociativeArray"
                    lid = Str_Any(lst.ids.trakt)
                    if lid <> ""
                        items = Trakt_Get("/users/me/lists/" + lid + "/items?extended=full,images&limit=100", integ)
                        if type(items.json) = "roArray" then rows.Push({ key: "list:" + lid, title: Str_Of(lst.name), items: Track_TraktItems(items.json) })
                    end if
                end if
            end for
        end if
    else if source = "mdblist"
        r = Mdb_Read("/watchlist/items?limit=200&unified=true", integ)
        items = Track_MdbItems(r.json)
        if items = invalid then return invalid
        rows.Push({ key: "watchlist", title: L("Watchlist de MDBList"), items: items })
        lists = Mdb_Read("/lists/user", integ)
        found = lists.json
        if type(found) = "roAssociativeArray" and type(found.lists) = "roArray" then found = found.lists
        if type(found) = "roArray"
            for each lst in found
                if rows.Count() >= 7 then exit for
                if type(lst) = "roAssociativeArray" and Str_Any(lst.id) <> ""
                    got = Mdb_Read("/lists/" + Str_Any(lst.id) + "/items?limit=200&unified=true", integ)
                    li = Track_MdbItems(got.json)
                    if li <> invalid then rows.Push({ key: "list:" + Str_Any(lst.id), title: Str_Of(lst.name), items: li })
                end if
            end for
        end if
    end if
    return rows
end function

function Track_TraktItems(list as object) as object
    out = []
    for each row in list
        if type(row) = "roAssociativeArray"
            kind = LCase(Str_Of(row["type"]))
            e = invalid
            if kind = "movie" then e = row.movie
            if kind = "show" then e = row.show
            if type(e) = "roAssociativeArray"
                id = Track_Id(e.ids)
                if id <> ""
                    k = "movie"
                    if kind = "show" then k = "series"
                    out.Push({ id: id, kind: k, name: Str_Of(e.title), poster: Track_Poster(id, Track_Image(e.images, "poster")) })
                end if
            end if
        end if
        if out.Count() >= 100 then exit for
    end for
    return out
end function

function Track_MdbItems(j as dynamic) as dynamic
    rows = []
    if type(j) = "roArray"
        for each r in j
            rows.Push({ row: r, kind: "" })
        end for
    else if type(j) = "roAssociativeArray"
        if type(j.items) = "roArray"
            for each r in j.items
                rows.Push({ row: r, kind: "" })
            end for
        else if type(j.movies) = "roArray" or type(j.shows) = "roArray"
            if type(j.movies) = "roArray"
                for each r in j.movies
                    rows.Push({ row: r, kind: "movie" })
                end for
            end if
            if type(j.shows) = "roArray"
                for each r in j.shows
                    rows.Push({ row: r, kind: "show" })
                end for
            end if
        else
            return invalid
        end if
    else
        return invalid
    end if
    out = []
    for each it in rows
        row = it.row
        if type(row) = "roAssociativeArray"
            kind = LCase(Str_Of(row.mediatype))
            if kind = "" then kind = LCase(Str_Of(row["type"]))
            if kind = "" then kind = it.kind
            if kind = "show" or kind = "tv" or kind = "series" or kind = "anime" or kind = "movie"
                ids = { imdb: Str_Of(row.imdb_id), tmdb: row.id }
                if type(row.ids) = "roAssociativeArray"
                    if Str_Of(row.ids.imdb) <> "" then ids.imdb = row.ids.imdb
                    if row.ids.tmdb <> invalid then ids.tmdb = row.ids.tmdb
                end if
                id = Track_Id(ids)
                if id <> ""
                    k = "series"
                    if kind = "movie" then k = "movie"
                    title = Str_Of(row.title)
                    if title = "" then title = Str_Of(row.name)
                    out.Push({ id: id, kind: k, name: title, poster: Track_Poster(id, Str_Of(row.poster)) })
                end if
            end if
        end if
        if out.Count() >= 100 then exit for
    end for
    return out
end function

function Track_Target(id as string, kind as string) as object
    ids = {}
    if Left(id, 2) = "tt"
        ids.imdb = id.Split(":")[0]
    else if LCase(Left(id, 5)) = "tmdb:"
        ids.tmdb = Mid(id, 6).Split(":")[0].ToInt()
    end if
    bucket = "movies"
    k = LCase(kind)
    if k = "series" or k = "tv" or k = "show" then bucket = "shows"
    return { bucket: bucket, ids: ids }
end function

sub Track_ApplyOps(source as string, integ as object, pid as string)
    ops = St_ReadFile("tops_" + pid)
    if type(ops) <> "roArray" or ops.Count() = 0 then return
    pending = []
    for each op in ops
        done = false
        if type(op) = "roAssociativeArray" and Str_Of(op.source) = source
            t = Track_Target(Str_Of(op.id), Str_Of(op.kind))
            if t.ids.Count() = 0
                done = true
            else if Str_Of(op.op) = "add" or Str_Of(op.op) = "remove"
                body = {}
                body[t.bucket] = [{ ids: t.ids }]
                path = "/sync/watchlist"
                if source = "mdblist" then path = "/watchlist/items"
                if op.op = "add"
                    if source = "mdblist" then path = path + "/add"
                else
                    path = path + "/remove"
                end if
                r = invalid
                if source = "trakt" then r = Trakt_Send("POST", path, integ, body)
                if source = "mdblist" then r = Mdb_Send("POST", path, integ, body)
                done = r.code >= 200 and r.code < 300
                if r.code >= 400 and r.code < 500 and r.code <> 401 and r.code <> 429 then done = true
            else if Str_Of(op.op) = "dropProgress"
                rid = Str_Of(op.remoteId)
                if rid = ""
                    done = true
                else
                    r = invalid
                    if source = "trakt" then r = Trakt_Send("DELETE", "/sync/playback/" + rid, integ, invalid)
                    if source = "mdblist" then r = Mdb_Send("DELETE", "/sync/playback/" + rid, integ, invalid)
                    done = (r.code >= 200 and r.code < 300) or r.code = 404
                end if
            end if
        else
            done = true
        end if
        if not done then pending.Push(op)
    end for
    St_WriteFile("tops_" + pid, pending)
end sub

function Track_Refresh() as object
    integ = St_Integrations()
    p = St_ActiveProfile()
    if p = invalid then return { ok: false }
    pid = p.id
    cw = Track_CwSource(integ)
    lib = Track_LibSource(integ)
    if cw = "" and lib = "" then return { ok: false }
    if cw <> "" then Track_ApplyOps(cw, integ, pid)
    if lib <> "" and lib <> cw then Track_ApplyOps(lib, integ, pid)
    changed = false
    if cw <> ""
        list = Track_Playback(cw, integ)
        if list <> invalid
            drops = St_ReadFile("tdrop_" + pid)
            if type(drops) <> "roAssociativeArray" then drops = {}
            kept = []
            busy = {}
            for each e in list
                if not drops.DoesExist(e.metaId) or ToInt(drops[e.metaId], 0) < ToInt(e.updated, 0)
                    kept.Push(e)
                    busy[e.metaId] = true
                end if
            end for
            history = Track_History(cw, integ)
            for each nu in NextUp_Fresh(history, busy)
                if not drops.DoesExist(nu.metaId) or ToInt(drops[nu.metaId], 0) < ToInt(nu.updated, 0) then kept.Push(nu)
            end for
            kept.SortBy("updated", "r")
            while kept.Count() > 20
                kept.Pop()
            end while
            St_WriteFile("tprogress_" + pid, { source: cw, at: St_Now(), items: kept })
            changed = true
        end if
    end if
    if lib <> ""
        rows = Track_LibraryRows(lib, integ)
        if rows <> invalid
            St_WriteFile("tlib_" + pid, { source: lib, at: St_Now(), rows: rows })
            changed = true
        end if
    end if
    return { ok: changed }
end function
