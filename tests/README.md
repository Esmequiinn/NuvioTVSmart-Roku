# Tests

El repositorio no trae runner de BrightScript ni CI, así que el test se ejecuta
con el intérprete [brs](https://www.npmjs.com/package/brs) (probado con 0.45.0),
que se instala fuera del checkout:

```sh
mkdir -p /tmp/brsprobe && cd /tmp/brsprobe
npm i brs@0.45.0
```

Después, desde la raíz del repo:

```sh
tests/run.sh /tmp/brsprobe/node_modules/.bin/brs
```

`tests/run.sh` corre el test dos veces: contra `components/tasks/CatalogTask.brs`
del árbol de trabajo (debe pasar) y contra la versión de `HEAD` reconstruida con
`git show` (debe fallar). No hace falta stashear ni revertir nada.

## Qué cubre

`test_required_extra_catalog.brs` levanta `execute()` de `CatalogTask.brs` con el
manifiesto real de Cinemeta (`fixtures/cinemeta.manifest.json`) y todos los
efectos colaterales mockeados (`St_*`, `Http_FetchHook`, caché, `Home_Build`,
`Progress_Enrich`, `Srv_HomeRows`, `Names_Translate`, `Str_Glyphs`). Luego
comprueba el contrato que separa "está en la lista" de "aparece en Home":

- `movie/year`, `series/year` y `series/last-videos` (extra requerido) siguen en
  `m.top.catalogs`.
- Esos mismos catálogos no aparecen en `m.visible`, así que no generan fila.
- `movie/top` (sin extras requeridos) se comporta igual que antes: listado y con
  fila.

Los mocks se declaran con `_brs_.mockFunction`, y el manifiesto se pasa a través
de `m` porque el cuerpo de un mock no ve las variables locales del llamador.
