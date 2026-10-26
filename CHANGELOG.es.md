# Registro de cambios

Aquí están todos los cambios importantes de Nuvio TV para Roku. Este registro solo cubre el canal de Roku.

[English](CHANGELOG.md) · **Español**

## [0.0.5] - 2026-10-25

### Agregado
- Interfaz en francés, alemán, italiano, neerlandés, polaco, turco, rumano, checo y húngaro. Elígela en **Ajustes → Apariencia → Idioma de la interfaz**, o déjala en Automático para usar el idioma de tu Roku. Los textos usan las traducciones de Nuvio TV cuando el texto es el mismo.
- Aviso de nueva versión, como en Nuvio para Smart TV. Cuando sale un release nuevo en GitHub, el canal muestra una vez las novedades, con un código QR pequeño para descargarlo. Las novedades salen en español o en inglés según tu Roku, y en los demás idiomas con traducción automática.

### Cambiado
- El inicio aparece antes, sobre todo la primera vez o después de reinstalar el canal. Si un catálogo tarda, los demás aparecen a los pocos segundos en lugar de esperarlo, y el lento se agrega cuando llega.
- Los títulos en otros alfabetos (como japonés o chino) se traducen después de que aparecen las filas, así que ya no detienen todo el inicio.
- Con un idioma que no sea español ni portugués, la página del celular se abre en inglés.

### Corregido
- Los catálogos que respondían mientras el canal estaba ocupado podían marcarse como "tardó demasiado en responder" y quedar vacíos.
- La duración de la película en los detalles decía "min left" en inglés.

## [0.0.4] - 2026-10-25

### Agregado
- Saltar intro, resumen y créditos. Aparece un botón **Saltar** durante esas partes, y cada una también se puede saltar automáticamente (**Ajustes → Reproducción → Saltar segmentos**). Usa introdb.app, y AniSkip para anime.
- Tarjeta de siguiente episodio cerca del final de un episodio, con cuenta regresiva cuando la reproducción automática está activada. Aparece cuando empiezan los créditos si se conocen, o en el porcentaje o los minutos antes del final que elijas.
- Precarga de las fuentes del siguiente episodio antes de que aparezca la tarjeta.
- Opción para usar la primera fuente disponible cuando el siguiente episodio no tiene el mismo grupo de fuentes, o para mostrar la lista.
- **¿Sigues viendo?** en pantalla completa después de varios episodios seguidos, con Sí y No.
- Recomendaciones cerca del final de una película o del último episodio (necesita TMDB). Elige una para abrir sus detalles.
- Avisos de contenido (desnudez, violencia, lenguaje soez, drogas y escenas de miedo) durante unos segundos al empezar un título.
- Ocultar subtítulos SDH y mostrar solo los subtítulos en tus idiomas preferidos.
- Estilo para los subtítulos de addons: tamaño, color, fondo, borde, negritas y altura. Los subtítulos que vienen dentro del video usan el estilo del Roku de **Configuración → Accesibilidad → Estilo de subtítulos**.
- Datos técnicos en pantalla con resolución, códec, audio y bitrate (**Ajustes → Avanzado**).
- Todos estos ajustes se sincronizan con tu cuenta de Nuvio.
- **Next up** en Seguir viendo: cuando terminas un episodio, el siguiente aparece en la fila para que sigas viendo.

