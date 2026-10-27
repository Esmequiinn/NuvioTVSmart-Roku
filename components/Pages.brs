sub showPage(name as string)
    if name <> "home" then Poster_Stop()
    hideExpanded()
    m.page = name
    if name = "folder" then m.nav.active = "home" else m.nav.active = name
    m.homePage.visible = name = "home"
    m.searchPage.visible = name = "search"
    m.discoverPage.visible = name = "discover"
    m.libraryPage.visible = name = "library" or name = "folder"
    m.hero.visible = false
    if name = "home"
        if m.needsReload or not m.homeLoaded
            loadHome()
            return
        end if
        refreshContinueRow()
        if m.homeRows.visible
            m.hero.visible = true
            showHeroFor(getRowItem(m.homeRows, m.homeRows.rowItemFocused))
        end if
    else if name = "library"
        buildLibrary()
    else if name = "folder"
        m.libraryRows.visible = true
        m.libraryEmpty.visible = false
        m.hero.visible = true
        showHeroFor(getRowItem(m.libraryRows, [0, 0]))
    else if name = "search"
        m.searchFocus = "keyboard"
        Recent_Refresh()
    else if name = "discover"
        m.discFocus = "bar"
        Disc_Show()
    end if
    if m.area = "page" and not overlayOpen() then focusPage()
end sub

sub Focus_Scene()
    node = m.top.focusedChild
    deepest = invalid
    guard = 0
    while node <> invalid and guard < 30
        deepest = node
        if node.isSameNode(m.top) then exit while
        inner = node.focusedChild
        if inner = invalid or inner.isSameNode(node) then exit while
        node = inner
        guard = guard + 1
    end while
    if deepest <> invalid and not deepest.isSameNode(m.top) then deepest.setFocus(false)
    m.top.setFocus(true)
end sub

sub focusPage()
    if m.top.dialog <> invalid then return
    if m.page = "home"
        if m.homeRows.visible and m.homeRows.content <> invalid and m.homeRows.content.getChildCount() > 0
            m.homeRows.setFocus(true)
        else
            Focus_Scene()
        end if
    else if m.page = "discover"
        Disc_Focus()
    else if m.page = "search"
        if m.searchFocus = "results" and searchHasResults()
            m.searchRows.setFocus(true)
        else if m.searchFocus = "recent" and m.recent.visible
            m.recent.setFocus(true)
        else if m.searchFocus = "button" and m.discoverButton.visible
            m.discoverButton.setFocus(true)
            Disc_ButtonPaint(true)
        else
            m.searchFocus = "keyboard"
            m.keyboard.setFocus(true)
        end if
    else if m.page = "library" or m.page = "folder"
        if m.libraryRows.visible
            m.libraryRows.setFocus(true)
        else
            Focus_Scene()
        end if
    end if
end sub

sub applyRowSizes(rows as object)
    root = rows.content
    sizes = []
    heights = []
    if root <> invalid
        cwLandscape = St_Pref("cwStyle") <> "poster"
        for i = 0 to root.getChildCount() - 1
            row = root.getChild(i)
            shape = "poster"
            if row.hasField("shape") then shape = row.shape
            if row.id = "cw" and cwLandscape then shape = "card"
            if shape = "card"
                sizes.Push([400, 225])
                heights.Push(305)
            else if shape = "landscape"
                sizes.Push([356, 200])
                heights.Push(280)
            else if shape = "square"
                sizes.Push([240, 240])
                heights.Push(320)
            else
                sizes.Push([200, 300])
                heights.Push(380)
            end if
        end for
    end if
    if sizes.Count() = 0
        sizes.Push([200, 300])
        heights.Push(380)
    end if
    rows.rowItemSize = sizes
    rows.rowHeights = heights
end sub

sub refreshContinueRow()
    root = m.homeRows.content
    if root = invalid then return
    first = root.getChild(0)
    hasCw = first <> invalid and first.id = "cw"
    cw = Content_ContinueRow()
    if hasCw and cw = invalid
        root.removeChildIndex(0)
    else if hasCw
        root.replaceChild(cw, 0)
    else if cw <> invalid
        root.insertChild(cw, 0)
    end if
    applyRowSizes(m.homeRows)
    if root.getChildCount() > 0 and not m.emptyState.visible then m.homeRows.visible = true
end sub

sub buildLibrary()
    root = CreateObject("roSGNode", "ContentNode")
    saved = St_Library()
    if saved.Count() > 0
        row = root.createChild("ContentNode")
        row.title = L("Mi lista")
        pattern = Poster_Pattern("library")
        for each e in saved
            poster = Str_Of(e.poster)
            fallback = ""
            if pattern <> ""
                custom = Poster_Custom(pattern, Str_Of(e.id), "", Str_Of(e.kind))
                if custom <> ""
                    fallback = poster
                    poster = custom
                end if
            end if
            Content_Item(row, {
                fallback: fallback
                title: Str_Of(e.name)
                poster: poster
                description: ""
                kind: Str_Of(e.kind)
                metaId: e.id
                videoId: ""
                background: ""
                metaLine: TypeLabel(Str_Of(e.kind))
                episodeLabel: ""
                progress: 0.0
            })
        end for
    end if
    prev = m.libraryRows.rowItemFocused
    m.libraryRows.content = root
    applyRowSizes(m.libraryRows)
    if root.getChildCount() > 0
        col = 0
        if type(prev) = "roArray" and prev.Count() > 1 then col = prev[1]
        last = root.getChild(0).getChildCount() - 1
        if col > last then col = last
        if col < 0 then col = 0
        m.libraryRows.jumpToRowItem = [0, col]
    end if
    hasItems = root.getChildCount() > 0
    m.libraryRows.visible = hasItems
    m.libraryEmpty.visible = not hasItems
    m.hero.visible = hasItems
    if hasItems then showHeroFor(getRowItem(m.libraryRows, m.libraryRows.jumpToRowItem))
