sub init()
    m.top.backgroundColor = "0x0C0C0FFF"
    m.top.backgroundUri = ""
    m.hero = m.top.findNode("hero")
    m.homePage = m.top.findNode("homePage")
    m.homeRows = m.top.findNode("homeRows")
    m.emptyState = m.top.findNode("emptyState")
    m.emptyTitle = m.top.findNode("emptyTitle")
    m.emptyBody = m.top.findNode("emptyBody")
    m.emptyQr = m.top.findNode("emptyQr")
    m.searchPage = m.top.findNode("searchPage")
    m.searchText = m.top.findNode("searchText")
    m.searchStatus = m.top.findNode("searchStatus")
    m.searchRows = m.top.findNode("searchRows")
    m.libraryPage = m.top.findNode("libraryPage")
    m.libraryRows = m.top.findNode("libraryRows")
    m.libraryEmpty = m.top.findNode("libraryEmpty")
    m.nav = m.top.findNode("nav")
    m.details = m.top.findNode("details")
    m.list = m.top.findNode("list")
    m.settings = m.top.findNode("settings")
    m.loginTimer = m.top.findNode("loginTimer")
    m.settingsOpen = false
    m.login = invalid
    m.loginPoll = invalid
    m.accountTask = invalid
    m.profiles = m.top.findNode("profiles")
    m.player = m.top.findNode("player")
    m.playerVideo = m.player.video
    m.loading = m.top.findNode("loading")
    m.loadingText = m.top.findNode("loadingText")
    m.loadingHint = m.top.findNode("loadingHint")
    m.heroTimer = m.top.findNode("heroTimer")
    m.expanded = m.top.findNode("expanded")
    m.expandTimer = m.top.findNode("expandTimer")
    m.autoTimer = m.top.findNode("autoTimer")
    m.streamsScreen = m.top.findNode("streamsScreen")
    m.trailerPlayer = m.top.findNode("trailerPlayer")
    m.streamsOpen = false
    m.trailerOpen = false
    m.trailerTask = invalid
    m.cardTask = invalid
    m.cardItem = invalid
    m.searchTimer = m.top.findNode("searchTimer")
    m.top.findNode("searchHeading").font.size = 56
    L_Texts(["searchHeading", "searchHint", "searchStatus", "libraryEmpty", "loadingHint"])

    m.stack = []
    m.manifests = []
    m.catalogs = []
    m.ctx = {}
    m.metaCache = {}
    m.metaCacheCount = 0
    m.page = "home"
    m.area = "page"
    m.detailsOpen = false
    m.homeLoaded = false
    m.needsReload = false
    m.busy = false
    m.lastSaved = 0
    m.kbKind = ""
    m.kbData = {}
    m.lastQuery = ""
    m.heroItem = invalid
    m.heroTask = invalid
    m.catalogTask = invalid
    m.metaTask = invalid
    m.streamTask = invalid
    m.subtitleTask = invalid
    m.importTask = invalid
    m.searchTask = invalid
    m.autoPlay = false
    m.searchFocus = "keyboard"
    m.searchRoot = CreateObject("roSGNode", "ContentNode")

    m.global.addFields({ accent: "0x7C4DFFFF" })
    m.global.addField("focusCard", "node", true)
    m.global.addFields({ expandShift: 0.0, expandIndex: -1, syncDirty: 0 })
    m.global.observeField("syncDirty", "onSyncDirty")
    m.pushTimer = m.top.createChild("Timer")
    m.pushTimer.duration = 8
    m.pushTimer.observeField("fire", "onPushTimer")
    m.global.addField("expandRow", "node", false)
    m.global.observeField("focusCard", "onFocusCard")
    m.expandTimer.observeField("fire", "onExpandTimer")
    m.autoTimer.observeField("fire", "onAutoTimer")
    m.streamsScreen.observeField("event", "onStreamsEvent")
    m.trailerPlayer.observeField("event", "onTrailerEvent")
    for each rows in [m.homeRows, m.searchRows, m.libraryRows]
        rows.rowLabelFont.size = 32
        rows.observeField("rowItemSelected", "onRowSelected")
        rows.observeField("rowItemFocused", "onRowFocused")
    end for

    m.keyboard = CreateObject("roSGNode", "MiniKeyboard")
    if m.keyboard = invalid then m.keyboard = CreateObject("roSGNode", "Keyboard")
    m.top.findNode("keyboardHolder").appendChild(m.keyboard)
    m.keyboard.observeField("text", "onSearchText")
    m.searchTimer.observeField("fire", "onSearchTimer")
    m.heroTimer.observeField("fire", "onHeroTimer")

    m.nav.observeField("chosen", "onNavChosen")
    m.nav.observeField("leave", "onNavLeave")
    m.details.observeField("selected", "onDetailsSelected")
    m.details.observeField("back", "onDetailsBack")
    m.list.observeField("selected", "onListSelected")
    m.list.observeField("back", "onListBack")
    m.profiles.observeField("selected", "onProfileChosen")
    m.settings.observeField("event", "onSettingsEvent")
    m.settings.observeField("back", "onSettingsBack")
    m.loginTimer.observeField("fire", "onLoginTimer")
    m.player.observeField("event", "onPlayerEvent")
    m.playerVideo.observeField("position", "onPlayerPosition")
    m.playerVideo.observeField("state", "onPlayerVideoState")
    m.scrobbleState = ""

    startServer()

    applyTheme()
    showProfiles()
    startQuietSync()
