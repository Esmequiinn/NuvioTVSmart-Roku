sub openDetails(item as object)
    Poster_Stop()
    m.autoCount = 0
    hideExpanded()
    m.ctx = {
        kind: item.itemType
        metaId: item.metaId
        videoId: ""
        videoIds: []
        title: item.title
        poster: Details_Poster(item)
        background: item.background
        logo: item.logo
        description: item.description
        rating: item.rating
        metaLine: item.metaLine
        episodeLabel: ""
        resumeVideo: item.videoId
        resumeLabel: item.episodeLabel
        resumeAlt: item.altIds
        fromStart: false
        imdb: ""
        meta: invalid
        metaReady: false
        pending: ""
        seasons: []
        subs: []
        streams: []
        pool: []
        bingePrefer: ""
        trailer: invalid
        originalLang: ""
        nextAuto: false
    }
    m.trailerTask = invalid
    if Left(m.ctx.metaId, 2) = "tt" then m.ctx.imdb = m.ctx.metaId
    m.detailsOpen = true
    m.details.visible = true
    first = heroData(item, m.metaCache[item.metaId])
    if m.metaCache[item.metaId] <> invalid then first.ratings = m.metaCache[item.metaId].ratings
    m.details.data = first
    m.details.extra = {}
    m.details.status = L("Cargando información...")
    renderDetailButtons()
    m.details.focusIndex = 0
    m.details.setFocus(true)
    m.metaTask = CreateObject("roSGNode", "MetaTask")
    m.metaTask.manifests = m.manifests
    m.metaTask.kind = m.ctx.kind
    m.metaTask.metaId = m.ctx.metaId
    m.metaTask.observeField("meta", "onDetailsMeta")
    m.metaTask.control = "RUN"
end sub

function Details_Poster(item as object) as string
    cached = m.metaCache[item.metaId]
    if cached <> invalid and Str_Of(cached.poster) <> "" then return cached.poster
    if item.hasField("portrait") and item.portrait <> "" then return item.portrait
    parent = item.getParent()
    landscape = parent <> invalid and ((parent.hasField("shape") and parent.shape <> "" and parent.shape <> "poster") or parent.id = "cw")
    if not landscape
        if item.hasField("remote") and item.remote <> "" then return item.remote
        return item.HDPosterUrl
    end if
    if Left(item.metaId, 2) = "tt" then return "https://images.metahub.space/poster/medium/" + item.metaId.Split(":")[0] + "/img"
    return ""
end function

sub closeDetails(refocus as boolean)
    m.detailsOpen = false
    m.details.visible = false
    m.details.trailer = {}
    m.metaTask = invalid
    m.trailerTask = invalid
    if refocus
        if m.page = "home" then refreshContinueRow()
        if m.page = "library" then buildLibrary()
        focusCurrent()
    end if
end sub

sub onDetailsBack()
    if m.busy
        cancelBusy()
        return
    end if
    closeDetails(true)
end sub

sub onDetailsMeta(event as object)
    task = event.getRoSGNode()
    if m.metaTask = invalid or not task.isSameNode(m.metaTask) then return
    m.metaTask = invalid
    meta = task.meta
    if meta = invalid then meta = {}
    cacheMeta(m.ctx.metaId, meta)
    m.ctx.meta = meta
    m.ctx.metaReady = true
    if Str_Of(meta.imdb) <> "" then m.ctx.imdb = meta.imdb
    if m.ctx.title = "" then m.ctx.title = Str_Of(meta.name)
    if Str_Of(meta.poster) <> ""
        m.ctx.poster = Str_Of(meta.poster)
        St_FixLibraryPoster(m.ctx.metaId, m.ctx.poster)
    end if
    if Str_Of(meta.background) <> "" then m.ctx.background = meta.background
    if Str_Of(meta.logo) <> ""
        m.ctx.logo = meta.logo
        if m.player.visible then m.player.logo = meta.logo
    end if
    if Str_Of(meta.description) <> "" then m.ctx.description = Str_OneLine(meta.description)
    m.ctx.metaLine = Meta_Line(m.ctx.kind, meta)
    m.ctx.originalLang = Str_Of(meta.originalLanguage)
    startTrailerLookup(meta)
    videos = []
    if type(meta.videos) = "roArray" then videos = meta.videos
    if LCase(m.ctx.kind) <> "movie" and videos.Count() > 0 then m.ctx.seasons = groupSeasons(videos)
    m.details.data = {
        title: m.ctx.title
        logo: m.ctx.logo
        background: m.ctx.background
        rating: Str_Of(meta.imdbRating)
        metaLine: m.ctx.metaLine
        description: m.ctx.description
        ratings: meta.ratings
    }
    m.details.status = ""
    renderDetailButtons()
    Details_Extra()
    if m.ctx.pending <> ""
        action = m.ctx.pending
        m.ctx.pending = ""
        hideBusy()
        runDetailAction(action)
    end if
end sub

sub Details_Extra()
    meta = m.ctx.meta
    if meta = invalid then return
    extra = { seasons: [], cast: [], crew: "", seasonIndex: 0 }
    entry = resumeEntry()
    resumeId = ""
    if entry <> invalid then resumeId = Str_Of(entry.videoId)
    watched = St_Watched()
    fallbackThumb = Str_Of(m.ctx.background)
    if isSeries()
        for si = 0 to m.ctx.seasons.Count() - 1
            season = m.ctx.seasons[si]
            eps = []
            for each v in season.episodes
                num = ToInt(v.episode, -1)
                code = ""
                if num >= 0 then code = "E" + num.ToStr()
                name = episodeTitle(v)
                if name = "" and num >= 0 then name = L("Episodio ") + num.ToStr()
                overview = Str_OneLine(v.overview)
                if overview = "" then overview = Str_OneLine(v.description)
                parts = []
                released = Left(Str_Of(v.released), 10)
                if released <> "" then parts.Push(Fmt_Date(released))
                runtime = ToInt(v.runtime, 0)
                if runtime > 0 then parts.Push(runtime.ToStr() + L(" min"))
                thumb = Str_Of(v.thumbnail)
                if thumb = "" then thumb = fallbackThumb
                progress = 0.0
                if v.id = resumeId and ToInt(entry.duration, 0) > 0 then progress = ToInt(entry.position, 0) / ToInt(entry.duration, 1)
                seen = watched.DoesExist(St_WatchedKey(m.ctx.metaId, v.season, v.episode))
                eps.Push({ id: v.id, code: code, name: name, overview: overview, meta: parts.Join("  ·  "), thumb: thumb, progress: progress, watched: seen })
                if v.id = resumeId then extra.seasonIndex = si
            end for
            extra.seasons.Push({ label: season.label, episodes: eps })
        end for
    end if
    if type(meta.cast) = "roArray" then extra.cast = meta.cast
    if type(meta.directors) = "roArray" and meta.directors.Count() > 0
        extra.crew = L("Dirección: ") + meta.directors.Join(", ")
    else if type(meta.creators) = "roArray" and meta.creators.Count() > 0
        extra.crew = L("Creada por: ") + meta.creators.Join(", ")
    end if
    m.details.extra = extra
