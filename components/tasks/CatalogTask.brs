sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    if m.top.folder <> invalid and type(m.top.folder.sources) = "roArray"
        Folder_Execute()
        return
    end if
    addons = St_Addons()
    prefs = St_Prefs()
    m.prefs = prefs
    m.cachePath = "cachefs:/home_" + St_ActiveProfile().id + ".json"
    cache = Home_ReadCache(addons)
    cachedManifests = {}
    if cache <> invalid
        for each entry in cache.manifests
            if type(entry) = "roAssociativeArray" then cachedManifests[Str_Of(entry.base)] = entry
        end for
        m.top.addonCount = addons.Count()
        m.top.failed = 0
        m.top.manifests = cache.manifests
        m.top.catalogs = cache.catalogs
        m.top.early = Home_Build(cache.rows, prefs, true)
    end if

    manifestUrls = []
    for each base in addons
        manifestUrls.Push(base + "/manifest.json")
    end for
    raw = Http_FetchHook(manifestUrls, 15000, 0, 8, invalid).data

    manifests = []
    failed = 0
    for i = 0 to addons.Count() - 1
        man = raw[i]
        if type(man) = "roAssociativeArray"
            manifests.Push({
                base: addons[i]
                name: Addon_Name(man, addons[i])
                manifest: {
                    id: Str_Of(man.id)
                    name: Str_Of(man.name)
                    resources: man.resources
                    types: man.types
                    idPrefixes: man.idPrefixes
                }
                catalogs: Home_SlimCatalogs(man.catalogs)
                search: Addon_SearchCatalogs(man)
            })
        else if cachedManifests.DoesExist(addons[i])
            manifests.Push(cachedManifests[addons[i]])
        else
            failed = failed + 1
        end if
    end for

    all = []
    seen = {}
    for each entry in manifests
        if type(entry.catalogs) = "roArray"
            for each cat in entry.catalogs
                if type(cat) = "roAssociativeArray" and IsStr(cat["type"]) and IsStr(cat.id)
                    if not Addon_RequiresExtra(cat)
                        key = St_CatalogKey(entry.manifest, entry.base, cat)
                        if seen.DoesExist(key) then key = key + "|" + all.Count().ToStr()
                        seen[key] = true
                        name = Str_Of(cat.name).Trim()
                        if name = "" then name = cat.id
                        all.Push({
                            key: key
                            name: name
                            kind: cat["type"]
                            id: cat.id
                            addon: entry.name
                            base: entry.base
                            hidden: prefs.hidden.DoesExist(key)
                            status: ""
                            count: 0
                        })
                    end if
                end if
            end for
        end if
    end for

    ordered = St_ApplyOrder(all, prefs.order)
    visible = []
    urls = []
    for each c in ordered
        if not c.hidden
            visible.Push(c)
            urls.Push(Addon_ResourceUrl(c.base, "catalog", c.kind, c.id))
        end if
    end for
    slim = []
    for each entry in manifests
        copy = {}
        copy.Append(entry)
        copy.Delete("catalogs")
        slim.Push(copy)
    end for
    m.top.addonCount = addons.Count()
    m.top.failed = failed
    m.top.catalogs = ordered
    m.top.manifests = slim
    m.visible = visible
    m.rowData = []
    m.shownPrefix = 0
    m.progressive = cache = invalid
    m.pattern = Poster_Pattern("home")
    for i = 0 to visible.Count() - 1
        m.rowData.Push(invalid)
    end for
    hook = Home_OnResult
    fetched = Http_FetchHook(urls, 30000, prefs.rowSize, 10, hook)
    for i = 0 to visible.Count() - 1
        if m.rowData[i] = invalid then Home_OnResult(i, fetched.data, fetched.diag)
    end for

    Progress_Enrich(manifests)
    saved = {}
    if cache <> invalid
        for each r in cache.rows
            if type(r) = "roAssociativeArray" and type(r.items) = "roArray" and r.items.Count() > 0 then saved[Str_Of(r.key)] = r
        end for
    end if
    rows = []
    for i = 0 to visible.Count() - 1
        r = m.rowData[i]
        if type(r) = "roAssociativeArray" and r.items.Count() > 0
            rows.Push(r)
        else if saved.DoesExist(visible[i].key)
            rows.Push(saved[visible[i].key])
        end if
    end for
    root = Home_Build(rows, prefs, true)

    Home_WriteCache(addons, manifests, ordered, rows)
    for each entry in manifests
        if type(entry) = "roAssociativeArray" then entry.Delete("catalogs")
    end for
    m.top.addonCount = addons.Count()
    m.top.failed = failed
    m.top.manifests = manifests
    m.top.catalogs = ordered
    m.top.content = root
