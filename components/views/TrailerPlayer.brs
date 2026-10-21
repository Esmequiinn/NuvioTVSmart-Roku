sub init()
    L_Texts(["loading"])
    m.video = m.top.findNode("video")
    m.loading = m.top.findNode("loading")
    m.video.observeField("state", "onState")
end sub

sub onTrailer()
    t = m.top.trailer
    if t = invalid or Str_Of(t.url) = ""
        m.video.control = "stop"
        return
    end if
    content = Trailer_Content(t)
    m.loading.visible = true
    m.video.EnableCookies()
    m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
    m.video.InitClientCertificates()
    m.video.content = content
    m.video.control = "play"
    m.video.setFocus(true)
end sub

sub onState()
    state = m.video.state
    m.loading.visible = state = "buffering" or state = "none"
    if state = "finished" or state = "error"
        m.video.control = "stop"
        m.top.event = { type: "close", error: state = "error" }
    end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false
    if key = "back"
        m.video.control = "stop"
        m.top.event = { type: "close", error: false }
        return true
    end if
    return false
end function