end sub

function isSeries() as boolean
    return m.ctx.seasons <> invalid and m.ctx.seasons.Count() > 0
end function

function resumeEntry() as dynamic
    for each e in St_Progress()
        if e.metaId = m.ctx.metaId then return e
    end for
    return invalid
end function

sub renderDetailButtons()
    buttons = []
    entry = resumeEntry()
    playLabel = L("Reproducir")
    if entry <> invalid
        if Bool_Of(entry.nextUp, false)
            playLabel = L("Reproducir  ") + Str_Of(entry.episode)
        else if Str_Of(entry.episode) <> ""
            playLabel = L("Continuar  ") + Str_Of(entry.episode)
        else
            playLabel = L("Continuar desde ") + Fmt_Time(ToInt(entry.position, 0))
        end if
    else if isSeries()
        first = firstEpisode()
        if first <> invalid then playLabel = L("Reproducir  ") + first.label
    end if
    if Len(playLabel) > 48 then playLabel = Left(playLabel, 46) + "..."
    buttons.Push({ id: "play", icon: "pkg:/images/ic_play.png", label: playLabel })
    if m.ctx.trailer <> invalid and Bool_Of(St_Pref("trailerButton"), true) then buttons.Push({ id: "trailer", icon: "pkg:/images/ic_trailer.png", label: L("Tráiler") })
    if entry <> invalid and not Bool_Of(entry.nextUp, false) then buttons.Push({ id: "restart", icon: "pkg:/images/ic_next.png", label: L("Desde el inicio") })
    if St_InLibrary(m.ctx.metaId)
        buttons.Push({ id: "library", icon: "pkg:/images/ic_check.png", label: L("En Mi lista") })
    else
        buttons.Push({ id: "library", icon: "pkg:/images/ic_add.png", label: L("Mi lista") })
    end if
    m.details.buttons = buttons
end sub

sub onDetailsSelected()
    if m.busy then return
    runDetailAction(m.details.selected)
end sub

sub runDetailAction(action as string)
    if Left(action, 3) = "ep:"
        m.ctx.fromStart = false
        pickEpisodeById(Mid(action, 4))
        return
    end if
    if action = "trailer"
        if m.ctx.trailer <> invalid then openTrailer(m.ctx.trailer)
        return
    end if
    if Left(action, 5) = "cast:"
        Cast_Open(ToInt(Mid(action, 6), -1))
        return
    end if
    if action = "manual"
        m.ctx.forceManual = true
        action = "play"
    end if
    if action = "library"
        added = St_ToggleLibrary({ id: m.ctx.metaId, kind: m.ctx.kind, name: m.ctx.title, poster: m.ctx.poster })
        renderDetailButtons()
        if added
            m.details.status = L("Agregado a Mi lista.")
        else
            m.details.status = L("Quitado de Mi lista.")
        end if
        return
    end if
    if not m.ctx.metaReady and LCase(m.ctx.kind) <> "movie"
        m.ctx.pending = action
        showBusy(L("Cargando información..."))
        return
    end if
    if not m.ctx.metaReady and Left(m.ctx.metaId, 2) <> "tt"
        m.ctx.pending = action
        showBusy(L("Cargando información..."))
        return
    end if
    if action = "episodes"
        openEpisodes()
    else if action = "play" or action = "restart"
        m.ctx.fromStart = action = "restart"
        playMain()
    else if action = "partyPlay"
        Party_PlayMedia()
    end if
end sub

sub Cast_Open(index as integer)
    meta = m.ctx.meta
    if meta = invalid or type(meta.cast) <> "roArray" or index < 0 or index >= meta.cast.Count() then return
    person = meta.cast[index]
    name = Str_Of(person.name)
    if name = "" then return
    if Str_Of(person.id) = "" and Key_Tmdb(St_Integrations()) = ""
        showMessage(name, L("Para ver sus películas y series necesitas TMDB activado."))
        return
    end if
    closeDetails(false)
    Folder_Load(name, { title: name, sources: [{ provider: "tmdb", tmdbSourceType: "PERSON", tmdbId: Str_Any(person.id), personName: name, title: L("Películas y series") }] })
end sub

sub openEpisodes()
    if not isSeries() then return
    seasonIndex = -1
    entry = resumeEntry()
    if entry <> invalid
        for i = 0 to m.ctx.seasons.Count() - 1
            for each v in m.ctx.seasons[i].episodes
                if v.id = entry.videoId then seasonIndex = i
            end for
        end for
    end if
    if m.ctx.seasons.Count() = 1
        openMenu("episodes", { season: 0 })
    else if seasonIndex >= 0
        openMenu("seasons", {})
        m.stack.Peek().focus = seasonIndex
        openMenu("episodes", { season: seasonIndex })
    else
        openMenu("seasons", {})
    end if
end sub

function firstEpisode() as dynamic
    if not isSeries() then return invalid
    season = m.ctx.seasons[0]
    if season.episodes.Count() = 0 then return invalid
    v = season.episodes[0]
    return { season: 0, video: v, label: episodeLabelFor(season, v) }
end function

function episodeLabelFor(season as object, v as object) as string
    num = ToInt(v.episode, -1)
    s = season.season
    label = ""
    if s > 0 and num >= 0
        label = L("T") + s.ToStr() + ":E" + num.ToStr()
    else if num >= 0
        label = season.label + " E" + num.ToStr()
    else
        label = season.label
    end if
    name = episodeTitle(v)
    if name <> "" then label = label + "  " + name
    return label
end function

sub playMain()
    if isSeries()
        entry = resumeEntry()
        if entry <> invalid and (not m.ctx.fromStart or Bool_Of(m.ctx.restartSame, false))
            pickEpisodeById(Str_Of(entry.videoId))
            return
        end if
        first = firstEpisode()
        if first <> invalid
            pickEpisodeById(first.video.id)
            return
        end if
    end if
    ids = [m.ctx.imdb]
    meta = m.ctx.meta
    if meta <> invalid and IsStr(meta.defaultVideoId) then ids.Push(meta.defaultVideoId)
    setVideo(m.ctx.metaId, ids)
    m.ctx.episodeLabel = ""
    m.ctx.epSeason = -1
    m.ctx.epEpisode = -1
    fetchStreams()
end sub

sub pickEpisodeById(videoId as string)
    for each season in m.ctx.seasons
        for each v in season.episodes
            if v.id = videoId
                pickEpisodeVideo(season, v)
                return
            end if
        end for
    end for
    setVideo(videoId, [])
    fetchStreams()
end sub