### Corregido
- Los ajustes de tu cuenta de Nuvio TV ahora sí llegan al Roku (tráiler por inactividad, póster personalizado, regex, idioma de audio secundario, reusar el último enlace y los demás). Nuvio guarda cada valor junto con su tipo y el Roku los ignoraba. Los cambios que haces en el Roku también se envían en el formato que lee Nuvio TV. Ahora también se sincronizan el estilo de subtítulos y el nombre del addon y el tipo en los catálogos.
- Pósters, episodios, fotos del reparto y fotos de perfil redondeados de un solo lado en Rokus HD. Si todavía pasa, **Ajustes → Avanzado → Esquinas redondeadas** tiene otras opciones.
- El canal ya no se congela al cambiar a otro perfil.
- El buscador ya no convierte el póster enfocado en una tarjeta horizontal después de unos segundos.
- Si algo falla dentro del reproductor, el canal muestra el error en lugar de cerrarse.
- Puedes escribir tus claves de TMDB y MDBList en la TV en **Ajustes → Integraciones**, y guardar claves desde la página del celular ya no falla con "No se pudo conectar con el Roku".
- Una forma más de abrir enlaces .ts en Rokus que no podían reproducirlos.
- Los pósters y la tarjeta horizontal enfocada ya no muestran esquinas cuadradas fuera del marco de selección en Rokus HD.
- El logo del título en la portada del inicio carga más rápido y solo una vez, en tu idioma. El canal le pide a TMDB solo el logo primero, sin esperar el resto de los detalles, y recuerda los logos que ya encontró.
- La clave de MDBList viene del perfil de Nuvio que estás usando. Antes, la sincronización pasaba por todos tus perfiles y el último, sin clave, la borraba. El canal también vuelve a sincronizar cuando cambias de perfil. Una clave que escribiste en la TV o en la página del celular se conserva.
- Tu clave de TMDB también viene del perfil de Nuvio que estás usando, igual que la de MDBList. **Ajustes → Integraciones** muestra lo que el canal encontró en tu cuenta la última vez que revisó.
- Las claves escritas con el teclado de la TV se leen bien en las versiones nuevas del sistema de Roku, y cada ajuste también se guarda en los archivos del canal por si el almacenamiento del Roku está lleno.
- Los tráilers prefieren la región de tu TMDB y prueban una segunda forma de abrir los tráilers de YouTube antes de usar uno en inglés.
- El Roku guarda solo ajustes pequeños en su propio almacenamiento, que tiene un límite de 16 KB. Tu biblioteca y Seguir viendo lo llenaban, así que los cambios nuevos (como una clave de MDBList escrita en la TV) no se guardaban. Ahora viven en los archivos del canal.
- Las filas del inicio se actualizan en su lugar cuando los catálogos terminan de cargar, en vez de desaparecer y volver a cargar.
- El ícono del canal y la pantalla de carga tienen el tamaño correcto en Rokus HD.
- La sincronización con tu cuenta de Nuvio ya no reemplaza una clave que escribiste en la TV.
- La reproducción automática revisa qué puede reproducir tu Roku y nunca elige fuentes que no puede (HEVC / x265 en modelos sin HEVC, 4K cuando el Roku o la tele no están en 4K), aunque coincidan con tu regex. Si ninguna fuente se puede reproducir, muestra la lista. Cuando una de esas falla, el error dice por qué. Puedes desactivarlo en **Ajustes → Reproducción → Priorizar fuentes compatibles con Roku**.
- **Ajustes → Acerca de** muestra el modelo del Roku, el modo de video, si reproduce HEVC y el espacio libre.
- Las listas de Trakt en las colecciones fallaban con "Trakt (403)" porque no se mandaba el número de la lista. Las colecciones, compañías, cadenas y personas de TMDB guardadas con un ID numérico también cargaban títulos equivocados. Las dos cosas ya funcionan, y las listas de Trakt de una carpeta cargan al mismo tiempo en vez de una por una.
- El canal guardaba los pósters del inicio en segundo plano mientras navegabas, lo que hacía más lento todo lo demás (colecciones, fotos del reparto) y a veces hacía que los pósters dejaran de cargar. Ahora espera a que el inicio esté listo, descarga menos a la vez y se detiene en cuanto abres algo.
- Volver a reproducir una fuente después de salir ya no falla con "la conexión se cortó". Si el enlace no puede continuar donde ibas, el canal lo intenta de otra forma, y si eso también falla empieza desde el principio en lugar de mostrar un error.
- El canal ya no se congela al regresar al inicio después de abrir Ajustes.
- El IPTV y otros enlaces sin extensión de archivo vuelven a reproducirse. Desde la 0.0.3 el canal le daba al Roku una lista de formatos para probar y el Roku la rechazaba, así que la pantalla se quedaba en negro hasta "la conexión se cortó". Ahora el Roku primero detecta el formato por sí solo, como en la 0.0.2.

