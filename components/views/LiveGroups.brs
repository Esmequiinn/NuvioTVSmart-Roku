sub Groups_Init()
    m.groupPanel = m.top.findNode("groupPanel")
    m.gpTitle = m.top.findNode("gpTitle")
    m.gpHint = m.top.findNode("gpHint")
    m.gpRows = m.top.findNode("gpRows")
    m.gpTitle.text = L("Grupos")
    m.gpHint.text = L("OK elige  ·  * opciones del grupo")
    m.gpSel = 0
    m.gpTop = 0
    m.gpN = 8
    m.gpNodes = []
    for r = 0 to m.gpN - 1
        g = m.gpRows.createChild("Group")
        g.translation = [0, r * 108]
        bg = g.createChild("Poster")
        bg.uri = "pkg:/images/card.9.png"
        bg.width = 660
        bg.height = 100
        icon = g.createChild("Poster")
        icon.translation = [30, 37]
        icon.width = 26
        icon.height = 26
        lb = g.createChild("Label")
        lb.translation = [78, 0]
        lb.width = 460
        lb.height = 100
        lb.vertAlign = "center"
        lb.maxLines = 1
        Iptv_SetFont(lb, 25, true)
        cnt = g.createChild("Label")
        cnt.translation = [540, 0]
        cnt.width = 92
        cnt.height = 100
        cnt.vertAlign = "center"
        cnt.horizAlign = "right"
        Iptv_SetFont(cnt, 22, false)
        m.gpNodes.Push({ g: g, bg: bg, icon: icon, lb: lb, cnt: cnt })
    end for
end sub

sub Live_BuildGroups()
    counts = {}
    order = []
    total = 0
    for each c in m.all
        if not m.hidden.DoesExist(c.k)
            g = Str_Of(c.g)
            if g <> "" and not m.hiddenGroups.DoesExist(g)
                if not counts.DoesExist(g)
                    counts[g] = 0
                    order.Push(g)
                end if
                counts[g] = counts[g] + 1
                total = total + 1
            else if g = ""
                total = total + 1
            end if
        end if
    end for
    favCount = 0
    for each k in m.favOrder
        if m.keyIndex <> invalid and m.keyIndex.DoesExist(k) and not m.hidden.DoesExist(k) then favCount = favCount + 1
    end for
    recentCount = 0
    for each k in Live_Recent()
        if m.keyIndex <> invalid and m.keyIndex.DoesExist(k) and not m.hidden.DoesExist(k) then recentCount = recentCount + 1
    end for
    m.groups = [{ id: "fav", label: L("Favoritos"), count: favCount }, { id: "recent", label: L("Vistos recientemente"), count: recentCount }, { id: "all", label: L("Todos"), count: total }]
    for each g in order
        if m.favGroups.DoesExist(g) then m.groups.Push({ id: "g", label: g, count: counts[g], star: true, locked: m.locks.DoesExist(g) })
    end for
    for each g in order
        if not m.favGroups.DoesExist(g) then m.groups.Push({ id: "g", label: g, count: counts[g], star: false, locked: m.locks.DoesExist(g) })
    end for
    if m.groupLabel <> invalid
        idx = Groups_FindLabel(m.groupLabel)
        if idx >= 0 then m.groupIdx = idx
    end if
    if m.groupIdx >= m.groups.Count() then m.groupIdx = Groups_Find("all")
end sub

function Groups_Find(id as string) as integer
    for i = 0 to m.groups.Count() - 1
        if m.groups[i].id = id then return i
    end for
    return 0
end function

function Groups_FindLabel(label as string) as integer
    for i = 0 to m.groups.Count() - 1
        if m.groups[i].label = label then return i
    end for
    return -1
end function

function Groups_Initial() as integer
    if Bool_Of(m.prefs.lastGroup, true)
        last = Str_Of(St_Get("iptvLastGroup_" + St_ActiveProfile().id, ""))
        if last <> ""
            idx = Groups_FindLabel(last)
            if idx >= 0 and not Bool_Of(m.groups[idx].locked, false) and m.groups[idx].count > 0 then return idx
        end if
    end if
    if m.favOrder.Count() > 0 then return Groups_Find("fav")
    return Groups_Find("all")