end sub

sub onSyncDirty()
    if St_Integrations().nuvioAccess = "" then return
    m.pushTimer.control = "stop"
    m.pushTimer.control = "start"
end sub

sub onPushTimer()
    if m.accountTask <> invalid or m.pushTask <> invalid
        m.pushTimer.control = "start"
        return
    end if
    m.pushTask = CreateObject("roSGNode", "AccountTask")
    m.pushTask.mode = "nuvioPush"
    m.pushTask.observeField("result", "onPushDone")
    m.pushTask.control = "RUN"
end sub

sub onPushDone()
    m.pushTask = invalid
end sub

sub startServer()
    m.server = CreateObject("roSGNode", "ServerTask")
    m.server.observeField("changed", "onServerChanged")
    m.server.observeField("state", "onServerState")
    if m.serverNames <> invalid then m.server.addonNames = m.serverNames
    if m.catalogs <> invalid then m.server.catalogs = m.catalogs
    m.server.control = "RUN"
end sub

sub onServerState()
    if m.server = invalid then return
    st = m.server.state
    if st = "stop" or st = "done"
        m.server.unobserveField("changed")
        m.server.unobserveField("state")
        m.server = invalid
        if m.serverRestarts = invalid then m.serverRestarts = 0
        if m.serverRestarts < 20
            m.serverRestarts = m.serverRestarts + 1
            startServer()
        end if
    end if
end sub

sub applyTheme()
    m.prefs = St_Prefs()
    m.accent = "0x" + m.prefs.accent + "FF"
    m.global.accent = m.accent
    m.list.accent = m.accent
    m.settings.accent = m.accent
    m.details.accent = m.accent
    m.player.accent = m.accent
    m.nav.accent = m.accent
    m.streamsScreen.accent = m.accent
    m.ui = {
        expandOn: Bool_Of(St_Pref("expandPoster"), true)
        expandDelay: ToInt(St_Pref("expandDelay"), 3)
        expandTrailer: Bool_Of(St_Pref("expandTrailer"), false)
        expandMuted: Bool_Of(St_Pref("expandMuted"), true)
        trailerTarget: Str_Of(St_Pref("trailerTarget"))
    }
    if m.ui.expandDelay < 1 then m.ui.expandDelay = 1
    profile = St_ActiveProfile()
    m.nav.profileName = profile.name
    m.nav.profileColor = St_ProfileColor(St_ActiveProfileIndex())
    m.nav.profileAvatar = Str_Of(profile.avatar)
    if m.prefs.captions
        m.playerVideo.globalCaptionMode = "On"
    else
        m.playerVideo.globalCaptionMode = "Off"
    end if
