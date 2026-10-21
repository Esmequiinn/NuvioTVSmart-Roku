sub openMenu(id as string, data as object)
    m.stack.Push({ id: id, data: data, focus: 0 })
    renderMenu(0)
end sub

sub renderMenu(focus as dynamic)
    if m.stack.Count() = 0 then return
    top = m.stack.Peek()
    cfg = buildMenu(top.id, top.data)
    top.cfg = cfg
    index = ToInt(focus, 0)
    if index >= cfg.items.Count() then index = cfg.items.Count() - 1
    if index < 0 then index = 0
    top.focus = index
    m.list.config = {
        title: cfg.title
        subtitle: Str_Of(cfg.subtitle)
        items: cfg.items
        details: cfg.details
        poster: Str_Of(cfg.poster)
        backdrop: Str_Of(cfg.backdrop)
        focus: index
    }
    if not m.player.visible
        m.list.visible = true
        if m.top.dialog = invalid then m.list.setFocus(true)
    end if
end sub

sub closeMenu()
    m.stack.Pop()
    if m.stack.Count() > 0
        renderMenu(m.stack.Peek().focus)
    else
        m.list.visible = false
        if m.settingsOpen
            refreshSettings()
            focusCurrent()
            return
        end if
        if m.needsReload and not m.detailsOpen
            m.area = "page"
            showPage("home")
            return
        end if
        focusCurrent()
    end if
end sub

sub goHome()
    m.stack.Clear()
    m.list.visible = false
    m.settingsOpen = false
    m.settings.visible = false
    closeDetails(false)
    m.area = "page"
    showPage("home")
end sub

sub onListBack()
    if m.busy
        cancelBusy()
        return
    end if
    if m.stack.Count() > 0
        if m.stack.Peek().id = "login"
            cancelLogin()
            return
        end if
    end if
    closeMenu()
end sub

sub onListSelected()
    if m.busy or m.stack.Count() = 0 then return
    top = m.stack.Peek()
    index = m.list.selected
    top.focus = index
    if top.cfg = invalid or index < 0 or index >= top.cfg.actions.Count() then return
    runAction(top.cfg.actions[index])
end sub

function menuOf(title as string, subtitle as string) as object
    return { title: title, subtitle: subtitle, items: [], details: [], actions: [], poster: "", backdrop: "" }
end function

sub addEntry(menu as object, label as string, detail as string, action as object)
    menu.items.Push(label)
    menu.details.Push(detail)
    menu.actions.Push(action)
end sub

function goneMenu() as object
    menu = menuOf(L("Ya no existe"), L("Este elemento cambió mientras estaba abierto."))
    addEntry(menu, L("Volver"), "", { act: "back" })
    return menu
end function

function buildMenu(id as string, data as object) as object
    if id = "settings" then return menuSettings()
    if id = "phone" then return menuPhone()
    if id = "addons" then return menuAddons()
    if id = "addon" then return menuAddon(data)
    if id = "catalogs" then return menuCatalogs()
    if id = "catalog" then return menuCatalog(data)
    if id = "profiles" then return menuProfiles()
    if id = "profile" then return menuProfile(data)
    if id = "appearance" then return menuAppearance()
    if id = "about" then return menuAbout()
    if id = "seasons" then return menuSeasons()
    if id = "episodes" then return menuEpisodes(data)
    if id = "streams" then return menuStreams()
    if id = "login" then return menuLogin()
    return goneMenu()
end function

function addonName(base as string) as string
    for each entry in m.manifests
        if entry.base = base then return entry.name
    end for
    re = CreateObject("roRegex", "^https?://([^/]+)", "i")
    found = re.Match(base)
    if found.Count() > 1 then return found[1]
    return base
end function

