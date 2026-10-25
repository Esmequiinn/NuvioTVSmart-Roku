function Content_Item(row as object, data as object) as object
    item = row.CreateChild("ContentNode")
    item.title = Str_Glyphs(Str_Of(data.title))
    item.HDPosterUrl = Str_Of(data.poster)
    item.description = Str_Of(data.description)
    progress = 0.0
    if data.progress <> invalid then progress = progress + data.progress
    item.addFields({
        itemType: Str_Of(data.kind)
        metaId: Str_Of(data.metaId)
        videoId: Str_Of(data.videoId)
        background: Str_Of(data.background)
        metaLine: Str_Of(data.metaLine)
        episodeLabel: Str_Of(data.episodeLabel)
        progress: progress
        altIds: Str_Of(data.altIds)
        logo: Str_Of(data.logo)
        rating: Str_Of(data.rating)
        fallback: Str_Of(data.fallback)
        idx: row.getChildCount() - 1
        badge: Str_Of(data.badge)
        kicker: Str_Of(data.kicker)
        subtitle: Str_Glyphs(Str_Of(data.subtitle))
        watched: Content_Watched(data)
        portrait: Str_Of(data.portrait)
    })
    return item
end function

function Content_Watched(data as object) as boolean
    kind = LCase(Str_Of(data.kind))
    if kind <> "movie" and kind <> "series" and kind <> "tv" then return false
    if Str_Of(data.badge) <> "" then return false
    return St_IsWatched(Str_Of(data.metaId))
end function

function Cw_Status(elapsed as integer, dur as integer) as string
    if dur > 0 and elapsed > 0
        remain = Int((dur - elapsed) / 60)
        if remain < 1 then remain = 1
        if remain < 60
            time = L("{m} min").Replace("{m}", remain.ToStr())
        else
            hours = Int(remain / 60)
            mins = remain mod 60
            time = L("{h} h").Replace("{h}", hours.ToStr())
            if mins > 0 then time = L("{h} h {m} min").Replace("{h}", hours.ToStr()).Replace("{m}", mins.ToStr())
        end if
        return L("Faltan {t}").Replace("{t}", time)
    end if
    return L("Continuar")
end function

function Cw_Episode(label as string) as object
    label = label.Trim()
    if label = "" then return { code: "", name: "" }
    cut = Instr(1, label, "  ")
    if cut = 0 then return { code: label, name: "" }
    return { code: Left(label, cut - 1).Trim(), name: Mid(label, cut + 2).Trim() }
end function

function Content_ContinueRow() as dynamic
    prefs = St_Prefs()
    if not prefs.continueWatching then return invalid
    list = St_Progress()
    if list.Count() = 0 then return invalid
    row = CreateObject("roSGNode", "ContentNode")
    row.id = "cw"
    row.title = L("Seguir viendo")
    landscape = St_Pref("cwStyle") <> "poster"
    pattern = ""
    if not landscape then pattern = Poster_Pattern("continue_watching")
    live = { tv: true, channel: true, channels: true, events: true, live: true }
    for each e in list
        if not live.DoesExist(LCase(Str_Of(e.kind)))
            elapsed = ToInt(e.position, 0)
            dur = ToInt(e.duration, 0)
            progress = 0.0
            if dur > 0 then progress = elapsed / dur
            episode = Str_Of(e.episode)
            parts = Cw_Episode(episode)
            altIds = ""
            if type(e.altIds) = "roArray" then altIds = e.altIds.Join("|")
            image = Str_Of(e.poster)
            fallbackImage = ""
            if landscape
                image = Str_Of(e.thumb)
                if image = "" then image = Str_Of(e.background)
                if image = "" and Left(e.metaId, 2) = "tt" then image = Img_Background(e.metaId)
                if image = "" then image = Str_Of(e.poster)
            else if pattern <> ""
                custom = Poster_Custom(pattern, Str_Of(e.metaId), "", Str_Of(e.kind))
                if custom <> ""
                    fallbackImage = image
                    image = custom
                end if
            end if
            Content_Item(row, {
                title: Str_Of(e.title)
                poster: image
                description: ""
                kind: Str_Of(e.kind)
                metaId: e.metaId
                videoId: e.videoId
                background: Str_Of(e.background)
                metaLine: ""
                episodeLabel: episode
                progress: progress
                altIds: altIds
                fallback: fallbackImage
                badge: Cw_Status(elapsed, dur)
                kicker: parts.code
                subtitle: parts.name
                portrait: Str_Of(e.poster)
            })
        end if
    end for
    if row.getChildCount() = 0 then return invalid
    return row
end function

function Poster_Pattern(screen as string) as string
    pattern = Str_Of(St_Pref("customPoster")).Trim()
    if pattern = "" then return ""
    screens = "," + Str_Of(St_Pref("posterScreens")) + ","
    if Instr(1, screens, "," + screen + ",") = 0 then return ""
    return pattern
