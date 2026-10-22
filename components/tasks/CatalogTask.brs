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
    manifestUrls = []
    for each base in addons
        manifestUrls.Push(base + "/manifest.json")
    end for
    raw = Http_FetchJsonAll(manifestUrls, 20000)

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
                catalogs: man.catalogs
                search: Addon_SearchCatalogs(man)
            })
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
        entry.Delete("catalogs")
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
    fetched = Http_Fetch(urls, 45000, prefs.rowSize)
    results = fetched.data

    Progress_Enrich(manifests)
    root = CreateObject("roSGNode", "ContentNode")
    cw = Content_ContinueRow()
    if cw <> invalid then root.appendChild(cw)

    limit = prefs.rowSize
    pattern = Poster_Pattern("home")
    for i = 0 to visible.Count() - 1
        data = results[i]
        c = visible[i]
        c.status = fetched.diag[i]
        c.count = 0
        if c.status = "ok" then c.status = L("Sin títulos")
        if type(data) = "roAssociativeArray" and type(data.metas) = "roArray" and data.metas.Count() > 0
            row = CreateObject("roSGNode", "ContentNode")
            row.title = c.name + "  ·  " + TypePlural(c.kind)
            row.addFields({ key: c.key })
            if type(prefs.titles) = "roAssociativeArray" and IsStr(prefs.titles[c.key]) then row.title = prefs.titles[c.key]
            shape = Catalog_Shape(data.metas)
            row.addFields({ shape: shape })
            rowPattern = pattern
            if shape <> "poster" then rowPattern = ""
            added = 0
            for each meta in data.metas
                if added >= limit then exit for
                if type(meta) = "roAssociativeArray" and IsStr(meta.id)
                    Content_Item(row, Catalog_ItemData(meta, c.kind, rowPattern))
                    added = added + 1
                end if
            end for
            c.count = added
            if added > 0
                root.appendChild(row)
                c.status = "ok"
            end if
        end if
    end for

    Collections_Rows(root, prefs)

    m.top.addonCount = addons.Count()
    m.top.failed = failed
    m.top.manifests = manifests
    m.top.catalogs = ordered
    m.top.content = root
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
                row.title = Str_Of(col.title)
                shape = "square"
                first = col.folders[0]
                if type(first) = "roAssociativeArray" and Str_Of(first.shape) <> "" then shape = first.shape
                row.addFields({ key: key, shape: shape, pinned: Bool_Of(col.pin, false) })
                for each folder in col.folders
                    if type(folder) = "roAssociativeArray"
                        item = Content_Item(row, {
                            title: Str_Of(folder.title)
                            poster: Str_Of(folder.cover)
                            description: ""
                            kind: "folder"
                            metaId: "folder:" + Str_Of(col.id) + ":" + Str_Of(folder.id)
                            videoId: ""
                            background: Folder_Back(folder)
                            metaLine: Str_Of(col.title)
                            episodeLabel: ""
                            progress: 0.0
                        })
                        item.addFields({ folder: { title: Str_Of(folder.title), sources: folder.sources, backdrop: Str_Of(folder.backdrop) } })
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
    for each src in f.sources
        if type(src) = "roAssociativeArray"
            base = St_NormalizeUrl(Str_Of(src.base))
            if base = ""
                for each entry in manifests
                    if base = "" and entry.manifest <> invalid and entry.manifest.id = Str_Of(src.addonId) then base = entry.base
                end for
            end if
            if base <> "" and Str_Of(src["type"]) <> "" and Str_Of(src.catalogId) <> ""
                url = Addon_ResourceUrl(base, "catalog", src["type"], src.catalogId)
                genre = Str_Of(src.genre)
                if genre <> "" then url = Left(url, Len(url) - 5) + "/genre=" + genre.EncodeUriComponent() + ".json"
                urls.Push(url)
                title = Str_Of(src.title)
                if title = "" then title = TypePlural(src["type"])
                infos.Push({ title: title, kind: src["type"] })
            end if
        end if
    end for
    root = CreateObject("roSGNode", "ContentNode")
    if urls.Count() > 0
        fetched = Http_Fetch(urls, 45000, prefs.rowSize)
        for i = 0 to infos.Count() - 1
            data = fetched.data[i]
            if type(data) = "roAssociativeArray" and type(data.metas) = "roArray" and data.metas.Count() > 0
                row = root.createChild("ContentNode")
                row.title = infos[i].title
                shape = Catalog_Shape(data.metas)
                row.addFields({ shape: shape })
                added = 0
                for each meta in data.metas
                    if added >= prefs.rowSize then exit for
                    if type(meta) = "roAssociativeArray" and IsStr(meta.id)
                        Content_Item(row, Catalog_ItemData(meta, infos[i].kind, ""))
                        added = added + 1
                    end if
                end for
            end if
        end for
    end if
    m.top.content = root
end sub

function Folder_Back(folder as object) as string
    if Str_Of(folder.backdrop) <> "" then return folder.backdrop
    return Str_Of(folder.cover)
end function
