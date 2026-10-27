sub Disc_Setup()
    m.discoverPage = m.top.findNode("discoverPage")
    m.discoverBar = m.top.findNode("discoverBar")
    m.discoverRows = m.top.findNode("discoverRows")
    m.discoverStatus = m.top.findNode("discoverStatus")
    m.discoverButton = m.top.findNode("discoverButton")
    m.discoverButtonBg = m.top.findNode("discoverButtonBg")
    m.discoverButtonText = m.top.findNode("discoverButtonText")
    m.discoverButtonIcon = m.top.findNode("discoverButtonIcon")
    m.recent = m.top.findNode("recentSearches")
    m.discoverButtonText.font.size = 28
    m.discoverButtonText.text = L("Descubrir")
    m.top.findNode("discoverHeading").text = L("Descubrir")
    m.discoverRows.observeField("rowItemSelected", "onRowSelected")
    m.discoverRows.observeField("rowItemFocused", "onDiscoverFocused")
    m.discoverBar.observeField("event", "onDiscoverBar")
    m.recent.observeField("event", "onRecentEvent")
    m.disc = { ready: false, cats: [], kind: "", catKey: "", genre: "", items: [], skip: 0, more: false, loading: false, sig: "" }
    Disc_Location()
end sub

function Disc_Where() as string
    loc = Str_Of(St_Pref("discoverLocation"))
    if loc <> "sidebar" and loc <> "off" then loc = "search"
    return loc
end function

sub Disc_Location()
    loc = Disc_Where()
    m.nav.discover = loc = "sidebar"
    m.discoverButton.visible = loc = "search"
    Disc_ButtonPaint(false)
end sub

sub Disc_ButtonPaint(on as boolean)
    if on
        m.discoverButtonBg.blendColor = "0xFFFFFFFF"
        m.discoverButtonText.color = "0x0C0C0FFF"
        m.discoverButtonIcon.blendColor = "0x0C0C0FFF"
    else
        m.discoverButtonBg.blendColor = "0x1C1C22FF"
        m.discoverButtonText.color = "0xF2F2F7FF"
        m.discoverButtonIcon.blendColor = "0xD8D8E0FF"
    end if
end sub

sub Disc_Show()
    cats = []
    if type(m.catalogs) = "roArray"
        for each c in m.catalogs
            if type(c) = "roAssociativeArray" and Str_Of(c.base) <> "" and Str_Of(c.id) <> "" then cats.Push(c)
        end for
    end if
    keys = []
    for each c in cats
        keys.Push(Str_Of(c.key))
    end for
    sig = keys.Join("|")
    if m.disc.ready and sig = m.disc.sig
        Disc_Chips()
        return
    end if
    m.disc.sig = sig
    m.disc.cats = cats
    m.disc.ready = true
    if cats.Count() = 0
        m.discoverBar.chips = []
        m.discoverRows.content = invalid
        m.discoverRows.visible = false
        m.discoverStatus.text = L("No hay catálogos cargados. Primero agrega un addon con catálogos.")
        m.discoverStatus.visible = true
        return
    end if
    saved = Str_Of(St_Get("discoverCat_" + St_ActiveProfile().id, ""))
    pick = cats[0]
    for each c in cats
        if c.key = saved then pick = c
    end for
    m.disc.kind = Str_Of(pick.kind)
    m.disc.catKey = pick.key
    m.disc.genre = ""
    Disc_Chips()
    Disc_Load(true)
end sub

function Disc_Catalog() as dynamic
    for each c in m.disc.cats
        if c.key = m.disc.catKey then return c
    end for
    return invalid
end function

function Disc_Kinds() as object
    out = []
    seen = {}
    for each c in m.disc.cats
        k = Str_Of(c.kind)
        if not seen.DoesExist(k)
            seen[k] = true
            out.Push(k)
        end if
    end for
    return out
end function

sub Disc_Chips()
    cat = Disc_Catalog()
    if cat = invalid then return
    chips = [{ id: "type", label: L("Tipo"), value: TypePlural(m.disc.kind) }]
    chips.Push({ id: "catalog", label: L("Catálogo"), value: Str_Glyphs(Str_Of(cat.name)) })
    if type(cat.genres) = "roArray" and cat.genres.Count() > 0
        g = m.disc.genre
        if g = "" then g = L("Predeterminado")
        chips.Push({ id: "genre", label: L("Género"), value: Str_Glyphs(g) })
    end if
    m.discoverBar.chips = chips
