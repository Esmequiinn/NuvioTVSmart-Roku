function Cloud_On() as boolean
    integ = St_Integrations()
    return Bool_Of(integ.cloudOn, true) and Cloud_Connected(integ).Count() > 0
end function

sub Cloud_LibraryRow(root as object)
    if not Cloud_On() then return
    row = root.createChild("ContentNode")
    row.title = L("Biblioteca en la nube")
    names = []
    for each acc in Cloud_Connected(St_Integrations())
        names.Push(acc.name)
    end for
    Content_Item(row, {
        title: L("Tu nube")
        poster: "pkg:/images/cloud_library.png"
        kind: "folder"
        metaId: "cloud:all"
        metaLine: names.Join("  ·  ")
        description: L("Explora y reproduce lo que ya tienes en tus cuentas conectadas.")
    })
end sub

function Cloud_IsItem(item as dynamic) as boolean
    if item = invalid or not item.hasField("metaId") then return false
    return Left(Str_Of(item.metaId), 6) = "cloud:"
end function

sub Cloud_Open()
    if m.cloudFilter = invalid then m.cloudFilter = { provider: "", type: "", query: "" }
    Cloud_Run({ mode: "list" }, L("Abriendo tu nube..."))
end sub

sub Cloud_Run(params as object, busyText as string)
    showBusy(busyText)
    m.cloudTask = CreateObject("roSGNode", "CloudTask")
    m.cloudTask.params = params
    m.cloudTask.observeField("result", "onCloudDone")
    m.cloudTask.control = "RUN"
end sub

sub onCloudDone(event as object)
    task = event.getRoSGNode()
    if m.cloudTask = invalid or not task.isSameNode(m.cloudTask) then return
    m.cloudTask = invalid
    hideBusy()
    r = task.result
    if r = invalid then r = {}
    if not Bool_Of(r.ok, false)
        showMessage(L("Biblioteca en la nube"), Str_Of(r.error))
        return
    end if
    mode = Str_Of(r.mode)
    if mode = "list"
        m.cloud = { items: r.items, providers: r.providers, errors: r.errors }
        if m.stack.Count() > 0 and m.stack.Peek().id = "cloud"
            renderMenu(m.stack.Peek().focus)
        else
            openMenu("cloud", {})
        end if
    else if mode = "files"
        index = ToInt(r.index, -1)
        if m.cloud = invalid or index < 0 or index >= m.cloud.items.Count() then return
        m.cloud.items[index].files = r.files
        Cloud_PickItem(index)
    end if
end sub

function Cloud_TypeName(kind as string) as string
    if kind = "torrent" then return L("Torrents")
    if kind = "usenet" then return L("Usenet")
    if kind = "web" then return L("Web")
    if kind = "files" then return L("Archivos")
    return L("Todos")
end function

function Cloud_ProviderName(id as string) as string
    if id = "" then return L("Todos")
    return Deb_Name(id)
end function

function Cloud_Visible() as object
    out = []
    f = m.cloudFilter
    q = LCase(Str_Of(f.query).Trim())
    i = 0
    for each it in m.cloud.items
        ok = true
        if f.provider <> "" and Str_Of(it.provider) <> f.provider then ok = false
        if f.type <> "" and Str_Of(it.type) <> f.type then ok = false
        if ok and q <> "" and Instr(1, LCase(Str_Of(it.name)), q) = 0 then ok = false
        if ok then out.Push(i)
        i = i + 1
    end for
    return out
end function

function Cloud_Playable(it as object) as integer
    if type(it.files) = "roArray" then return it.files.Count()
    return -1
end function

function Cloud_Meta(it as object) as string
    parts = [Deb_Name(Str_Of(it.provider)), Cloud_TypeName(Str_Of(it.type))]
    status = Str_Of(it.status)
    if status = "" then status = L("Listo para reproducir")
    parts.Push(status)
    size = Cloud_Size(it.size)
    if size <> "" then parts.Push(size)
    return parts.Join("  •  ")
end function

function Cloud_FileLine(it as object) as string
    n = Cloud_Playable(it)
    if n = 0 then return L("Sin archivos reproducibles")
    if n = 1 then return L("1 archivo reproducible")
    if n > 1 then return L("{n} archivos reproducibles").Replace("{n}", n.ToStr())
    return ""
end function