end sub

sub showProfiles()
    list = []
    profiles = St_Profiles()
    for i = 0 to profiles.Count() - 1
        list.Push({ id: profiles[i].id, name: profiles[i].name, color: St_ProfileColor(i), avatar: Str_Of(profiles[i].avatar) })
    end for
    m.profiles.profiles = list
    m.profiles.visible = true
    m.profiles.setFocus(true)
end sub

sub onProfileChosen()
    pid = m.profiles.selected
    if pid = "__add"
        showKeyboard("pickerProfile", L("Nombre del perfil"), "", {})
        return
    end if
    changed = St_Settings().active <> pid or not m.homeLoaded
    St_SetActiveProfile(pid)
    m.profiles.visible = false
    applyTheme()
    if changed
        m.needsReload = true
        m.stack.Clear()
        m.list.visible = false
        closeDetails(false)
        showPage("home")
        loadHome()
    else
        focusCurrent()
    end if
end sub

sub loadHome()
    applyTheme()
    m.homeLoaded = true
    m.needsReload = false
    m.emptyState.visible = false
    m.homeRows.visible = false
    m.hero.visible = false
    m.loadingText.text = L("Cargando catálogos...")
    m.loadingHint.visible = false
    m.loading.visible = true
    if m.catalogTask <> invalid
        m.catalogTask.unobserveField("content")
        m.catalogTask.control = "STOP"
    end if
    m.catalogTask = CreateObject("roSGNode", "CatalogTask")
    m.catalogTask.observeField("content", "onCatalogsLoaded")
    m.catalogTask.control = "RUN"
    if m.page = "home" and m.area = "page" and not overlayOpen() then m.top.setFocus(true)
end sub

sub onCatalogsLoaded(event as object)
    task = event.getRoSGNode()
    if m.catalogTask = invalid or not task.isSameNode(m.catalogTask) then return
    m.manifests = task.manifests
    m.catalogs = task.catalogs
    if m.manifests = invalid then m.manifests = []
    if m.catalogs = invalid then m.catalogs = []
    names = {}
    for each entry in m.manifests
        names[entry.base] = entry.name
    end for
    m.serverNames = names
    if m.server <> invalid
        m.server.addonNames = names
        m.server.catalogs = m.catalogs
    end if
    if not m.busy then m.loading.visible = false
    content = task.content
    m.homeRows.content = content
    applyRowSizes(m.homeRows)
    if content <> invalid and content.getChildCount() > 0
        m.emptyState.visible = false
        m.homeRows.visible = true
        if m.page = "home"
            m.hero.visible = true
            showHeroFor(getRowItem(m.homeRows, [0, 0]))
        end if
    else
        m.homeRows.visible = false
        m.hero.visible = false
        showEmptyState(task.addonCount, task.failed)
    end if
    if m.page = "library" then buildLibrary()
    if m.area = "page" and not overlayOpen() then focusPage()
end sub