function menuSettings() as object
    addons = St_Addons()
    menu = menuOf(L("Ajustes"), L("Perfil: ") + St_ActiveProfile().name)
    addEntry(menu, L("Cambiar de perfil"), "", { act: "switchProfile" })
    addEntry(menu, L("Configurar desde el celular"), L("Agrega addons, colecciones, perfiles y catálogos desde el navegador de tu celular o computadora."), { go: "phone" })
    addEntry(menu, L("Addons (") + addons.Count().ToStr() + ")", L("Agrega, ordena o elimina addons."), { go: "addons" })
    addEntry(menu, L("Catálogos (") + m.catalogs.Count().ToStr() + ")", L("Muestra, oculta y reordena las filas del inicio."), { go: "catalogs" })
    addEntry(menu, L("Perfiles"), L("Crea perfiles y elige si los addons se comparten entre ellos."), { go: "profiles" })
    addEntry(menu, L("Apariencia y reproducción"), L("Color, títulos por fila, Seguir viendo y subtítulos."), { go: "appearance" })
    addEntry(menu, L("Importar colección (.json)"), L("Escribe la dirección de un archivo .json con una lista de addons."), { act: "kbCollection" })
    addEntry(menu, L("Recargar catálogos"), L("Vuelve a pedir los catálogos a todos tus addons."), { act: "reload" })
    addEntry(menu, L("Acerca de"), "", { go: "about" })
    return menu
end function

function menuPhone() as object
    url = Net_ServerUrl()
    if url = ""
        menu = menuOf(L("Configura desde tu celular"), L("El Roku no tiene conexión de red en este momento."))
        addEntry(menu, L("Volver"), "", { act: "back" })
        return menu
    end if
    subtitle = L("Conecta tu celular o computadora al mismo wifi que el Roku y abre esta dirección en el navegador (o escanea el código):")
    menu = menuOf(L("Configura desde tu celular"), subtitle)
    menu.poster = Net_QrUri(url)
    addEntry(menu, url, L("Los cambios se aplican solos. Puedes dejar esta pantalla abierta mientras configuras."), { act: "home" })
    addEntry(menu, L("Ir al inicio"), "", { act: "home" })
    return menu
end function

function menuAddons() as object
    addons = St_Addons()
    scope = L("Compartidos entre todos los perfiles")
    if not St_Settings().shared then scope = L("Solo para el perfil ") + St_ActiveProfile().name
    menu = menuOf("Addons", addons.Count().ToStr() + L(" instalados  ·  ") + scope)
    for i = 0 to addons.Count() - 1
        addEntry(menu, (i + 1).ToStr() + ".  " + addonName(addons[i]), addons[i], { go: "addon", index: i })
    end for
    addEntry(menu, L("+  Agregar addon con el teclado"), L("Escribe la dirección del addon (con o sin /manifest.json)."), { act: "kbAddon" })
    addEntry(menu, L("+  Agregar desde el celular"), L("Más cómodo: pega la dirección desde tu celular."), { go: "phone" })
    return menu
end function

function menuAddon(data as object) as object
    addons = St_Addons()
    index = ToInt(data.index, -1)
    if index < 0 or index >= addons.Count() then return goneMenu()
    menu = menuOf(addonName(addons[index]), addons[index])
    addEntry(menu, L("Subir"), L("Los addons de arriba aparecen primero."), { act: "addonMove", delta: -1 })
    addEntry(menu, L("Bajar"), "", { act: "addonMove", delta: 1 })
    addEntry(menu, L("Eliminar"), L("Quita este addon y sus catálogos."), { act: "addonRemove" })
    return menu
end function

function menuCatalogs() as object
    menu = menuOf(L("Catálogos"), L("Elige un catálogo para mostrarlo, ocultarlo o moverlo."))
    if m.catalogs.Count() = 0
        menu.subtitle = L("No hay catálogos cargados. Agrega un addon con catálogos primero.")
        addEntry(menu, L("Volver"), "", { act: "back" })
        return menu
    end if
    for each c in m.catalogs
        label = c.name + "  ·  " + TypePlural(c.kind)
        if c.hidden then label = L("Oculto  —  ") + label
        detail = L("Addon: ") + c.addon
        status = Str_Of(c.status)
        if status = "ok"
            detail = detail + "  ·  " + ToInt(c.count, 0).ToStr() + L(" títulos")
        else if status <> ""
            detail = detail + L("  ·  Problema: ") + status
        end if
        addEntry(menu, label, detail, { go: "catalog", key: c.key })
    end for
    return menu
