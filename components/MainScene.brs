sub init()
    St_Migrate()
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
    m.skeleton = m.top.findNode("skeleton")
    m.spinner = m.top.findNode("spinner")
    m.spinner.poster.uri = "pkg:/images/spinner.png"
    m.spinner.poster.width = 96
    m.spinner.poster.height = 96
    m.skeleton.observeField("visible", "onSkeletonVisible")
    m.loadingText = m.top.findNode("loadingText")
    m.loadingHint = m.top.findNode("loadingHint")
    m.heroTimer = m.top.findNode("heroTimer")
    m.expanded = m.top.findNode("expanded")
    m.expandTimer = m.top.findNode("expandTimer")
    m.autoTimer = m.top.findNode("autoTimer")
    m.subsWait = m.top.findNode("subsWait")
    m.streamsScreen = m.top.findNode("streamsScreen")
    m.trailerPlayer = m.top.findNode("trailerPlayer")
    m.sheet = m.top.findNode("sheet")
    m.auth = m.top.findNode("auth")
    m.auth.observeField("event", "onAuthEvent")
    m.partyJoin = m.top.findNode("partyJoin")
    m.partyJoin.observeField("event", "onPartyJoinEvent")
    m.partyPanel = m.top.findNode("partyPanel")
    m.partyPanel.observeField("event", "onPartyPanelEvent")
    m.trackAuth = m.top.findNode("trackAuth")
    m.trackAuth.observeField("event", "onTrackAuthEvent")
    m.toast = m.top.findNode("toast")
    m.sheet.observeField("chosen", "onSheetChosen")
    m.sheet.observeField("closed", "onSheetClosed")
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
    m.global.addFields({ expandShift: 0.0, expandIndex: -1, syncDirty: 0, corners: "auto" })
    Mask_Global()
    m.global.observeField("syncDirty", "onSyncDirty")
    m.pushTimer = m.top.createChild("Timer")
    m.pushTimer.duration = 8
    m.pushTimer.observeField("fire", "onPushTimer")
    m.global.addField("expandRow", "node", false)
    m.global.observeField("focusCard", "onFocusCard")
    m.expandTimer.observeField("fire", "onExpandTimer")
    m.autoTimer.observeField("fire", "onAutoTimer")
    m.subsWait.observeField("fire", "onSubsWait")
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
    m.settings.observeField("leave", "onSettingsLeave")
    m.loginTimer.observeField("fire", "onLoginTimer")
    m.player.observeField("event", "onPlayerEvent")
    m.playerVideo.observeField("position", "onPlayerPosition")
    m.playerVideo.observeField("state", "onPlayerVideoState")
    m.scrobbleState = ""

    startServer()

    applyTheme()
    if Auth_ShouldGate()
        Auth_Open("onboarding")
    else
        showProfiles()
    end if
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
    m.nav.profileName = Str_Glyphs(Str_Of(profile.name))
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
        m.homeRows.content = invalid
        m.homeRows.visible = false
        m.area = "page"
        showPage("home")
        if not m.homeRows.isInFocusChain() and not overlayOpen() then Focus_Scene()
        startQuietSync()
    else
        focusCurrent()
    end if
end sub

sub loadHome()
    applyTheme()
    m.homeLoaded = true
    m.needsReload = false
    m.emptyState.visible = false
    m.loadingHint.visible = false
    hasRows = m.homeRows.content <> invalid and m.homeRows.content.getChildCount() > 0 and m.homeRows.visible
    if not hasRows
        m.homeRows.visible = false
        m.hero.visible = false
        m.skeleton.visible = m.page = "home"
    end if
    if m.catalogTask <> invalid
        m.catalogTask.unobserveField("content")
        m.catalogTask.unobserveField("early")
        m.catalogTask.control = "STOP"
    end if
    m.catalogTask = CreateObject("roSGNode", "CatalogTask")
    m.catalogTask.observeField("early", "onCatalogsEarly")
    m.catalogTask.observeField("content", "onCatalogsLoaded")
    m.catalogTask.control = "RUN"
    if m.page = "home" and m.area = "page" and not overlayOpen()
        if hasRows
            m.hero.visible = true
            showHeroFor(getRowItem(m.homeRows, m.homeRows.rowItemFocused))
            focusPage()
        else
            Focus_Scene()
        end if
    end if
end sub

sub onSkeletonVisible()
    anim = m.top.findNode("skeletonPulse")
    if m.skeleton.visible then anim.control = "start" else anim.control = "stop"
end sub