end sub

function Home_SlimCatalogs(list as dynamic) as dynamic
    if type(list) <> "roArray" then return list
    out = []
    for each cat in list
        if type(cat) = "roAssociativeArray"
            slim = { "type": cat["type"], id: cat.id, name: cat.name }
            if cat.DoesExist("extra") then slim.extra = cat.extra
            if cat.DoesExist("extraRequired") then slim.extraRequired = cat.extraRequired
            if cat.DoesExist("extraSupported") then slim.extraSupported = cat.extraSupported
            out.Push(slim)
        end if
    end for
    return out
end function

sub Names_Items(list as object)
    foreign = []
    for each it in list
        if Str_HasForeign(it.title)
            foreign.Push({ id: Str_Of(it.metaId), kind: Str_Of(it.kind), title: it.title, original: it.title, ref: it })
        else
            it.title = Str_Glyphs(it.title)
        end if
    end for
    if foreign.Count() = 0 then return
    Names_Translate(foreign)
    for each f in foreign
        f.ref.title = f.title
    end for
end sub

sub Home_OnResult(index as integer, data as object, diag as object)
    if m.rowData[index] <> invalid then return
    c = m.visible[index]
    status = diag[index]
    if status = "ok" then status = L("Sin títulos")
    row = { key: c.key, name: c.name, kind: c.kind, shape: "poster", items: [] }
    parsed = data[index]
    if type(parsed) = "roAssociativeArray" and type(parsed.metas) = "roArray" and parsed.metas.Count() > 0
        row.shape = Catalog_Shape(parsed.metas)
        rowPattern = m.pattern
        if row.shape <> "poster" then rowPattern = ""
        for each meta in parsed.metas
            if row.items.Count() >= m.prefs.rowSize then exit for
            if type(meta) = "roAssociativeArray" and IsStr(meta.id) then row.items.Push(Catalog_ItemData(meta, c.kind, rowPattern))
        end for
        if row.items.Count() > 0 then status = "ok"
        Names_Items(row.items)
    end if
    c.status = status
    c.count = row.items.Count()
    m.rowData[index] = row
    data[index] = invalid
    if not m.progressive then return
    prefix = m.shownPrefix
    while prefix < m.rowData.Count() and m.rowData[prefix] <> invalid
        prefix = prefix + 1
    end while
    if prefix = m.shownPrefix then return
    rows = []
    for i = 0 to prefix - 1
        r = m.rowData[i]
        if r.items.Count() > 0 then rows.Push(r)
    end for
    if rows.Count() < 2 and prefix < m.rowData.Count() then return
    m.shownPrefix = prefix
    m.top.early = Home_Build(rows, m.prefs, false)
end sub

function Home_Build(rows as object, prefs as object, withCollections as boolean) as object
    root = CreateObject("roSGNode", "ContentNode")
    cw = Content_ContinueRow()
    if cw <> invalid then root.appendChild(cw)
    hidden = prefs.hidden
    if type(hidden) <> "roAssociativeArray" then hidden = {}
    for each r in rows
        if type(r) = "roAssociativeArray" and type(r.items) = "roArray" and r.items.Count() > 0 and not hidden.DoesExist(Str_Of(r.key))
            row = root.createChild("ContentNode")
            row.title = Str_Glyphs(Str_Of(r.name)).Trim() + "  ·  " + TypePlural(Str_Of(r.kind))
            if type(prefs.titles) = "roAssociativeArray" and IsStr(prefs.titles[r.key]) then row.title = Str_Glyphs(prefs.titles[r.key]).Trim()
            row.addFields({ key: Str_Of(r.key), shape: Str_Of(r.shape) })
            for each item in r.items
                Content_Item(row, item)
            end for
        end if
    end for
    if withCollections
        Collections_Rows(root, prefs)
    else
        Rows_Sort(root, prefs.order)
    end if
    return root
