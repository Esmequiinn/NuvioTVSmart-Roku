sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    fs = CreateObject("roFileSystem")
    dir = "cachefs:/p/"
    if not fs.Exists(dir)
        if not fs.CreateDirectory(dir)
            dir = "tmp:/p/"
            if not fs.Exists(dir) then fs.CreateDirectory(dir)
        end if
    end if
    digest = CreateObject("roEVPDigest")
    port = CreateObject("roMessagePort")
    map = {}
    queue = []
    seen = {}
    for each url in m.top.urls
        if type(url) = "roString" or type(url) = "String"
            if Left(url, 4) = "http" and not seen.DoesExist(url) and queue.Count() < 500
                seen[url] = true
                digest.Setup("md5")
                ba = CreateObject("roByteArray")
                ba.FromAsciiString(url)
                path = dir + digest.Process(ba) + ".img"
                if fs.Exists(path)
                    map[url] = path
                else
                    queue.Push({ url: url, path: path })
                end if
            end if
        end if
    end for
    active = {}
    index = 0
    clock = CreateObject("roTimespan")
    while index < queue.Count() or active.Count() > 0
        while index < queue.Count() and active.Count() < 8
            job = queue[index]
            index = index + 1
            xfer = CreateObject("roUrlTransfer")
            xfer.SetMessagePort(port)
            xfer.SetUrl(job.url)
            xfer.EnableEncodings(true)
            if LCase(Left(job.url, 6)) = "https:"
                xfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
                xfer.InitClientCertificates()
            end if
            if xfer.AsyncGetToFile(job.path + ".part")
                job.xfer = xfer
                job.started = clock.TotalMilliseconds()
                active[xfer.GetIdentity().ToStr()] = job
            end if
        end while
        msg = wait(500, port)
        if type(msg) = "roUrlEvent" and msg.GetInt() = 1
            key = msg.GetSourceIdentity().ToStr()
            job = active[key]
            if job <> invalid
                active.Delete(key)
                if msg.GetResponseCode() = 200 and fs.Rename(job.path + ".part", job.path)
                    map[job.url] = job.path
                else
                    fs.Delete(job.path + ".part")
                end if
            end if
        end if
        now = clock.TotalMilliseconds()
        for each key in active.Keys()
            job = active[key]
            if now - job.started > 20000
                job.xfer.AsyncCancel()
                fs.Delete(job.path + ".part")
                active.Delete(key)
            end if
        end for
    end while
    m.top.result = map
end sub