end function

function findCatalog(key as string) as dynamic
    for each c in m.catalogs
        if c.key = key then return c
    end for
    return invalid
end function

function menuCatalog(data as object) as object
    c = findCatalog(Str_Of(data.key))
    if c = invalid then return goneMenu()
    menu = menuOf(c.name + "  ·  " + TypePlural(c.kind), L("Addon: ") + c.addon)
    if c.hidden
        addEntry(menu, L("Mostrar en el inicio"), "", { act: "catToggle" })
    else
        addEntry(menu, L("Ocultar del inicio"), "", { act: "catToggle" })
    end if
    addEntry(menu, L("Subir"), "", { act: "catMove", delta: -1 })
    addEntry(menu, L("Bajar"), "", { act: "catMove", delta: 1 })
    return menu
end function

function menuProfiles() as object
    profiles = St_Profiles()
    active = St_ActiveProfile()
    menu = menuOf(L("Perfiles"), L("Cada perfil tiene su propio Seguir viendo, color y orden de catálogos."))
    for each p in profiles
        label = p.name
        if p.id = active.id then label = label + L("   (en uso)")
        addEntry(menu, label, "", { go: "profile", id: p.id })
    end for
    addEntry(menu, L("+  Nuevo perfil"), "", { act: "kbNewProfile" })
    if St_Settings().shared
        addEntry(menu, L("Addons: compartidos entre perfiles"), L("Todos los perfiles usan la misma lista de addons. Selecciona para separarlos."), { act: "toggleShared" })
    else
        addEntry(menu, L("Addons: separados por perfil"), L("Cada perfil tiene su propia lista de addons. Selecciona para compartirlos."), { act: "toggleShared" })
    end if
    return menu
end function

function menuProfile(data as object) as object
    profiles = St_Profiles()
    idx = St_ProfileIndex(profiles, Str_Of(data.id))
    if idx < 0 then return goneMenu()
    p = profiles[idx]
    menu = menuOf(p.name, "")
    addEntry(menu, L("Usar este perfil"), "", { act: "useProfile", id: p.id })
    addEntry(menu, L("Cambiar nombre"), "", { act: "kbRenameProfile" })
    addEntry(menu, L("Eliminar perfil"), L("Borra su historial y preferencias."), { act: "deleteProfile" })
    return menu
end function

function menuAppearance() as object
    prefs = St_Prefs()
    menu = menuOf(L("Apariencia y reproducción"), L("Perfil: ") + St_ActiveProfile().name)
    addEntry(menu, L("Color: ") + St_ColorName(prefs.accent), L("Selecciona para cambiar de color."), { act: "cycleColor" })
    addEntry(menu, L("Títulos por fila: ") + prefs.rowSize.ToStr(), L("Menos títulos hace que el inicio cargue más rápido."), { act: "cycleRowSize" })
    cwLabel = L("Seguir viendo: activado")
    if not prefs.continueWatching then cwLabel = L("Seguir viendo: desactivado")
    addEntry(menu, cwLabel, "", { act: "toggleCW" })
    ccLabel = L("Subtítulos: desactivados")
    if prefs.captions then ccLabel = L("Subtítulos: activados")
    addEntry(menu, ccLabel, L("Usa los subtítulos incluidos en el video cuando existen."), { act: "toggleCaptions" })
    addEntry(menu, L("Borrar historial de Seguir viendo"), "", { act: "clearHistory" })
    return menu
end function

function menuAbout() as object
    info = L("Fork no oficial de Nuvio para Roku, hecho con permiso de los desarrolladores de Nuvio. No es una app oficial de Nuvio.") + chr(10) + L("Versión 2.2.0  ·  Basado en Nuvio (licencia GPL-3.0)")
    menu = menuOf(L("Nuvio TV para Roku"), info)
    addEntry(menu, L("Volver"), "", { act: "back" })
    return menu
end function

