function Srv_HomeRows(limit as integer) as object
    rows = []
    for each sv in Srv_List()
        if sv.on <> false and type(sv.libs) = "roArray"
            for each lib in sv.libs
                if lib.on <> false
                    row = Srv_LibraryRow(sv, lib, limit)
                    if row <> invalid then rows.Push(row)
                end if
            end for
        end if
    end for
    return rows
end function

function Srv_LibraryRow(sv as object, lib as object, limit as integer) as dynamic
    itemType = "Movie"
    if lib.kind = "series" then itemType = "Series"
    if limit < 10 then limit = 20
    q = Srv_UserQuery(sv)
    q.Append([["parentId", lib.id], ["recursive", "true"], ["includeItemTypes", itemType], ["fields", "ProviderIds,Overview,Genres,ProductionYear"], ["sortBy", "DateCreated,SortName"], ["sortOrder", "Descending"], ["limit", limit.ToStr()], ["imageTypeLimit", "1"], ["enableImageTypes", "Primary,Backdrop"]])
    r = Srv_Get(sv, Srv_ItemsPath(sv), q, 20000)
    items = Srv_J(r.json, "Items")
    if type(items) <> "roArray" then return invalid
    out = []
    for each it in items
        ids = Srv_Ids(it)
        mid = ""
        if Left(ids.imdb, 2) = "tt" then mid = ids.imdb
        if mid = "" and ids.tmdb <> "" then mid = "tmdb:" + ids.tmdb
        if mid <> ""
            iid = Str_Of(Srv_J(it, "Id"))
            genres = Srv_J(it, "Genres")
            if type(genres) <> "roArray" then genres = []
            meta = { id: mid, type: lib.kind, name: Str_Of(Srv_J(it, "Name")), poster: Srv_Image(sv, iid, "Primary", 342), background: Srv_Image(sv, iid, "Backdrop", 1280), releaseInfo: Str_Any(Srv_J(it, "ProductionYear")), genres: genres, description: Str_OneLine(Str_Of(Srv_J(it, "Overview"))) }
            out.Push(Catalog_ItemData(meta, lib.kind, ""))
        end if
    end for
    if out.Count() = 0 then return invalid
    return { key: "srv:" + sv.id + ":" + lib.id, name: lib.name + "  ·  " + sv.name, kind: lib.kind, shape: "poster", items: out }
end function
