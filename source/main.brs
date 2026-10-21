sub Main(args as dynamic)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    lang = UiLanguage()
    table = {}
    if lang = "en"
        parsed = ParseJson(ReadAsciiFile("pkg:/locale/en.json"))
        if type(parsed) = "roAssociativeArray" then table = parsed
    end if
    screen.getGlobalNode().addFields({ uiLang: lang, i18n: table })

    scene = screen.CreateScene("MainScene")
    scene.observeField("exitApp", port)
    screen.Show()

    if type(args) = "roAssociativeArray" and args.addon_url <> invalid
        scene.externalInput = args
    end if

    input = CreateObject("roInput")
    input.SetMessagePort(port)

    while true
        msg = wait(0, port)
        msgType = type(msg)
        if msgType = "roSGScreenEvent"
            if msg.IsScreenClosed() then return
        else if msgType = "roSGNodeEvent"
            if msg.getField() = "exitApp" and msg.getData() = true then return
        else if msgType = "roInputEvent"
            info = msg.GetInfo()
            if info <> invalid then scene.externalInput = info
        end if
    end while
end sub

function UiLanguage() as string
    choice = "auto"
    section = CreateObject("roRegistrySection", "nuviotv")
    if section.Exists("settings")
        saved = ParseJson(section.Read("settings"))
        if type(saved) = "roAssociativeArray"
            value = saved["uiLang"]
            if value <> invalid and GetInterface(value, "ifString") <> invalid then choice = value
        end if
    end if
    if choice = "es" or choice = "en" then return choice
    locale = LCase(CreateObject("roDeviceInfo").GetCurrentLocale())
    if Left(locale, 2) = "es" then return "es"
    return "en"
end function