sub pickEpisodeVideo(season as object, v as object)
    m.ctx.episodeLabel = episodeLabelFor(season, v)
    m.ctx.episodeMeta = { name: episodeTitle(v), overview: Str_OneLine(v.overview), thumbnail: Str_Of(v.thumbnail) }
    ids = []
    s = ToInt(v.season, -1)
    e = ToInt(v.episode, -1)
    m.ctx.epSeason = s
    m.ctx.epEpisode = e
    if m.ctx.imdb <> "" and s >= 0 and e >= 0 then ids.Push(m.ctx.imdb + ":" + s.ToStr() + ":" + e.ToStr())
    setVideo(v.id, ids)
    fetchStreams()
end sub

function nextEpisode() as dynamic
    found = false
    if type(m.ctx.seasons) <> "roArray" then return invalid
    for each season in m.ctx.seasons
        if type(season.episodes) <> "roArray" then return invalid
        for each v in season.episodes
            if found then return { season: season, video: v }
            if v.id = m.ctx.videoId then found = true
        end for
    end for
    return invalid
end function

sub setVideo(primary as string, ids as object)
    m.ctx.nextUpSaved = false
    all = [primary]
    for each id in ids
        all.Push(id)
    end for
    m.ctx.videoId = primary
    m.ctx.videoIds = Addon_UniqueIds(all)
end sub

function groupSeasons(videos as object) as object
    map = {}
    order = []
    for each v in videos
        if type(v) = "roAssociativeArray" and IsStr(v.id)
            season = ToInt(v.season, -1)
            key = "s" + season.ToStr()
            if not map.DoesExist(key)
                map[key] = []
                order.Push(season)
            end if
            map[key].Push(v)
        end if
    end for
    sorted = []
    for each s in order
        if s > 0 then insertSorted(sorted, s)
    end for
    for each s in order
        if s <= 0 then sorted.Push(s)
    end for
    result = []
    for each s in sorted
        eps = map["s" + s.ToStr()]
        label = L("Temporada ") + s.ToStr()
        if s = 0 then label = L("Especiales")
        if s < 0 then label = "Videos"
        result.Push({ season: s, label: label, episodes: sortEpisodes(eps) })
    end for
    return result
end function

sub insertSorted(list as object, value as integer)
    idx = list.Count()
    for i = 0 to list.Count() - 1
        if value < list[i]
            idx = i
            exit for
        end if
    end for
    list.Push(value)
    j = list.Count() - 1
    while j > idx
        list[j] = list[j - 1]
        j = j - 1
    end while
    list[idx] = value
end sub

function sortEpisodes(eps as object) as object
    numbered = true
    for each e in eps
        if ToInt(e.episode, -1) < 0 then numbered = false
    end for
    if not numbered then return eps
    out = []
    for each e in eps
        n = ToInt(e.episode, 0)
        idx = out.Count()
        for i = 0 to out.Count() - 1
            if n < ToInt(out[i].episode, 0)
                idx = i
                exit for
            end if
        end for
        out.Push(e)
        j = out.Count() - 1
        while j > idx
            out[j] = out[j - 1]
            j = j - 1
        end while
        out[idx] = e
    end for
    return out
end function

function episodeTitle(v as object) as string
    name = Str_Of(v.name)
    if name = "" then name = Str_Of(v.title)
    return name
end function

sub fetchStreams()
    ids = m.ctx.videoIds
    if type(ids) <> "roArray" or ids.Count() = 0 then ids = [m.ctx.videoId]
    m.ctx.subs = []
    m.ctx.subsWaited = false
    m.ctx.waitingSubs = false
    m.ctx.pool = []
    m.ctx.streams = []
    m.ctx.loading = true
    m.ctx.decided = false
    m.ctx.reused = invalid
    m.ctx.timerFired = false
    m.ctx.skipped = 0
    m.ctx.auto = autoplayOptions()
    m.autoTimer.control = "stop"
    pre = m.prefetch
    m.prefetch = invalid
    if pre <> invalid and pre.videoId = m.ctx.videoId and pre.task <> invalid
        m.streamTask = pre.task
        m.streamTask.observeField("batch", "onStreamBatch")
        m.streamTask.observeField("streams", "onStreamsLoaded")
        m.ctx.preDone = pre.task.streams <> invalid
    else
        m.ctx.preDone = false
        m.streamTask = CreateObject("roSGNode", "StreamTask")
        m.streamTask.manifests = m.manifests
        m.streamTask.kind = m.ctx.kind
        m.streamTask.videoIds = ids
        m.streamTask.observeField("batch", "onStreamBatch")
        m.streamTask.observeField("streams", "onStreamsLoaded")
        m.streamTask.control = "RUN"
    end if
    m.subtitleTask = CreateObject("roSGNode", "SubtitleTask")
    m.subtitleTask.manifests = m.manifests
    m.subtitleTask.kind = m.ctx.kind
    m.subtitleTask.videoIds = ids
    m.subtitleTask.observeField("subs", "onSubsLoaded")
    m.subtitleTask.control = "RUN"

    cached = reusableLink()
    if cached <> invalid
        m.ctx.decided = true
        m.ctx.reused = cached
        m.ctx.reusedPlay = true
        m.ctx.streams = [cached]
        playStream(0, 0)
        return
    end if
    if Bool_Of(m.ctx.preDone, false)
        m.ctx.preDone = false
        Streams_Done(m.streamTask)
        if m.ctx.decided then return
        if not m.ctx.auto.active
            openStreams()
            return
        end if
    end if
    if m.ctx.auto.active
        showBusy(L("Buscando enlaces..."))
        timeout = m.ctx.auto.timeout
        if timeout > 0
            m.autoTimer.duration = timeout
            m.autoTimer.control = "start"
        end if
        return
    end if
    openStreams()
end sub

function autoplayOptions() as object
    mode = Str_Of(St_Pref("autoplayMode"))
    binge = ""
    if m.ctx.bingePrefer <> "" and Bool_Of(St_Pref("bingeNext"), true) then binge = m.ctx.bingePrefer
    if binge = "" and isSeries() and Bool_Of(St_Pref("bingeReuse"), false)
        saved = St_Link("b:" + m.ctx.metaId, 0)
        if saved <> invalid then binge = Str_Of(saved.binge)
    end if
    if m.ctx.nextAuto and mode = "manual" then mode = "first"
    if Bool_Of(m.ctx.forceManual, false)
        mode = "manual"
        binge = ""
    end if
    timeout = ToInt(St_Pref("autoplayTimeout"), 3)
    return {
        mode: mode
        file: Str_Of(m.ctx.partyFile)
        regex: Str_Of(St_Pref("autoplayRegex"))
        scope: Str_Of(St_Pref("autoplayScope"))
        addons: St_Pref("autoplayAddons")
        binge: binge
        noFallback: binge <> "" and m.ctx.nextAuto and not Bool_Of(St_Pref("bingeFallback"), true)
        timeout: timeout
        active: mode <> "manual" or binge <> ""
    }
end function