end function

function Home_Signature(addons as object) as string
    return addons.Join("|") + "#" + ToInt(St_Prefs().rowSize, 0).ToStr() + "#" + Str_Of(St_Pref("customPoster"))
end function

function Home_ReadCache(addons as object) as dynamic
    if addons.Count() = 0 then return invalid
    text = ReadAsciiFile(m.cachePath)
    if text = "" then return invalid
    cache = ParseJson(text)
    if type(cache) <> "roAssociativeArray" then return invalid
    if Str_Of(cache.sig) <> Home_Signature(addons) then return invalid
    if type(cache.rows) <> "roArray" or cache.rows.Count() = 0 then return invalid
    if type(cache.manifests) <> "roArray" then return invalid
    if type(cache.catalogs) <> "roArray" then cache.catalogs = []
    return cache
end function

sub Home_WriteCache(addons as object, manifests as object, catalogs as object, rows as object)
    if rows.Count() = 0 then return
    full = []
    for each entry in manifests
        copy = {}
        copy.Append(entry)
        full.Push(copy)
    end for
    WriteAsciiFile(m.cachePath, FormatJson({ sig: Home_Signature(addons), manifests: full, catalogs: catalogs, rows: rows }))
end sub

sub Progress_Enrich(manifests as object)
    list = St_Progress()
    jobs = []
    urls = []
    for i = 0 to list.Count() - 1
        e = list[i]
        if Str_Of(e.poster) = "" or Str_Of(e.title) = ""
            kind = Str_Of(e.kind)
            if kind = "" then kind = "movie"
            url = ""
            for each entry in manifests
                if url = "" and Addon_Supports(entry.manifest, "meta", kind, e.metaId) then url = Addon_ResourceUrl(entry.base, "meta", kind, e.metaId)
            end for
            if url = "" and Left(e.metaId, 2) = "tt" then url = Addon_ResourceUrl("https://v3-cinemeta.strem.io", "meta", kind, e.metaId)
            if url <> ""
                jobs.Push(i)
                urls.Push(url)
            end if
        end if
    end for
    if urls.Count() = 0 then return
    results = Http_FetchJsonAll(urls, 12000)
    changed = false
    for j = 0 to jobs.Count() - 1
        data = results[j]
        if type(data) = "roAssociativeArray" and type(data.meta) = "roAssociativeArray"
            e = list[jobs[j]]
            meta = data.meta
            if Str_Of(e.title) = "" then e.title = Str_Of(meta.name)
            if Str_Of(e.poster) = "" then e.poster = Str_Of(meta.poster)
            if Str_Of(e.background) = "" then e.background = Str_Of(meta.background)
            changed = true
        end if
    end for
    if changed then St_Set(St_ProgressKey(), list)
end sub

function Catalog_Shape(metas as object) as string
    counts = { poster: 0, landscape: 0, square: 0 }
    checked = 0
    for each meta in metas
        if checked >= 10 then exit for
        if type(meta) = "roAssociativeArray"
            shape = LCase(Str_Of(meta.posterShape))
            if shape = "regular" or shape = "" then shape = "poster"
            if counts.DoesExist(shape) then counts[shape] = counts[shape] + 1
            checked = checked + 1
        end if
    end for
    best = "poster"
    if counts.landscape > counts[best] then best = "landscape"
    if counts.square > counts[best] then best = "square"
    return best
end function

