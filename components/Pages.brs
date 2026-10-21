sub showPage(name as string)
    hideExpanded()
    m.page = name
    m.nav.active = name
    m.homePage.visible = name = "home"
    m.searchPage.visible = name = "search"
    m.libraryPage.visible = name = "library"
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
    else if name = "search"
        m.searchFocus = "keyboard"
    end if
    if m.area = "page" and not overlayOpen() then focusPage()
end sub

sub focusPage()
    if m.top.dialog <> invalid then return
    if m.page = "home"
        if m.homeRows.visible and m.homeRows.content <> invalid and m.homeRows.content.getChildCount() > 0
            m.homeRows.setFocus(true)
        else
            m.top.setFocus(true)
        end if
    else if m.page = "search"
        if m.searchFocus = "results" and searchHasResults()
            m.searchRows.setFocus(true)
        else
            m.searchFocus = "keyboard"
            m.keyboard.setFocus(true)
        end if
    else if m.page = "library"
        if m.libraryRows.visible
            m.libraryRows.setFocus(true)
        else
            m.top.setFocus(true)
        end if
    end if
end sub

sub applyRowSizes(rows as object)
    root = rows.content
    landscape = false
    if root <> invalid
        first = root.getChild(0)
        if first <> invalid
            if first.id = "cw" and St_Pref("cwStyle") <> "poster" then landscape = true
        end if
    end if
    if landscape
        rows.rowItemSize = [[400, 225], [200, 300]]
        rows.rowHeights = [305, 380]
    else
        rows.rowItemSize = [[200, 300]]
        rows.rowHeights = [380]
    end if
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
    cw = Content_ContinueRow()
    if cw <> invalid then root.appendChild(cw)
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
    m.libraryRows.content = root
    applyRowSizes(m.libraryRows)
    hasItems = root.getChildCount() > 0
    m.libraryRows.visible = hasItems
    m.libraryEmpty.visible = not hasItems
    m.hero.visible = hasItems
    if hasItems then showHeroFor(getRowItem(m.libraryRows, [0, 0]))
end sub

function searchHasResults() as boolean
    root = m.searchRows.content
    return root <> invalid and root.getChildCount() > 0
end function

function searchKey(key as string) as boolean
    inResults = m.searchRows.isInFocusChain()
    if key = "back"
        focusNav()
        return true
    end if
    if inResults
        if key = "left"
            m.searchFocus = "keyboard"
            m.keyboard.setFocus(true)
            return true
        end if
        return false
    end if
    if key = "right" and searchHasResults()
        m.searchFocus = "results"
        m.searchRows.setFocus(true)
        return true
    end if
    if key = "left"
        focusNav()
        return true
    end if
    return false
end function

sub onSearchText()
    m.searchText.text = m.keyboard.text
    m.searchTimer.control = "stop"
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