sub Home_TakeTask(task as object)
    manifests = task.manifests
    catalogs = task.catalogs
    if manifests = invalid or manifests.Count() = 0 then return
    m.manifests = manifests
    if catalogs <> invalid then m.catalogs = catalogs
    names = {}
    for each entry in m.manifests
        names[entry.base] = entry.name
    end for
    m.serverNames = names
    if m.server <> invalid
        m.server.addonNames = names
        m.server.catalogs = m.catalogs
    end if
end sub

sub onCatalogsEarly(event as object)
    task = event.getRoSGNode()
    if m.catalogTask = invalid or not task.isSameNode(m.catalogTask) then return
    Home_TakeTask(task)
    content = task.early
    if content = invalid or content.getChildCount() = 0 then return
    Home_Show(content)
end sub

sub onCatalogsLoaded(event as object)
    task = event.getRoSGNode()
    if m.catalogTask = invalid or not task.isSameNode(m.catalogTask) then return
    Home_TakeTask(task)
    if task.manifests = invalid or task.manifests.Count() = 0
        m.manifests = []
        m.catalogs = []
    end if
    content = task.content
    m.skeleton.visible = false
    if content <> invalid and content.getChildCount() > 0
        Home_Show(content)
        Poster_Cache(m.homeRows.content)
    else
        m.homeRows.content = content
        m.homeRows.visible = false
        m.hero.visible = false
        showEmptyState(task.addonCount, task.failed)
    end if
    if m.page = "library" then buildLibrary()
end sub

function Home_RowKey(row as object) as string
    if row = invalid then return ""
    if row.id = "cw" then return "cw"
    if row.hasField("key") then return row.key
    return row.title
end function

function Home_RowSig(row as object) as string
    if row = invalid then return ""
    n = row.getChildCount()
    parts = [n.ToStr(), row.title]
    for i = 0 to n - 1
        if i > 5 then exit for
        c = row.getChild(i)
        if c.hasField("remote") then parts.Push(c.remote) else parts.Push(c.HDPosterUrl)
    end for
    return parts.Join("|")
end function

sub Poster_Localize(root as object)
    if root = invalid or m.posterMap = invalid then return
    for i = 0 to root.getChildCount() - 1
        row = root.getChild(i)
        for j = 0 to row.getChildCount() - 1
            item = row.getChild(j)
            local = m.posterMap[item.HDPosterUrl]
            if local <> invalid
                if not item.hasField("remote") then item.addFields({ remote: item.HDPosterUrl }) else item.remote = item.HDPosterUrl
                item.HDPosterUrl = local
            end if
        end for
    end for
end sub

sub Poster_Cache(root as object)
    if root = invalid then return
    urls = []
    for i = 0 to root.getChildCount() - 1
        row = root.getChild(i)
        for j = 0 to row.getChildCount() - 1
            if j >= 12 then exit for
            u = row.getChild(j).HDPosterUrl
            if Left(u, 4) = "http" then urls.Push(u)
        end for
    end for
    if urls.Count() = 0 then return
    Poster_Stop()
    m.posterTask = CreateObject("roSGNode", "PosterCacheTask")
    m.posterTask.urls = urls
    m.posterTask.observeField("result", "onPosterCache")
    m.posterTask.control = "RUN"
end sub

sub Poster_Stop()
    if m.posterTask = invalid then return
    m.posterTask.unobserveField("result")
    m.posterTask.cancel = true
    m.posterTask = invalid
end sub

sub onPosterCache(event as object)
    task = event.getRoSGNode()
    if m.posterTask = invalid or not task.isSameNode(m.posterTask) then return
    m.posterTask = invalid
    found = task.result
    if type(found) <> "roAssociativeArray" then return
    if m.posterMap = invalid then m.posterMap = {}
    for each k in found
        m.posterMap[k] = found[k]
    end for
end sub