### Cambiado
- El README explica qué códecs no pueden reproducir algunos modelos de Roku.
- El README explica cómo mantener el Roku en 4K con **Ajustes → Tipo de pantalla → Detectar automáticamente**.
- El README y este registro de cambios también están en español.

### Problemas conocidos
- La clave de MDBList de tu cuenta de Nuvio todavía no llega al Roku en algunas cuentas. **Ajustes → Integraciones** muestra lo que el canal encontró en tu cuenta, para ayudar a encontrar la causa.

## [0.0.3] - 2026-10-24

### Agregado
- Pantalla de inicio de sesión de Nuvio la primera vez que abres el canal, con un código QR como en las otras apps de Nuvio. También puedes seguir sin cuenta y agregar addons desde tu celular o desde Ajustes en la TV.
- Interfaz y página del celular en portugués. Elígela en **Ajustes → Apariencia → Idioma de la interfaz**.
- Presiona `*` en Seguir viendo para ver las opciones de Nuvio TV: ir a detalles, reproducir manualmente, empezar desde el principio o quitarlo. Lo que quitas también se quita de tu cuenta de Nuvio.
- Presiona `*` en cualquier póster para ir a detalles, agregarlo o quitarlo de tu biblioteca, o marcarlo como visto o no visto. Los títulos vistos muestran una palomita, sincronizada con Nuvio.
- Página de detalles como en Nuvio: pestañas de temporadas, tarjetas de episodios con descripción, fecha, duración e imagen en el idioma de tus metadatos, reparto con fotos y el director o los creadores.
- Ajustes estilo Nuvio, QR de la cuenta, códigos de Trakt y Simkl, panel de Watch Party y pantalla para unirse.
- Tus colecciones activas de Nuvio aparecen en **Ajustes → Contenido y descubrimiento**, donde puedes activar o desactivar cada una.
- Carpetas de colecciones con fuentes de TMDB (listas, colecciones, personas, compañías, cadenas y descubrir) y listas de Trakt, no solo catálogos de addons.
- Todos los idiomas de TMDB de Nuvio TV, y listas completas de idiomas para audio y subtítulos.
- **Priorizar fuentes compatibles con Roku** en Ajustes → Reproducción: la reproducción automática deja al final los archivos REMUX con audio TrueHD o DTS-HD, y el 4K cuando tu tele no está en modo 4K.
- El reproductor muestra todas las pistas de audio que reporta el Roku, aunque se repitan idiomas, con el nombre de la pista y el formato.
- Los subtítulos de addons que llegan después de que empieza la reproducción se pueden elegir en el menú de subtítulos.
- La versión aparece en el Roku como 0.0.3 beta.
- Elige a un actor en la página de detalles para ver sus películas y series (necesita TMDB).
- Presiona `*` en el botón Reproducir de la página de detalles para elegir la fuente manualmente.
- Pantalla de carga como en Nuvio mientras se abre una fuente: el fondo del título con su logo en el centro.
- Lista de fuentes como en Nuvio: un botón para actualizar y un filtro por addon que puedes elegir, que se desplaza de lado cuando hay muchos.
- Las carpetas de colecciones muestran su GIF al enfocarlas, como en Nuvio (necesita un Roku que soporte imágenes animadas; los GIF se convierten a WebP animado), y su logo y video en la portada del inicio.
- Cuando una carpeta de colección no puede cargar una fuente, el canal dice cuál y por qué (por ejemplo un código de error de Trakt o un addon que no está instalado).
- Los títulos en chino, japonés, coreano y otros alfabetos que el Roku no puede mostrar aparecen con su nombre de TMDB en el idioma de tus metadatos, o en inglés.
- En los canales en vivo de Xtream que se reproducen por HLS con una sola pista de audio, el menú de audio ofrece cargar todas las pistas desde el enlace `.ts` original. Si el Roku no puede abrirlo, regresa a la versión que sí funciona.
- El idioma de la interfaz se elige de una lista, y el aviso para volver a abrir el canal aparece en el idioma que elegiste.