function Cloud_Menu(id as string, data as object) as object
    if m.cloud = invalid then return goneMenu()
    if id = "cloud"
        menu = menuOf(L("Biblioteca en la nube"), L("Explora y reproduce lo que ya tienes en tus cuentas conectadas."))
        f = m.cloudFilter
        addEntry(menu, L("Proveedor") + ":  " + Cloud_ProviderName(f.provider), L("Elige de qué cuenta ver los archivos."), { act: "cloudProvider" })
        addEntry(menu, L("Tipo") + ":  " + Cloud_TypeName(f.type), L("Torrents, Usenet, descargas web o archivos."), { act: "cloudType" })
        query = Str_Of(f.query)
        searchLabel = L("Buscar en la nube")
        if query <> "" then searchLabel = searchLabel + ":  " + query
        addEntry(menu, searchLabel, L("Filtra por nombre lo que ya está cargado."), { act: "cloudSearch" })
        addEntry(menu, L("Actualizar biblioteca en la nube"), L("Vuelve a leer tus cuentas."), { act: "cloudRefresh" })
        for each err in m.cloud.errors
            addEntry(menu, Str_Of(err), "", { act: "cloudRefresh" })
        end for
        visible = Cloud_Visible()
        if visible.Count() = 0
            addEntry(menu, L("Aún no hay nada aquí"), L("No hay archivos reproducibles que coincidan con los filtros."), { act: "noop" })
            return menu
        end if
        for each i in visible
            it = m.cloud.items[i]
            detail = Cloud_FileLine(it)
            if detail <> "" then detail = detail + chr(10)
            addEntry(menu, Str_Of(it.name), detail + Cloud_Meta(it), { act: "cloudItem", index: i })
        end for
        return menu
    end if
    index = ToInt(data.index, -1)
    if index < 0 or index >= m.cloud.items.Count() then return goneMenu()
    it = m.cloud.items[index]
    menu = menuOf(L("Elige un archivo para reproducir"), Str_Of(it.name))
    j = 0
    for each f in it.files
        detail = Cloud_Size(f.size)
        spot = Cloud_Spot(Cloud_VideoId(it, f))
        if spot > 0 then detail = detail + "  ·  " + L("Continuar desde") + " " + Cloud_Clock(spot)
        addEntry(menu, Str_Of(f.name), detail, { act: "cloudPlay", index: index, file: j })
        j = j + 1
    end for
    return menu
end function

function Cloud_Action(act as string, a as object) as boolean
    if act = "cloudItem"
        index = ToInt(a.index, -1)
        if m.cloud = invalid or index < 0 or index >= m.cloud.items.Count() then return true
        it = m.cloud.items[index]
        if type(it.files) = "roArray"
            Cloud_PickItem(index)
        else
            Cloud_Run({ mode: "files", provider: Str_Of(it.provider), item: it, index: index }, L("Leyendo archivos..."))
        end if
        return true
    end if
    if act = "cloudPlay"
        Cloud_Play(ToInt(a.index, -1), ToInt(a.file, -1), false)
        return true
    end if
    if act = "cloudRefresh"
        Cloud_Open()
        return true
    end if
    if act = "cloudProvider"
        options = [""]
        for each p in m.cloud.providers
            options.Push(p.id)
        end for
        m.cloudFilter.provider = Cloud_Cycle(options, m.cloudFilter.provider)
        refreshMenu()
        return true
    end if
    if act = "cloudType"
        m.cloudFilter.type = Cloud_Cycle(["", "torrent", "usenet", "web", "files"], m.cloudFilter.type)
        refreshMenu()
        return true
    end if
    if act = "cloudSearch"
        showKeyboard("cloudSearch", L("Buscar en la nube"), Str_Of(m.cloudFilter.query), {})
        return true
    end if
    return false
end function

function Cloud_Keyboard(kind as string, text as string) as boolean
    if kind <> "cloudSearch" then return false
    if m.cloudFilter <> invalid then m.cloudFilter.query = text.Trim()
    refreshMenu()
    return true
end function

function Cloud_Cycle(options as object, current as string) as string
    for i = 0 to options.Count() - 1
        if options[i] = current then return options[(i + 1) mod options.Count()]
    end for
    return options[0]
end function

sub Cloud_PickItem(index as integer)
    it = m.cloud.items[index]
    if type(it.files) <> "roArray" or it.files.Count() = 0
        showMessage(L("Sin archivos reproducibles"), L("Este elemento no tiene un video que se pueda reproducir."))
        return
    end if
    if it.files.Count() = 1
        Cloud_Play(index, 0, false)
        return
    end if
    openMenu("cloudFiles", { index: index })
