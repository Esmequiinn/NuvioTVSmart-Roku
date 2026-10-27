sub Sheet_Open(cfg as object, handler as string, data as dynamic)
    hideExpanded()
    m.sheetHandler = handler
    m.sheetData = data
    m.sheet.config = Str_CleanDeep(cfg)
    m.sheet.visible = true
    m.sheet.setFocus(true)
end sub

sub Sheet_Close()
    m.sheet.visible = false
    m.sheet.setFocus(false)
    m.sheetHandler = ""
    focusCurrent()
end sub

sub onSheetClosed()
    if not m.sheet.visible then return
    if m.sheetHandler = "message" and Bool_Of(m.exitAfterDialog, false) then m.top.exitApp = true
    Sheet_Close()
end sub

sub onSheetChosen()
    if not m.sheet.visible then return
    choice = m.sheet.chosen
    handler = Str_Of(m.sheetHandler)
    data = m.sheetData
    m.sheet.visible = false
    m.sheet.setFocus(false)
    m.sheetHandler = ""
    if handler = "cw"
        Options_RunContinue(choice, data)
    else if handler = "poster"
        Options_RunPoster(choice, data)
    else if handler = "party"
        Party_RunMenu(choice)
    else if handler = "tracking"
        if choice = "trakt" or choice = "simkl" or choice = "mdblist" then Tracking_Disconnect(choice)
        focusCurrent()
    else if handler = "langPick"
        if choice <> "" and data <> invalid
            St_SetPref(data.pref, choice)
            if data.pref = "tmdbLanguage" then m.metaCache = {}
            refreshSettings()
        end if
        focusCurrent()
    else if handler = "uiLangPick"
        if choice <> ""
            UiLang_Apply(choice)
        else
            focusCurrent()
        end if
    else if handler = "discoverPick"
        chip = ""
        if data <> invalid then chip = Str_Of(data.chip)
        Disc_Chosen(chip, choice)
    else if handler = "message"
        if Bool_Of(m.exitAfterDialog, false) then m.top.exitApp = true
        focusCurrent()
    else
        focusCurrent()
    end if
end sub

function Options_FocusedItem() as dynamic
    rows = activeRows()
    if rows = invalid or not rows.isInFocusChain() then return invalid
    focus = rows.rowItemFocused
    item = getRowItem(rows, focus)
    if item = invalid then return invalid
    row = rows.content.getChild(focus[0])
    return { item: item, row: row, rows: rows, cw: row <> invalid and row.id = "cw" }
end function

function Options_Open() as boolean
    target = Options_FocusedItem()
    if target = invalid then return false
    item = target.item
    if item.itemType = "folder" then return false
    if target.cw
        items = [{ id: "details", label: L("Ir a detalles") }]
        if Str_Of(St_Pref("autoplayMode")) <> "manual" or Bool_Of(St_Pref("reuseLink"), false) then items.Push({ id: "manual", label: L("Reproducir manualmente") })
        items.Push({ id: "restart", label: L("Empezar desde el principio") })
        items.Push({ id: "remove", label: L("Eliminar") })
        Sheet_Open({ title: item.title, subtitle: L("Elige qué hacer con este elemento."), items: items, style: "tv" }, "cw", target)
        return true
    end if
    items = [{ id: "details", label: L("Ir a detalles") }]
    if St_InLibrary(item.metaId)
        items.Push({ id: "library", label: L("Eliminar de biblioteca") })
    else
        items.Push({ id: "library", label: L("Añadir a biblioteca") })
    end if
    kind = LCase(item.itemType)
    if kind = "movie" or kind = "series" or kind = "tv"
        if St_IsWatched(item.metaId)
            items.Push({ id: "watched", label: L("Marcar como no visto") })
        else
            items.Push({ id: "watched", label: L("Marcar como visto") })
        end if
    end if
    Sheet_Open({ title: item.title, subtitle: L("Acciones del título"), items: items, style: "tv" }, "poster", target)
    return true
end function

sub Options_RunContinue(choice as string, target as object)
    item = target.item
    if choice = "details"
        openDetails(item)
    else if choice = "manual"
        openDetails(item)
        m.details.visible = false
        m.ctx.direct = true
        m.ctx.forceManual = true
        runDetailAction("play")
    else if choice = "restart"
        openDetails(item)
        m.details.visible = false
        m.ctx.direct = true
        m.ctx.restartSame = true
        runDetailAction("restart")
    else if choice = "remove"
        St_RemoveProgress(item.metaId)
        refreshContinueRow()
        if m.page = "library" then buildLibrary()
        focusCurrent()
    else
        focusCurrent()
    end if
end sub

sub Options_RunPoster(choice as string, target as object)
    item = target.item
    if choice = "details"
        openDetails(item)
        return
    end if
    if choice = "library"
        poster = Details_Poster(item)
        added = St_ToggleLibrary({ id: item.metaId, kind: item.itemType, name: item.title, poster: poster })
        if added then Toast_Show(L("Agregado a Mi lista.")) else Toast_Show(L("Quitado de Mi lista."))
        if m.page = "library" then buildLibrary()
    else if choice = "watched"
        Watched_Toggle(item)
    end if
    focusCurrent()
end sub

sub Watched_Toggle(item as object)
    id = item.metaId
    watched = not St_IsWatched(id)
    kind = LCase(item.itemType)
    if kind = "tv" then kind = "series"
    entries = [{ id: id, kind: kind, title: item.title, season: invalid, episode: invalid }]
    if kind = "series"
        meta = m.metaCache[id]
        if meta <> invalid and type(meta.videos) = "roArray"
            for each v in meta.videos
                if type(v) = "roAssociativeArray" and ToInt(v.season, 0) > 0 and ToInt(v.episode, 0) > 0
                    entries.Push({ id: id, kind: kind, title: item.title, season: ToInt(v.season, 0), episode: ToInt(v.episode, 0) })
                end if
            end for
        end if
    end if
    St_SetWatched(entries, watched)
    if watched
        St_RemoveProgress(id)
        refreshContinueRow()
        Toast_Show(L("Marcado como visto."))
    else
        Toast_Show(L("Marcado como no visto."))
    end if
    Watched_Refresh(id, watched)
end sub

sub Watched_Refresh(id as string, watched as boolean)
    for each rows in [m.homeRows, m.libraryRows, m.searchRows]
        root = rows.content
        if root <> invalid
            for i = 0 to root.getChildCount() - 1
                row = root.getChild(i)
                for j = 0 to row.getChildCount() - 1
                    it = row.getChild(j)
                    if it.hasField("metaId") and it.metaId = id and it.hasField("watched") then it.watched = watched
                end for
            end for
        end if
    end for
end sub