sub showEmptyState(addonCount as integer, failed as integer)
    url = Net_ServerUrl()
    if addonCount = 0
        m.emptyTitle.text = L("Aún no tienes addons")
        body = L("Conecta tu celular al mismo wifi que el Roku, abre el navegador y entra a:") + chr(10) + url + chr(10) + chr(10)
        body = body + L("Desde ahí puedes agregar addons, importar colecciones y configurar todo.")
    else if failed >= addonCount
        m.emptyTitle.text = L("No se pudo conectar con tus addons")
        body = L("Ninguno de tus ") + addonCount.ToStr() + L(" addons respondió. Revisa que el Roku tenga internet y que las direcciones sean correctas.") + chr(10) + chr(10)
        body = body + L("Configuración desde el celular: ") + url
    else
        problems = []
        for each c in m.catalogs
            status = Str_Of(c.status)
            if status <> "" and status <> "ok" and problems.Count() < 4 then problems.Push(c.name + " (" + TypePlural(c.kind) + "): " + status)
        end for
        if problems.Count() > 0
            m.emptyTitle.text = L("Tus catálogos no cargaron")
            body = problems.Join(chr(10)) + chr(10) + chr(10)
        else
            m.emptyTitle.text = L("Tus addons no tienen catálogos visibles")
            body = L("Puede que todos los catálogos estén ocultos o que tus addons solo den enlaces. Agrega un addon de catálogos o revisa Ajustes > Catálogos.") + chr(10) + chr(10)
        end if
        body = body + L("Configuración desde el celular: ") + url
    end if
    m.emptyBody.text = body
    if url <> "" then m.emptyQr.uri = Net_QrUri(url)
    m.emptyState.visible = true
end sub

function overlayOpen() as boolean
    return m.player.visible or m.trailerOpen or m.profiles.visible or m.streamsOpen or m.stack.Count() > 0 or m.detailsOpen or m.settingsOpen
end function

sub focusCurrent()
    if m.top.dialog <> invalid then return
    if m.trailerOpen
        m.trailerPlayer.setFocus(true)
    else if m.player.visible
        m.player.setFocus(true)
    else if m.streamsOpen
        m.streamsScreen.setFocus(true)
    else if m.profiles.visible
        m.profiles.setFocus(true)
    else if m.stack.Count() > 0
        m.list.setFocus(true)
    else if m.settingsOpen
        m.settings.setFocus(true)
    else if m.detailsOpen
        m.details.setFocus(true)
    else if m.area = "nav"
        m.nav.setFocus(true)
    else
        focusPage()
    end if
end sub

sub focusNav()
    hideExpanded()
    m.area = "nav"
    m.nav.setFocus(true)
end sub

sub onNavLeave()
    m.area = "page"
    focusPage()
end sub

sub onNavChosen()
    choice = m.nav.chosen
    if choice = "profile"
        showProfiles()
    else if choice = "settings"
        openSettings()
    else
        m.area = "page"
        showPage(choice)
    end if
end sub

function getRowItem(rows as object, cell as dynamic) as dynamic
    if type(cell) <> "roArray" or cell.Count() < 2 then return invalid
    root = rows.content
    if root = invalid then return invalid
    row = root.getChild(cell[0])
    if row = invalid then return invalid
    return row.getChild(cell[1])
end function

sub onRowFocused(event as object)
    hideExpanded()
    rows = event.getRoSGNode()
    if rows.isSameNode(m.searchRows) then return
    showHeroFor(getRowItem(rows, rows.rowItemFocused))
end sub

sub onRowSelected(event as object)
    if m.busy then return
    rows = event.getRoSGNode()
    item = getRowItem(rows, rows.rowItemSelected)
    if item = invalid then return
    if item.itemType = "folder"
        openFolder(item)
        return
    end if
    openDetails(item)
end sub

sub openFolder(item as object)
    if not item.hasField("folder") then return
    hideExpanded()
    showBusy(L("Cargando..."))
    m.folderTitle = item.title
    task = CreateObject("roSGNode", "CatalogTask")
    task.baseManifests = m.manifests
    task.folder = item.folder
    task.observeField("content", "onFolderLoaded")
    task.control = "RUN"
    m.folderTask = task
end sub

sub onFolderLoaded(event as object)
    task = event.getRoSGNode()
    if m.folderTask = invalid or not task.isSameNode(m.folderTask) then return
    m.folderTask = invalid
    hideBusy()
    root = task.content
    if root = invalid or root.getChildCount() = 0
        showMessage(m.folderTitle, L("Esta carpeta no tiene catálogos de tus addons instalados."))
        return
    end if
    m.libraryRows.content = root
    applyRowSizes(m.libraryRows)
    m.area = "page"
    showPage("folder")