sub Collections_Rows(root as object, prefs as object)
    cols = St_ReadFile("collections_" + St_ActiveProfile().id)
    if type(cols) <> "roArray" or cols.Count() = 0 then return
    hidden = prefs.hidden
    if type(hidden) <> "roAssociativeArray" then hidden = {}
    for each col in cols
        if type(col) = "roAssociativeArray" and type(col.folders) = "roArray" and col.folders.Count() > 0
            key = "col:" + Str_Of(col.id)
            if not hidden.DoesExist(key)
                row = root.createChild("ContentNode")
                row.title = Str_Glyphs(Str_Of(col.title)).Trim()
                shape = "square"
                first = col.folders[0]
                if type(first) = "roAssociativeArray" and Str_Of(first.shape) <> "" then shape = first.shape
                row.addFields({ key: key, shape: shape, pinned: Bool_Of(col.pin, false) })
                for each folder in col.folders
                    if type(folder) = "roAssociativeArray"
                        cover = Img_Fix(Str_Of(folder.cover))
                        if cover = "" then cover = Img_Fix(Str_Of(col.backdrop))
                        item = Content_Item(row, {
                            title: Str_Glyphs(Str_Of(folder.title)).Trim()
                            poster: cover
                            logo: Img_Fix(Str_Of(folder.logo))
                            description: ""
                            kind: "folder"
                            metaId: "folder:" + Str_Of(col.id) + ":" + Str_Of(folder.id)
                            videoId: ""
                            background: Img_Fix(Folder_Back(folder))
                            metaLine: Str_Of(col.title)
                            episodeLabel: ""
                            progress: 0.0
                        })
                        item.addFields({ gif: Img_Fix(Str_Of(folder.gif)), heroVideo: Str_Of(folder.video), colTitle: Str_Glyphs(Str_Of(col.title)).Trim(), hideTitle: Bool_Of(folder.hideTitle, false), folder: { title: Str_Of(folder.title), sources: folder.sources, backdrop: Str_Of(folder.backdrop) } })
                    end if
                end for
            end if
        end if
    end for
    Rows_Sort(root, prefs.order)
end sub

sub Rows_Sort(root as object, order as dynamic)
    rank = {}
    if type(order) = "roArray"
        for i = 0 to order.Count() - 1
            if IsStr(order[i]) then rank[order[i]] = i
        end for
    end if
    entries = []
    for i = 0 to root.getChildCount() - 1
        row = root.getChild(i)
        r = 100000 + i
        if row.id = "cw"
            r = -2
        else if row.hasField("pinned") and row.pinned
            r = -1
        else if row.hasField("key") and rank.DoesExist(row.key)
            r = rank[row.key]
        end if
        entries.Push({ row: row, r: r })
    end for
    sorted = []
    while entries.Count() > 0
        best = 0
        for j = 1 to entries.Count() - 1
            if entries[j].r < entries[best].r then best = j
        end for
        sorted.Push(entries[best].row)
        entries.Delete(best)
    end while
    root.removeChildrenIndex(root.getChildCount(), 0)
    root.appendChildren(sorted)
end sub