sub Home_Show(content as object)
    Poster_Localize(content)
    m.skeleton.visible = false
    m.emptyState.visible = false
    old = m.homeRows.content
    focused = m.homeRows.isInFocusChain()
    engaged = old <> invalid and old.getChildCount() > 0 and m.homeRows.visible
    if not engaged
        m.homeRows.content = content
        applyRowSizes(m.homeRows)
        m.homeRows.visible = true
        if m.page = "home"
            m.hero.visible = true
            showHeroFor(getRowItem(m.homeRows, [0, 0]))
        end if
        if m.area = "page" and not overlayOpen() then focusPage()
        return
    end if
    oldKeys = []
    for i = 0 to old.getChildCount() - 1
        oldKeys.Push(Home_RowKey(old.getChild(i)))
    end for
    newRows = []
    for i = 0 to content.getChildCount() - 1
        newRows.Push(content.getChild(i))
    end for
    prefix = oldKeys.Count() <= newRows.Count()
    if prefix
        for i = 0 to oldKeys.Count() - 1
            if oldKeys[i] <> Home_RowKey(newRows[i]) then prefix = false
        end for
    end if
    focus = m.homeRows.rowItemFocused
    focusKey = ""
    if type(focus) = "roArray" and focus.Count() > 0 and focus[0] < oldKeys.Count() then focusKey = oldKeys[focus[0]]
    if prefix
        for i = oldKeys.Count() to newRows.Count() - 1
            old.appendChild(newRows[i])
        end for
        focusRow = -1
        if type(focus) = "roArray" and focus.Count() > 0 and focused then focusRow = focus[0]
        for i = 0 to oldKeys.Count() - 1
            if i <> focusRow and Home_RowSig(old.getChild(i)) <> Home_RowSig(newRows[i]) then old.replaceChild(newRows[i], i)
        end for
        applyRowSizes(m.homeRows)
        Home_Refocus()
        return
    end if
    m.homeRows.content = content
    applyRowSizes(m.homeRows)
    target = 0
    for i = 0 to newRows.Count() - 1
        if Home_RowKey(newRows[i]) = focusKey then target = i
    end for
    m.homeRows.jumpToRowItem = [target, 0]
    if focused then m.homeRows.setFocus(true)
    Home_Refocus()
end sub

sub Home_Refocus()
    if m.page <> "home" or m.area <> "page" or overlayOpen() or m.settingsOpen then return
    if m.homeRows.isInFocusChain() then return
    focusPage()
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
    return m.sheet.visible or m.auth.visible or m.trackAuth.visible or m.partyPanel.visible or m.partyJoin.visible or m.player.visible or m.trailerOpen or m.profiles.visible or m.streamsOpen or m.stack.Count() > 0 or m.detailsOpen or m.settingsOpen
end function

sub focusCurrent()
    if m.top.dialog <> invalid then return
    if m.sheet.visible
        m.sheet.setFocus(true)
    else if m.auth.visible
        m.auth.setFocus(true)
    else if m.trackAuth.visible
        m.trackAuth.setFocus(true)
    else if m.partyPanel.visible
        m.partyPanel.setFocus(true)
    else if m.partyJoin.visible
        m.partyJoin.setFocus(true)
    else if m.trailerOpen
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
    else if m.detailsOpen and not m.details.visible and m.ctx <> invalid and Bool_Of(m.ctx.direct, false)
        closeDetails(true)
    else if m.detailsOpen
        m.details.setFocus(true)
    else if m.area = "nav"
        m.nav.setFocus(true)
    else
        focusPage()
    end if
end sub

sub Toast_Show(text as string)
    m.toast.text = text
end sub

sub focusNav()
    hideExpanded()
    m.area = "nav"
    m.nav.setFocus(true)
end sub

sub onNavLeave()
    if m.settingsOpen
        m.settings.setFocus(true)
        return
    end if
    m.area = "page"
    focusPage()
end sub

sub onSettingsLeave()
    m.nav.setFocus(true)
end sub

sub onNavChosen()
    choice = m.nav.chosen
    if m.settingsOpen and choice <> "settings"
        m.settingsOpen = false
        m.settings.visible = false
    end if
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
    focus = rows.rowItemSelected
    row = invalid
    if type(focus) = "roArray" and rows.content <> invalid then row = rows.content.getChild(focus[0])
    if row <> invalid and row.id = "cw"
        Continue_Play(item, "play")
        return
    end if
    openDetails(item)
end sub

sub Continue_Play(item as object, action as string)
    openDetails(item)
    m.details.visible = false
    m.ctx.direct = true
    runDetailAction(action)
end sub

sub openFolder(item as object)
    if not item.hasField("folder") then return
    Folder_Load(item.title, item.folder)
end sub