### Cambiado
- El inicio se abre al instante con las últimas filas cargadas y las actualiza en segundo plano, y los catálogos cargan en paralelo. Ya no aparecen los mensajes de "addons cargados".
- Seguir viendo reproduce directo con la última fuente que usaste en vez de abrir la página de detalles. Si ese enlace venció, vuelve a buscar fuentes.
- Los menús de opciones, audio, subtítulos y fuentes usan el estilo de diálogo de Nuvio TV.
- Los pósters y las tarjetas tienen esquinas más redondeadas, como en Nuvio, y el marco de selección las sigue.
- Los tráilers buscan primero un tráiler en el idioma de tus metadatos.
- Solo se envían a tu cuenta los ajustes que cambias en el Roku y que ya existen en tu cuenta de Nuvio. Los catálogos del inicio que solo existen en el Roku ya no se agregan a tu cuenta.
- Seguir viendo desde tu cuenta muestra una entrada por serie (el último episodio) y conserva el avance local que todavía no se ha enviado.
- Las tarjetas de colecciones solo muestran el nombre de la carpeta cuando la colección lo indica.
- La biblioteca ya no muestra Seguir viendo, y sus pósters no se expanden ni reproducen tráilers.
- La fuente enfocada solo se resalta, sin el borde exterior, y el resaltado se mueve con la lista en vez de aparecer tarde.
- Los emojis se quitan de todos los títulos, nombres y descripciones, no solo en las fuentes.
- Las imágenes redondas, íconos, interruptores y botones del reproductor se dibujan a su tamaño exacto, así que se ven más nítidos.
- Los pósters del inicio se guardan en el Roku después de cargar, para que no vuelvan a cargar al regresar.

### Corregido
- Watch Party terminaba al pausar, y los otros dispositivos no seguían al Roku. Ahora el Roku manda su estado a la sala al instante y solo sale cuando la sala de verdad termina.
- Continuar desde Seguir viendo empezaba desde el principio en algunas fuentes.
- Adelantar mucho regresaba a la posición anterior.
- Algunas fuentes cerraban el reproductor sin error, y por eso podía desaparecer el avance de Seguir viendo. Ahora el canal reintenta el enlace en otros formatos antes de mostrar un error.
- Cambiar la pista de audio a veces regresaba a la original.
- Cambiar de fuente desde el reproductor a veces no hacía nada o cerraba el reproductor.
- Los subtítulos de addons solo cargaban a veces.
- Los canales en vivo de Xtream IPTV (`.ts`) no se reproducían. Ahora el canal prueba la versión HLS del enlace.
- Los logos de las películas no aparecían en el reproductor ni en la pantalla de pausa al volver a reproducir un título.
- Agregar un título a Mi lista desde una fila horizontal guardaba la imagen horizontal en vez del póster.
- Las colecciones mostraban el nombre de la carpeta sobre la portada aunque estuviera oculto en la colección.
- La clave de MDBList no llegaba de tu cuenta de Nuvio en algunos perfiles.
- Las tarjetas de Trakt y MDBList en la página del celular estaban rotas.
- Solo se podía elegir con OK la primera fuente de la lista.
- `*` en Seguir viendo abría Ajustes.
- Después de abrir el menú de audio, subtítulos o fuentes en el reproductor, el control dejaba de responder hasta cerrar el canal.
- Los catálogos del inicio que tardaban mucho desaparecían unos segundos después de cargar. Ahora conservan los últimos títulos cargados.
- El marco de selección en pósters, tarjetas y episodios se cortaba arriba y sus esquinas no coincidían. Ahora queda dentro de la tarjeta.
- Los tráilers y fondos en la tarjeta expandida tenían esquinas cuadradas.
- El marco de selección en la lista de fuentes aparecía tarde y podía quedarse en varias fuentes a la vez. La última fuente se cortaba.
- Los interruptores y botones se veían cortados en las orillas.
- Los emojis en los nombres de colecciones y catálogos aparecían como cuadros vacíos.
- Mi lista guardaba por un momento la imagen horizontal antes de cambiar al póster.
- Los canales en vivo aparecían en Seguir viendo.
- Atrás en la pantalla de perfiles abierta desde la app regresa a tu perfil en vez de cerrar el canal.
- El canal se congelaba después de quitar el último título de Mi lista.
- Guardar la clave de TMDB o MDBList desde la página del celular a veces decía que no se podía conectar con el Roku.
- Las carpetas de colecciones con IDs de lista guardados como números decimales no cargaban.
- Los logos e imágenes de colecciones enlazados desde páginas de GitHub (`github.com/.../blob/...?raw=true`) no aparecían.
- Las fuentes de colecciones de TMDB con calificación máxima de 0 no regresaban títulos.
- La sección Acerca de todavía decía versión 2.2.0.
- Las listas de Trakt en las colecciones ahora reintentan con tu cuenta de Trakt y con películas y series juntas cuando la primera consulta regresa vacía.

