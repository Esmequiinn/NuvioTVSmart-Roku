# Nuvio TV para Roku

[English](README.md) · **Español**

<div align="center">

  <img src="assets/brand/app_logo_wordmark.png" alt="Nuvio" width="300" />

  <p>
    Una app de contenido gratuita y de código abierto para tu celular, tu computadora y la tele que ya tienes.
    <br />
    Tú pones las fuentes. Nuvio las convierte en una biblioteca con portadas, calificaciones, subtítulos y tu avance guardado en todas tus pantallas.
  </p>

  [Sitio web](https://nuvio.tv) · [Releases de GitHub](https://github.com/NuvioMedia/NuvioTVSmart/releases/latest) · [Apoya a Nuvio](https://nuvio.tv/support)

</div>

Este es un canal de Roku no oficial basado en [Nuvio](https://github.com/NuvioMedia). Está en **beta**: la versión actual es la **0.0.7**. Te permite explorar y reproducir contenido de addons estilo Stremio en cualquier Roku TV o stick de Roku.

> **Esta no es una app oficial de Nuvio** y no está afiliada ni respaldada por el equipo de Nuvio. No aloja, guarda ni distribuye ningún contenido. Todo lo que ves viene de los addons que instalas.

> **Aquí se usó IA, así que lo que pienses sobre eso guárdatelo, yo solo quería tener Nuvio en mi Roku.**

---

## Funciones

- Addons estilo Stremio: catálogos, metadatos, fuentes y subtítulos
- Interfaz estilo Nuvio: barra lateral, portada del inicio, selector de perfiles, página de detalles, vista de episodios y pantalla de pausa
- Reproductor propio con cambio de fuente, pistas de audio y subtítulos
- Saltar intro, resumen y créditos (introdb.app, y AniSkip para anime), con salto automático opcional
- Tarjeta de siguiente episodio con cuenta regresiva, precarga del siguiente episodio y **¿Sigues viendo?** en pantalla completa
- Recomendaciones al terminar una película y avisos de contenido al empezar un título
- Estilo para los subtítulos de addons, filtro de subtítulos SDH y solo subtítulos en tus idiomas preferidos
- Datos técnicos de la reproducción en pantalla
- **Next up** en Seguir viendo al terminar un episodio
- Búsqueda en todos tus addons, con búsquedas recientes
- Descubrir: explora cualquier catálogo de tus addons por tipo, catálogo y género, desde Buscar o con su propio lugar en el menú lateral
- Perfiles, con addons compartidos o por perfil
- Mi lista y Seguir viendo
- Página de configuración desde el celular: agrega addons, importa colecciones y administra catálogos y ajustes desde el navegador de tu celular
- Pantalla de inicio de sesión estilo Nuvio la primera vez que abres el canal, o sigue sin cuenta y agrega addons desde el celular o la TV
- Inicio de sesión con tu cuenta de Nuvio (QR o correo) con sincronización en ambos sentidos de perfiles, addons, biblioteca, avance, ajustes y catálogos del inicio
- Colecciones de Nuvio (con fuentes de addons, TMDB y Trakt), fotos de perfil y color del tema de tu cuenta
- Watch Party con tu cuenta de Nuvio
- Opciones de Nuvio TV con el botón `*`: ir a detalles, reproducir manualmente, empezar desde el principio o quitar de Seguir viendo, y agregar a la biblioteca o marcar como visto en cualquier póster
- Página de detalles como en Nuvio: episodios con descripción e imagen en el idioma de tus metadatos, calificaciones, reparto y equipo
- Metadatos de TMDB en tu idioma y calificaciones de MDBList
- Registro de lo que ves en Trakt y Simkl, solo vincula tu cuenta
- Funciona con servicios debrid a través de tus addons (por ejemplo AIOStreams)
- Reproducción automática: primera fuente, manual o por regex, compatible con tus patrones regex de Nuvio TV
- Lista de fuentes estilo Nuvio con el texto completo del formatter, insignias de calidad e insignias Fusion
- Patrones de URL para pósters personalizados (marcadores estilo RPDB)
- Tráilers de IMDb y YouTube, en la página de detalles, la portada del inicio o la tarjeta expandida
- Póster enfocado que se expande a una tarjeta horizontal
- Catálogos horizontales y cuadrados
- Interfaz en español, inglés, portugués, francés, alemán, italiano, neerlandés, polaco, turco, rumano, checo y húngaro
- Inicio rápido: el último inicio se abre al instante mientras los catálogos se actualizan en segundo plano
- Aviso de nueva versión con las novedades y un código QR para descargarla
- Tráiler en pantalla completa en el inicio después de unos segundos en un título, como en Nuvio TV para Android

## Estado

Algunas funciones todavía no se han probado. Si pruebas alguna de las marcadas como **Sin probar**, abre un issue y cuéntanos cómo te fue.

| Función | Estado |
| --- | --- |
| Addons de fuentes HTTP (enlaces directos `http`/`https`) | ✅ Funciona |
| Addons de catálogo | ✅ Funciona |
| Addons de metadatos | ✅ Funciona |
| Idioma de los metadatos | ✅ Funciona |
| Reproductor de fuentes (reproducir y cambiar de fuente) | ✅ Funciona |
| Búsqueda | ✅ Funciona |
| Mi lista | ✅ Funciona |
| Portada del inicio | ✅ Funciona |
| Barra lateral | ✅ Funciona |
| Vista de episodios | ✅ Funciona |
| Página de configuración desde el celular (agregar addons desde el celular) | ✅ Funciona |
| Pantalla de ajustes | ✅ Funciona |
| Servicios debrid (a través de addons como AIOStreams) | ✅ Funciona |
| Cambiar pistas de audio y subtítulos | ✅ Funciona |
| Tráilers | ✅ Funciona |
| Póster enfocado que se expande | ✅ Funciona |
| Integración con TMDB | ✅ Funciona |
| Integración con MDBList | ✅ Funciona |
| Trakt | ⚠️ Sin probar |
| Simkl | ⚠️ Sin probar |
| Inicio de sesión y sincronización con tu cuenta de Nuvio | ✅ Funciona |
| Fuentes con el texto del formatter del addon | ✅ Funciona, pero sin emojis |
| Insignias (calidad, HDR, códec, audio, tamaño y Fusion) | ✅ Funciona |
| Seguir viendo en horizontal | ✅ Funciona |
| Importar colecciones | ✅ Funciona |
| Colecciones de Nuvio | ✅ Funciona |
| Sincronización del Roku hacia tu cuenta de Nuvio | ✅ Funciona |
| Fotos de perfil y color del tema desde Nuvio | ✅ Funciona |
| Catálogos horizontales y cuadrados | ✅ Funciona |
| Reproducción automática (primera fuente y patrón regex) | ✅ Funciona |
| Reusar el último enlace y la misma fuente para el siguiente episodio | ✅ Funciona |
| Idiomas preferidos y secundarios de audio y subtítulos | ✅ Funciona |
| Patrones de URL para pósters personalizados | ⚠️ Sin probar |
| Interfaz en inglés | ✅ Funciona |
| Interfaz en portugués | ✅ Funciona |
| Interfaz en francés, alemán, italiano, neerlandés, polaco, turco, rumano, checo y húngaro | ⚠️ Sin probar |
| Aviso de nueva versión | ✅ Funciona |
| Descubrir | ✅ Funciona |
| Búsquedas recientes | ✅ Funciona |
| Tráiler en pantalla completa en el inicio | ✅ Funciona |
| Cuenta de MDBList (QR) | ✅ Funciona |
| Watch Party | ✅ Funciona |
| Menú de opciones con `*` y quitar títulos de Seguir viendo | ✅ Funciona |
| Colecciones con fuentes de TMDB y Trakt | ⚠️ Sin probar |
| Tarjeta de siguiente episodio | ✅ Funciona |
| ¿Sigues viendo? | ✅ Funciona |
| Recomendaciones al terminar una película | ✅ Funciona |
| Avisos de contenido | ✅ Funciona |
| Saltar intro, resumen y créditos | ✅ Funciona |
| Estilo de subtítulos y filtro SDH | ⚠️ Sin probar |
| Datos técnicos de la reproducción | ⚠️ Sin probar |
| Next up en Seguir viendo | ⚠️ Sin probar |
| Clave de MDBList desde tu cuenta de Nuvio | ✅ Funciona |

### Limitaciones conocidas

- Roku solo puede reproducir enlaces directos. Los torrents, magnets y enlaces externos se omiten.
- Los formatos que se pueden reproducir dependen del modelo de tu Roku (MP4, MKV, HLS y DASH son los más comunes).
- Algunos modelos de Roku, como el Roku Express, no pueden decodificar algunos códecs de video, como HEVC (x265), 10 bits o HDR. El canal revisa qué puede reproducir tu Roku y la reproducción automática nunca elige esas fuentes, aunque coincidan con tu regex. Si eliges una tú, puede fallar con "la conexión se cortó" o con un error de códec. En **Ajustes → Acerca de** dentro del canal puedes ver el modelo de tu Roku y si puede reproducir HEVC.
- En teles de 720p el Roku reduce la interfaz, así que los marcos de selección y los botones se ven menos nítidos que en teles 1080p o 4K.
- Roku no puede decodificar audio TrueHD ni DTS-HD, que usan la mayoría de los archivos REMUX. Esas pistas de audio no aparecen en el reproductor. El canal prefiere otras fuentes para la reproducción automática.
- El 4K (HEVC arriba de 1080p) solo se reproduce cuando tu Roku y tu tele están en modo 4K. Los canales no pueden cambiar el modo de pantalla, así que configúralo en tu Roku en **Ajustes → Tipo de pantalla → Detectar automáticamente**. Si tu tele soporta 4K, el Roku se quedará en 4K.
- Los GIF animados de las colecciones solo se mueven en los modelos de Roku que soportan imágenes animadas. Los modelos más viejos muestran la imagen de portada.
- Los perfiles creados en el Roku y los cambios a las colecciones no se envían a tu cuenta de Nuvio. Las colecciones solo se pueden ver.
- Roku no puede mostrar emojis. Las banderas en las descripciones de las fuentes se muestran como el nombre del idioma y los demás emojis se quitan.
- Watch Party revisa la sala cada 2.5 segundos y manda al instante los cambios de reproducir, pausar y adelantar, así que puede haber 1 o 2 segundos de diferencia con las demás personas.
- Los plugins de Nuvio no están disponibles, porque necesitan JavaScript y Roku no puede ejecutarlo.

## Instalación

El canal se instala con el Modo Desarrollador de Roku (sideload). Solo tienes que activarlo una vez.

1. **Descarga el canal.** Baja el `.zip` más reciente de la página de [Releases](../../releases). No lo descomprimas.
2. **Activa el Modo Desarrollador.** Con el control de tu Roku presiona: `Inicio` ×3, `Arriba` ×2, `Derecha`, `Izquierda`, `Derecha`, `Izquierda`, `Derecha`. Acepta el acuerdo, elige una contraseña y deja que el Roku se reinicie. Anota la dirección IP que aparece (por ejemplo `192.168.1.50`).
3. **Abre el instalador.** En una computadora o celular conectado al mismo Wi-Fi, abre `http://IP_DE_TU_ROKU` en el navegador. Entra con el usuario `rokudev` y la contraseña que elegiste.
4. **Sube el zip.** Haz clic en **Upload**, elige el `.zip` que descargaste y haz clic en **Install with zip**. El canal se abre solo cuando termina.
5. **Para actualizar.** Repite los pasos 3 y 4 con el `.zip` nuevo. Tus perfiles y addons se conservan.

Solo se puede tener un canal en modo desarrollador a la vez. Aparece en el inicio de tu Roku como **Nuvio TV**.

## Configuración

Con el canal abierto, entra a `http://IP_DE_TU_ROKU:8888` desde un celular o computadora conectado al mismo Wi-Fi. Desde ahí puedes:

- Agregar addons (pega la dirección del `manifest.json`) o importar una colección
- Mostrar, ocultar y reordenar las filas del inicio
- Crear perfiles
- Iniciar sesión en tu cuenta de Nuvio
- Pegar tu propia clave de TMDB o MDBList (opcional)
- Configurar el regex de reproducción automática, el patrón de pósters personalizados y las insignias Fusion

También puedes agregar un addon desde tu computadora con el control externo de Roku: `curl -d "" "http://IP_DE_TU_ROKU:8060/launch/dev?addon_url=URL_DEL_MANIFEST"`

### Claves de API y cuentas

El `.zip` del release ya trae las claves de TMDB, Trakt y Simkl, así que no tienes que crear nada:

| Servicio | Qué tienes que hacer |
| --- | --- |
| TMDB | Nada. Si quieres, puedes pegar tu propia clave en la página del celular (Cuenta) o escribirla en el Roku en **Ajustes → Integraciones**. |
| MDBList | Conecta tu cuenta con el código QR en **Ajustes → Integraciones → Cuenta de MDBList**, o usa tu clave gratis de [mdblist.com](https://mdblist.com): pégala en la página del celular (Cuenta), escríbela en el Roku en **Ajustes → Integraciones**, o llega sola si está guardada en tu cuenta de Nuvio. |
| Trakt | Vincula tu cuenta en el Roku en **Ajustes → Seguimiento** e ingresa el código. |
| Simkl | Vincula tu cuenta en el Roku en **Ajustes → Seguimiento** e ingresa el código. |

### Cuenta de Nuvio

Inicia sesión desde **Ajustes → Cuenta** en el Roku (código QR) o desde la página del celular (correo y contraseña). El Roku trae tus perfiles, fotos de perfil, addons, biblioteca, Seguir viendo, colecciones, catálogos del inicio y tus ajustes de Nuvio TV (idiomas de audio y subtítulos, reglas de reproducción automática, insignias, pósters personalizados, tráilers, color del tema y más). Se sincroniza cada vez que abres el canal, y los cambios que hagas en el Roku se envían a tu cuenta unos segundos después.

También puedes conectarte a un [servidor de Nuvio propio](https://github.com/NuvioMedia/self-host) desde la página del celular (**Cuenta → Tu propio servidor**).

## Compilar desde el código

El canal es BrightScript y SceneGraph puro, así que no hay nada que compilar. Comprime estos archivos y carpetas desde la raíz del repositorio e instala el resultado:

```
zip -r NuvioTV-Roku.zip manifest source components images web locale LICENSE
```

### Traducciones

Los textos de la interfaz están escritos en español en el código y se traducen con los archivos de `locale/` (`en.json`, `pt.json`, `fr.json`, `de.json`, `it.json`, `nl.json`, `pl.json`, `tr.json`, `ro.json`, `cs.json` y `hu.json`). Los idiomas nuevos usan las traducciones de Nuvio TV cuando el texto es el mismo, y el resto se tradujo para este canal, así que algunas frases pueden sonar raras. Los idiomas con otros alfabetos (como ruso, griego, árabe, chino o japonés) no se incluyeron porque puede que la fuente del sistema del Roku no los muestre. Los pull requests que agreguen o mejoren traducciones son bienvenidos.

## Contribuir

Los reportes de errores, problemas, ideas y sugerencias son muy bienvenidos. Abre un issue e incluye el modelo de tu Roku y la versión del sistema (**Configuración → Sistema → Acerca de**).

**¡También son muy bienvenidos nuevos testers!** Si tienes un Roku y algo de tiempo, prueba las funciones marcadas como **Sin probar** y cuéntame qué funciona y qué no.

## Créditos y licencia

- Basado en [Nuvio](https://github.com/NuvioMedia) del equipo de Nuvio. El nombre y los logos de Nuvio pertenecen a sus dueños.
- Con licencia [GNU General Public License v3.0](LICENSE).