sub Folder_Load(title as string, folder as object)
    hideExpanded()
    showBusy(L("Cargando..."))
    m.folderTitle = title
    task = CreateObject("roSGNode", "CatalogTask")
    task.baseManifests = m.manifests
    task.folder = folder
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
    fails = task.folderFails
    detail = ""
    if type(fails) = "roArray" and fails.Count() > 0 then detail = fails.Join(chr(10))
    if root = invalid or root.getChildCount() = 0
        text = L("Esta carpeta no tiene catálogos de tus addons instalados.")
        if detail <> "" then text = L("No se pudo cargar:") + chr(10) + detail
        showMessage(m.folderTitle, text)
        return
    end if
    if detail <> "" then Toast_Show(L("No se pudo cargar:") + " " + fails.Join(", "))
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
        hide = item.hasField("hideTitle") and item.hideTitle = true
        title = item.title
        line = item.metaLine
        if hide
            title = ""
            line = ""
        end if
        logo = ""
        if item.hasField("logo") then logo = item.logo
        m.hero.data = { title: title, logo: logo, background: item.background, rating: "", metaLine: line, description: "" }
        video = ""
        if item.hasField("heroVideo") then video = item.heroVideo
        hasGif = item.hasField("gif") and item.gif <> ""
        if video <> "" and not hasGif and m.page = "home"
            m.heroTrailerOn = true
            m.hero.trailer = { url: video }
        else if Bool_Of(m.heroTrailerOn, false)
            m.heroTrailerOn = false
            m.hero.trailer = {}
        end if
        return
    end if
    if Bool_Of(m.heroTrailerOn, false)
        if m.cardItem = invalid or not m.cardItem.isSameNode(item)
            m.heroTrailerOn = false
            m.hero.trailer = {}
        end if
    end if
    m.heroItem = item
    cached = m.metaCache[item.metaId]
    d = heroData(item, cached)
    if cached = invalid
        if m.logoCache = invalid then m.logoCache = {}
        quick = m.logoCache[item.metaId]
        if quick <> invalid and quick <> ""
            d.logo = quick
        else if quick = invalid
            d.logoPending = true
            Logo_Start(item)
        end if
    end if
    m.hero.data = d
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
    if m.logoCache <> invalid and Str_Of(m.logoCache[item.metaId]) <> "" then logo = m.logoCache[item.metaId]
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
    if item = invalid or item.itemType = "folder" then return
    if m.metaCache[item.metaId] <> invalid then return
    if m.manifests.Count() = 0
        m.hero.data = heroData(item, invalid)
        return
    end if
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
    if meta = invalid
        if m.heroItem <> invalid and m.heroItem.metaId = task.metaId then m.hero.data = heroData(m.heroItem, invalid)
        return
    end if
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
    m.spinner.control = "start"
end sub

sub hideBusy()
    m.busy = false
    m.loading.visible = false
    m.spinner.control = "stop"
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
        if m.auth.visible
            Auth_Approved()
            return
        end if
        Toast_Show(L("Sesión iniciada. Sincronizando con Nuvio..."))
        m.syncToast = true
        startQuietSync()
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
    text = Kb_Text(dlg)
    dlg.close = true
    if choice <> 0 then return
    if text = "" and m.kbKind <> "regex" and m.kbKind <> "customPoster" and m.kbKind <> "integKey" then return
    handleKeyboard(m.kbKind, text, m.kbData)
end sub

sub showMessage(title as string, text as string)
    hideBusy()
    Sheet_Open({ title: title, subtitle: text, items: [{ id: "ok", label: L("Aceptar") }] }, "message", invalid)
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
    if key = "back" and m.profiles.visible and Bool_Of(m.homeLoaded, false)
        m.profiles.visible = false
        focusCurrent()
        return true
    end if
    if overlayOpen() then return false
    if m.area = "nav"
        if key = "back" and m.page <> "home"
            m.area = "page"
            showPage("home")
            return true
        end if
        if key = "options"
            openSettings()
            return true
        end if
        return false
    end if
    if key = "options"
        Options_Open()
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
    if m.ui = invalid or m.page = "library" or m.page = "search" then return
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
    if item.itemType = "folder" or m.page = "library" or m.page = "search" then return
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
    task.kind = Str_Of(item.itemType)
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

function Kb_Text(dlg as object) as string
    text = ""
    if dlg.hasField("text") then text = Str_Of(dlg.text)
    kb = invalid
    if dlg.hasField("keyboard") then kb = dlg.keyboard
    if text = "" and kb <> invalid
        if kb.hasField("text") then text = Str_Of(kb.text)
        if text = "" and kb.hasField("textEditBox") and kb.textEditBox <> invalid then text = Str_Of(kb.textEditBox.text)
    end if
    return text.Trim()
end function

sub Logo_Start(item as object)
    if m.logoTask <> invalid then m.logoTask.unobserveField("logo")
    m.logoTask = CreateObject("roSGNode", "LogoTask")
    m.logoTask.kind = item.itemType
    m.logoTask.metaId = item.metaId
    m.logoTask.observeField("logo", "onLogoFound")
    m.logoTask.control = "RUN"
end sub

sub onLogoFound(event as object)
    task = event.getRoSGNode()
    id = task.metaId
    logo = task.logo
    if m.logoCache = invalid then m.logoCache = {}
    if m.logoCache.Count() > 300 then m.logoCache = {}
    m.logoCache[id] = logo
    item = m.heroItem
    if item = invalid or item.metaId <> id or m.metaCache[id] <> invalid then return
    d = heroData(item, invalid)
    if logo <> "" then d.logo = logo
    m.hero.data = d
end sub