end function

sub Live_ApplyGroup(resetSel as boolean)
    m.view = []
    if m.groups.Count() = 0 then Live_BuildGroups()
    if m.groupIdx >= m.groups.Count() then m.groupIdx = Groups_Find("all")
    grp = m.groups[m.groupIdx]
    m.groupLabel = grp.label
    if grp.id = "fav"
        for each k in m.favOrder
            if m.keyIndex <> invalid and m.keyIndex.DoesExist(k) and not m.hidden.DoesExist(k) then m.view.Push(m.keyIndex[k])
        end for
    else if grp.id = "recent"
        for each k in Live_Recent()
            if m.keyIndex <> invalid and m.keyIndex.DoesExist(k) and not m.hidden.DoesExist(k) then m.view.Push(m.keyIndex[k])
        end for
    else
        for i = 0 to m.all.Count() - 1
            c = m.all[i]
            if not m.hidden.DoesExist(c.k)
                g = Str_Of(c.g)
                if grp.id = "all"
                    if g = "" or (not m.hiddenGroups.DoesExist(g) and not (m.locks.DoesExist(g) and not m.unlocked.DoesExist(g))) then m.view.Push(i)
                else if g = grp.label
                    m.view.Push(i)
                end if
            end if
        end for
    end if
    if resetSel
        m.sel = 0
        m.top0 = 0
    end if
    if m.sel >= m.view.Count() then m.sel = m.view.Count() - 1
    if m.sel < 0 then m.sel = 0
    Live_ClampTop()
    m.status.visible = false
    if not m.loaded
        m.status.text = L("Cargando canales...")
        m.status.visible = true
    else if m.all.Count() = 0
        m.status.text = L("Todavía no hay canales. Agrega una lista M3U o una cuenta Xtream en Ajustes → TV en vivo.")
        m.status.visible = true
    else if m.view.Count() = 0 and grp.id = "fav"
        m.status.text = L("Aún no tienes favoritos. Presiona * en un canal para agregarlo.")
        m.status.visible = true
    else if m.view.Count() = 0
        m.status.text = L("No hay canales en este grupo. Presiona Izquierda para elegir otro.")
        m.status.visible = true
    end if
    Live_AskGuide()
    Live_Render()
    Live_SchedulePreview()
end sub

sub Groups_Open()
    Live_BuildGroups()
    if m.groups.Count() = 0 then return
    m.zone = "groups"
    m.gpSel = m.groupIdx
    m.previewTimer.control = "stop"
    if m.mode = "watch" then m.overlay.visible = false
    m.groupPanel.visible = true
    m.top.event = { action: "panel", on: true }
    Groups_Render()
end sub

sub Groups_Close()
    if m.zone <> "groups" then return
    m.groupPanel.visible = false
    m.top.event = { action: "panel", on: false }
    m.zone = "grid"
    if m.mode = "watch" then Overlay_Show()
    if m.mode = "guide" then Live_Render()
end sub

sub Groups_Render()
    if m.gpSel < m.gpTop then m.gpTop = m.gpSel
    if m.gpSel > m.gpTop + m.gpN - 1 then m.gpTop = m.gpSel - m.gpN + 1
    if m.gpTop < 0 then m.gpTop = 0
    for r = 0 to m.gpN - 1
        node = m.gpNodes[r]
        i = m.gpTop + r
        if i >= m.groups.Count()
            node.g.visible = false
        else
            grp = m.groups[i]
            node.g.visible = true
            node.lb.text = grp.label
            node.cnt.text = ToInt(grp.count, 0).ToStr()
            icon = ""
            if grp.id = "fav" or Bool_Of(grp.star, false) then icon = "pkg:/images/ic_star.png"
            if Bool_Of(grp.locked, false) and not m.unlocked.DoesExist(grp.label) then icon = "pkg:/images/ic_lock.png"
            if grp.id = "recent" then icon = "pkg:/images/ic_replay.png"
            node.icon.uri = icon
            node.icon.visible = icon <> ""
            if i = m.gpSel
                node.bg.blendColor = "0xF2F2F7FF"
                node.lb.color = "0x111114FF"
                node.cnt.color = "0x3A3A44FF"
                node.icon.blendColor = "0x111114FF"
            else if i = m.groupIdx
                node.bg.blendColor = "0x2C2C36F0"
                node.lb.color = "0xFFFFFFFF"
                node.cnt.color = "0xE5E5EEFF"
                node.icon.blendColor = "0xFFC94DFF"
            else
                node.bg.blendColor = "0x1A1A21E6"
                node.lb.color = "0xC9C9D6FF"
                node.cnt.color = "0x80808EFF"
                node.icon.blendColor = "0xFFC94DFF"
            end if
        end if
    end for