end sub

sub showHeroFor(item as dynamic)
    if item = invalid then return
    if item.itemType = "folder"
        m.heroItem = item
        m.heroTimer.control = "stop"
        m.hero.data = { title: item.title, logo: "", background: item.background, rating: "", metaLine: item.metaLine, description: "" }
        return
    end if
    if Bool_Of(m.heroTrailerOn, false)
        if m.cardItem = invalid or not m.cardItem.isSameNode(item)
            m.heroTrailerOn = false
            m.hero.trailer = {}
        end if
    end if
    m.heroItem = item
    m.hero.data = heroData(item, m.metaCache[item.metaId])
    m.heroTimer.control = "stop"
    if m.metaCache[item.metaId] = invalid then m.heroTimer.control = "start"
end sub

function heroData(item as object, meta as dynamic) as object
    logo = item.logo
    background = item.background
    if background = "" then background = item.HDPosterUrl
    rating = item.rating
    metaLine = item.metaLine
    description = item.description
    title = item.title
    if Left(item.metaId, 2) = "tt" and logo = "" then logo = Img_Logo(item.metaId)
    if meta <> invalid
        if Str_Of(meta.logo) <> "" then logo = meta.logo
        if item.background = "" and Str_Of(meta.background) <> "" then background = meta.background
        if rating = "" then rating = Str_Of(meta.imdbRating)
        if description = "" or item.videoId <> "" then description = Str_OneLine(meta.description)
        if title = "" then title = Str_Of(meta.name)
        line = Meta_Line(item.itemType, meta)
        if item.videoId = "" and Len(line) > Len(metaLine) then metaLine = line
    end if
    if item.videoId <> "" and item.episodeLabel <> "" then metaLine = item.metaLine
    if item.hasField("badge") and item.badge <> "" then metaLine = Cw_HeroLine(item, meta)
    return { title: title, logo: logo, background: background, rating: rating, metaLine: metaLine, description: description }
end function

function Cw_HeroLine(item as object, meta as dynamic) as string
    parts = []
    episode = [item.kicker, item.subtitle]
    if item.subtitle = "" then episode = [item.kicker]
    first = episode.Join("  ·  ").Trim()
    if item.kicker = "" then first = TypeLabel(item.itemType)
    parts.Push(first)
    if meta <> invalid
        if type(meta.genres) = "roArray" and meta.genres.Count() > 0 and IsStr(meta.genres[0]) then parts.Push(meta.genres[0])
        year = Str_Of(meta.releaseInfo)
        if Len(year) >= 4 then parts.Push(Left(year, 4))
    end if
    parts.Push(UCase(item.badge))
    return parts.Join("  ·  ")
end function

function Meta_Line(kind as string, meta as object) as string
    parts = [TypeLabel(kind)]
    year = Str_Of(meta.releaseInfo)
    if year <> "" then parts.Push(year)
    if type(meta.genres) = "roArray" and meta.genres.Count() > 0 then parts.Push(meta.genres.Join(", "))
    runtime = Str_Of(meta.runtime)
    if runtime <> "" then parts.Push(runtime)
    return parts.Join("  ·  ")
end function

sub onHeroTimer()
    item = m.heroItem
    if item = invalid or m.manifests.Count() = 0 then return
    if item.itemType = "folder" then return
    if m.metaCache[item.metaId] <> invalid then return
    m.heroTask = CreateObject("roSGNode", "MetaTask")
    m.heroTask.manifests = m.manifests
    m.heroTask.kind = item.itemType
    m.heroTask.metaId = item.metaId
    m.heroTask.observeField("meta", "onHeroMeta")
    m.heroTask.control = "RUN"
end sub

sub onHeroMeta(event as object)
    task = event.getRoSGNode()
    meta = task.meta
    if meta = invalid then return
    cacheMeta(task.metaId, meta)
    if m.heroItem <> invalid and m.heroItem.metaId = task.metaId
        m.hero.data = heroData(m.heroItem, meta)
    end if
