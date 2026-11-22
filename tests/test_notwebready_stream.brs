' Regression test: a stream whose behaviorHints.notWebReady is true needs custom
' HTTP headers that the Roku player cannot send. It must still be listed, but
' marked, and selecting it must show a message instead of starting playback.
'
' Reference behavior (original JS client):
'   js/ui/screens/player/playerScreenMethods-17-get-web-header-restricted-stream-message.js
' The field is read from behaviorHints in js/core/player/pluginManager.js.
'
' This test drives the real Stream_Build() and playStream(). playStream() runs
' without a SceneGraph tree, so every side effect of the normal playback path is
' mocked; only the early refusal is under test.

sub main()
    path = "pkg:/tests/fixtures/notwebready.streams.json"
    text = ReadAsciiFile(path)
    if text = ""
        print "FAIL: no se pudo leer el fixture " + path
        print "RESULT: FAIL"
        return
    end if
    data = ParseJson(text)
    if type(data) <> "roAssociativeArray" or type(data.streams) <> "roArray" or data.streams.Count() <> 2
        print "FAIL: el fixture debe traer dos streams"
        print "RESULT: FAIL"
        return
    end if

    Mock_Install()

    addon = { name: "Addon de prueba", logo: "", order: 1 }
    normal = Stream_Build(data.streams[0], data.streams[0].url, addon, [], false)
    blocked = Stream_Build(data.streams[1], data.streams[1].url, addon, [], false)

    failures = 0
    failures = failures + Expect_Field("normal", normal, false)
    failures = failures + Expect_Field("notWebReady", blocked, true)
    failures = failures + Expect_Mark(blocked, true)
    failures = failures + Expect_Mark(normal, false)
    ' The proxy headers keep being parsed as before.
    if type(blocked.headers) <> "roArray" or blocked.headers.Count() <> 2
        print "FAIL: los proxyHeaders.request no se parsearon (" + Str_Of(blocked.headers) + ")"
        failures = failures + 1
    else
        print "PASS: proxyHeaders.request parseado (" + blocked.headers.Count().ToStr() + " encabezados)"
    end if

    ' Selecting the notWebReady stream must show the notice and not touch the
    ' playback state (sourceIndex is set right after the guard).
    m.toast = ""
    m.ctx = { streams: [normal, blocked], fromStart: false, videoId: "" }
    playStream(1, 0)
    if m.toast <> Expected_Message()
        print "FAIL: la reproduccion no mostro el aviso (toast='" + m.toast + "')"
        failures = failures + 1
    else
        print "PASS: aviso mostrado: " + m.toast
    end if
    if m.ctx.sourceIndex <> invalid
        print "FAIL: playStream toco el estado de reproduccion para un stream notWebReady"
        failures = failures + 1
    else
        print "PASS: playStream no inicio la reproduccion del stream notWebReady"
    end if

    ' The normal stream must keep going through the playback path.
    m.toast = ""
    m.ctx = { streams: [normal, blocked], fromStart: false, videoId: "" }
    playStream(0, 0)
    if m.ctx.sourceIndex <> 0
        print "FAIL: el stream normal no llego al camino de reproduccion"
        failures = failures + 1
    else
        print "PASS: el stream normal sigue el camino de reproduccion"
    end if

    if failures = 0
        print "RESULT: PASS (campo, marca en la lista y aviso de reproduccion)"
    else
        print "RESULT: FAIL (" + failures.ToStr() + " comprobaciones fallidas)"
    end if
end sub

' Mock bodies cannot see local variables, so state shared with them lives in m.
sub Mock_Install()
    ' brs has no roByteArray.FromAsciiString(), which the real Str_Glyphs uses.
    _brs_.mockFunction("str_glyphs", function(text as string) as string
        return text
    end function)

    _brs_.mockFunction("toast_show", sub(text as string)
        m.toast = text
    end sub)

    ' Everything below belongs to the successful playback path, which is not under
    ' test here but must exist so the base (unpatched) playStream can run.
    _brs_.mockFunction("showplayer", sub(index as integer)
        m.shown = index
    end sub)

    _brs_.mockFunction("stream_format", function(url as string) as string
        return ""
    end function)

    _brs_.mockFunction("stream_attempts", function(url as string) as object
        return []
    end function)

    _brs_.mockFunction("st_resumefor", function(videoId as string) as integer
        return 0
    end function)

    _brs_.mockFunction("probe_needed", function(url as string) as boolean
        return false
    end function)

    _brs_.mockFunction("hlsp_needed", function(url as string) as boolean
        return false
    end function)

    _brs_.mockFunction("play_begin", sub()
    end sub)

    _brs_.mockFunction("load_status", sub(text as string)
    end sub)
end sub

function Expected_Message() as string
    return L("Este enlace necesita encabezados web que Roku no puede enviar. Elige otra fuente o contacta al proveedor del addon.")
end function

function Mark_Text() as string
    return L("Requiere encabezados")
end function

function Expect_Field(label as string, s as object, want as boolean) as integer
    if not IsBool(s.notWebReady) or s.notWebReady <> want
        print "FAIL: " + label + " notWebReady no se parseo como " + want.ToStr()
        return 1
    end if
    print "PASS: " + label + " notWebReady=" + s.notWebReady.ToStr()
    return 0
end function

function Expect_Mark(s as object, want as boolean) as integer
    label = "stream"
    if type(s) = "roAssociativeArray" then label = Str_Of(s.name)
    has = Has_Mark(s, Mark_Text())
    if has <> want
        print "FAIL: " + label + " marca '" + Mark_Text() + "' presente=" + has.ToStr()
        return 1
    end if
    print "PASS: " + label + " marca '" + Mark_Text() + "' presente=" + has.ToStr()
    return 0
end function

function Has_Mark(s as object, mark as string) as boolean
    if type(s) <> "roAssociativeArray" then return false
    if type(s.badges) = "roArray"
        for each b in s.badges
            if type(b) = "roAssociativeArray" and Str_Of(b.n) = mark then return true
        end for
    end if
    if type(s.chips) = "roArray"
        for each c in s.chips
            if IsStr(c) and c = mark then return true
        end for
    end if
    return false
end function