function reusableLink() as dynamic
    if m.ctx.nextAuto or Bool_Of(m.ctx.forceManual, false) then return invalid
    if not Bool_Of(St_Pref("reuseLink"), false) and not Bool_Of(m.ctx.direct, false) then return invalid
    hours = ToInt(St_Pref("reuseHours"), 24)
    if hours < 1 then hours = 24
    saved = St_Link("v:" + m.ctx.videoId, hours * 3600)
    if saved = invalid or type(saved.stream) <> "roAssociativeArray" then return invalid
    if Str_Of(saved.stream.url) = "" then return invalid
    return saved.stream
end function

sub onSubsLoaded(event as object)
    task = event.getRoSGNode()
    if m.subtitleTask = invalid or not task.isSameNode(m.subtitleTask) then return
    m.subtitleTask = invalid
    subs = task.subs
    if subs <> invalid then m.ctx.subs = subs
    if Bool_Of(m.ctx.waitingSubs, false)
        m.ctx.waitingSubs = false
        m.ctx.subsWaited = true
        m.subsWait.control = "stop"
        if m.player.visible then launchAttempt()
    else if m.player.visible and type(subs) = "roArray" and subs.Count() > ToInt(m.ctx.loadedSubs, 0)
        m.player.extraSubs = subs
    end if
end sub

sub mergeStreams(incoming as object)
    if incoming = invalid then return
    for each s in incoming
        idx = m.ctx.pool.Count()
        for i = 0 to m.ctx.pool.Count() - 1
            if ToInt(m.ctx.pool[i].order, 0) > ToInt(s.order, 0)
                idx = i
                exit for
            end if
        end for
        m.ctx.pool.Push(s)
        j = m.ctx.pool.Count() - 1
        while j > idx
            m.ctx.pool[j] = m.ctx.pool[j - 1]
            j = j - 1
        end while
        m.ctx.pool[idx] = s
    end for
end sub

sub syncStreams()
    if m.ctx.reused <> invalid
        found = -1
        for i = 0 to m.ctx.pool.Count() - 1
            if m.ctx.pool[i].url = m.ctx.reused.url then found = i
        end for
        if m.ctx.loading then return
        list = []
        if found < 0 then list.Push(m.ctx.reused)
        for each s in m.ctx.pool
            list.Push(s)
        end for
        m.ctx.streams = list
        m.ctx.reused = invalid
    else
        m.ctx.streams = m.ctx.pool
    end if
    playing = Str_Of(m.ctx.playingUrl)
    if playing <> ""
        for i = 0 to m.ctx.streams.Count() - 1
            if m.ctx.streams[i].url = playing then m.ctx.sourceIndex = i
        end for
    end if
    if m.player.visible
        m.player.sources = sourceLabels()
        m.player.sourceIndex = ToInt(m.ctx.sourceIndex, 0)
    end if
    if m.streamsOpen
        m.streamsScreen.streams = m.ctx.streams
        m.streamsScreen.loading = m.ctx.loading
    end if
end sub

sub onStreamBatch(event as object)
    task = event.getRoSGNode()
    if m.streamTask = invalid or not task.isSameNode(m.streamTask) then return
    b = task.batch
    if b = invalid then return
    mergeStreams(b.streams)
    syncStreams()
    if not m.ctx.decided and m.ctx.auto.active
        if m.ctx.auto.timeout = 0 or m.ctx.timerFired then tryAutoPick(false)
    end if
end sub

sub onAutoTimer()
    if m.ctx.decided or not m.ctx.loading then return
    m.ctx.timerFired = true
    tryAutoPick(false)
end sub

sub onStreamsLoaded(event as object)
    Streams_Done(event.getRoSGNode())
end sub

sub Streams_Done(task as object)
    if m.streamTask = invalid or not task.isSameNode(m.streamTask) then return
    m.streamTask = invalid
    m.ctx.loading = false
    m.ctx.skipped = task.skipped
    final = task.streams
    if final = invalid then final = []
    m.ctx.pool = final
    syncStreams()
    if m.streamsOpen then m.streamsScreen.note = noStreamsText()
    if not m.ctx.decided and m.ctx.auto.active then tryAutoPick(true)
end sub

function noStreamsText() as string
    text = L("Ninguno de tus addons devolvió enlaces que Roku pueda reproducir para este título.")
    if m.ctx.skipped > 0 then text = text + L(" Se omitieron ") + m.ctx.skipped.ToStr() + L(" enlaces de tipo torrent o externos, que Roku no puede abrir.")
    return text
end function

sub tryAutoPick(final as boolean)
    index = Autoplay_Pick(m.ctx.streams, m.ctx.auto)
    if index >= 0
        m.ctx.decided = true
        m.ctx.reusedPlay = false
        m.autoTimer.control = "stop"
        hideBusy()
        playStream(index, 0)
        return
    end if
    if not final then return
    m.ctx.decided = true
    m.autoTimer.control = "stop"
    hideBusy()
    m.ctx.nextAuto = false
    if m.ctx.streams.Count() = 0
        if m.player.visible then closePlayer(false)
        showMessage(L("Sin enlaces"), noStreamsText())
        return
    end if
    if m.player.visible then closePlayer(false)
    openStreams()
end sub

sub openStreams()
    m.ctx.nextAuto = false
    code = ""
    epTitle = ""
    if m.ctx.episodeLabel <> ""
        if ToInt(m.ctx.epSeason, -1) >= 0 and ToInt(m.ctx.epEpisode, -1) >= 0
            code = L("T") + m.ctx.epSeason.ToStr() + " E" + m.ctx.epEpisode.ToStr()
        else
            code = m.ctx.episodeLabel
        end if
        if m.ctx.episodeMeta <> invalid then epTitle = m.ctx.episodeMeta.name
    else
        code = m.ctx.metaLine
    end if
    resume = St_ResumeFor(m.ctx.videoId)
    resumeText = ""
    if resume > 0 then resumeText = Fmt_Time(resume)
    place = Str_Of(St_Pref("badgePlace"))
    m.streamsScreen.accent = m.accent
    m.streamsScreen.resume = resumeText
    m.streamsScreen.fromStart = m.ctx.fromStart
    m.streamsScreen.info = { title: m.ctx.title, logo: m.ctx.logo, background: m.ctx.background, code: code, episodeTitle: epTitle, place: place, showLogo: Bool_Of(St_Pref("addonLogo"), true) }
    m.streamsScreen.note = ""
    m.streamsScreen.loading = m.ctx.loading
    m.streamsScreen.streams = m.ctx.streams
    if not m.ctx.loading then m.streamsScreen.note = noStreamsText()
    m.streamsOpen = true
    m.streamsScreen.visible = true
    if m.top.dialog = invalid then m.streamsScreen.setFocus(true)
end sub

sub closeStreams(refocus as boolean)
    m.streamsOpen = false
    m.streamsScreen.visible = false
    m.streamTask = invalid
    m.autoTimer.control = "stop"
    if refocus then focusCurrent()
end sub