sub Folder_Execute()
    f = m.top.folder
    manifests = m.top.baseManifests
    if manifests = invalid then manifests = []
    prefs = St_Prefs()
    urls = []
    infos = []
    integ = St_Integrations()
    tmdbKey = Key_Tmdb(integ)
    lang = Tmdb_Lang()
    for each src in f.sources
        if type(src) = "roAssociativeArray"
            provider = LCase(Str_Of(src.provider))
            if provider = "" or provider = "addon"
                base = St_NormalizeUrl(Str_Of(src.base))
                if base = ""
                    for each entry in manifests
                        if base = "" and entry.manifest <> invalid and entry.manifest.id = Str_Of(src.addonId) then base = entry.base
                    end for
                end if
                if base = "" then Folder_Fail(L("Addon no instalado: ") + Str_Of(src.addonId), -1)
                if base <> "" and Str_Of(src["type"]) <> "" and Str_Of(src.catalogId) <> ""
                    url = Addon_ResourceUrl(base, "catalog", src["type"], src.catalogId)
                    genre = Str_Of(src.genre)
                    if genre <> "" then url = Left(url, Len(url) - 5) + "/genre=" + genre.EncodeUriComponent() + ".json"
                    urls.Push(url)
                    title = Str_Of(src.title)
                    if title = "" then title = TypePlural(src["type"])
                    infos.Push({ title: title, kind: src["type"], provider: "addon" })
                end if
            else if provider = "tmdb" and tmdbKey <> ""
                if UCase(Str_Of(src.tmdbSourceType)) = "PERSON" and Str_Any(src.tmdbId) = "" and Str_Of(src.personName) <> ""
                    found = Http_Request("GET", "https://api.themoviedb.org/3/search/person?api_key=" + tmdbKey + "&language=" + lang + "&query=" + Str_Of(src.personName).EncodeUriComponent(), {}, invalid, 10000).json
                    if type(found) = "roAssociativeArray" and type(found.results) = "roArray" and found.results.Count() > 0 then src.tmdbId = Str_Any(found.results[0].id)
                end if
                job = Folder_TmdbUrl(src, tmdbKey, lang)
                if job <> invalid
                    urls.Push(job.url)
                    infos.Push(job)
                end if
            else if provider = "trakt"
                req = Folder_TraktRequest(src, "")
                if req = invalid
                    Folder_Fail("Trakt", 0)
                else
                    infos.Push({ title: Str_Of(src.title), provider: "trakt", src: src })
                    urls.Push(req)
                end if
            else if provider = "mdblist" and Str_Of(integ.mdbKey) <> ""
                infos.Push({ title: Str_Of(src.title), provider: "mdblist", src: src })
                urls.Push("")
            end if
        end if
    end for
    root = CreateObject("roSGNode", "ContentNode")
    if urls.Count() > 0
        direct = []
        index = []
        for i = 0 to urls.Count() - 1
            if type(urls[i]) = "roAssociativeArray" or urls[i] <> ""
                direct.Push(urls[i])
                index.Push(i)
            end if
        end for
        results = []
        codes = []
        for i = 0 to urls.Count() - 1
            results.Push(invalid)
            codes.Push(0)
        end for
        if direct.Count() > 0
            fetched = Http_FetchHook(direct, 30000, 0, 8, invalid)
            for j = 0 to index.Count() - 1
                results[index[j]] = fetched.data[j]
                codes[index[j]] = fetched.codes[j]
            end for
        end if
        for i = 0 to infos.Count() - 1
            info = infos[i]
            metas = invalid
            if info.provider = "addon"
                data = results[i]
                if type(data) = "roAssociativeArray" and type(data.metas) = "roArray" then metas = data.metas
            else if info.provider = "tmdb"
                metas = Folder_TmdbMetas(results[i], info)
                if type(results[i]) <> "roAssociativeArray" then Folder_Fail("TMDB", 0)
            else if info.provider = "trakt"
                metas = Folder_TraktMetas(info.src, results[i], codes[i])
            else if info.provider = "mdblist"
                metas = Folder_MdbMetas(info.src, integ.mdbKey)
            end if
            groups = [{ title: Str_Of(info.title), metas: metas }]
            if (Str_Of(info.mode) = "person" or Str_Of(info.mode) = "director") and type(metas) = "roArray"
                movies = []
                shows = []
                for each mt in metas
                    if mt["type"] = "series" then shows.Push(mt) else movies.Push(mt)
                end for
                groups = [{ title: L("Películas"), metas: movies }, { title: L("Series"), metas: shows }]
            end if
            for each grp in groups
                metas = grp.metas
                info.title = grp.title
                if type(metas) = "roArray" and metas.Count() > 0
                    row = root.createChild("ContentNode")
                    row.title = Str_Glyphs(Str_Of(info.title)).Trim()
                    shape = Catalog_Shape(metas)
                    row.addFields({ shape: shape })
                    batch = []
                    for each meta in metas
                        if batch.Count() >= prefs.rowSize then exit for
                        if type(meta) = "roAssociativeArray" and IsStr(meta.id)
                            kind = Str_Of(info.kind)
                            if kind = "" then kind = Str_Of(meta["type"])
                            batch.Push(Catalog_ItemData(meta, kind, ""))
                        end if
                    end for
                    Names_Items(batch)
                    for each data in batch
                        Content_Item(row, data)
                    end for
                end if
            end for
        end for
    end if
    if m.folderFails <> invalid then m.top.folderFails = m.folderFails
    m.top.content = root
end sub


