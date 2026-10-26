sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    id = m.top.metaId
    imdb = ""
    if Left(id, 2) = "tt" then imdb = id.Split(":")[0]
    logo = ""
    integ = St_Integrations()
    key = Key_Tmdb(integ)
    if integ.tmdbEnabled and key <> "" and integ.tmdbArtwork
        logo = Logo_Tmdb(id, imdb, LCase(m.top.kind), key)
    end if
    if logo = "" and imdb <> "" then logo = Img_Logo(imdb)
    m.top.logo = logo
end sub

function Logo_Tmdb(id as string, imdb as string, kind as string, key as string) as string
    media = "movie"
    if kind <> "movie" then media = "tv"
    tmdbId = ""
    if LCase(Left(id, 5)) = "tmdb:"
        tmdbId = Mid(id, 6)
        cut = Instr(1, tmdbId, ":")
        if cut > 0 then tmdbId = Left(tmdbId, cut - 1)
    else if imdb <> ""
        found = Http_FetchJson("https://api.themoviedb.org/3/find/" + imdb + "?external_source=imdb_id&api_key=" + key, 8000)
        if type(found) <> "roAssociativeArray" then return ""
        list = found.movie_results
        if media = "tv" then list = found.tv_results
        if type(list) = "roArray" and list.Count() > 0 then tmdbId = Str_Any(list[0].id)
        if tmdbId = "" and media = "movie" and type(found.tv_results) = "roArray" and found.tv_results.Count() > 0
            media = "tv"
            tmdbId = Str_Any(found.tv_results[0].id)
        end if
    end if
    if tmdbId = "" then return ""
    lang2 = LCase(Left(Tmdb_Lang(), 2))
    images = Http_FetchJson("https://api.themoviedb.org/3/" + media + "/" + tmdbId + "/images?api_key=" + key + "&include_image_language=" + lang2 + ",en,null", 8000)
    if type(images) <> "roAssociativeArray" or type(images.logos) <> "roArray" then return ""
    best = ""
    fallback = ""
    for each entry in images.logos
        if type(entry) = "roAssociativeArray" and IsStr(entry.file_path)
            code = Str_Of(entry.iso_639_1)
            if code = lang2 and best = "" then best = entry.file_path
            if code = "en" and fallback = "" then fallback = entry.file_path
            if fallback = "" and code = "" then fallback = entry.file_path
        end if
    end for
    if best = "" then best = fallback
    if best = "" then return ""
    return "https://image.tmdb.org/t/p/w500" + Left(best, Len(best) - 4) + ".png"
end function