end function

function Poster_Ids(metaId as string, imdb as string, kind as string) as object
    d = { imdb_id: "", tmdb_id: "", tvdb_id: "", kitsu_id: "", anilist_id: "", mal_id: "", anidb_id: "", id: metaId, type: LCase(kind), shape: "poster" }
    idType = "unknown"
    value = metaId
    if Left(metaId, 2) = "tt"
        idType = "imdb"
        value = metaId.Split(":")[0]
        d.imdb_id = value
    else
        cut = Instr(1, metaId, ":")
        if cut > 0
            idType = LCase(Left(metaId, cut - 1))
            value = Mid(metaId, cut + 1).Split(":")[0]
            if d.DoesExist(idType + "_id") then d[idType + "_id"] = value
        end if
    end if
    if imdb <> "" then d.imdb_id = imdb
    d.id_type = idType
    d.typed_id = value
    if idType = "tmdb" or idType = "tvdb"
        prefix = "series"
        if LCase(kind) = "movie" then prefix = "movie"
        d.typed_id = prefix + "-" + value
    end if
    return d
end function

function Poster_Fill(pattern as string, d as object) as string
    re = CreateObject("roRegex", "\{([a-z_]+(?:\|[a-z_]+)*)(\?)?\}", "")
    out = ""
    rest = pattern
    found = re.Match(rest)
    while found.Count() > 1
        cut = Instr(1, rest, found[0])
        out = out + Left(rest, cut - 1)
        names = found[1].Split("|")
        optional = false
        if found.Count() > 2 then optional = Str_Of(found[2]) = "?"
        if names.Count() > 1
            value = ""
            for each n in names
                if value = "" and Str_Of(d[n]) <> "" then value = d[n]
            end for
            if value = "" then return ""
            out = out + value
        else if d.DoesExist(names[0])
            value = Str_Of(d[names[0]])
            if value = "" and not optional then return ""
            out = out + value
        else
            out = out + found[0]
        end if
        rest = Mid(rest, cut + Len(found[0]))
        found = re.Match(rest)
    end while
    return out + rest
end function

function Poster_Custom(pattern as string, metaId as string, imdb as string, kind as string) as string
    if pattern = "" or metaId = "" then return ""
    decoded = pattern.Replace("%7B", "{").Replace("%7b", "{").Replace("%7D", "}").Replace("%7d", "}").Replace("%7C", "|").Replace("%7c", "|")
    d = Poster_Ids(metaId, imdb, kind)
    url = Poster_Fill(decoded, d)
    if url <> "" then return url
    rpdb = Instr(1, decoded, "ratingposterdb.com") > 0 or Instr(1, decoded, "aioratings.com") > 0 or Instr(1, decoded, "top-posters.com") > 0
    if rpdb and Instr(1, decoded, "{imdb_id}") > 0
        for each alt in ["tmdb", "tvdb"]
            if d[alt + "_id"] <> ""
                prefix = "series"
                if LCase(kind) = "movie" then prefix = "movie"
                url = Poster_Fill(decoded.Replace("/imdb/", "/" + alt + "/").Replace("{imdb_id}", prefix + "-" + d[alt + "_id"]), d)
                if url <> "" then return url
            end if
        end for
    end if
    return ""
end function

function Catalog_ItemData(meta as object, fallbackKind as string, posterPattern = "" as string) as object
    kind = Str_Of(meta["type"])
    if kind = "" then kind = fallbackKind
    parts = [TypeLabel(kind)]
    release = Str_Any(meta.releaseInfo)
    if release = "" then release = Left(Str_Of(meta.released), 4)
    if release <> "" then parts.Push(release)
    rating = Str_Any(meta.imdbRating)
    if type(meta.genres) = "roArray" and meta.genres.Count() > 0
        genres = []
        for each g in meta.genres
            if IsStr(g) and genres.Count() < 3 then genres.Push(g)
        end for
        if genres.Count() > 0 then parts.Push(genres.Join(", "))
    end if
    poster = Str_Of(meta.poster)
    background = Str_Of(meta.background)
    if background = "" then background = poster
    fallback = ""
    if posterPattern <> ""
        custom = Poster_Custom(posterPattern, Str_Of(meta.id), Addon_ImdbId(meta), kind)
        if custom <> ""
            fallback = poster
            poster = custom
        end if
    end if
    return {
        title: Str_Of(meta.name)
        poster: poster
        description: Str_Glyphs(Str_OneLine(meta.description))
        kind: kind
        metaId: meta.id
        videoId: ""
        background: background
        metaLine: Str_Glyphs(parts.Join("  ·  "))
        episodeLabel: ""
        progress: 0.0
        logo: Str_Of(meta.logo)
        rating: rating
        fallback: fallback
    }
end function