end sub

function Groups_Key(key as string) as boolean
    n = m.groups.Count()
    if key = "up" or key = "down"
        if key = "up" then m.gpSel = m.gpSel - 1 else m.gpSel = m.gpSel + 1
        if m.gpSel < 0 then m.gpSel = n - 1
        if m.gpSel >= n then m.gpSel = 0
        Groups_Render()
    else if key = "rewind" or key = "fastforward"
        if key = "rewind" then m.gpSel = m.gpSel - m.gpN else m.gpSel = m.gpSel + m.gpN
        if m.gpSel < 0 then m.gpSel = 0
        if m.gpSel >= n then m.gpSel = n - 1
        Groups_Render()
    else if key = "OK"
        Groups_Pick(m.gpSel)
    else if key = "left"
        if m.mode = "watch"
            Groups_Close()
        else
            m.groupPanel.visible = false
            m.zone = "grid"
            Live_Render()
            m.top.event = { action: "panel", on: false }
            m.top.event = { action: "nav" }
        end if
    else if key = "right" or key = "back"
        Groups_Close()
    else if key = "options"
        grp = m.groups[m.gpSel]
        if grp.id = "g"
            m.top.event = { action: "groupOptions", group: grp.label, fav: Bool_Of(grp.star, false), locked: Bool_Of(grp.locked, false), hasPin: Str_Of(m.prefs.pin) <> "" }
        end if
    end if
    return true
end function

sub Groups_Pick(idx as integer)
    if idx < 0 or idx >= m.groups.Count() then return
    grp = m.groups[idx]
    if Bool_Of(grp.locked, false) and not m.unlocked.DoesExist(grp.label)
        m.top.event = { action: "pin", group: grp.label }
        return
    end if
    m.groupIdx = idx
    St_Set("iptvLastGroup_" + St_ActiveProfile().id, grp.label)
    m.groupPanel.visible = false
    m.zone = "grid"
    m.top.event = { action: "panel", on: false }
    Live_ApplyGroup(true)
    if m.mode = "watch"
        m.sel = Watch_PlayingPos()
        m.ovSel = 0
        m.ovTop = 0
        Overlay_Show()
    end if
end sub

sub Groups_Command(cmd as object)
    what = Str_Of(cmd.what)
    label = Str_Of(cmd.group)
    if label = "" then return
    if what = "fav"
        st = Iptv_Store("FavGroups")
        if st.DoesExist(label) then st.Delete(label) else st[label] = true
        Iptv_SaveStore("FavGroups", st)
        m.favGroups = st
    else if what = "hide"
        st = Iptv_Store("HiddenGroups")
        if st.DoesExist(label) then st.Delete(label) else st[label] = true
        Iptv_SaveStore("HiddenGroups", st)
        m.hiddenGroups = st
    else if what = "lock"
        st = Iptv_Store("Locks")
        if st.DoesExist(label)
            st.Delete(label)
        else
            st[label] = true
            m.unlocked.Delete(label)
        end if
        Iptv_SaveStore("Locks", st)
        m.locks = st
    end if
    keep = m.groupLabel
    Live_BuildGroups()
    idx = Groups_FindLabel(keep)
    if idx < 0 or (Bool_Of(m.groups[idx].locked, false) and not m.unlocked.DoesExist(keep)) then idx = Groups_Find("all")
    m.groupIdx = idx
    Live_ApplyGroup(false)
    if m.zone = "groups"
        m.gpSel = Groups_FindLabel(label)
        if m.gpSel < 0 then m.gpSel = m.groupIdx
        Groups_Render()
    end if
end sub