function Folder_TmdbUrl(src as object, key as string, lang as string) as dynamic
    api = "https://api.themoviedb.org/3"
    kind = UCase(Str_Of(src.tmdbSourceType))
    id = Str_Any(src.tmdbId)
    media = "movie"
    if UCase(Str_Of(src.mediaType)) = "TV" or kind = "NETWORK" then media = "tv"
    title = Str_Of(src.title)
    q = "api_key=" + key + "&language=" + lang
    if kind = "COLLECTION" and id <> "" then return { url: api + "/collection/" + id + "?" + q, provider: "tmdb", kind: "movie", mode: "parts", title: title }
    if kind = "LIST" and id <> "" then return { url: api + "/list/" + id + "?" + q, provider: "tmdb", kind: "", mode: "items", media: media, title: title }
    if (kind = "PERSON" or kind = "DIRECTOR") and id <> "" then return { url: api + "/person/" + id + "/combined_credits?" + q, provider: "tmdb", kind: "", mode: LCase(kind), media: media, title: title }
    sortBy = Str_Of(src.sortBy)
    if sortBy = "" or sortBy = "original"
        sortBy = "popularity.desc"
    end if
    params = [q, "page=1", "sort_by=" + sortBy]
    filters = src.filters
    if type(filters) <> "roAssociativeArray" then filters = {}
    tv = media = "tv"
    pairs = [["withGenres", "with_genres"], ["withoutGenres", "without_genres"], ["voteAverageGte", "vote_average.gte"], ["voteAverageLte", "vote_average.lte"], ["voteCountGte", "vote_count.gte"], ["withOriginalLanguage", "with_original_language"], ["withOriginCountry", "with_origin_country"], ["withKeywords", "with_keywords"], ["withoutKeywords", "without_keywords"], ["withCompanies", "with_companies"], ["withoutCompanies", "without_companies"], ["withoutWatchProviders", "without_watch_providers"]]
    for each pr in pairs
        v = Str_Any(filters[pr[0]])
        if pr[0] = "voteAverageLte" and (v = "0" or v = "0.0") then v = ""
        if v <> "" then params.Push(pr[1] + "=" + v.EncodeUriComponent())
    end for
    gte = Str_Any(filters.releaseDateGte)
    lte = Str_Any(filters.releaseDateLte)
    if tv
        if gte <> "" then params.Push("first_air_date.gte=" + gte)
        if lte <> "" then params.Push("first_air_date.lte=" + lte)
        if Str_Any(filters.withNetworks) <> "" then params.Push("with_networks=" + Str_Any(filters.withNetworks).EncodeUriComponent())
    else
        if gte <> "" then params.Push("primary_release_date.gte=" + gte)
        if lte <> "" then params.Push("primary_release_date.lte=" + lte)
    end if
    year = ToInt(filters.year, 0)
    if year > 0
        if tv then params.Push("first_air_date_year=" + year.ToStr()) else params.Push("year=" + year.ToStr())
    end if
    if Str_Any(filters.withWatchProviders) <> ""
        region = Str_Any(filters.watchRegion)
        if region = "" then region = "US"
        params.Push("watch_region=" + region)
        params.Push("with_watch_providers=" + Str_Any(filters.withWatchProviders).EncodeUriComponent())
        params.Push("with_watch_monetization_types=" + "flatrate|free|ads|rent|buy".EncodeUriComponent())
    end if
    if kind = "COMPANY" and id <> "" then params.Push("with_companies=" + id)
    if kind = "NETWORK" and id <> ""
        params.Push("with_networks=" + id)
        params.Push("with_status=" + "0|3|4".EncodeUriComponent())
    end if
    return { url: api + "/discover/" + media + "?" + params.Join("&"), provider: "tmdb", kind: "", mode: "results", media: media, title: title }
end function

function Folder_TmdbMeta(item as dynamic, media as string) as dynamic
    if type(item) <> "roAssociativeArray" or item.id = invalid then return invalid
    m2 = Str_Of(item.media_type)
    if m2 = "" then m2 = media
    if m2 <> "movie" and m2 <> "tv" then return invalid
    name = Str_Of(item.title)
    if name = "" then name = Str_Of(item.name)
    if name = "" then return invalid
    kind = "movie"
    if m2 = "tv" then kind = "series"
    poster = ""
    if Str_Of(item.poster_path) <> "" then poster = "https://image.tmdb.org/t/p/w342" + item.poster_path
    back = ""
    if Str_Of(item.backdrop_path) <> "" then back = "https://image.tmdb.org/t/p/w1280" + item.backdrop_path
    if poster = "" then poster = back
    date = Str_Of(item.release_date)
    if date = "" then date = Str_Of(item.first_air_date)
    rating = ""
    if item.vote_average <> invalid and item.vote_average > 0 then rating = Str(Int(item.vote_average * 10) / 10).Trim()
    return { id: "tmdb:" + Str_Any(item.id), type: kind, name: name, poster: poster, background: back, description: Str_Of(item.overview), releaseInfo: Left(date, 4), released: date, imdbRating: rating }
