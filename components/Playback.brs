sub openDetails(item as object)
    hideExpanded()
    m.ctx = {
        kind: item.itemType
        metaId: item.metaId
        videoId: ""
        videoIds: []
        title: item.title
        poster: item.HDPosterUrl
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
    m.details.data = heroData(item, m.metaCache[item.metaId])
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
    if m.ctx.poster = "" then m.ctx.poster = Str_Of(meta.poster)
    if Str_Of(meta.background) <> "" then m.ctx.background = meta.background
    if Str_Of(meta.logo) <> "" then m.ctx.logo = meta.logo
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
    }
    m.details.status = ""
    renderDetailButtons()
    if m.ctx.pending <> ""
        action = m.ctx.pending
        m.ctx.pending = ""
        hideBusy()
        runDetailAction(action)
    end if
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
        if Str_Of(entry.episode) <> ""
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
    if isSeries() then buttons.Push({ id: "episodes", icon: "pkg:/images/ic_episodes.png", label: L("Episodios") })
    if m.ctx.trailer <> invalid and Bool_Of(St_Pref("trailerButton"), true) then buttons.Push({ id: "trailer", icon: "pkg:/images/ic_trailer.png", label: L("Tráiler") })
    if entry <> invalid then buttons.Push({ id: "restart", icon: "pkg:/images/ic_next.png", label: L("Desde el inicio") })
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
    if action = "trailer"
        if m.ctx.trailer <> invalid then openTrailer(m.ctx.trailer)
        return
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
    end if
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
        if entry <> invalid and not m.ctx.fromStart
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
    for each season in m.ctx.seasons
        for each v in season.episodes
            if found then return { season: season, video: v }
            if v.id = m.ctx.videoId then found = true
        end for
    end for
    return invalid
end function

sub setVideo(primary as string, ids as object)
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
    m.ctx.pool = []
    m.ctx.streams = []
    m.ctx.loading = true
    m.ctx.decided = false
    m.ctx.reused = invalid
    m.ctx.timerFired = false
    m.ctx.skipped = 0
    m.ctx.auto = autoplayOptions()
    m.autoTimer.control = "stop"
    m.streamTask = CreateObject("roSGNode", "StreamTask")
    m.streamTask.manifests = m.manifests
    m.streamTask.kind = m.ctx.kind
    m.streamTask.videoIds = ids
    m.streamTask.observeField("batch", "onStreamBatch")
    m.streamTask.observeField("streams", "onStreamsLoaded")
    m.streamTask.control = "RUN"
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
        m.ctx.streams = [cached]
        playStream(0, 0)
        return
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
    timeout = ToInt(St_Pref("autoplayTimeout"), 3)
    return {
        mode: mode
        regex: Str_Of(St_Pref("autoplayRegex"))
        scope: Str_Of(St_Pref("autoplayScope"))
        addons: St_Pref("autoplayAddons")
        binge: binge
        timeout: timeout
        active: mode <> "manual" or binge <> ""
    }
end function

function reusableLink() as dynamic
    if not Bool_Of(St_Pref("reuseLink"), false) or m.ctx.nextAuto then return invalid
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
    task = event.getRoSGNode()
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
        playStream(ToInt(ev.index, -1), 0)
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
    content = CreateObject("roSGNode", "ContentNode")
    content.url = s.url
    content.title = m.ctx.title
    fmt = Stream_Format(s.url)
    if fmt <> "" then content.streamFormat = fmt
    if type(s.headers) = "roArray" and s.headers.Count() > 0 then content.HttpHeaders = s.headers
    if LCase(Left(s.url, 6)) = "https:"
        content.HttpSendClientCertificates = true
        content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
    end if
    tracks = []
    if type(m.ctx.subs) = "roArray"
        for each subItem in m.ctx.subs
            tracks.Push({ Language: subItem.lang, TrackName: subItem.url, Description: subItem.label })
        end for
    end if
    if tracks.Count() > 0 then content.SubtitleTracks = tracks
    resume = startAt
    if resume = 0 and not m.ctx.fromStart then resume = St_ResumeFor(m.ctx.videoId)
    if resume > 0 then content.PlayStart = resume
    m.lastSaved = resume

    metaLine = m.ctx.metaLine
    title = m.ctx.title
    description = m.ctx.description
    if m.ctx.episodeLabel <> ""
        metaLine = m.ctx.episodeLabel
        if m.ctx.episodeMeta <> invalid and m.ctx.episodeMeta.overview <> "" then description = m.ctx.episodeMeta.overview
    end if
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
    }
    m.player.sources = sourceLabels()
    m.player.sourceIndex = index
    video = m.playerVideo
    if m.player.visible then video.control = "stop"
    m.scrobbleState = ""
    video.EnableCookies()
    video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    video.InitClientCertificates()
    video.content = content
    m.list.visible = false
    m.player.visible = true
    m.player.active = true
    m.player.setFocus(true)
    video.control = "play"
end sub

sub rememberStream()
    if m.ctx.savedLink = true then return
    s = m.ctx.playingStream
    if s = invalid then return
    m.ctx.savedLink = true
    if Bool_Of(St_Pref("reuseLink"), false)
        St_SaveLink("v:" + m.ctx.videoId, { stream: { url: s.url, headers: s.headers, name: s.name, desc: s.desc, addon: s.addon, logo: s.logo, binge: s.binge, chips: s.chips, badges: [], label: s.label, order: -1 } })
    end if
    if Str_Of(s.binge) <> "" and isSeries() then St_SaveLink("b:" + m.ctx.metaId, { binge: s.binge })
end sub

sub onPlayerEvent()
    ev = m.player.event
    if ev = invalid then return
    kind = Str_Of(ev.type)
    if kind = "close"
        closePlayer(true)
    else if kind = "source"
        saveProgress()
        playStream(ToInt(ev.index, 0), ToInt(ev.position, 0))
    else if kind = "finished"
        St_RemoveProgress(m.ctx.metaId)
        scrobble("stop")
        m.scrobbleState = ""
        nxt = nextEpisode()
        if nxt <> invalid and Bool_Of(St_Pref("autoNext"), true)
            playNext(nxt)
        else
            closePlayer(false)
        end if
    else if kind = "error"
        closePlayer(false)
        showMessage(L("No se pudo reproducir"), L("Este enlace no funcionó en Roku (") + Str_Of(ev.message) + L("). Prueba con otra fuente de la lista."))
    else if kind = "next"
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
    if state = "playing" then rememberStream()
    if state = "playing" and m.scrobbleState <> "playing"
        m.scrobbleState = "playing"
        scrobble("start")
    else if state = "paused" and m.scrobbleState = "playing"
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
    if Abs(current - m.lastSaved) >= 15 then saveProgress()
end sub

sub saveProgress()
    video = m.playerVideo
    current = Int(video.position)
    total = Int(video.duration)
    m.lastSaved = current
    if not m.prefs.continueWatching or current < 10 then return
    if total > 0 and current > total * 0.95
        St_RemoveProgress(m.ctx.metaId)
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

function progressThumb() as string
    if m.ctx.episodeLabel <> "" and m.ctx.episodeMeta <> invalid
        if m.ctx.episodeMeta.thumbnail <> "" then return m.ctx.episodeMeta.thumbnail
    end if
    return Str_Of(m.ctx.background)
end function

sub closePlayer(save as boolean)
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
    if Bool_Of(St_Pref("trailerAutoplay"), false)
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
