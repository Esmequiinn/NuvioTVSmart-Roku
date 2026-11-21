' Regression test: a catalog whose extra params are required (for example the
' "genre" extra of Cinemeta movie/year) must be kept in the catalog list, but it
' must not produce a Home row, because the client cannot request it without
' parameters.
'
' The reference implementation (js/core/addons/homeCatalogs.js) separates
' "catalog is listed" from "catalog shows on Home":
'   catalogShouldShowOnHome(catalog) = not catalogRequiresExtras(catalog)
'
' This test drives CatalogTask.execute() with the real Cinemeta manifest, with
' every side effect (network, registry, cache, rendering) mocked, and then checks
' both halves of that contract on m.top.catalogs (listed) and m.visible (rows).

sub main()
    fixture = "pkg:/tests/fixtures/cinemeta.manifest.json"
    text = ReadAsciiFile(fixture)
    if text = ""
        print "FAIL: no se pudo leer el fixture " + fixture
        print "RESULT: FAIL"
        return
    end if
    manifest = ParseJson(text)
    if type(manifest) <> "roAssociativeArray" or type(manifest.catalogs) <> "roArray"
        print "FAIL: el fixture no contiene un manifiesto con catalogs"
        print "RESULT: FAIL"
        return
    end if

    ' Mock bodies cannot see local variables of this function, so publish the
    ' fixture through m, which is shared by every function of the interpreter.
    m.manifest = manifest
    Mock_Install()
    Run_Execute()

    failures = 0
    failures = failures + Expect_Listed("movie", "year")
    failures = failures + Expect_Listed("series", "year")
    failures = failures + Expect_Listed("series", "last-videos")
    failures = failures + Expect_Listed("movie", "top")
    failures = failures + Expect_NoRow("movie", "year")
    failures = failures + Expect_NoRow("series", "year")
    failures = failures + Expect_NoRow("series", "last-videos")
    failures = failures + Expect_Row("movie", "top")

    if failures = 0
        print "RESULT: PASS (" + Catalogs().Count().ToStr() + " catalogos listados, " + m.visible.Count().ToStr() + " filas de Home)"
    else
        print "RESULT: FAIL (" + failures.ToStr() + " comprobaciones fallidas)"
    end if
end sub

sub Mock_Install()
    ' Registry, network, cache, progress, servers and rendering are not under test.
    _brs_.mockFunction("st_addons", function() as object
        return ["https://v3-cinemeta.strem.io"]
    end function)

    _brs_.mockFunction("st_activeprofile", function() as object
        return { id: "test" }
    end function)

    _brs_.mockFunction("st_prefs", function() as object
        return { rowSize: 20, order: [], hidden: {} }
    end function)

    _brs_.mockFunction("home_readcache", function(addons as object) as dynamic
        return invalid
    end function)

    _brs_.mockFunction("home_writecache", sub(addons as object, manifests as object, catalogs as object, rows as object)
    end sub)

    ' First call fetches manifests, second one fetches catalog rows.
    _brs_.mockFunction("http_fetchhook", function(urls as object, timeoutMs as integer, metaLimit as integer, concurrency as integer, hook as dynamic) as object
        if timeoutMs = 15000
            return { data: [m.manifest], diag: ["ok"], codes: [200] }
        end if
        diag = []
        for each u in urls
            diag.Push("Sin respuesta")
        end for
        return { data: [], diag: diag, codes: [] }
    end function)

    _brs_.mockFunction("poster_pattern", function(name as string) as string
        return ""
    end function)

    _brs_.mockFunction("srv_homerows", function(limit as integer) as object
        return []
    end function)

    _brs_.mockFunction("progress_enrich", sub(manifests as object)
    end sub)

    ' Return the rows as-is so the test can inspect what Home would receive.
    _brs_.mockFunction("home_build", function(rows as object, prefs as object, withCollections as boolean) as object
        return rows
    end function)

    _brs_.mockFunction("names_translate", sub(items as object, net = true as boolean)
    end sub)

    _brs_.mockFunction("str_glyphs", function(s as string) as string
        return s
    end function)
end sub

sub Run_Execute()
    m.top = {}
    m.top.folder = invalid
    execute()
end sub

function Catalogs() as object
    if type(m.top.catalogs) = "roArray" then return m.top.catalogs
    return []
end function

function Find_Catalog(kind as string, id as string) as dynamic
    for each c in Catalogs()
        if type(c) = "roAssociativeArray" and Str_Of(c.kind) = kind and Str_Of(c.id) = id
            return c
        end if
    end for
    return invalid
end function

function Has_Row(kind as string, id as string) as boolean
    for each c in m.visible
        if Str_Of(c.kind) = kind and Str_Of(c.id) = id then return true
    end for
    return false
end function

function Expect_Listed(kind as string, id as string) as integer
    c = Find_Catalog(kind, id)
    if c = invalid
        print "FAIL: " + kind + "/" + id + " deberia seguir en la lista de catalogos y no esta"
        return 1
    end if
    if not Bool_Of(c.needsExtra, false) and (id = "year" or id = "last-videos")
        print "FAIL: " + kind + "/" + id + " esta listado pero sin marcar needsExtra"
        return 1
    end if
    print "PASS: " + kind + "/" + id + " listado (" + Str_Of(c.name) + ")"
    return 0
end function

function Expect_Row(kind as string, id as string) as integer
    if not Has_Row(kind, id)
        print "FAIL: " + kind + "/" + id + " deberia generar fila en Home y no lo hace"
        return 1
    end if
    print "PASS: " + kind + "/" + id + " con fila en Home"
    return 0
end function

function Expect_NoRow(kind as string, id as string) as integer
    if Has_Row(kind, id)
        print "FAIL: " + kind + "/" + id + " no deberia generar fila en Home"
        return 1
    end if
    print "PASS: " + kind + "/" + id + " sin fila en Home"
    return 0
end function