end function

function Folder_TmdbMetas(data as dynamic, info as object) as object
    out = []
    if type(data) <> "roAssociativeArray" then return out
    list = invalid
    media = Str_Of(info.media)
    if info.mode = "parts"
        list = data.parts
        media = "movie"
    else if info.mode = "items"
        list = data.items
    else if info.mode = "person"
        list = data.cast
    else if info.mode = "director"
        crew = []
        if type(data.crew) = "roArray"
            for each c in data.crew
                if type(c) = "roAssociativeArray" and LCase(Str_Of(c.job)) = "director" then crew.Push(c)
            end for
        end if
        list = crew
    else
        list = data.results
    end if
    if type(list) <> "roArray" then return out
    if Str_Of(info.mode) = "person" or Str_Of(info.mode) = "director" then list = Folder_ByVotes(list)
    seen = {}
    for each item in list
        meta = Folder_TmdbMeta(item, media)
        if meta <> invalid and not seen.DoesExist(meta.id)
            seen[meta.id] = true
            out.Push(meta)
        end if
    end for
    return out
end function

function Folder_ByVotes(list as object) as object
    pool = []
    for each item in list
        if type(item) = "roAssociativeArray" then pool.Push(item)
    end for
    out = []
    while pool.Count() > 0 and out.Count() < 60
        best = 0
        for i = 1 to pool.Count() - 1
            if ToInt(pool[i].vote_count, 0) > ToInt(pool[best].vote_count, 0) then best = i
        end for
        out.Push(pool[best])
        pool.Delete(best)
    end while
    return out
end function

function Folder_TraktMedia(src as object) as string
    mt = UCase(Str_Of(src.mediaType))
    if mt = "TV" or mt = "SHOW" or mt = "SERIES" then return "show"
    return "movie"
end function

function Folder_TraktRequest(src as object, media as string) as dynamic
    client = Config_TraktClientId()
    listId = Str_Any(src.traktListId)
    if client = "" or listId = "" then return invalid
    if media = "" then media = Folder_TraktMedia(src)
    sortBy = Str_Of(src.sortBy)
    if sortBy = "" then sortBy = "rank"
    sortHow = Str_Of(src.sortHow)
    if sortHow = "" then sortHow = "asc"
    headers = { "Content-Type": "application/json", "trakt-api-version": "2", "trakt-api-key": client }
    url = "https://api.trakt.tv/lists/" + listId.EncodeUriComponent() + "/items/" + media + "?extended=full,images&page=1&limit=60&sort_by=" + sortBy + "&sort_how=" + sortHow
    return { url: url, headers: headers }
end function

function Folder_TraktGet(req as object, auth as boolean) as object
    headers = {}
    for each k in req.headers
        headers[k] = req.headers[k]
    end for
    if auth then headers["Authorization"] = "Bearer " + St_Integrations().traktToken
    return Http_Request("GET", req.url, headers, invalid, 20000)
end function

