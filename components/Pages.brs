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
    if name <> "folder" and Bool_Of(m.libraryGrid, false)
        m.libraryGrid = false
        Grid_Layout()
    end if
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
    labels = []
    names = Bool_Of(St_Pref("posterLabels"), false)
    if root <> invalid
        cwLandscape = St_Pref("cwStyle") <> "poster"
        for i = 0 to root.getChildCount() - 1
            row = root.getChild(i)
            shape = "poster"
            if row.hasField("shape") then shape = row.shape
            if row.id = "cw" and cwLandscape then shape = "card"
            more = row.hasField("gridPart") and row.gridPart > 0
            extra = 0
            named = names and row.id <> "cw" and shape <> "hero"
            if named then extra = 44
            if row.hasField("labels") then row.labels = named else row.addFields({ labels: named })
            labels.Push(not more and shape <> "hero")
            if shape = "hero"
                sizes.Push([1600, 500])
                heights.Push(560)
            else if shape = "card"
                sizes.Push([400, 225])
                if more then heights.Push(249) else heights.Push(305)
            else if shape = "landscape"
                sizes.Push([356, 200])
                if more then heights.Push(224 + extra) else heights.Push(280 + extra)
            else if shape = "square"
                sizes.Push([240, 240])
                if more then heights.Push(264 + extra) else heights.Push(320 + extra)
            else
                sizes.Push([200, 300])
                if more then heights.Push(324 + extra) else heights.Push(380 + extra)
            end if
        end for
    end if
    if sizes.Count() = 0
        sizes.Push([200, 300])
        heights.Push(380)
        labels.Push(true)
    end if
    rows.rowItemSize = sizes
    rows.rowHeights = heights
    rows.showRowLabel = labels
end sub

function Home_Mode() as string
    mode = Str_Of(St_Pref("homeLayout"))
    if mode = "grid" or mode = "classic" then return mode
    return "modern"
end function

function Home_Grid() as boolean
    return Home_Mode() = "grid"
end function

sub Grid_Layout()
    if m.homeRows = invalid or m.hero = invalid or m.libraryRows = invalid then return
    mode = Home_Mode()
    if mode = "modern"
        m.homeRows.translation = [152, 560]
        m.homeRows.numRows = 2
        m.homeRows.rowFocusAnimationStyle = "fixedFocus"
    else
        m.homeRows.translation = [152, 150]
        m.homeRows.numRows = 4
        if mode = "grid" then m.homeRows.rowFocusAnimationStyle = "floatingFocus" else m.homeRows.rowFocusAnimationStyle = "fixedFocus"
    end if
    m.homeRows.vertFocusAnimationStyle = "fixedFocus"
    m.hero.wide = mode <> "modern" or Bool_Of(St_Pref("heroFull"), false)
    if Bool_Of(m.libraryGrid, false) then style = "floatingFocus" else style = "fixedFocus"
    m.libraryRows.rowFocusAnimationStyle = style
    Home_CarouselTimer()
end sub

function Home_Decorate(content as object) as object
    if content = invalid then return content
    mode = Home_Mode()
    if mode = "modern" then return content
    hero = invalid
    if Bool_Of(St_Pref("heroSection"), true) then hero = Hero_Row(content)
    if mode = "grid" then content = Grid_Wrap(content, true)
    if hero <> invalid then content.insertChild(hero, 0)
    return content
end function

function Hero_Row(content as object) as dynamic
    chosen = St_Pref("heroCatalogs")
    wanted = {}
    if type(chosen) = "roArray"
        for each k in chosen
            if IsStr(k) and k <> "" then wanted[k] = true
        end for
    end if
    picked = []
    fallback = []
    for i = 0 to content.getChildCount() - 1
        row = content.getChild(i)
        if row.id <> "cw" and row.hasField("key") and row.getChildCount() > 0
            first = row.getChild(0)
            if first.itemType <> "folder"
                if wanted.DoesExist(Hero_Key(row.key)) then picked.Push(row)
                if fallback.Count() < 3 then fallback.Push(row)
            end if
        end if
    end for
    if picked.Count() = 0
        if wanted.Count() > 0 then return invalid
        picked = fallback
    end if
    hero = CreateObject("roSGNode", "ContentNode")
    hero.id = "herocar"
    hero.addFields({ key: "herocar", shape: "hero" })
    seen = {}
    for n = 0 to 19
        for each row in picked
            if n < row.getChildCount() and hero.getChildCount() < 10
                item = row.getChild(n)
                id = Str_Of(item.metaId)
                art = Str_Of(item.background) <> "" or Left(id, 2) = "tt"
                if art and not seen.DoesExist(id)
                    seen[id] = true
                    copy = Grid_Copy(item)
                    copy.addFields({ heroCard: true })
                    hero.appendChild(copy)
                end if
            end if
        end for
    end for
    if hero.getChildCount() = 0 then return invalid
    return hero