sub onStreamsEvent()
    ev = m.streamsScreen.event
    if ev = invalid then return
    kind = Str_Of(ev.type)
    if kind = "back"
        closeStreams(true)
    else if kind = "play"
        m.ctx.decided = true
        m.ctx.reusedPlay = false
        playStream(ToInt(ev.index, -1), 0)
    else if kind = "refresh"
        m.ctx.forceManual = true
        fetchStreams()
    else if kind = "toggleStart"
        m.ctx.fromStart = not m.ctx.fromStart
        m.streamsScreen.fromStart = m.ctx.fromStart
    end if
end sub

function sourceLabels() as object
    labels = []
    for each item in m.ctx.streams
        label = Str_Of(item.addon)
        first = Str_OneLine(item.name)
        if first <> "" and first <> label then label = label + "  ·  " + first
        detail = Str_FirstLine(item.desc)
        if detail <> "" then label = label + "  ·  " + detail
        if label = "" then label = Str_Of(item.label)
        labels.Push(Left(label, 110))
    end for
    return labels
end function

sub playStream(index as integer, startAt as integer)
    streams = m.ctx.streams
    if streams = invalid or index < 0 or index >= streams.Count() then return
    s = streams[index]
    m.ctx.sourceIndex = index
    m.ctx.playingUrl = s.url
    m.ctx.playingStream = s
    m.ctx.savedLink = false
    m.ctx.attempts = Stream_Attempts(s.url)
    m.ctx.attempt = 0
    m.ctx.retriedDrop = false
    m.ctx.resumeMode = ""
    resume = startAt
    if resume = 0 and not m.ctx.fromStart then resume = St_ResumeFor(m.ctx.videoId)
    m.ctx.startAt = resume
    m.lastSaved = resume
    showPlayer(index)
    if m.subtitleTask <> invalid and not Bool_Of(m.ctx.subsWaited, false)
        m.ctx.waitingSubs = true
        m.subsWait.control = "stop"
        m.subsWait.control = "start"
        return
    end if
    launchAttempt()
end sub

sub onSubsWait()
    if m.ctx = invalid then return
    m.ctx.subsWaited = true
    if Bool_Of(m.ctx.waitingSubs, false)
        m.ctx.waitingSubs = false
        if m.player.visible then launchAttempt()
    end if
end sub

sub showPlayer(index as integer)
    Poster_Stop()
    metaLine = m.ctx.metaLine
    title = m.ctx.title
    description = m.ctx.description
    if m.ctx.episodeLabel <> ""
        metaLine = m.ctx.episodeLabel
        if m.ctx.episodeMeta <> invalid and m.ctx.episodeMeta.overview <> "" then description = m.ctx.episodeMeta.overview
    end if
    m.player.partyEnabled = true
    m.player.extraSubs = []
    m.player.info = {
        title: title
        logo: m.ctx.logo
        metaLine: metaLine
        description: description
        background: m.ctx.background
        isSeries: isSeries()
        audioLang: Str_Of(St_Pref("audioLang"))
        audioLang2: Str_Of(St_Pref("audioLang2"))
        subLang: Str_Of(St_Pref("subLang"))
        subLang2: Str_Of(St_Pref("subLang2"))
        forcedSubs: Bool_Of(St_Pref("forcedSubs"), false)
        originalLang: Str_Of(m.ctx.originalLang)
        pauseOverlay: Bool_Of(St_Pref("pauseOverlay"), true)
        clock: Bool_Of(St_Pref("clock"), true)
        resumeAt: ToInt(m.ctx.startAt, 0)
        skip: Bool_Of(St_Pref("skipIntro"), true)
        autoSkip: Extras_AutoSkip()
        nextMode: Str_Of(St_Pref("nextMode"))
        nextPct: ToInt(St_Pref("nextPct"), 99)
        nextMin: ToInt(St_Pref("nextMin"), 2)
        autoNext: Bool_Of(St_Pref("autoNext"), true)
        postPlay: Bool_Of(St_Pref("postPlay"), true)
        postPct: ToInt(St_Pref("postPct"), 96)
        stats: Bool_Of(St_Pref("playerStats"), false)
        stripSdh: Bool_Of(St_Pref("stripSdh"), false)
        onlyPreferred: Bool_Of(St_Pref("onlyPrefSubs"), false)
        customSubs: Bool_Of(St_Pref("customSubs"), true)
        subStyle: { size: Str_Of(St_Pref("subSize")), color: Str_Of(St_Pref("subColor")), bg: Str_Of(St_Pref("subBg")), bold: Bool_Of(St_Pref("subBold"), false), edge: Str_Of(St_Pref("subEdge")), offset: ToInt(St_Pref("subOffset"), 0) }
    }
    Extras_Start()
    m.player.sources = sourceLabels()
    m.player.sourceIndex = index
    video = m.playerVideo
    if m.player.visible then video.control = "stop"
    m.scrobbleState = ""
    m.list.visible = false
    m.player.visible = true
    m.player.active = true
    m.player.setFocus(true)
end sub

function subtitleTracks() as object
    tracks = []
    if type(m.ctx.subs) = "roArray"
        for each subItem in m.ctx.subs
            tracks.Push({ Language: subItem.lang, TrackName: subItem.url, Description: subItem.label })
        end for
    end if
    return tracks
end function

sub launchAttempt()
    s = m.ctx.playingStream
    if s = invalid then return
    attempts = m.ctx.attempts
    if type(attempts) <> "roArray" or attempts.Count() = 0 then attempts = [{ url: s.url, fmt: "" }]
    attempt = attempts[ToInt(m.ctx.attempt, 0)]
    content = CreateObject("roSGNode", "ContentNode")
    content.url = attempt.url
    content.title = m.ctx.title
    if attempt.fmt <> "" then content.streamFormat = attempt.fmt
    if type(s.headers) = "roArray" and s.headers.Count() > 0 then content.HttpHeaders = s.headers
    if LCase(Left(attempt.url, 6)) = "https:"
        content.HttpSendClientCertificates = true
        content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    end if
    tracks = subtitleTracks()
    if tracks.Count() > 0 then content.SubtitleTracks = tracks
    m.ctx.loadedSubs = tracks.Count()
    resume = ToInt(m.ctx.startAt, 0)
    if resume > 0 and Str_Of(m.ctx.resumeMode) = "" then content.PlayStart = resume
    video = m.playerVideo
    video.control = "stop"
    video.EnableCookies()
    video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    video.InitClientCertificates()
    video.content = content
    video.control = "play"
    m.ctx.launchedAt = CreateObject("roTimespan")
    lowered = LCase(s.url)
    q = Instr(1, lowered, "?")
    if q > 0 then lowered = Left(lowered, q - 1)
    m.player.altAudio = attempt.fmt = "hls" and Right(lowered, 3) = ".ts"
end sub