end sub

function searchHasResults() as boolean
    root = m.searchRows.content
    return root <> invalid and root.getChildCount() > 0
end function

function searchKey(key as string) as boolean
    inResults = m.searchRows.isInFocusChain()
    if m.searchFocus = "button" and m.discoverButton.hasFocus()
        if key = "up" or key = "back"
            Search_ToKeyboard()
            return true
        end if
        if key = "OK"
            Disc_ButtonPaint(false)
            m.area = "page"
            showPage("discover")
            return true
        end if
        if key = "right"
            Search_ToRight()
            return true
        end if
        if key = "left"
            Disc_ButtonPaint(false)
            focusNav()
            return true
        end if
        return true
    end if
    if key = "back"
        focusNav()
        return true
    end if
    if inResults
        if key = "left"
            Search_ToKeyboard()
            return true
        end if
        return false
    end if
    if key = "right"
        Search_ToRight()
        return true
    end if
    if key = "down" and m.discoverButton.visible and m.keyboard.isInFocusChain()
        m.searchFocus = "button"
        m.discoverButton.setFocus(true)
        Disc_ButtonPaint(true)
        return true
    end if
    if key = "left"
        focusNav()
        return true
    end if
    return false
end function

sub Search_ToKeyboard()
    Disc_ButtonPaint(false)
    m.searchFocus = "keyboard"
    m.keyboard.setFocus(true)
end sub

sub Search_ToRight()
    if searchHasResults() and m.searchRows.visible
        Disc_ButtonPaint(false)
        m.searchFocus = "results"
        m.searchRows.setFocus(true)
        if Str_Of(m.lastQuery) <> "" then St_AddSearch(m.lastQuery)
    else if m.recent.visible
        Disc_ButtonPaint(false)
        m.searchFocus = "recent"
        m.recent.setFocus(true)
    end if
end sub

sub onSearchText()
    m.searchText.text = m.keyboard.text
    m.searchTimer.control = "stop"
    if m.keyboard.text.Trim() = ""
        if m.searchTask <> invalid
            m.searchTask.unobserveField("row")
            m.searchTask.unobserveField("done")
            m.searchTask.control = "STOP"
            m.searchTask = invalid
        end if
        m.lastQuery = ""
        m.searchRows.content = CreateObject("roSGNode", "ContentNode")
        m.searchRows.visible = false
        Recent_Refresh()
        Search_Idle()
        return
    end if
    m.recent.visible = false
    m.searchTimer.control = "start"
end sub

sub onSearchTimer()
    query = m.keyboard.text.Trim()
    if Len(query) >= 2 and query <> m.lastQuery then runSearch(query)
end sub

sub runSearch(query as string)
    text = query.Trim()
    if text = "" then return
    m.lastQuery = text
    m.searchText.text = text
    if m.keyboard.isInFocusChain() then m.searchFocus = "keyboard"
    if m.manifests.Count() = 0
        m.searchStatus.text = L("Primero agrega addons.")
        m.searchStatus.visible = true
        return
    end if
    if m.searchTask <> invalid
        m.searchTask.unobserveField("row")
        m.searchTask.unobserveField("done")
        m.searchTask.control = "STOP"
    end if
    m.recent.visible = false
    m.searchRoot = CreateObject("roSGNode", "ContentNode")
    m.searchRows.content = m.searchRoot
    m.searchRows.visible = false
    m.searchStatus.text = L("Buscando ") + Chr(34) + text + Chr(34) + "..."
    m.searchStatus.visible = true
    m.searchTask = CreateObject("roSGNode", "SearchTask")
    m.searchTask.manifests = m.manifests
    m.searchTask.query = text
    m.searchTask.limit = m.prefs.rowSize
    m.searchTask.observeField("row", "onSearchRow")
    m.searchTask.observeField("done", "onSearchDone")
    m.searchTask.control = "RUN"
end sub

sub onSearchRow(event as object)
    task = event.getRoSGNode()
    if m.searchTask = invalid or not task.isSameNode(m.searchTask) then return
    row = task.row
    if row = invalid then return
    m.searchRoot.appendChild(row)
    if not m.searchRows.visible
        m.searchRows.content = m.searchRoot
        m.searchRows.visible = true
        m.searchStatus.visible = false
        if m.searchFocus = "results" and m.page = "search" and m.area = "page" and not overlayOpen() then m.searchRows.setFocus(true)
    end if
end sub

sub onSearchDone(event as object)
    task = event.getRoSGNode()
    if m.searchTask = invalid or not task.isSameNode(m.searchTask) then return
    m.searchTask = invalid
    if task.searchable = 0
        m.searchStatus.text = L("Ninguno de tus addons tiene búsqueda. Agrega uno que la tenga, como Cinemeta o TMDB.")
        m.searchStatus.visible = true
    else if m.searchRoot.getChildCount() = 0
        m.searchStatus.text = L("Sin resultados para ") + Chr(34) + m.lastQuery + Chr(34) + "."
        m.searchStatus.visible = true
    end if
end sub