end sub

sub cacheMeta(id as string, meta as object)
    if m.metaCacheCount > 80
        m.metaCache = {}
        m.metaCacheCount = 0
    end if
    if m.metaCache[id] = invalid then m.metaCacheCount = m.metaCacheCount + 1
    m.metaCache[id] = meta
end sub

sub showBusy(text as string)
    m.busy = true
    m.loadingText.text = text
    m.loadingHint.visible = true
    m.loading.visible = true
end sub

sub hideBusy()
    m.busy = false
    m.loading.visible = false
end sub

sub cancelBusy()
    m.folderTask = invalid
    m.metaTask = invalid
    m.streamTask = invalid
    m.importTask = invalid
    m.autoPlay = false
    m.autoTimer.control = "stop"
    if m.ctx <> invalid and m.ctx.DoesExist("decided") then m.ctx.decided = true
    if m.player.visible and m.playerVideo.state <> "playing" and m.playerVideo.state <> "paused"
        hideBusy()
        closePlayer(false)
        return
    end if
    m.searchFocus = "keyboard"
    m.searchRoot = CreateObject("roSGNode", "ContentNode")
    hideBusy()
    focusCurrent()
end sub

sub onExternalInput()
    info = m.top.externalInput
    if info = invalid then return
    if not St_AddAddon(info.addon_url) then return
    reloadWhenIdle()
end sub

sub reloadWhenIdle()
    if not overlayOpen() and not m.busy
        loadHome()
    else
        m.needsReload = true
        if m.stack.Count() > 0 and not m.player.visible then renderMenu(m.stack.Peek().focus)
    end if
end sub

sub onServerChanged()
    what = m.server.changed
    if what = "search"
        if m.player.visible then return
        m.stack.Clear()
        m.list.visible = false
        closeDetails(false)
        m.profiles.visible = false
        m.area = "page"
        showPage("search")
        m.keyboard.text = m.server.searchQuery
        runSearch(m.server.searchQuery)
        m.searchFocus = "results"
        return
    end if
    if what = "nuvioLogin"
        if not m.player.visible then startNuvioSync()
        return
    end if
    if what = "theme"
        applyTheme()
        refreshSettings()
        if m.stack.Count() > 0 and not m.player.visible then renderMenu(m.stack.Peek().focus)
        return
    end if
    reloadWhenIdle()
end sub

sub showKeyboard(kind as string, title as string, text as string, data as object)
    m.kbKind = kind
    m.kbData = data
    dlg = CreateObject("roSGNode", "KeyboardDialog")
    dlg.title = title
    dlg.buttons = [L("Aceptar"), L("Cancelar")]
    dlg.observeFieldScoped("buttonSelected", "onKeyboardButton")
    dlg.observeFieldScoped("wasClosed", "onDialogClosed")
    m.top.dialog = dlg
    dlg.text = text
    dlg.keyboard.textEditBox.maxTextLength = 600
    dlg.keyboard.textEditBox.cursorPosition = Len(text)
end sub

sub onKeyboardButton()
    dlg = m.top.dialog
    if dlg = invalid then return
    choice = dlg.buttonSelected
    text = dlg.text.Trim()
    dlg.close = true
    if choice <> 0 then return
    if text = "" and m.kbKind <> "regex" and m.kbKind <> "customPoster" then return
    handleKeyboard(m.kbKind, text, m.kbData)
end sub

sub showMessage(title as string, text as string)
    dlg = CreateObject("roSGNode", "Dialog")
    dlg.title = title
    dlg.message = text
    dlg.buttons = ["OK"]
    dlg.observeFieldScoped("buttonSelected", "onMessageButton")
    dlg.observeFieldScoped("wasClosed", "onDialogClosed")
    m.top.dialog = dlg
end sub

