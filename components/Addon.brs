function Addon_Name(manifest as object, base as string) as string
    name = Str_Of(manifest.name).Trim()
    if name <> "" then return name
    return base
end function

function Addon_RequiresExtra(cat as object) as boolean
    if type(cat.extraRequired) = "roArray" and cat.extraRequired.Count() > 0 then return true
    if type(cat.extra) = "roArray"
        for each e in cat.extra
            if type(e) = "roAssociativeArray" and IsBool(e.isRequired)
                if e.isRequired then return true
            end if
        end for
    end if
    return false
end function

function Addon_Supports(manifest as object, resource as string, kind as string, id as string) as boolean
    if type(manifest.resources) <> "roArray" then return false
    found = false
    types = manifest.types
    prefixes = manifest.idPrefixes
    for each r in manifest.resources
        if IsStr(r)
            if r = resource then found = true
        else if type(r) = "roAssociativeArray"
            if Str_Of(r.name) = resource
                found = true
                if type(r.types) = "roArray" then types = r.types
                if type(r.idPrefixes) = "roArray" then prefixes = r.idPrefixes
            end if
        end if
        if found then exit for
    end for
    if not found then return false
    if type(types) = "roArray" and types.Count() > 0
        ok = false
        for each t in types
            if Str_Of(t) = kind then ok = true
        end for
        if not ok then return false
    end if
    if type(prefixes) = "roArray" and prefixes.Count() > 0
        ok = false
        for each pfx in prefixes
            p = Str_Of(pfx)
            if p <> "" and Left(id, Len(p)) = p then ok = true
        end for
        if not ok then return false
    end if
    return true
end function

function Addon_ResourceUrl(base as string, resource as string, kind as string, id as string) as string
    return Addon_Url(base, "/" + resource + "/" + kind.EncodeUriComponent() + "/" + id.EncodeUriComponent() + ".json")
end function

function Addon_Url(base as string, path as string) as string
    root = base
    query = ""
    cut = Instr(1, root, "?")
    if cut > 0
        query = Mid(root, cut + 1)
        root = Left(root, cut - 1)
    end if
    if LCase(Right(root, 14)) = "/manifest.json" then root = Left(root, Len(root) - 14)
    while Len(root) > 0 and Right(root, 1) = "/"
        root = Left(root, Len(root) - 1)
    end while
    if query = "" then return root + path
    return root + path + "?" + query
end function

function Addon_SearchCatalogs(man as object) as object
    out = []
    if type(man.catalogs) <> "roArray" then return out
    for each cat in man.catalogs
        if type(cat) = "roAssociativeArray" and IsStr(cat["type"]) and IsStr(cat.id)
            searchable = false
            blocked = false
            if type(cat.extra) = "roArray"
                for each e in cat.extra
                    if type(e) = "roAssociativeArray"
                        extraName = Str_Of(e.name)
                        if extraName = "search"
                            searchable = true
                        else if Bool_Of(e.isRequired, false)
                            blocked = true
                        end if
                    end if
                end for
            end if
            if type(cat.extraSupported) = "roArray"
                for each e in cat.extraSupported
                    if Str_Of(e) = "search" then searchable = true
                end for
            end if
            if type(cat.extraRequired) = "roArray"
                for each e in cat.extraRequired
                    if Str_Of(e) <> "search" then blocked = true
                end for
            end if
            if searchable and not blocked then out.Push({ kind: cat["type"], id: cat.id, name: Str_Of(cat.name) })
        end if
    end for
    return out
end function

function Col_ExtractUrls(data as dynamic) as object
    urls = []
    list = invalid
    if type(data) = "roArray"
        list = data
    else if type(data) = "roAssociativeArray"
        for each k in ["addons", "collection", "items", "list"]
            if type(data[k]) = "roArray"
                list = data[k]
                exit for
            end if
        end for
        if list = invalid
            for each k in ["transportUrl", "manifestUrl", "url"]
                if IsStr(data[k])
                    urls.Push(data[k])
                    exit for
                end if
            end for
        end if
    end if
    if list = invalid then return urls
    for each it in list
        if IsStr(it)
            urls.Push(it)
        else if type(it) = "roAssociativeArray"
            for each k in ["transportUrl", "manifestUrl", "url", "manifest"]
                if IsStr(it[k])
                    urls.Push(it[k])
                    exit for
                end if
            end for
        end if
    end for
    return urls
end function

function Col_Import(source as string) as integer
    text = source.Trim()
    if text = "" then return 0
    data = invalid
    first = Left(text, 1)
    if first = "[" or first = "{"
        data = ParseJson(text)
    else
        url = text
        if Instr(1, url, "://") = 0 then url = "https://" + url
        data = Http_FetchJson(url, 20000)
    end if
    added = 0
    for each u in Col_ExtractUrls(data)
        if St_AddAddon(u) then added = added + 1
    end for
    return added
end function