function menuSeasons() as object
    menu = menuOf(m.ctx.title, m.ctx.description)
    menu.poster = m.ctx.poster
    menu.backdrop = m.ctx.background
    seasons = m.ctx.seasons
    for i = 0 to seasons.Count() - 1
        addEntry(menu, seasons[i].label, seasons[i].episodes.Count().ToStr() + L(" episodios"), { go: "episodes", season: i })
    end for
    return menu
end function

function menuEpisodes(data as object) as object
    seasons = m.ctx.seasons
    idx = ToInt(data.season, 0)
    if seasons = invalid or idx < 0 or idx >= seasons.Count() then return goneMenu()
    season = seasons[idx]
    menu = menuOf(m.ctx.title, season.label)
    menu.poster = m.ctx.poster
    menu.backdrop = m.ctx.background
    resumeId = ""
    for each e in St_Progress()
        if e.metaId = m.ctx.metaId then resumeId = e.videoId
    end for
    for each v in season.episodes
        num = ToInt(v.episode, -1)
        label = episodeTitle(v)
        if num >= 0 then label = num.ToStr() + ".  " + label
        if label = "" then label = v.id
        if v.id = resumeId then label = label + L("   (en curso)")
        detail = Str_OneLine(v.overview)
        if detail = "" then detail = Str_OneLine(v.description)
        released = Left(Str_Of(v.released), 10)
        if released <> "" then detail = released + "   " + detail
        addEntry(menu, label, detail, { act: "pickEpisode", season: idx, video: v.id })
    end for
    return menu
end function

function menuStreams() as object
    title = m.ctx.title
    if m.ctx.episodeLabel <> "" then title = title + "  ·  " + m.ctx.episodeLabel
    streams = m.ctx.streams
    menu = menuOf(title, streams.Count().ToStr() + L(" enlaces encontrados"))
    menu.poster = m.ctx.poster
    menu.backdrop = m.ctx.background
    resume = St_ResumeFor(m.ctx.videoId)
    if resume > 0
        if m.ctx.fromStart
            addEntry(menu, L("Empezar desde el principio  (cambiar)"), L("Selecciona para continuar desde ") + Fmt_Time(resume) + ".", { act: "toggleStart" })
        else
            addEntry(menu, L("Continuar desde ") + Fmt_Time(resume) + L("  (cambiar)"), L("Selecciona para empezar desde el principio."), { act: "toggleStart" })
        end if
    end if
    for i = 0 to streams.Count() - 1
        addEntry(menu, streams[i].label, streams[i].detail, { act: "play", index: i })
    end for
    return menu
end function

sub refreshMenu()
    if m.stack.Count() > 0 then renderMenu(m.stack.Peek().focus)
end sub

