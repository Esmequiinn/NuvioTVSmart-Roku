sub init()
    m.mark = m.top.findNode("mark")
    m.titleLabel = m.top.findNode("title")
    m.subtitleLabel = m.top.findNode("subtitle")
    m.poster = m.top.findNode("poster")
    m.backdrop = m.top.findNode("backdrop")
    m.list = m.top.findNode("list")
    m.divider = m.top.findNode("divider")
    m.detail = m.top.findNode("detail")
    m.details = []
    m.list.font.size = 34
    m.list.focusedFont.size = 34
    m.list.observeField("itemSelected", "onItemSelected")
    m.list.observeField("itemFocused", "onItemFocused")
    m.top.observeField("focusedChild", "onFocusChanged")
end sub

sub render()
    cfg = m.top.config
    if cfg = invalid then return
    m.titleLabel.text = textOf(cfg.title)
    m.subtitleLabel.text = textOf(cfg.subtitle)
    m.backdrop.uri = textOf(cfg.backdrop)

    posterUri = textOf(cfg.poster)
    if posterUri <> ""
        m.poster.uri = posterUri
        m.poster.visible = true
        m.list.translation = [560, 300]
        m.list.itemSize = [1260, 66]
        m.divider.translation = [560, 906]
        m.divider.width = 1260
        m.detail.translation = [560, 926]
        m.detail.width = 1260
    else
        m.poster.visible = false
        m.list.translation = [112, 300]
        m.list.itemSize = [1700, 66]
        m.divider.translation = [112, 906]
        m.divider.width = 1700
        m.detail.translation = [112, 926]
        m.detail.width = 1700
    end if

    content = CreateObject("roSGNode", "ContentNode")
    if type(cfg.items) = "roArray"
        for each text in cfg.items
            child = content.CreateChild("ContentNode")
            child.title = textOf(text)
        end for
    end if
    m.details = []
    if type(cfg.details) = "roArray" then m.details = cfg.details
    m.list.content = content

    focus = 0
    if cfg.focus <> invalid then focus = cfg.focus
    if focus >= content.getChildCount() then focus = content.getChildCount() - 1
    if focus < 0 then focus = 0
    m.list.jumpToItem = focus
    showDetail(focus)
end sub

sub applyAccent()
    color = m.top.accent
    if color = "" then return
    m.mark.color = color
end sub

sub onItemSelected()
    m.top.selected = m.list.itemSelected
end sub

sub onItemFocused()
    showDetail(m.list.itemFocused)
end sub

sub showDetail(index as integer)
    text = ""
    if index >= 0 and index < m.details.Count() then text = textOf(m.details[index])
    m.detail.text = text
    m.divider.visible = text <> ""
end sub

sub onFocusChanged()
    if m.top.hasFocus() then m.list.setFocus(true)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        m.top.back = true
        return true
    end if
    return false
end function

function textOf(v as dynamic) as string
    if v = invalid then return ""
    if GetInterface(v, "ifString") <> invalid then return v
    return ""
end function
