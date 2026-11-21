function Rate_Sources() as object
    return [{ id: "trakt", name: "Trakt" }, { id: "simkl", name: "Simkl" }, { id: "mdblist", name: "MDBList" }]
end function

function Rate_Connected(integ as object, id as string) as boolean
    if id = "trakt" then return Str_Of(integ.traktToken) <> ""
    if id = "simkl" then return Str_Of(integ.simklToken) <> ""
    if id = "mdblist" then return Str_Of(integ.mdbRefresh) <> "" or Str_Of(integ.mdbAccess) <> ""
    return false
end function

function Rate_Source(integ as object) as string
    id = Str_Of(integ.rateSource)
    if id = "" or not Rate_Connected(integ, id) then return ""
    return id
end function

function Rate_Name(id as string) as string
    for each s in Rate_Sources()
        if s.id = id then return s.name
    end for
    return L("Apagadas")
end function

function Rate_Episodes(id as string) as boolean
    return id = "trakt" or id = "mdblist"
end function

function Rate_Keys(kind as string, ids as dynamic, season as integer, episode as integer) as object
    out = []
    if type(ids) <> "roAssociativeArray" then return out
    prefix = "m"
    k = LCase(kind)
    if k = "series" or k = "tv" or k = "show" or k = "shows" then prefix = "s"
    if episode > 0 then prefix = "e"
    suffix = ""
    if episode > 0 then suffix = ":" + season.ToStr() + ":" + episode.ToStr()
    imdb = Str_Of(ids.imdb)
    if Left(imdb, 2) = "tt" then out.Push(prefix + ":" + imdb + suffix)
    tmdb = Str_Any(ids.tmdb)
    if tmdb <> "" and tmdb <> "0" then out.Push(prefix + ":tmdb:" + Deb_TorboxId(tmdb) + suffix)
    return out
end function

function Rate_IdsFor(metaId as string) as object
    if Left(metaId, 2) = "tt" then return { imdb: metaId.Split(":")[0] }
    if LCase(Left(metaId, 5)) = "tmdb:" then return { tmdb: Mid(metaId, 6).Split(":")[0] }
    return {}
end function

function Rate_File() as string
    return "rates_" + St_ActiveProfile().id
end function

function Rate_Cache() as object
    data = St_ReadFile(Rate_File())
    if type(data) <> "roAssociativeArray" or type(data.map) <> "roAssociativeArray" then return { source: "", at: 0, map: {} }
    return data
end function

function Rate_Get(kind as string, metaId as string, season as integer, episode as integer) as integer
    source = Rate_Source(St_Integrations())
    if source = "" then return 0
    cache = Rate_Cache()
    if Str_Of(cache.source) <> source then return 0
    for each key in Rate_Keys(kind, Rate_IdsFor(metaId), season, episode)
        v = cache.map[key]
        if v <> invalid then return ToInt(v, 0)
    end for
    return 0
end function

sub Rate_Remember(kind as string, metaId as string, season as integer, episode as integer, rating as integer)
    source = Rate_Source(St_Integrations())
    cache = Rate_Cache()
    if Str_Of(cache.source) <> source then cache = { source: source, at: 0, map: {} }
    for each key in Rate_Keys(kind, Rate_IdsFor(metaId), season, episode)
        if rating > 0 then cache.map[key] = rating else cache.map.Delete(key)
    end for
    St_WriteFile(Rate_File(), cache)
end sub