## [0.0.2] - 2026-10-21

### Agregado
- Sincronización con Nuvio en ambos sentidos. El canal se sincroniza con tu cuenta de Nuvio cada vez que se abre, y los cambios hechos en el Roku se envían unos segundos después: addons, Mi lista, avance de Seguir viendo, ajustes y orden de los catálogos del inicio. Solo se actualizan en tu cuenta los ajustes que cambias en el Roku.
- Los addons se leen de la lista de addons de tu cuenta para cada perfil, como en Nuvio TV para Smart TVs.
- Orden de los catálogos del inicio, catálogos ocultos y nombres personalizados de catálogos desde tu cuenta de Nuvio.
- Colecciones de Nuvio en el inicio, en el mismo lugar que en Nuvio. Al abrir una carpeta se muestran sus catálogos.
- Fotos de perfil de tu cuenta de Nuvio, en la pantalla de perfiles y en el menú lateral.
- El color del tema de Nuvio se usa como color de acento del canal.
- Tráiler del póster enfocado, en la portada del inicio o en la tarjeta expandida, como en Nuvio.
- Trakt, Simkl y TMDB funcionan sin crear tus propias apps ni claves. Solo tienes que vincular tu cuenta de Trakt o Simkl.
- Tarjetas de Seguir viendo como en Nuvio: tiempo restante, número de episodio, título, nombre del episodio y una barra de avance delgada. Al enfocar una se muestra arriba el episodio, el género, el año y el tiempo restante.
- Los catálogos horizontales y cuadrados conservan su forma en vez de mostrarse como pósters.
- Las banderas en las descripciones de las fuentes se muestran como el nombre del idioma (por ejemplo Latino, Castellano o English).
- Adelantar en el reproductor se acelera mientras más tiempo mantienes o sigues presionando izquierda y derecha: 10 segundos, luego 30 segundos, 1 minuto y 2 minutos.

### Cambiado
- El póster expandido ahora se ve como en Nuvio (fondo con solo el logo o el título), y los pósters de después se recorren a la derecha en vez de quedar tapados.
- Las filas mantienen el título enfocado en la orilla izquierda, como en Nuvio.
- El marco de selección usa tu color de acento y se ajusta a los pósters y tarjetas.
- La página de detalles se oculta mientras se reproduce su tráiler. Cualquier botón la regresa.
- Trakt y Simkl ya no piden un Client ID ni Client Secret en la página del celular.
- Nombre y descripción más claros para el ajuste del color del perfil.
- El menú lateral de Ajustes ahora cabe con todas las secciones.

### Corregido
- Ajustes no se abría.
- No se podían cambiar las pistas de audio y subtítulos en el reproductor.
- El póster expandido aparecía en la esquina superior izquierda de la pantalla.
- Pixeles oscuros alrededor del póster expandido y detrás de las esquinas de los pósters.
- La barra de avance se quedaba al inicio en videos donde el Roku no reporta la duración.
- La página del celular podía dejar de responder ("No se pudo conectar con el Roku"). Ahora muestra el error real y se reinicia sola.
- Los emojis que el Roku no puede mostrar aparecían como cuadros vacíos en las descripciones de las fuentes.
- El marco de selección se cortaba en el lado izquierdo de las filas.
- Algunas revisiones con valores faltantes podían detener el canal en Rokus reales.

