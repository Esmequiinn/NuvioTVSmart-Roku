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

function Ui_LangCodes() as object
    return ["auto", "es", "en", "pt", "fr", "de", "it", "nl", "pl", "tr", "ro", "cs", "hu"]
end function

function Ui_LangNames() as object
    return { auto: L("Automático"), es: "Español", en: "English", pt: "Português (Brasil)", fr: "Français", de: "Deutsch", it: "Italiano", nl: "Nederlands", pl: "Polski", tr: "Türkçe", ro: "Română", cs: "Čeština", hu: "Magyar" }
end function

function Ui_LangResolve(choice as string) as string
    codes = Ui_LangCodes()
    if choice <> "auto"
        for each c in codes
            if c = choice then return c
        end for
    end if
    locale = LCase(Left(CreateObject("roDeviceInfo").GetCurrentLocale(), 2))
    for each c in codes
        if c <> "auto" and c = locale then return c
    end for
    return "en"
end function