end function

function Hero_Key(key as string) as string
    return key.Replace("|", "_")
end function

function Home_FocusRow() as dynamic
    if m.homeRows = invalid or m.homeRows.content = invalid then return invalid
    focus = m.homeRows.rowItemFocused
    if type(focus) <> "roArray" or focus.Count() < 1 then return invalid
    return m.homeRows.content.getChild(focus[0])
end function

sub Home_HeroState()
    if m.page <> "home"
        m.hero.bare = false
        m.hero.dots = { count: 0, index: 0 }
        return
    end if
    if not m.hero.visible and not Bool_Of(m.heroHidden, false) then return
    mode = Home_Mode()
    bare = false
    show = true
    dots = { count: 0, index: 0 }
    if mode <> "modern"
        row = Home_FocusRow()
        if row <> invalid and row.id = "herocar"
            focus = m.homeRows.rowItemFocused
            dots = { count: row.getChildCount(), index: focus[1] }
        else if mode = "classic" and Bool_Of(St_Pref("classicGradient"), false)
            bare = true
        else
            show = false
        end if
    end if
    m.hero.bare = bare
    m.hero.dots = dots
    m.heroHidden = not show
    m.hero.visible = show
end sub

sub Home_CarouselTimer()
    if m.carouselTimer = invalid
        m.carouselTimer = m.top.createChild("Timer")
        m.carouselTimer.repeat = true
        m.carouselTimer.duration = 10
        m.carouselTimer.observeField("fire", "onCarouselTimer")
    end if
    m.carouselTimer.control = "stop"
    m.carouselWait = 1
    if Home_Mode() <> "modern" and Bool_Of(St_Pref("heroSection"), true) then m.carouselTimer.control = "start"
end sub

sub onCarouselTimer()
    if m.page <> "home" or m.area <> "page" or overlayOpen() or m.busy or not m.homeRows.isInFocusChain()
        m.carouselWait = 1
        return
    end if
    row = Home_FocusRow()
    if row = invalid or row.id <> "herocar" or row.getChildCount() < 2
        m.carouselWait = 1
        return
    end if
    if m.carouselWait > 0
        m.carouselWait = m.carouselWait - 1
        return
    end if
    focus = m.homeRows.rowItemFocused
    nxt = focus[1] + 1
    if nxt >= row.getChildCount() then nxt = 0
    m.homeRows.jumpToRowItem = [focus[0], nxt]
end sub

function Grid_Cols(shape as string) as integer
    if shape = "landscape" or shape = "card" then return 4
    if shape = "square" then return 6
    return 7
end function

function Grid_Wrap(content as object, cap as boolean) as object
    if content = invalid then return content
    if m.gridFull = invalid or cap then m.gridFull = {}
    root = CreateObject("roSGNode", "ContentNode")
    rows = []
    for i = 0 to content.getChildCount() - 1
        rows.Push(content.getChild(i))
    end for
    for each row in rows
        if row.id = "cw" or row.id = "herocar" or row.getChildCount() = 0
            root.appendChild(row)
        else
            Grid_Split(root, row, cap)
        end if
    end for
    return root
end function

sub Grid_Split(root as object, row as object, cap as boolean)
    items = []
    for i = 0 to row.getChildCount() - 1
        items.Push(row.getChild(i))
    end for
    shape = "poster"
    if row.hasField("shape") then shape = Str_Of(row.shape)
    cols = Grid_Cols(shape)
    key = Home_RowKey(row)
    shown = items.Count()
    more = cap and shown > cols * 3
    if more
        shown = cols * 3 - 1
        m.gridFull[key] = { title: Str_Of(row.title), items: items }
    end if
    row.removeChildrenIndex(row.getChildCount(), 0)
    if not row.hasField("gridPart") then row.addFields({ gridPart: 0 })
    fields = row.getFields()
    part = 0
    chunk = row
    for i = 0 to shown - 1
        if i > 0 and i mod cols = 0
            root.appendChild(chunk)
            part = part + 1
            chunk = Grid_Chunk(fields, key, part)
        end if
        chunk.appendChild(items[i])
    end for
    if more
        if chunk.getChildCount() >= cols
            root.appendChild(chunk)
            part = part + 1
            chunk = Grid_Chunk(fields, key, part)
        end if
        tile = CreateObject("roSGNode", "ContentNode")
        tile.title = L("Ver todo")
        tile.addFields({ itemType: "seeall", gridKey: key, metaId: "", idx: shown })
        chunk.appendChild(tile)
    end if
    root.appendChild(chunk)