## [0.0.1] - 2026-10-21

Primer release público (primera beta).

### Agregado
- Interfaz en inglés, además del español. Elígela en **Ajustes → Apariencia → Idioma de la interfaz** (Automático sigue el idioma de tu Roku). La página del celular usa el mismo idioma.
- Lista de fuentes estilo Nuvio: filtros por addon, texto completo del formatter del addon, logo del addon y opción para continuar o empezar de nuevo.
- Insignias integradas en las fuentes para calidad, HDR / Dolby Vision, códec, audio y tamaño del archivo.
- Insignias Fusion, importadas de tu cuenta de Nuvio o desde una URL de JSON de insignias en la página del celular, arriba o abajo de cada fuente.
- Modos de reproducción automática: Manual, Primera fuente y Coincidencia por regex. Usan las mismas reglas regex que Nuvio TV, incluidos los preajustes, los addons permitidos y el tiempo de espera.
- Reusar el último enlace, la misma fuente para el siguiente episodio y recordar la fuente de cada serie.
- Idiomas de audio preferido y secundario (Sistema, Original o un idioma específico).
- Idiomas de subtítulos preferido y secundario, además de subtítulos forzados.
- Patrones de URL para pósters personalizados con los marcadores de Nuvio (`{id}`, `{imdb_id}`, `{tmdb_id}`, `{type}` y más). El canal regresa al póster original si el personalizado no carga.
- Póster enfocado que se expande a una tarjeta horizontal después de un momento, con tráiler opcional sin sonido.
- Tráilers: un botón de tráiler en la página de detalles y reproducción automática opcional. Las fuentes son primero IMDb, luego los tráilers del propio título y luego YouTube.
- Sincronización con la cuenta de Nuvio de los ajustes de reproductor, reproducción automática, diseño, tráilers, TMDB, MDBList e insignias, además de tu clave de API de MDBList.
- Secciones **Fuentes** y **Tráilers** en Ajustes.
- Opciones en la página del celular para el regex de reproducción automática, el patrón de pósters personalizados, las insignias Fusion y regresar al servidor oficial.

### Cambiado
- La dirección del servidor de Nuvio está en `components/Config.brs`. Está vacía en el código fuente, como en los repositorios oficiales de Nuvio, y llena en los releases.

### Corregido
- Ajustes sincronizados con nombres en mayúsculas y minúsculas mezcladas que a veces no se aplicaban.

## Versiones internas antes de la 0.0.1

### 2026-10-20

#### Agregado
- Inicio de sesión con tu cuenta de Nuvio por QR o correo, que trae perfiles, addons, biblioteca, Seguir viendo y ajustes.
- Metadatos de TMDB en tu idioma y calificaciones de MDBList.
- Registro de lo que ves en Trakt y Simkl.
- Idiomas preferidos de audio y subtítulos.
- Seguir viendo en horizontal con imágenes de los episodios, configurable a póster.
- Selector de perfiles con fondo negro teñido del color del perfil.
- Pantalla de Ajustes estilo Nuvio.

#### Cambiado
- La pantalla de pausa ahora espera más antes de aparecer.

#### Corregido
- Detección de pistas de subtítulos y audio en el reproductor.
- Cambiar de fuente mientras algo ya se estaba reproduciendo.
- La última fila del inicio se cortaba.

### 2026-10

#### Agregado
- Canal reconstruido con interfaz estilo Nuvio: barra lateral, portada del inicio, página de detalles, vista de episodios, reproductor propio y pantalla de pausa.
- Addons estilo Stremio para catálogos, metadatos, fuentes y subtítulos.
- Búsqueda en todos los addons.
- Perfiles, Mi lista y Seguir viendo.
- Página del celular para agregar addons, importar colecciones y administrar catálogos y perfiles.
- Logos y marca reales de Nuvio (fork no oficial, con permiso).

#### Corregido
- Controles y ajustes que no respondían.
- La página del celular no hacía nada al enviar addons.
- Catálogos vacíos.
- Faltaban fuentes para títulos de catálogos basados en TMDB.
