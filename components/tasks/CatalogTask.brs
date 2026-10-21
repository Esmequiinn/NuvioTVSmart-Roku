sub init()
    m.top.functionName = "execute"
end sub

sub execute()
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
            added = 0
            for each meta in data.metas
                if added >= limit then exit for
                if type(meta) = "roAssociativeArray" and IsStr(meta.id)
                    Content_Item(row, Catalog_ItemData(meta, c.kind, pattern))
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