function Folder_TraktMetas(src as object, first as dynamic, firstCode as integer) as object
    out = []
    media = Folder_TraktMedia(src)
    req = Folder_TraktRequest(src, media)
    if req = invalid
        Folder_Fail("Trakt", 0)
        return out
    end if
    r = { code: firstCode, json: first }
    token = St_Integrations().traktToken <> ""
    if r.code = 0 or r.code = 429 or r.code >= 500
        r = Folder_TraktGet(req, false)
    end if
    if r.code = 403
        alt = { url: req.url, headers: {} }
        for each k in req.headers
            alt.headers[k] = req.headers[k]
        end for
        alt.headers["User-Agent"] = "okhttp/4.12.0"
        r2 = Folder_TraktGet(alt, false)
        if r2.code >= 200 and r2.code < 300 then r = r2
    end if
    if (r.code = 401 or r.code = 403 or r.code = 404) and token
        r2 = Folder_TraktGet(req, true)
        if r2.code >= 200 and r2.code < 300 or r.code = 0 then r = r2
    end if
    if (type(r.json) <> "roArray" or r.json.Count() = 0) and r.code >= 200 and r.code < 300
        r = Folder_TraktGet(Folder_TraktRequest(src, "movie,show"), token)
    end if
    if type(r.json) <> "roArray"
        if r.code = 404
            Folder_Fail(L("Trakt: lista privada o eliminada"), r.code)
        else
            Folder_Fail("Trakt", r.code)
        end if
        return out
    end if
    for each entry in r.json
        if type(entry) = "roAssociativeArray"
            kindKey = media
            e = entry[kindKey]
            if type(e) <> "roAssociativeArray"
                kindKey = Str_Of(entry["type"])
                if kindKey = "movie" or kindKey = "show" then e = entry[kindKey]
            end if
            if type(e) = "roAssociativeArray"
                ids = e.ids
                if type(ids) <> "roAssociativeArray" then ids = {}
                id = Str_Of(ids.imdb)
                if id = "" and ids.tmdb <> invalid then id = "tmdb:" + Str_Any(ids.tmdb)
                if id <> "" and Str_Of(e.title) <> ""
                    kind = "movie"
                    if kindKey = "show" then kind = "series"
                    poster = ""
                    if Left(id, 2) = "tt" then poster = "https://images.metahub.space/poster/medium/" + id + "/img"
                    if poster = "" then poster = Folder_TraktImage(e.images, ["poster"])
                    back = Folder_TraktImage(e.images, ["fanart", "banner", "thumb"])
                    if back = "" and Left(id, 2) = "tt" then back = "https://images.metahub.space/background/medium/" + id + "/img"
                    out.Push({ id: id, type: kind, name: Str_Of(e.title), poster: poster, background: back, description: Str_Of(e.overview), releaseInfo: Str_Any(e.year), logo: Folder_TraktImage(e.images, ["logo", "clearart"]) })
                end if
            end if
        end if
    end for
    return out
end function

sub Folder_Fail(name as string, code as integer)
    if m.folderFails = invalid then m.folderFails = []
    text = name
    if code > 0
        text = text + " (" + code.ToStr() + ")"
    else if code = 0
        text = text + " (" + L("sin respuesta") + ")"
    end if
    for each f in m.folderFails
        if f = text then return
    end for
    m.folderFails.Push(text)
end sub

function Folder_TraktImage(images as dynamic, keys as object) as string
    if type(images) <> "roAssociativeArray" then return ""
    for each k in keys
        list = images[k]
        if type(list) = "roArray" and list.Count() > 0 and IsStr(list[0]) and list[0] <> ""
            path = list[0]
            if Left(path, 4) <> "http" then path = "https://" + path
            return path
        end if
    end for
    return ""
end function

function Folder_MdbMetas(src as object, key as string) as object
    out = []
    r = Http_Request("GET", "https://api.mdblist.com/lists/" + Str_Any(src.listId) + "/items?apikey=" + key + "&limit=40", {}, invalid, 20000)
    data = r.json
    lists = []
    if type(data) = "roArray" then lists.Push(data)
    if type(data) = "roAssociativeArray"
        if type(data.movies) = "roArray" then lists.Push(data.movies)
        if type(data.shows) = "roArray" then lists.Push(data.shows)
    end if
    for each list in lists
        for each it in list
            if type(it) = "roAssociativeArray"
                id = Str_Of(it.imdb_id)
                if id = "" and it.id <> invalid then id = "tmdb:" + Str_Any(it.id)
                kind = "movie"
                if LCase(Str_Of(it.mediatype)) = "show" then kind = "series"
                if id <> "" and Str_Of(it.title) <> "" then out.Push({ id: id, type: kind, name: Str_Of(it.title), poster: Str_Of(it.poster), background: "", description: "", releaseInfo: Str_Any(it.release_year) })
            end if
        end for
    end for
    return out
end function

function Folder_Back(folder as object) as string
    if Str_Of(folder.backdrop) <> "" then return folder.backdrop
    return Str_Of(folder.cover)
end function
