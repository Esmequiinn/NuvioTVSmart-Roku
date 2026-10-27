sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    kind = m.top.kind
    extras = []
    if m.top.genre <> "" then extras.Push("genre=" + m.top.genre.EncodeUriComponent())
    if m.top.skip > 0 then extras.Push("skip=" + m.top.skip.ToStr())
    url = m.top.base + "/catalog/" + kind.EncodeUriComponent() + "/" + m.top.catalogId.EncodeUriComponent()
    if extras.Count() > 0 then url = url + "/" + extras.Join("&")
    res = Http_Fetch([url + ".json"], 20000, 0)
    data = res.data[0]
    if type(data) <> "roAssociativeArray" or type(data.metas) <> "roArray"
        m.top.result = { items: [], count: 0, error: res.diag[0] }
        return
    end if
    pattern = Poster_Pattern("search")
    items = []
    foreign = []
    for each meta in data.metas
        if type(meta) = "roAssociativeArray" and IsStr(meta.id)
            it = Catalog_ItemData(meta, kind, pattern)
            if Str_HasForeign(it.title)
                foreign.Push({ id: Str_Of(it.metaId), kind: Str_Of(it.kind), title: it.title, original: it.title, ref: it })
            else
                it.title = Str_Glyphs(it.title)
            end if
            items.Push(it)
        end if
    end for
    if foreign.Count() > 0
        Names_Translate(foreign)
        for each f in foreign
            f.ref.title = f.title
        end for
    end if
    m.top.result = { items: items, count: data.metas.Count(), error: "" }
end sub