sub Alt_Audio(position as integer)
    s = m.ctx.playingStream
    if s = invalid then return
    attempts = m.ctx.attempts
    target = -1
    for i = 0 to attempts.Count() - 1
        if attempts[i].url = s.url and attempts[i].fmt = "" then target = i
    end for
    if target < 0
        attempts.Push({ url: s.url, fmt: "" })
        target = attempts.Count() - 1
        m.ctx.attempts = attempts
    end if
    m.ctx.altFrom = ToInt(m.ctx.attempt, 0)
    m.ctx.attempt = target
    if position > 5 then m.ctx.startAt = position
    refreshResume()
    launchAttempt()
end sub

function Alt_Restore(position as integer) as boolean
    if m.ctx.altFrom = invalid then return false
    m.ctx.attempt = m.ctx.altFrom
    m.ctx.altFrom = invalid
    if position > 5 then m.ctx.startAt = position
    refreshResume()
    launchAttempt()
    Toast_Show(L("Roku no pudo abrir el enlace original. Se volvió a la versión que sí funciona."))
    return true
end function

function Resume_Retry(position as integer) as boolean
    startAt = ToInt(m.ctx.startAt, 0)
    if startAt <= 0 or position - startAt >= 15 then return false
    mode = Str_Of(m.ctx.resumeMode)
    if mode = ""
        m.ctx.resumeMode = "seek"
    else if mode = "seek"
        m.ctx.resumeMode = "zero"
        m.ctx.startAt = 0
        Toast_Show(L("Este enlace no permitió continuar desde donde ibas, así que empezó desde el principio."))
    else
        return false
    end if
    refreshResume()
    launchAttempt()
    return true
end function

function nextAttempt(position as integer) as boolean
    attempts = m.ctx.attempts
    if type(attempts) <> "roArray" then return false
    nxt = ToInt(m.ctx.attempt, 0) + 1
    if nxt >= attempts.Count() then return false
    m.ctx.attempt = nxt
    if position > 10 then m.ctx.startAt = position
    refreshResume()
    launchAttempt()
    return true
end function

sub refreshResume()
    info = m.player.info
    if info = invalid then return
    info.resumeAt = ToInt(m.ctx.startAt, 0)
    m.player.info = info
end sub

sub reloadWithSubtitle(url as string, position as integer)
    if m.ctx.playingStream = invalid then return
    m.ctx.startAt = position
    info = m.player.info
    if info <> invalid
        info.resumeAt = position
        info.subLang = "url:" + url
        m.player.info = info
    end if
    launchAttempt()
end sub

function playbackFailureText(message as string) as string
    s = m.ctx.playingStream
    text = L("Este enlace no funcionó en Roku (") + message + L("). Prueba con otra fuente de la lista.")
    if s <> invalid and not Device_Can4K()
        re = CreateObject("roRegex", "2160|\b4k\b|\buhd\b", "i")
        if re.IsMatch(Stream_SearchText(s)) then text = L("Este enlace es 4K y tu Roku o tu TV no está en modo 4K. Elige una fuente 1080p o menor.")
    end if
    if s <> invalid and not Device_CanHevc()
        re2 = CreateObject("roRegex", "\b(x265|hevc|h\.?265|10bit|10-bit|hdr|hdr10)\b", "i")
        if re2.IsMatch(Stream_SearchText(s)) then text = L("Este enlace es HEVC (x265) y tu Roku no puede reproducir ese formato. Elige una fuente x264 o H.264.")
    end if
    return text
end function

sub rememberStream()
    if Bool_Of(m.ctx.savedLink, false) then return
    s = m.ctx.playingStream
    if s = invalid then return
    m.ctx.savedLink = true
    if s.url <> ""
        St_SaveLink("v:" + m.ctx.videoId, { stream: { url: s.url, headers: s.headers, name: s.name, desc: s.desc, addon: s.addon, logo: s.logo, binge: s.binge, chips: s.chips, badges: [], label: s.label, order: -1 } })
    end if
    if Str_Of(s.binge) <> "" and isSeries() then St_SaveLink("b:" + m.ctx.metaId, { binge: s.binge })
end sub

sub onPlayerEvent()
    try
        Player_Event()
    catch e
        print "PLAYBACK ERROR "; Err_Text(e)
        showMessage(L("Error del reproductor"), Err_Text(e))
    end try
end sub

sub Player_Event()
    ev = m.player.event
    if ev = invalid then return
    kind = Str_Of(ev.type)
    if kind = "close"
        closePlayer(true)
    else if kind = "crash"
        showMessage(L("Error del reproductor"), Str_Of(ev.message))
    else if kind = "control"
        Party_Publish(Bool_Of(ev.paused, false), 0.0 + ev.position)
    else if kind = "party"
        Party_Menu()
    else if kind = "source"
        saveProgress()
        playStream(ToInt(ev.index, 0), ToInt(ev.position, 0))
    else if kind = "nextAuto"
        Next_Auto()
    else if kind = "nextNow"
        m.autoCount = 0
        nxt = nextEpisode()
        if nxt <> invalid
            saveProgress()
            playNext(nxt)
        end if
    else if kind = "prefetchNext"
        Next_Prefetch()
    else if kind = "stillYes"
        m.autoCount = 0
        nxt = nextEpisode()
        if nxt <> invalid
            saveProgress()
            playNext(nxt)
        else
            closePlayer(true)
        end if
    else if kind = "stillNo"
        m.autoCount = 0
        closePlayer(true)
    else if kind = "recPick"
        closePlayer(true)
        if m.streamsOpen then closeStreams(false)
        item = CreateObject("roSGNode", "ContentNode")
        item.title = Str_Of(ev.name)
        item.HDPosterUrl = Str_Of(ev.poster)
        item.addFields({ itemType: Str_Of(ev.kind), metaId: Str_Of(ev.id), videoId: "", background: Str_Of(ev.background), metaLine: "", episodeLabel: "", progress: 0.0, logo: "", rating: "", fallback: "", portrait: Str_Of(ev.poster) })
        if m.detailsOpen then closeDetails(false)
        openDetails(item)
    else if kind = "altAudio"
        Alt_Audio(ToInt(ev.position, 0))
    else if kind = "subsReload"
        reloadWithSubtitle(Str_Of(ev.url), ToInt(ev.position, 0))
    else if kind = "finished" and not playbackEnded(ToInt(ev.position, 0), ToInt(ev.duration, 0))
        position = ToInt(ev.position, 0)
        if position < 10 and Bool_Of(m.ctx.reusedPlay, false)
            fallbackFromReuse()
        else if Resume_Retry(position)
        else if position > 30 and not Bool_Of(m.ctx.retriedDrop, false)
            m.ctx.retriedDrop = true
            m.ctx.startAt = position
            refreshResume()
            launchAttempt()
        else if Alt_Restore(ToInt(m.ctx.startAt, 0))
        else if position < 10 and Bool_Of(m.ctx.reusedPlay, false)
            fallbackFromReuse()
        else if not nextAttempt(position)
            saveProgress()
            closePlayer(false)
            showMessage(L("No se pudo reproducir"), playbackFailureText(L("la conexión se cortó")))
        end if
    else if kind = "finished"
        St_RemoveProgress(m.ctx.metaId)
        NextUp_Save()
        scrobble("stop")
        m.scrobbleState = ""
        nxt = nextEpisode()
        if nxt <> invalid and Bool_Of(St_Pref("autoNext"), true)
            Next_Auto()
        else
            closePlayer(false)
        end if
    else if kind = "error"
        position = Int(m.playerVideo.position)
        if Alt_Restore(ToInt(m.ctx.startAt, 0))
        else if position < 10 and Bool_Of(m.ctx.reusedPlay, false)
            fallbackFromReuse()
        else if not nextAttempt(position)
            closePlayer(position > 10)
            showMessage(L("No se pudo reproducir"), playbackFailureText(Str_Of(ev.message)))
        end if
    else if kind = "next"
        m.autoCount = 0
        nxt = nextEpisode()
        if nxt = invalid
            showMessage(L("Fin de la serie"), L("Este es el último episodio disponible."))
        else
            saveProgress()
            playNext(nxt)
        end if
    else if kind = "episodes"
        closePlayer(true)
        if m.streamsOpen then closeStreams(false)
        if m.stack.Count() > 0
            renderMenu(m.stack.Peek().focus)
        else
            openEpisodes()
        end if
    end if