end sub

function Grid_Chunk(fields as object, key as string, part as integer) as object
    chunk = CreateObject("roSGNode", "ContentNode")
    skip = { change: true, focusedChild: true, focusable: true, title: true, key: true, gridPart: true }
    for each name in fields
        if not skip.DoesExist(name) and fields[name] <> invalid
            if chunk.hasField(name)
                chunk.setField(name, fields[name])
            else
                extra = {}
                extra[name] = fields[name]
                chunk.addFields(extra)
            end if
        end if
    end for
    chunk.title = ""
    chunk.addFields({ key: key + "#" + part.ToStr(), gridPart: part })
    return chunk
end function

function Grid_Copy(src as object) as object
    node = CreateObject("roSGNode", "ContentNode")
    skip = { change: true, focusedChild: true, focusable: true }
    fields = src.getFields()
    for each name in fields
        if not skip.DoesExist(name) and fields[name] <> invalid
            if node.hasField(name)
                node.setField(name, fields[name])
            else
                extra = {}
                extra[name] = fields[name]
                node.addFields(extra)
            end if
        end if
    end for
    return node
end function

sub Grid_SeeAll(tile as object)
    if m.gridFull = invalid or not m.gridFull.DoesExist(tile.gridKey) then return
    info = m.gridFull[tile.gridKey]
    row = CreateObject("roSGNode", "ContentNode")
    row.title = info.title
    shape = "poster"
    parent = tile.getParent()
    if parent <> invalid and parent.hasField("shape") then shape = Str_Of(parent.shape)
    row.addFields({ shape: shape, key: "all:" + Str_Of(tile.gridKey) })
    for i = 0 to info.items.Count() - 1
        copy = Grid_Copy(info.items[i])
        if copy.hasField("idx") then copy.idx = i
        row.appendChild(copy)
    end for
    source = CreateObject("roSGNode", "ContentNode")
    source.appendChild(row)
    hideExpanded()
    m.folderTitle = info.title
    m.libraryGrid = true
    m.libraryRows.content = Grid_Wrap(source, false)
    applyRowSizes(m.libraryRows)
    Grid_Layout()
    m.area = "page"
    showPage("folder")
end sub

sub refreshContinueRow()
    root = m.homeRows.content
    if root = invalid then return
    at = 0
    first = root.getChild(0)
    if first <> invalid and first.id = "herocar"
        at = 1
        first = root.getChild(1)
    end if
    hasCw = first <> invalid and first.id = "cw"
    cw = Content_ContinueRow()
    if hasCw and cw = invalid
        root.removeChildIndex(at)
    else if hasCw
        root.replaceChild(cw, at)
    else if cw <> invalid
        root.insertChild(cw, at)
    end if
    applyRowSizes(m.homeRows)
    if root.getChildCount() > 0 and not m.emptyState.visible then m.homeRows.visible = true
end sub

sub buildLibrary()
    m.libraryGrid = false
    Grid_Layout()
    root = CreateObject("roSGNode", "ContentNode")
    rows = invalid
    source = Track_LibSource(St_Integrations())
    if source <> ""
        cache = St_ReadFile("tlib_" + St_ActiveProfile().id)
        if type(cache) = "roAssociativeArray" and Str_Of(cache.source) = source and type(cache.rows) = "roArray" then rows = cache.rows
    end if
    if rows = invalid then rows = [{ title: L("Mi lista"), items: St_Library() }]
    pattern = Poster_Pattern("library")
    for each r in rows
        if type(r) = "roAssociativeArray" and type(r.items) = "roArray" and r.items.Count() > 0
            row = root.createChild("ContentNode")
            row.title = Str_Of(r.title)
            for each e in r.items
                if type(e) = "roAssociativeArray"
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
                        metaId: Str_Of(e.id)
                        videoId: ""
                        background: ""
                        metaLine: TypeLabel(Str_Of(e.kind))
                        episodeLabel: ""
                        progress: 0.0
                    })
                end if
            end for
        end if
    end for
    prev = m.libraryRows.rowItemFocused
    m.libraryRows.content = root
    applyRowSizes(m.libraryRows)
    if root.getChildCount() > 0
        col = 0
        rowAt = 0
        if type(prev) = "roArray" and prev.Count() > 1
            rowAt = prev[0]
            col = prev[1]
        end if
        if rowAt < 0 or rowAt >= root.getChildCount() then rowAt = 0
        last = root.getChild(rowAt).getChildCount() - 1
        if col > last then col = last
        if col < 0 then col = 0
        m.libraryRows.jumpToRowItem = [rowAt, col]
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
    Ambient_Poke()
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