sub onMessageButton()
    if m.top.dialog <> invalid then m.top.dialog.close = true
    if Bool_Of(m.exitAfterDialog, false) then m.top.exitApp = true
end sub

sub onDialogClosed(event as object)
    closed = event.getRoSGNode()
    current = m.top.dialog
    if current <> invalid and not current.isSameNode(closed) then return
    m.top.dialog = invalid
    focusCurrent()
end sub

sub startImport(source as string)
    showBusy(L("Importando colección..."))
    m.importTask = CreateObject("roSGNode", "ImportTask")
    m.importTask.source = source
    m.importTask.observeField("added", "onImportDone")
    m.importTask.control = "RUN"
end sub

sub onImportDone(event as object)
    task = event.getRoSGNode()
    if m.importTask = invalid or not task.isSameNode(m.importTask) then return
    m.importTask = invalid
    hideBusy()
    added = task.added
    if added > 0
        m.needsReload = true
        if m.stack.Count() > 0 then renderMenu(m.stack.Peek().focus)
        countText = added.ToStr() + " addons"
        if added = 1 then countText = "1 addon"
        showMessage(L("Colección importada"), L("Se agregó ") + countText + L(". Los catálogos se recargan al volver al inicio."))
    else
        showMessage(L("Sin cambios"), L("No se encontraron addons nuevos en esa colección. Revisa que la dirección del .json sea correcta."))
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if m.busy
        if key = "back" then cancelBusy()
        return true
    end if
    if overlayOpen() then return false
    if m.area = "nav"
        if key = "back" and m.page <> "home"
            m.area = "page"
            showPage("home")
            return true
        end if
        return false
    end if
    if key = "options"
        openSettings()
        return true
    end if
    if m.page = "search" then return searchKey(key)
    if m.page = "folder" and key = "back"
        m.area = "page"
        showPage("home")
        return true
    end if
    if key = "left" or key = "back"
        focusNav()
        return true
    end if
    return false
end function

function activeRows() as dynamic
    if m.page = "home" then return m.homeRows
    if m.page = "library" or m.page = "folder" then return m.libraryRows
    if m.page = "search" then return m.searchRows
    return invalid
end function

sub onFocusCard()
    hideExpanded()
    if m.ui = invalid then return
    if not m.ui.expandOn and not m.ui.expandTrailer then return
    m.expandTimer.duration = m.ui.expandDelay
    m.expandTimer.control = "start"
end sub

sub hideExpanded()
    m.expandTimer.control = "stop"
    m.cardTask = invalid
    m.cardItem = invalid
    if Bool_Of(m.heroTrailerOn, false)
        m.heroTrailerOn = false
        m.hero.trailer = {}
    end if
    if m.expanded.open then m.expanded.open = false
    if m.expandRows <> invalid
        m.expandRows.focusBitmapBlendColor = "0xFFFFFFFF"
        m.expandRows = invalid
    end if
end sub

sub onExpandTimer()
    card = m.global.focusCard
    if card = invalid or m.busy or m.area <> "page" or overlayOpen() then return
    if not card.itemHasFocus then return
    rows = activeRows()
    if rows = invalid or not rows.isInFocusChain() then return
    item = card.itemContent
    if item = invalid then return
    if item.itemType = "folder" then return
    focus = rows.rowItemFocused
    if type(focus) = "roArray" and focus.Count() > 0 and rows.content <> invalid
        row = rows.content.getChild(focus[0])
        if row <> invalid and row.id = "cw" then return
    end if
    meta = m.metaCache[item.metaId]
    m.cardItem = item
    m.trailerToHero = m.ui.trailerTarget <> "card" or not m.ui.expandOn
    if m.ui.expandOn then openExpanded(rows, item, meta)
    if m.ui.expandTrailer then startCardTrailer(item, meta)
end sub