end sub

function Extras_AutoSkip() as object
    out = []
    for each pair in [["autoSkipIntro", "intro"], ["autoSkipRecap", "recap"], ["autoSkipOutro", "outro"], ["autoSkipCredits", "credits"]]
        if Bool_Of(St_Pref(pair[0]), false) then out.Push(pair[1])
    end for
    return out
end function

sub Extras_Start()
    key = Str_Of(m.ctx.videoId)
    if key = Str_Of(m.extrasFor) and m.extrasData <> invalid
        m.player.nextInfo = m.extrasData.nextEp
        m.player.segments = m.extrasData.segments
        m.player.recs = m.extrasData.recs
        return
    end if
    m.extrasFor = key
    m.player.segments = []
    m.player.parental = []
    m.player.recs = []
    nxt = nextEpisode()
    info = {}
    if nxt <> invalid
        v = nxt.video
        code = L("T") + ToInt(v.season, 0).ToStr() + " E" + ToInt(v.episode, 0).ToStr()
        info = { code: code, title: episodeTitle(v), thumb: Str_Of(v.thumbnail) }
    end if
    m.player.nextInfo = info
    m.extrasData = { nextEp: info, segments: [], recs: [] }
    imdb = Str_Of(m.ctx.imdb)
    id = Str_Of(m.ctx.metaId)
    params = { tag: key, imdb: imdb, movie: not isSeries(), season: ToInt(m.ctx.epSeason, -1), episode: ToInt(m.ctx.epEpisode, -1) }
    if Left(id, 4) = "mal:" then params.mal = id.Split(":")[1]
    if Left(id, 6) = "kitsu:" then params.kitsu = id.Split(":")[1]
    if Left(key, 6) = "kitsu:" and params.episode < 0
        parts = key.Split(":")
        if parts.Count() >= 3 then params.episode = parts[parts.Count() - 1].ToInt()
    end if
    if Bool_Of(St_Pref("skipIntro"), true) or Extras_AutoSkip().Count() > 0 then Extras_Run("skip", params)
    if Bool_Of(St_Pref("parentalGuide"), true) and Left(imdb, 2) = "tt" then Extras_Run("parental", { tag: key, imdb: imdb })
    if Bool_Of(St_Pref("postPlay"), true) and nxt = invalid
        tmdb = ""
        if Left(id, 5) = "tmdb:" then tmdb = id.Split(":")[1]
        Extras_Run("recs", { tag: key, imdb: imdb, tmdb: tmdb, series: isSeries() })
    end if
end sub

sub Extras_Run(mode as string, params as object)
    task = CreateObject("roSGNode", "PlayerDataTask")
    task.mode = mode
    task.params = params
    task.observeField("result", "onExtrasResult")
    task.control = "RUN"
    if m.extrasTasks = invalid then m.extrasTasks = []
    m.extrasTasks.Push(task)
end sub

sub onExtrasResult(event as object)
    task = event.getRoSGNode()
    r = task.result
    if m.extrasTasks <> invalid
        kept = []
        for each t in m.extrasTasks
            if not t.isSameNode(task) then kept.Push(t)
        end for
        m.extrasTasks = kept
    end if
    if r = invalid or Str_Of(r.tag) <> Str_Of(m.extrasFor) or not m.player.visible then return
    if r.mode = "skip" and type(r.segments) = "roArray"
        m.player.segments = r.segments
        m.extrasData.segments = r.segments
    end if
    if r.mode = "parental" and type(r.items) = "roArray" then m.player.parental = r.items
    if r.mode = "recs" and type(r.items) = "roArray"
        m.player.recs = r.items
        m.extrasData.recs = r.items
    end if
end sub

sub Next_Auto()
    nxt = nextEpisode()
    if nxt = invalid
        closePlayer(false)
        return
    end if
    m.autoCount = ToInt(m.autoCount, 0) + 1
    limit = ToInt(St_Pref("stillCount"), 3)
    if Bool_Of(St_Pref("stillWatching"), true) and m.autoCount >= limit
        m.player.stillWatching = true
        return
    end if
    saveProgress()
    playNext(nxt)
end sub

sub Next_Prefetch()
    if not Bool_Of(St_Pref("preloadNext"), false) then return
    nxt = nextEpisode()
    if nxt = invalid then return
    v = nxt.video
    ids = [v.id]
    s = ToInt(v.season, -1)
    e = ToInt(v.episode, -1)
    if m.ctx.imdb <> "" and s >= 0 and e >= 0 then ids.Push(m.ctx.imdb + ":" + s.ToStr() + ":" + e.ToStr())
    task = CreateObject("roSGNode", "StreamTask")
    task.manifests = m.manifests
    task.kind = m.ctx.kind
    task.videoIds = Addon_UniqueIds(ids)
    task.control = "RUN"
    m.prefetch = { videoId: v.id, task: task }
end sub

sub playNext(nxt as object)
    m.ctx.bingePrefer = ""
    if m.ctx.playingStream <> invalid then m.ctx.bingePrefer = Str_Of(m.ctx.playingStream.binge)
    m.ctx.nextAuto = true
    m.ctx.fromStart = true
    if m.streamsOpen then closeStreams(false)
    pickEpisodeVideo(nxt.season, nxt.video)
end sub

sub onPlayerVideoState()
    if not m.player.visible then return
    state = m.playerVideo.state
    if state = "playing"
        rememberStream()
        m.ctx.reusedPlay = false
        m.ctx.altFrom = invalid
    end if
    Party_OnVideoState(state)
    if state = "playing" then Party_OnPlaying()
    if state = "playing" and m.scrobbleState <> "playing"
        m.scrobbleState = "playing"
        scrobble("start")
    else if state = "paused" and m.scrobbleState = "playing"
        saveProgress()
        m.scrobbleState = "paused"
        scrobble("pause")
    end if
