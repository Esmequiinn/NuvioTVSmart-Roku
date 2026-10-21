function L(text as string) as string
    if m.i18n = invalid
        m.i18n = {}
        if m.global <> invalid
            table = m.global.i18n
            if type(table) = "roAssociativeArray" then m.i18n = table
        end if
    end if
    value = m.i18n[text]
    if value = invalid then return text
    return value
end function

sub L_Texts(ids as object)
    for each id in ids
        node = m.top.findNode(id)
        if node <> invalid then node.text = L(node.text)
    end for
end sub