end sub

sub Disc_Load(reset as boolean)
    cat = Disc_Catalog()
    if cat = invalid then return
    if reset
        m.disc.items = []
        m.disc.skip = 0
        m.disc.more = true
        m.discoverRows.content = CreateObject("roSGNode", "ContentNode")
        m.discoverRows.visible = false
        m.discoverStatus.text = L("Cargando...")
        m.discoverStatus.visible = true
    end if
    if m.discTask <> invalid then m.discTask.unobserveField("result")
    task = CreateObject("roSGNode", "DiscoverTask")
    task.base = cat.base
    task.kind = cat.kind
    task.catalogId = cat.id
    task.genre = m.disc.genre
    task.skip = m.disc.skip
    task.observeField("result", "onDiscoverResult")
    task.control = "RUN"
    m.discTask = task
    m.disc.loading = true
end sub

sub onDiscoverResult(event as object)
    task = event.getRoSGNode()
    if m.discTask = invalid or not task.isSameNode(m.discTask) then return
    m.discTask = invalid
    m.disc.loading = false
    r = task.result
    if type(r) <> "roAssociativeArray" then r = { items: [], count: 0, error: "" }
    seen = {}
    for each it in m.disc.items
        seen[Str_Of(it.kind) + ":" + Str_Of(it.metaId)] = true
    end for
    fresh = []
    for each it in r.items
        k = Str_Of(it.kind) + ":" + Str_Of(it.metaId)
        if not seen.DoesExist(k)
            seen[k] = true
            fresh.Push(it)
        end if
    end for
    cat = Disc_Catalog()
    m.disc.skip = m.disc.skip + ToInt(r.count, 0)
    m.disc.more = fresh.Count() > 0 and cat <> invalid and Bool_Of(cat.skip, false)
    Disc_Append(fresh)
    if m.disc.items.Count() = 0
        m.discoverRows.visible = false
        title = L("No se encontró contenido")
        if Str_Of(r.error) <> "" and Str_Of(r.error) <> "ok" then title = title + chr(10) + Str_Of(r.error)
        m.discoverStatus.text = title + chr(10) + L("Prueba con otro género o catálogo")
        m.discoverStatus.visible = true
    end if
end sub

sub Disc_Append(fresh as object)
    if fresh.Count() = 0 then return
    root = m.discoverRows.content
    if root = invalid
        root = CreateObject("roSGNode", "ContentNode")
        m.discoverRows.content = root
    end if
    perRow = 7
    for each it in fresh
        m.disc.items.Push(it)
        row = invalid
        n = root.getChildCount()
        if n > 0 then row = root.getChild(n - 1)
        if row = invalid or row.getChildCount() >= perRow then row = root.createChild("ContentNode")
        Content_Item(row, it)
    end for
    if not m.discoverRows.visible
        m.discoverRows.visible = true
        m.discoverStatus.visible = false
        sizes = []
        heights = []
        for i = 0 to 0
            sizes.Push([200, 300])
            heights.Push(340)
        end for
        m.discoverRows.rowItemSize = sizes
        m.discoverRows.rowHeights = heights
    end if
end sub

sub onDiscoverFocused()
    hideExpanded()
    focus = m.discoverRows.rowItemFocused
    root = m.discoverRows.content
    if type(focus) <> "roArray" or root = invalid then return
    if focus[0] >= root.getChildCount() - 2 and m.disc.more and not m.disc.loading then Disc_Load(false)
end sub

sub onDiscoverBar()
    ev = m.discoverBar.event
    if ev = invalid then return
    if ev.type = "left"
        focusNav()
    else if ev.type = "down"
        if m.discoverRows.visible and m.discoverRows.content <> invalid and m.discoverRows.content.getChildCount() > 0
            m.discFocus = "rows"
            m.discoverRows.setFocus(true)
        end if
    else if ev.type = "pick"
        Disc_Pick(ev.id)
    end if
end sub

