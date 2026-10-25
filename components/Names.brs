function Names_Cache() as object
    if m.namesCache = invalid
        m.namesLang = Tmdb_Lang()
        data = St_ReadFile("names_" + m.namesLang)
        if type(data) <> "roAssociativeArray" then data = {}
        m.namesCache = data
        m.namesDirty = false
    end if
    return m.namesCache
end function

sub Names_Save()
    if m.namesCache = invalid or not Bool_Of(m.namesDirty, false) then return
    if m.namesCache.Count() > 600 then m.namesCache = {}
    St_WriteFile("names_" + m.namesLang, m.namesCache)
    m.namesDirty = false
end sub

function Names_Url(id as string, kind as string, title as string, key as string, lang as string) as string
    api = "https://api.themoviedb.org/3"
    q = "api_key=" + key + "&language=" + lang
    media = "movie"
    k = LCase(kind)
    if k = "series" or k = "tv" or k = "show" then media = "tv"
    if Left(id, 2) = "tt" then return api + "/find/" + id.Split(":")[0] + "?" + q + "&external_source=imdb_id"
    if Left(id, 5) = "tmdb:" then return api + "/" + media + "/" + id.Split(":")[1] + "?" + q
    if title = "" then return ""
    return api + "/search/" + media + "?" + q + "&query=" + title.EncodeUriComponent()
end function

function Names_Pick(data as dynamic) as string
    if type(data) <> "roAssociativeArray" then return ""
    for each field in ["movie_results", "tv_results", "results"]
        list = data[field]
        if type(list) = "roArray" and list.Count() > 0 and type(list[0]) = "roAssociativeArray"
            name = Str_Of(list[0].title)
            if name = "" then name = Str_Of(list[0].name)
            if name <> "" then return name
        end if
    end for
    name = Str_Of(data.title)
    if name = "" then name = Str_Of(data.name)
    return name
end function

sub Names_Translate(items as object)
    if items.Count() = 0 then return
    key = Key_Tmdb(St_Integrations())
    cache = Names_Cache()
    todo = []
    for each it in items
        if cache.DoesExist(it.id)
            if cache[it.id] <> "" then it.title = cache[it.id]
        else if key <> "" and todo.Count() < 40
            todo.Push(it)
        end if
    end for
    if todo.Count() > 0
        for each lang in [m.namesLang, "en-US"]
            urls = []
            pending = []
            for each it in todo
                if not Bool_Of(it.done, false)
                    url = Names_Url(it.id, it.kind, it.original, key, lang)
                    if url <> ""
                        urls.Push(url)
                        pending.Push(it)
                    end if
                end if
            end for
            if urls.Count() > 0
                res = Http_Fetch(urls, 12000, 0)
                for i = 0 to pending.Count() - 1
                    name = Names_Pick(res.data[i])
                    if name <> "" and not Str_HasForeign(name)
                        pending[i].title = name
                        pending[i].done = true
                    end if
                end for
            end if
        end for
        for each it in todo
            if Bool_Of(it.done, false) then cache[it.id] = it.title else cache[it.id] = ""
        end for
        m.namesDirty = true
        Names_Save()
    end if
    for each it in items
        it.title = Str_Glyphs(it.title)
    end for
end sub