sub runAction(a as object)
    if IsStr(a.go)
        openMenu(a.go, a)
        return
    end if
    act = Str_Of(a.act)
    top = m.stack.Peek()
    data = top.data

    if act = "noop"
        return
    else if act = "cancelLogin"
        cancelLogin()
    else if act = "back"
        closeMenu()
    else if act = "home"
        goHome()
    else if act = "reload"
        m.needsReload = true
        goHome()
    else if act = "kbAddon"
        showKeyboard("addon", L("Dirección del addon"), "https://", {})
    else if act = "switchProfile"
        m.stack.Clear()
        m.list.visible = false
        showProfiles()
    else if act = "kbCollection"
        showKeyboard("collection", L("Dirección del .json de la colección"), "https://", {})
    else if act = "kbNewProfile"
        showKeyboard("newProfile", L("Nombre del perfil"), "", {})
    else if act = "kbRenameProfile"
        profiles = St_Profiles()
        idx = St_ProfileIndex(profiles, Str_Of(data.id))
        if idx >= 0 then showKeyboard("renameProfile", L("Nuevo nombre"), profiles[idx].name, { id: data.id })
    else if act = "addonMove"
        data.index = St_MoveAddon(ToInt(data.index, -1), ToInt(a.delta, 0))
        m.needsReload = true
        refreshMenu()
    else if act = "addonRemove"
        St_RemoveAddon(ToInt(data.index, -1))
        m.needsReload = true
        closeMenu()
    else if act = "catToggle"
        c = findCatalog(Str_Of(data.key))
        if c <> invalid
            St_SetCatalogHidden(m.catalogs, c.key, not c.hidden)
            m.server.catalogs = m.catalogs
            m.needsReload = true
        end if
        refreshMenu()
    else if act = "catMove"
        if St_MoveCatalog(m.catalogs, Str_Of(data.key), ToInt(a.delta, 0))
            m.server.catalogs = m.catalogs
            m.needsReload = true
        end if
        refreshMenu()
    else if act = "useProfile"
        St_SetActiveProfile(Str_Of(a.id))
        m.needsReload = true
        applyTheme()
        goHome()
    else if act = "deleteProfile"
        if St_DeleteProfile(Str_Of(data.id))
            m.needsReload = true
            closeMenu()
        else
            showMessage(L("No se puede eliminar"), L("Debe quedar al menos un perfil."))
        end if
    else if act = "toggleShared"
        St_SetShared(not St_Settings().shared)
        m.needsReload = true
        refreshMenu()
    else if act = "cycleColor"
        colors = St_Colors()
        current = 0
        for i = 0 to colors.Count() - 1
            if colors[i].hex = UCase(m.prefs.accent) then current = i
        end for
        St_SetAccent(colors[(current + 1) mod colors.Count()].hex)
        applyTheme()
        refreshMenu()
    else if act = "cycleRowSize"
        sizes = St_RowSizes()
        current = 0
        for i = 0 to sizes.Count() - 1
            if sizes[i] = m.prefs.rowSize then current = i
        end for
        St_SetRowSize(sizes[(current + 1) mod sizes.Count()])
        applyTheme()
        m.needsReload = true
        refreshMenu()
    else if act = "toggleCW"
        St_SetFlag("continueWatching", not m.prefs.continueWatching)
        applyTheme()
        refreshMenu()
    else if act = "toggleCaptions"
        St_SetFlag("captions", not m.prefs.captions)
        applyTheme()
        refreshMenu()
    else if act = "clearHistory"
        St_ClearProgress()
        showMessage(L("Listo"), L("Se borró el historial de Seguir viendo de este perfil."))
    else if act = "pickEpisode"
        season = m.ctx.seasons[ToInt(a.season, 0)]
        for each v in season.episodes
            if v.id = Str_Of(a.video) then pickEpisodeVideo(season, v)
        end for
    else if act = "toggleStart"
        m.ctx.fromStart = not m.ctx.fromStart
        refreshMenu()
    else if act = "play"
        playStream(ToInt(a.index, -1), 0)
    end if
end sub

sub handleKeyboard(kind as string, text as string, data as object)
    if kind = "regex"
        if text <> "" and CreateObject("roRegex", text, "i") = invalid
            showMessage(L("Patrón no válido"), L("Revisa el patrón regex. Ejemplo: 4K|2160p|Remux"))
            return
        end if
        St_SetPref("autoplayRegex", text)
        if text <> "" then St_SetPref("autoplayMode", "regex")
        refreshSettings()
        return
    end if
    if kind = "customPoster"
        St_SetPref("customPoster", text)
        m.needsReload = true
        refreshSettings()
        return
    end if
    if kind = "pickerProfile"
        if St_AddProfile(text) = invalid
            showMessage(L("No se creó"), L("El máximo es de 8 perfiles."))
        end if
        showProfiles()
    else if kind = "addon"
        if St_AddAddon(text)
            m.needsReload = true
            refreshMenu()
        else
            showMessage(L("No se agregó"), L("La dirección no es válida o ese addon ya está en la lista."))
        end if
    else if kind = "collection"
        startImport(text)
    else if kind = "newProfile"
        if St_AddProfile(text) = invalid
            showMessage(L("No se creó"), L("Escribe un nombre. El máximo es de 8 perfiles."))
        else
            refreshMenu()
            refreshSettings()
        end if
    else if kind = "renameProfile"
        St_RenameProfile(Str_Of(data.id), text)
        applyTheme()
        refreshMenu()
    end if
end sub