sub Disc_Pick(chip as string)
    items = []
    focus = 0
    title = ""
    if chip = "type"
        title = L("Tipo")
        kinds = Disc_Kinds()
        for i = 0 to kinds.Count() - 1
            if kinds[i] = m.disc.kind then focus = i
            items.Push({ id: kinds[i], label: TypePlural(kinds[i]), checked: kinds[i] = m.disc.kind })
        end for
    else if chip = "catalog"
        title = L("Catálogo")
        for each c in m.disc.cats
            if c.kind = m.disc.kind
                if c.key = m.disc.catKey then focus = items.Count()
                items.Push({ id: c.key, label: Str_Of(c.name) + "  ·  " + Str_Of(c.addon), checked: c.key = m.disc.catKey })
            end if
        end for
    else if chip = "genre"
        title = L("Género")
        cat = Disc_Catalog()
        items.Push({ id: "__all", label: L("Predeterminado"), checked: m.disc.genre = "" })
        if cat <> invalid and type(cat.genres) = "roArray"
            for each g in cat.genres
                if g = m.disc.genre then focus = items.Count()
                items.Push({ id: g, label: g, checked: g = m.disc.genre })
            end for
        end if
    end if
    if items.Count() = 0 then return
    Sheet_Open({ title: title, items: items, focus: focus, style: "cards", width: 760 }, "discoverPick", { chip: chip })
end sub

sub Disc_Chosen(chip as string, choice as string)
    if choice = ""
        focusCurrent()
        return
    end if
    if chip = "type"
        if choice <> m.disc.kind
            m.disc.kind = choice
            saved = Str_Of(St_Get("discoverCat_" + St_ActiveProfile().id, ""))
            pick = invalid
            for each c in m.disc.cats
                if c.kind = choice and (pick = invalid or c.key = saved) then pick = c
            end for
            if pick <> invalid then m.disc.catKey = pick.key
            m.disc.genre = ""
            Disc_Chips()
            Disc_Load(true)
        end if
    else if chip = "catalog"
        if choice <> m.disc.catKey
            m.disc.catKey = choice
            m.disc.genre = ""
            St_Set("discoverCat_" + St_ActiveProfile().id, choice)
            Disc_Chips()
            Disc_Load(true)
        end if
    else if chip = "genre"
        g = choice
        if g = "__all" then g = ""
        if g <> m.disc.genre
            m.disc.genre = g
            Disc_Chips()
            Disc_Load(true)
        end if
    end if
    m.discFocus = "bar"
    focusCurrent()
end sub

function Disc_Key(key as string) as boolean
    if m.discoverRows.isInFocusChain()
        if key = "up"
            m.discFocus = "bar"
            m.discoverBar.setFocus(true)
            return true
        end if
        if key = "left" or key = "back"
            focusNav()
            return true
        end if
        return false
    end if
    if key = "back"
        if Disc_Where() = "search"
            m.area = "page"
            showPage("search")
        else
            focusNav()
        end if
        return true
    end if
    return false
end function

sub Disc_Focus()
    if m.discFocus = "rows" and m.discoverRows.visible
        m.discoverRows.setFocus(true)
    else
        m.discFocus = "bar"
        m.discoverBar.setFocus(true)
    end if
end sub

sub Recent_Refresh()
    list = St_SearchHistory()
    show = list.Count() > 0 and Str_Of(m.keyboard.text).Trim() = "" and not searchHasResults()
    m.recent.items = list
    m.recent.visible = show
    if show
        m.searchStatus.visible = false
    else if m.searchFocus = "recent"
        m.searchFocus = "keyboard"
    end if
end sub

sub onRecentEvent()
    ev = m.recent.event
    if ev = invalid then return
    if ev.type = "left"
        m.searchFocus = "keyboard"
        m.keyboard.setFocus(true)
    else if ev.type = "clear"
        St_ClearSearches()
        m.searchFocus = "keyboard"
        Recent_Refresh()
        m.keyboard.setFocus(true)
        Search_Idle()
    else if ev.type = "remove"
        St_RemoveSearch(Str_Of(ev.query))
        Recent_Refresh()
        if not m.recent.visible
            m.searchFocus = "keyboard"
            m.keyboard.setFocus(true)
            Search_Idle()
        end if
    else if ev.type = "search"
        q = Str_Of(ev.query)
        St_AddSearch(q)
        m.keyboard.text = q
        m.searchFocus = "results"
        m.recent.visible = false
        runSearch(q)
    end if
end sub

sub Search_Idle()
    if m.recent.visible then return
    m.searchStatus.text = L("Escribe para buscar películas y series en tus addons.")
    m.searchStatus.visible = true
end sub