end sub

sub scrobble(action as string)
    integ = St_Integrations()
    if integ.traktToken = "" and integ.simklToken = "" then return
    if m.ctx.imdb = "" then return
    video = m.playerVideo
    progress = 0.0
    if video.duration > 0 then progress = video.position * 100.0 / video.duration
    task = CreateObject("roSGNode", "AccountTask")
    task.mode = "scrobble"
    task.params = { action: action, imdb: m.ctx.imdb, isShow: isSeries(), season: ToInt(m.ctx.epSeason, -1), episode: ToInt(m.ctx.epEpisode, -1), progress: progress }
    task.control = "RUN"
    m.scrobbleTask = task
end sub

sub onPlayerPosition()
    if not m.player.visible then return
    current = Int(m.playerVideo.position)
    if Abs(current - m.lastSaved) >= 10 then saveProgress()
end sub

sub saveProgress()
    video = m.playerVideo
    current = Int(video.position)
    total = Int(video.duration)
    m.lastSaved = current
    if not m.prefs.continueWatching or current < 10 then return
    kind = LCase(Str_Of(m.ctx.kind))
    if kind = "tv" or kind = "channel" or kind = "channels" or kind = "events" or kind = "live" then return
    if total > 0 and current > total * 0.95
        St_RemoveProgress(m.ctx.metaId)
        NextUp_Save()
        return
    end if
    St_SaveProgress({
        metaId: m.ctx.metaId
        videoId: m.ctx.videoId
        kind: m.ctx.kind
        title: m.ctx.title
        poster: m.ctx.poster
        background: m.ctx.background
        episode: m.ctx.episodeLabel
        thumb: progressThumb()
        altIds: m.ctx.videoIds
        position: current
        duration: total
    })
end sub

sub NextUp_Save()
    if Bool_Of(m.ctx.nextUpSaved, false) or not isSeries() then return
    if not m.prefs.continueWatching then return
    m.ctx.nextUpSaved = true
    nxt = nextEpisode()
    if nxt = invalid then return
    v = nxt.video
    released = Str_Of(v.released)
    if released <> ""
        now = CreateObject("roDateTime")
        if Left(released, 10) > Left(now.ToISOString(), 10) then return
    end if
    s = ToInt(v.season, -1)
    e = ToInt(v.episode, -1)
    ids = [Str_Of(v.id)]
    if m.ctx.imdb <> "" and s >= 0 and e >= 0 then ids.Push(m.ctx.imdb + ":" + s.ToStr() + ":" + e.ToStr())
    thumb = Str_Of(v.thumbnail)
    if thumb = "" then thumb = Str_Of(m.ctx.background)
    St_SaveProgress({
        metaId: m.ctx.metaId
        videoId: Str_Of(v.id)
        kind: m.ctx.kind
        title: m.ctx.title
        poster: m.ctx.poster
        background: m.ctx.background
        episode: episodeLabelFor(nxt.season, v) + "  " + episodeTitle(v)
        thumb: thumb
        altIds: ids
        position: 0
        duration: 0
        nextUp: true
        season: s
        ep: e
    })
end sub

sub fallbackFromReuse()
    m.ctx.reusedPlay = false
    m.ctx.reused = invalid
    m.ctx.decided = false
    m.ctx.streams = m.ctx.pool
    if m.ctx.auto.active
        m.playerVideo.control = "stop"
        m.player.active = false
        m.player.visible = false
        showBusy(L("Buscando enlaces..."))
        if not m.ctx.loading
            tryAutoPick(true)
        else
            m.ctx.timerFired = true
        end if
        return
    end if
    m.ctx.decided = true
    openStreams()
    closePlayer(false)
end sub

function playbackEnded(position as integer, duration as integer) as boolean
    if duration <= 0 then return false
    if position >= duration - 90 then return true
    return position >= duration * 0.9
end function

function progressThumb() as string
    if m.ctx.episodeLabel <> "" and m.ctx.episodeMeta <> invalid
        if m.ctx.episodeMeta.thumbnail <> "" then return m.ctx.episodeMeta.thumbnail
    end if
    return Str_Of(m.ctx.background)
end function

sub closePlayer(save as boolean)
    if m.party <> invalid
        m.partyIdle = m.party.mediaKey
        m.partyFollowing = ""
        Party_Status("browsing")
    end if
    if save then saveProgress()
    if m.scrobbleState <> "" then scrobble("stop")
    m.scrobbleState = ""
    m.player.active = false
    m.player.visible = false
    m.ctx.fromStart = false
    m.ctx.nextAuto = false
    if m.detailsOpen then renderDetailButtons()
    if m.streamsOpen
        m.streamsScreen.fromStart = false
        focusCurrent()
    else if m.stack.Count() > 0
        renderMenu(m.stack.Peek().focus)
    else
        focusCurrent()
    end if
end sub

sub startTrailerLookup(meta as object)
    if not Bool_Of(St_Pref("trailerButton"), true) and not Bool_Of(St_Pref("trailerAutoplay"), false) then return
    task = CreateObject("roSGNode", "TrailerTask")
    task.imdb = Str_Of(m.ctx.imdb)
    task.kind = Str_Of(m.ctx.kind)
    task.localYt = meta.trailerLocal
    task.ytIds = meta.trailerYt
    task.urls = meta.trailerUrls
    task.tag = m.ctx.metaId
    task.observeField("result", "onTrailerFound")
    task.control = "RUN"
    m.trailerTask = task
end sub

sub onTrailerFound(event as object)
    task = event.getRoSGNode()
    if m.trailerTask = invalid or not task.isSameNode(m.trailerTask) then return
    m.trailerTask = invalid
    r = task.result
    if r = invalid or Str_Of(r.url) = "" or not m.detailsOpen or task.tag <> m.ctx.metaId then return
    r.title = m.ctx.title
    m.ctx.trailer = r
    renderDetailButtons()
    if Bool_Of(St_Pref("trailerAutoplay"), false) and m.details.visible
        auto = {}
        auto.Append(r)
        auto.delay = ToInt(St_Pref("trailerDelay"), 7)
        m.details.trailer = auto
    end if
end sub

sub openTrailer(t as object)
    m.details.trailer = {}
    m.trailerOpen = true
    m.trailerPlayer.visible = true
    m.trailerPlayer.trailer = t
    m.trailerPlayer.setFocus(true)
end sub

sub onTrailerEvent()
    ev = m.trailerPlayer.event
    if ev = invalid then return
    m.trailerOpen = false
    m.trailerPlayer.visible = false
    m.trailerPlayer.trailer = { url: "" }
    if Bool_Of(ev.error, false) then showMessage(L("Tráiler no disponible"), L("No se pudo reproducir el tráiler de este título en Roku."))
    focusCurrent()
end sub