end sub

function Cloud_VideoId(it as object, f as object) as string
    return "cloud:" + Str_Of(it.provider) + ":" + Str_Of(it.type) + ":" + Str_Of(it.id) + ":" + Str_Of(f.id)
end function

function Cloud_Spot(videoId as string) as integer
    spots = St_Get("cloudSpots", {})
    if type(spots) <> "roAssociativeArray" then return 0
    e = spots[videoId]
    if type(e) <> "roAssociativeArray" then return 0
    return ToInt(e.p, 0)
end function

sub Cloud_SaveSpot(videoId as string, position as integer, total as integer)
    spots = St_Get("cloudSpots", {})
    if type(spots) <> "roAssociativeArray" then spots = {}
    if position < 10 or (total > 0 and position > total * 0.95)
        if not spots.DoesExist(videoId) then return
        spots.Delete(videoId)
    else
        spots[videoId] = { p: position, d: total, t: CreateObject("roDateTime").AsSeconds() }
    end if
    if spots.Count() > 200
        oldest = ""
        best = 0
        for each k in spots
            if oldest = "" or ToInt(spots[k].t, 0) < best
                oldest = k
                best = ToInt(spots[k].t, 0)
            end if
        end for
        spots.Delete(oldest)
    end if
    St_Set("cloudSpots", spots)
end sub

function Cloud_Clock(seconds as integer) as string
    h = Int(seconds / 3600)
    mm = Int((seconds mod 3600) / 60)
    ss = seconds mod 60
    if h > 0 then return h.ToStr() + ":" + Cloud_Pad(mm) + ":" + Cloud_Pad(ss)
    return mm.ToStr() + ":" + Cloud_Pad(ss)
end function

function Cloud_Pad(n as integer) as string
    if n < 10 then return "0" + n.ToStr()
    return n.ToStr()
end function

function Cloud_NextInfo() as object
    c = m.ctx.cloudAt
    if c = invalid or m.cloud = invalid then return {}
    it = m.cloud.items[c.index]
    if it = invalid or type(it.files) <> "roArray" or c.file + 1 >= it.files.Count() then return {}
    nxt = it.files[c.file + 1]
    return { code: L("Archivo") + " " + (c.file + 2).ToStr(), title: Str_Of(nxt.name), thumb: "" }
end function

function Cloud_Next() as boolean
    c = m.ctx.cloudAt
    if c = invalid or Cloud_NextInfo().Count() = 0 then return false
    saveProgress()
    Cloud_Play(c.index, c.file + 1, true)
    return true
end function

sub Cloud_Play(index as integer, fileIndex as integer, fromStart as boolean)
    if m.cloud = invalid or index < 0 or index >= m.cloud.items.Count() then return
    it = m.cloud.items[index]
    if type(it.files) <> "roArray" or fileIndex < 0 or fileIndex >= it.files.Count() then return
    f = it.files[fileIndex]
    provider = Str_Of(it.provider)
    title = Str_Of(f.name)
    videoId = Cloud_VideoId(it, f)
    line = Deb_Name(provider)
    if it.files.Count() > 1 then line = line + "  ·  " + L("Archivo") + " " + (fileIndex + 1).ToStr() + "/" + it.files.Count().ToStr()
    m.ctx = {
        kind: "movie"
        metaId: "cloud:" + provider + ":" + Str_Of(it.id)
        videoId: videoId
        videoIds: []
        title: title
        poster: ""
        background: ""
        logo: ""
        description: Str_Of(it.name)
        rating: ""
        metaLine: line
        episodeLabel: ""
        fromStart: fromStart
        imdb: ""
        meta: invalid
        metaReady: true
        seasons: []
        subs: []
        pool: []
        bingePrefer: ""
        originalLang: ""
        nextAuto: false
        cloud: true
        cloudAt: { index: index, file: fileIndex }
        direct: true
        streams: [{ url: "", name: Deb_Name(provider), desc: title, addon: Deb_Name(provider), filename: title, headers: [], debrid: { cloud: provider, item: { id: Str_Of(it.id), kind: Str_Of(it.kind), param: Str_Of(it.param) }, file: { id: Str_Of(f.id), name: title } } }]
    }
    m.list.visible = false
    startAt = 0
    if not fromStart then startAt = Cloud_Spot(videoId)
    playStream(0, startAt)
end sub