sub openExpanded(rows as object, item as object, meta as dynamic)
    rect = Rows_FocusRect(rows)
    if rect = invalid then return
    h = rect.h
    toW = Int(rect.w * 2.66)
    x = rect.x
    if x + toW > 1880 then x = 1880 - toW
    hd = heroData(item, meta)
    background = hd.background
    if background = "" and Left(item.metaId, 2) = "tt" then background = Img_Background(item.metaId)
    parent = item.getParent()
    m.global.expandRow = parent
    idx = -1
    if item.hasField("idx")
        idx = item.idx
    else if parent <> invalid
        for i = 0 to parent.getChildCount() - 1
            if parent.getChild(i).isSameNode(item) then idx = i
        end for
    end if
    m.global.expandIndex = idx
    m.expanded.data = { x: x, y: rect.y, h: h, fromW: rect.w, toW: toW, background: background, logo: hd.logo, title: hd.title }
    m.expanded.open = true
    m.expandRows = rows
    rows.focusBitmapBlendColor = "0xFFFFFF00"
end sub

function Rows_FocusRect(rows as object) as dynamic
    focus = rows.rowItemFocused
    if type(focus) <> "roArray" or focus.Count() < 2 then return invalid
    row = focus[0]
    size = Arr_At(rows.rowItemSize, row)
    if type(size) <> "roArray" or size.Count() < 2 then return invalid
    offset = Arr_At(rows.rowLabelOffset, row)
    gap = 0
    if type(offset) = "roArray" and offset.Count() > 1 then gap = offset[1]
    shift = Arr_At(rows.focusXOffset, row)
    if shift = invalid then shift = 0
    x = 0
    y = 0
    node = rows
    while node <> invalid
        t = node.translation
        if type(t) = "roArray" and t.Count() > 1
            x = x + t[0]
            y = y + t[1]
        end if
        node = node.getParent()
    end while
    return { x: x + shift, y: y + Rows_LabelHeight(rows) + gap, w: size[0], h: size[1] }
end function

function Arr_At(list as dynamic, index as integer) as dynamic
    if type(list) <> "roArray" or list.Count() = 0 then return invalid
    if index >= list.Count() then index = list.Count() - 1
    if index < 0 then index = 0
    return list[index]
end function

function Rows_LabelHeight(rows as object) as integer
    if m.rowLabelH <> invalid then return m.rowLabelH
    h = 36
    probe = CreateObject("roSGNode", "Label")
    if rows.rowLabelFont <> invalid then probe.font = rows.rowLabelFont
    probe.text = "Ág"
    r = probe.boundingRect()
    if r <> invalid and r.height > 10 and r.height < 90 then h = Int(r.height)
    m.rowLabelH = h
    return h
end function

sub startCardTrailer(item as object, meta as dynamic)
    imdb = ""
    if Left(item.metaId, 2) = "tt" then imdb = item.metaId.Split(":")[0]
    task = CreateObject("roSGNode", "TrailerTask")
    if meta <> invalid
        if Str_Of(meta.imdb) <> "" then imdb = meta.imdb
        task.localYt = meta.trailerLocal
        task.ytIds = meta.trailerYt
        task.urls = meta.trailerUrls
    end if
    if imdb = "" and meta = invalid then return
    task.imdb = imdb
    task.tag = item.metaId
    task.observeField("result", "onCardTrailer")
    task.control = "RUN"
    m.cardTask = task
end sub

sub onCardTrailer(event as object)
    task = event.getRoSGNode()
    if m.cardTask = invalid or not task.isSameNode(m.cardTask) then return
    m.cardTask = invalid
    r = task.result
    if r = invalid or Str_Of(r.url) = "" or m.cardItem = invalid then return
    if m.cardItem.metaId <> task.tag then return
    if m.trailerToHero
        if m.busy or m.area <> "page" or overlayOpen() then return
        m.heroTrailerOn = true
        m.hero.muted = m.ui.expandMuted
        m.hero.trailer = r
        return
    end if
    if not m.expanded.open then return
    m.expanded.muted = m.ui.expandMuted
    m.expanded.trailer = r
end sub
