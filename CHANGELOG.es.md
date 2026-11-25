# Registro de cambios

Aquí están todos los cambios importantes de Nuvio TV para Roku. Este registro solo cubre el canal de Roku.

[English](CHANGELOG.md) · **Español**

## [0.1.9] - 2026-11-23

### Agregado
- **Edición con IPTV: películas y series de tus listas.** Las películas y series que vienen en tus listas M3U o cuentas Xtream ahora aparecen en el inicio como filas llamadas **IPTV - nombre del grupo**, con los pósters de la propia lista, y también salen en **Buscar** por nombre.
  - **Ver todo**: cuando un grupo tiene más títulos de los que caben en la fila, la última tarjeta es **Ver todo**, que abre el grupo completo en **Descubrir** y carga más conforme bajas. Cada grupo también aparece en **Descubrir** como catálogo.
  - Las filas de IPTV aparecen en **Ajustes → Catálogos** como cualquier otro catálogo, así que puedes ocultarlas o subirlas y bajarlas. En el inicio se muestran hasta 40 filas de IPTV a la vez; el resto está en Descubrir y en Buscar.
  - **Detalles correctos**: cuando abres un título, el canal usa el id de TMDB que manda tu proveedor Xtream cuando lo trae. Si no lo trae, busca el título en TMDB (con tu clave de TMDB, o en Cinemeta si no tienes) solo para ese título. Así tiene los detalles, la descripción, las imágenes y los episodios correctos como cualquier otra película o serie. Si no se encuentra el título, igual se abre con el nombre, el póster y los episodios de la lista para que puedas reproducirlo.
  - **Corregir coincidencia**: si un título se emparejó con la película o serie equivocada, presiona `*` sobre él y elige **Corregir coincidencia**, escribe el nombre (y el año si quieres) y elige el correcto de la lista. Déjalo vacío o elige **Volver a automático** para deshacerlo.
  - **Copias como fuentes**: cuando tus listas tienen la misma película varias veces (4K, 1080p, latino, subtitulada, en distintos grupos), aparece una sola vez en las filas y cada copia sale como su propia fuente **IPTV** con su calidad e idioma. Las películas de tus listas también salen como fuentes **IPTV** cuando abres la misma película desde cualquier otro catálogo.
  - **Episodios de series**: se reconocen sin importar cómo los nombre la lista: S02E01, S2 E1, T2 E1, T02C01, 2x01, "Temporada 2 Capítulo 1" o "Season 2 Episode 1", así cada episodio sale como fuente **IPTV** en la temporada y el episodio correctos.
  - Para que el Roku no se quede sin espacio ni se congele, se guardan hasta 25,000 películas y episodios por perfil en archivos chicos (unos 2 MB para una lista grande), y se actualizan en segundo plano junto con tus canales.

- **Zoom de pantalla (las dos ediciones).** El reproductor tiene un botón nuevo, **Pantalla**, junto a Fuentes y Audio, con **Original**, **Zoom ligero** y **Zoom (llenar pantalla)**. El zoom agranda la imagen para quitar las barras negras, recortando un poco las orillas. En la edición con IPTV está en el menú de `*` mientras ves un canal. Cada reproductor recuerda lo que elegiste. Roku no deja que los canales estiren (deformen) la imagen, por eso no hay opción de estirar.
- **Edición con IPTV: recorre la guía desde la barra del canal.** Viendo un canal, **Izquierda** y **Derecha** se mueven por la guía en la barra de abajo: lo que pasaron antes y lo que sigue, con su día, horario y descripción. Presiona **OK** en un programa que todavía no empieza para ponerle un recordatorio. Vuelve a lo que está pasando ahora cuando la barra se oculta o cambias de canal. Para cambiar entre las opciones de un canal, usa **<<** y **>>** (retroceder y adelantar).

### Corregido
- **Edición con IPTV: menú del canal mientras lo ves.** Las TV Roku se quedan con el `*` para su propia configuración mientras un video ocupa toda la pantalla, por eso el `*` solo abría el menú del canal mientras el canal cargaba. Ahora **Play/Pausa** abre el menú del canal mientras lo ves, también con la lista de canales abierta. El `*` sigue funcionando en la guía.
- **Edición con IPTV: guía al cambiar de grupo.** Si entrabas a un grupo antes de que terminara de cargar la guía, los demás grupos se podían quedar sin guía hasta volver a abrir el canal. Ahora los canales sin guía se vuelven a pedir solos, y si una petición de la guía se atora, se reintenta.
- **Seguir viendo (edición con IPTV)**: las listas y guías grandes pueden llenar el almacenamiento del Roku, y entonces el Roku borra otros archivos guardados, como tu Seguir viendo. Por eso la fila desaparecía o tardaba mucho en salir hasta que sincronizabas a mano. Ahora la fila se queda en el inicio, se vuelve a sincronizar sola cuando terminan de cargar tus listas y tu guía, y lo reintenta si la sincronización falla.
- **Botón `*` y arranque de la reproducción (las dos ediciones)**: se quitó el registro de diagnóstico que corría cada vez que presionabas `*`, la revisión del enlace antes de reproducir vuelve a esperar 5 segundos como en 0.1.7 en lugar de 10, y elegir un subtítulo integrado ya no deja cambiada la configuración de subtítulos del propio Roku: vuelve a como la tenías al cerrar el reproductor.
- **Continuar una película o episodio (las dos ediciones)**: en algunos Roku, continuar donde te quedaste mostraba un "Error del reproductor" ('Dot' Operator attempted with invalid BrightScript Component). Venía de un registro de diagnóstico agregado en 0.1.8; ya no se escribe al continuar y ya no puede detener la reproducción en ningún Roku.
- **Edición con IPTV**: las listas M3U grandes ya no congelan el canal ni te regresan al inicio del Roku. Ahora la lista se guarda y se lee por partes en lugar de toda de una vez, y se cargan hasta 20,000 canales en vivo por lista.
- **Plex**: después de poner el código, la pantalla ahora dice que está buscando tus servidores en lugar de quedarse en "Esperando aprobación". Si tu cuenta de Plex no tiene un Plex Media Server, te lo dice (Nuvio se conecta a tu propio Plex Media Server, no a las películas y TV en vivo gratis de Plex).

## [0.1.8] - 2026-11-21

### Agregado
- **Edición con IPTV**, un segundo `.zip` en el mismo release (`NuvioTV-Roku-0.1.8-IPTV.zip`). Es el mismo canal con todo lo de arriba y un nuevo lugar **En vivo** en el menú lateral:
  - Agrega **listas M3U** o **cuentas Xtream** en **Ajustes → TV en vivo**, o desde el celular en la página de configuración (`http://IP_DE_TU_ROKU:8888`, pestaña **TV en vivo**). Cada perfil tiene sus propias listas y puede compartirlas con los otros perfiles. Si la lista trae su propia guía, se usa sola; también puedes poner la dirección de tu propia guía XMLTV en cada lista, incluidas las comprimidas `.xml.gz`.
  - **Guía de programación estilo TiviMate**: un panel arriba con el póster del programa (de TMDB o de la guía; si no, el logo del canal), el número, nombre y grupo del canal, **EN VIVO**, el título grande, día y horario, cuánto falta, episodio y categoría, avance, descripción y una vista previa del canal con sonido. Abajo, cada canal con su número, logo y nombre, los programas con su horario, una línea roja con la hora actual y un borde rojo en el canal que está sonando. **Izquierda** abre la lista de grupos como panel lateral, igual que la lista de canales (**Favoritos**, **Vistos recientemente**, **Todos** y cada grupo con cuántos canales tiene), e **Izquierda** otra vez abre el menú lateral normal.
  - **Viendo un canal**: la barra de abajo muestra el canal, **EN VIVO**, el formato de video y audio, el programa actual con su avance, hora de inicio y fin, y lo que sigue. **Arriba y Abajo cambian de canal**, **OK** muestra la barra del canal y **OK** otra vez abre la lista de canales encima del video con lo que dan ahora (Izquierda dentro de ella abre los grupos), **Repetición instantánea** regresa al canal anterior y Atrás vuelve a la guía.
  - **Reproducción más estable**: si un canal se corta o se congela, se reconecta solo, y si sigue fallando pasa a la siguiente opción del canal. El audio y los subtítulos que elijas se recuerdan en cada canal.
  - **Opciones del canal**: cuando una lista trae el mismo canal varias veces (mismo `tvg-id`), aparece una sola vez en la guía con la misma programación. Al verlo, **Izquierda y Derecha cambian entre sus opciones**, y si una no reproduce se prueba la siguiente. La vista previa de la guía siempre usa la primera opción.
  - Las listas funcionan con cualquier dirección, aunque no terminen en `.m3u` o sean un enlace de GitHub.
  - Apartado **Guía (EPG)** en **Ajustes → TV en vivo** y en la página del celular: muestra qué guía usa cada lista (la suya o una personalizada) y cuántos programas y canales cargó. Puedes poner varias guías en una lista, separadas por coma.
  - **Favoritos**: presiona `*` en un canal para agregarlo o quitarlo. Aparecen primero en la guía.
  - Filas **Canales favoritos** y **Canales recientes** en el inicio, con lo que dan ahora, su avance, cuánto falta y lo que sigue. Presiona `*` en uno para verlo, agregarlo o quitarlo de favoritos, o quitarlo de canales recientes.
  - **Más ajustes de TV en vivo** en **Ajustes → TV en vivo**: tamaño de la guía (Compacta, Normal, Grande), mostrar u ocultar números, logos, nombres, nombres en dos líneas, horarios, la línea de la hora actual, el borde rojo y la vista previa; abrir en el último grupo; empezar en el último canal en pantalla completa; reconectar solo; cambiar a otra opción si una falla; recordar audio y subtítulos; invertir Arriba y Abajo; cuánto dura la barra del canal; cada cuánto se actualizan las listas y la guía; y ajustar la hora de la guía si sale adelantada o atrasada.
  - **Recordatorios de programas**: en la guía, presiona **OK** en un programa que todavía no empieza y elige **Recordarme cuando empiece**. Le aparece una campanita, y un minuto antes de que empiece se desliza una tarjeta desde la esquina de arriba a la derecha con el logo del canal, el programa y la hora, estés viendo lo que estés viendo en la app (un canal, una película o una serie). Presiona **OK** en él otra vez para quitar el recordatorio.
  - **Imágenes de películas y series**: el póster de cada programa se busca en TMDB por su título (también cuando la guía acorta el nombre, como "Bichos Una aventura"), así las películas y series muestran su póster en la guía y en el inicio. La imagen de la propia guía solo se usa cuando TMDB no tiene nada y es vertical y con buen tamaño; si no, se muestra el logo del canal. Necesita tu clave de TMDB; se puede apagar en **Ajustes → TV en vivo**.
  - El hero del inicio para un canal se ve como los demás: **TV en vivo · grupo**, lo que dan ahora con cuánto falta y lo que sigue, y su descripción.
  - **Manejo de canales y grupos**: presiona `*` en un canal para renombrarlo u ocultarlo, y en un grupo (en la lista de grupos) para agregarlo a **grupos favoritos** (salen primero, con estrella), ocultarlo o **bloquearlo con PIN**, que se pone en **Ajustes → TV en vivo → PIN**. Los canales y grupos ocultos se pueden volver a mostrar desde Ajustes.
  - El aviso de actualización es el mismo que el de la edición normal.
- **Plex** en **Ajustes → Servidores multimedia**, junto a Jellyfin y Emby, como en Nuvio TV. Vincula tu cuenta con un código en plex.tv/link y se agregan todos tus servidores, con sus bibliotecas de películas y series en el inicio y como fuentes al reproducir.
- **Simkl** como fuente de **Seguir viendo**, junto a Nuvio, Trakt y MDBList, en **Ajustes → Seguimiento**.

### Corregido
- El tráiler en los detalles ya no arranca mientras te sigues moviendo; solo sale cuando te quedas quieto unos segundos.
- Moverse arriba y abajo en el menú lateral (Inicio, En vivo, Buscar, Descubrir, Biblioteca, Ajustes) ya no se traba: solo se redibujan las dos opciones que cambian en vez de todo el menú en cada botón.
- Moverse rápido por las filas del inicio es más fluido.
- Los logos de la tarjeta expandida cargan mucho más rápido, usando el que ya estaba cargado en el inicio.
- Las badges del reproductor y de la pantalla de pausa van en su propia fila debajo de la línea del episodio, como en Nuvio TV de Android TV.
- Los filtros de addons en el panel de **Fuentes** del reproductor ya no se salen del panel.
- Los subtítulos integrados toman el estilo que elegiste en el menú de subtítulos, hasta donde el Roku lo permite.
- Enlaces `.ts` con varios audios: el canal espera más a los enlaces lentos antes de leer sus audios, y si no puede leerlos el menú de audio dice por qué. Con **Cargar todos los audios del enlace original** la barra ya se mueve a donde adelantas. Adelantar o continuar a la mitad de estos archivos ya no se queda cargando, y un archivo nuevo ya no se queda con los audios del anterior.
- Edición IPTV: si abres **Ajustes** estando en **En vivo**, el sonido del canal se detiene, y la vista previa vuelve al cerrar Ajustes.
- Edición IPTV: la guía ya no se queda en "Cargando guía..." para siempre. Arriba a la derecha ahora se ve qué está haciendo (descargando, abriendo o leyendo la guía, con porcentaje), los programas aparecen en cuanto la primera guía está lista, la guía anterior se sigue viendo mientras carga la nueva, y si tarda más de 10 minutos deja de esperar y te pide revisar el enlace.
- Edición IPTV: la etiqueta **EN VIVO** se ve nítida y ya no se ve cortada de los lados.
- Edición IPTV: el audio MP3 se muestra como **MP3** en vez de **MPG123**.
- Edición IPTV: las guías grandes (como las de epgshare01) cargan mucho más rápido y completas. El canal se salta sin leerlos los programas de canales que no tienes, guarda la guía descomprimida en el espacio más grande del Roku, espera hasta 15 minutos por guía y muestra cuántos MB lleva descargados. Si una guía llega cortada, **Ajustes → TV en vivo** lo dice.
- Edición IPTV: cada lista puede usar **dos guías a la vez** (**Ajustes → TV en vivo → Guía (EPG)**, o la pestaña **TV en vivo** de la página del celular), y puedes elegir si también se usa la guía que trae la lista. Cada línea muestra cuántos programas y canales cargó cada guía.
- Los subtítulos integrados ya aparecen aunque los subtítulos del Roku estén apagados: al elegir uno en el menú de subtítulos se encienden, y la elección se vuelve a aplicar cuando el video arranca.
- Enlaces `.ts` con varios audios (como DeepFlix): al adelantar o continuar, la imagen ya no empieza pixeleada, ya no muestra una parte anterior a la de la barra y ya no se detiene después de un rato. El canal ahora lee los tiempos reales en varios puntos del archivo, empieza cada salto en un cuadro completo de verdad (lee el video mismo en lugar de confiar en las marcas del archivo, que algunos archivos ponen en todos los cuadros, aunque el siguiente quede más adelante) y nunca manda dos veces el mismo pedazo. Si aun así se detiene, se reconecta hasta 3 veces conservando todos los audios antes de probar otra forma de abrir el enlace.

## [0.1.7] - 2026-11-21

### Agregado
- **Biblioteca en la nube**, como en Nuvio TV. Si tienes conectado TorBox, Premiumize o Real-Debrid, abre **Biblioteca → Biblioteca en la nube** para ver lo que ya tienes en esas cuentas: filtra por proveedor y tipo (torrents, Usenet, descargas web, archivos), busca por nombre y actualiza. Cada elemento muestra cuántos archivos reproducibles tiene, su estado y su tamaño. Elige un archivo para reproducirlo; el canal recuerda dónde te quedaste en cada archivo y pasa al siguiente cuando termina uno. Puedes apagarla en **Ajustes → Servicios conectados**.
- **Real-Debrid** en **Ajustes → Servicios conectados**. Por ahora solo se usa para la biblioteca en la nube.
- **Calificaciones**, como en Nuvio TV. Elige dónde se guardan en **Ajustes → Seguimiento → Calificaciones** (Trakt, Simkl o MDBList). En la ficha de cada título aparece el botón **Calificar** con tu calificación actual, y con Trakt y MDBList también puedes calificar episodios desde sus opciones.
- **MDBList** en **Ajustes → Seguimiento**, junto a Trakt y Simkl, para conectar tu cuenta como seguimiento.
- Nuevas opciones de **Seguir viendo** en **Ajustes → Diseño**, como en Nuvio TV: qué se abre al elegir algo (la fuente, los detalles, o detalles solo para lo que viene), el orden (predeterminado, estilo streaming o una fila aparte de Próximamente), miniaturas de episodios, difuminar los siguientes episodios que no has visto, el siguiente desde el episodio más avanzado y mostrar episodios antes de que se estrenen. Se sincronizan con tu cuenta de Nuvio.
- **Marcar como visto** en el menú de opciones de Seguir viendo.
- **Nuevo menú de subtítulos**, como en Nuvio TV: los subtítulos se agrupan primero por idioma y dentro de cada idioma ves todas las pistas con su origen (integrado, servidor, fuente o complemento) y etiquetas de Forzados, SDH y formato. Atrás o Izquierda regresa a los idiomas.
- **Sincronización de subtítulos** en el menú de subtítulos: adelántalos o atrásalos de 0.1 s o 0.5 s (también con ⏪/⏩ mientras la barra está abierta), o usa **Sincronizar línea**: cuando escuchas una frase, la eliges de la lista y el canal la acomoda solo. El ajuste se guarda por título.
- **Estilo de subtítulos** dentro del reproductor, con vista previa en vivo mientras cambias tamaño, color, fondo, borde, negritas y altura.
- Los subtítulos que vienen con la fuente (complementos) y los de Jellyfin/Emby también aparecen en el menú.
- **Archivos .ts en los que sí te puedes mover**, como en Nuvio para celular: cuando un enlace `.ts` directo deja que el Roku lo pida por partes, el canal lee su duración real del propio archivo, así la barra muestra el tiempo correcto y puedes adelantar, atrasar y continuar donde te quedaste. Si el archivo trae varios audios, **todos aparecen en el menú de audio** con su idioma, y al cambiar sigues en el mismo minuto. Los formatos de audio que tu Roku no puede reproducir (como DTS) se marcan; si eliges uno, se abre el enlace original para que el Roku lo reproduzca.
- **Calificar con estrellas**, como en Nuvio TV: 5 estrellas que se llenan de media en media (del 1 al 10), con tu calificación en números grandes, dónde se sincroniza y los botones **Quitar calificación** / **Guardar**.
- **Las fuentes dentro del reproductor** se ven como en Nuvio TV: un panel lateral con filtros por complemento, cada fuente como tarjeta con sus badges y la que se está reproduciendo marcada.
- **Los badges de la fuente que se reproduce** (los de imagen, como 4K, HDR o Atmos) aparecen bajo el título en la barra del reproductor y en la pantalla de pausa.
- **Fuente de Más como esto** en **Ajustes → Seguimiento** (TMDB, Trakt o Simkl), como en Nuvio TV.
- **Marcar como visto / no visto ahora también se manda a Trakt, Simkl y MDBList** si los tienes conectados, no solo a tu cuenta de Nuvio.
- Los catálogos que piden un filtro (como "por año" o "últimos videos" de Cinemeta) ahora aparecen en **Descubrir**, que elige el primer valor por ti y te deja cambiarlo; siguen sin salir en las filas del inicio. Gracias a **@JoshRob297** por detectarlo (PR #33).

### Corregido
- Cuando la reproducción automática pasa al siguiente episodio, ya no aparece un "Error del reproductor" (Execution timeout) que se queda pegado en pantalla. Al ordenar las fuentes por audio, el canal volvía a buscar tu perfil y tus ajustes por cada fuente; con un perfil grande eso tardaba demasiado. Ahora los busca una vez y los reutiliza hasta que algo cambia.
- Si llega a haber un error mientras se reproduce un video, el canal ya no muestra encima del reproductor un aviso que no se puede cerrar.
- Los idiomas de los subtítulos se reconocen mejor: portugués de Brasil o de Portugal, español latino o de España, chino simplificado o tradicional, y nombres escritos de distintas formas (pob, pt-BR, "Latino", "Castellano"…). Tu idioma preferido elige primero la coincidencia más cercana.
- Los subtítulos SRT/VTT que empiezan con una marca oculta, tienen líneas desordenadas o varias líneas al mismo tiempo ahora se ven bien. Si un archivo está dañado, aparece un aviso en vez de fallar sin decir nada.
- Con la reproducción automática, si una fuente de debrid no se puede preparar, el canal pasa a la siguiente fuente en vez de detenerse.
- Las fuentes de TorBox que TorBox lista con otro hash ahora se reconocen como en caché.
- Los logos y fondos de TMDB muy grandes se piden al tamaño que muestra el Roku, para que no se acabe la memoria de imágenes.

- **Next up** en Seguir viendo ahora reproduce justo ese capítulo desde el principio, en vez de a veces saltar al siguiente y a la mitad.
- El nombre del capítulo ya no sale repetido en Seguir viendo ni en la portada.
- Las **colecciones** ahora muestran todas sus listas, no solo la primera.
- El tráiler ya no se queda sonando en el fondo si sales justo cuando empieza, y los tráilers siguen funcionando después. En los detalles, el tráiler solo empieza cuando dejas de moverte.
- En los detalles, cuando los botones no caben en una línea (con Calificar activado), los que sobran pasan a una segunda línea debajo de **Continuar** en vez de cortarse.
- La pantalla de pausa ya no tapa la imagen pausada con la imagen del título: ves justo donde te quedaste, con el logo, la descripción y los datos encima.
- Si reproduces desde Seguir viendo antes de que carguen los detalles, la pantalla de pausa llena la descripción y los datos en cuanto llegan.
- El logo de la pantalla de carga y de pausa usa el que ya estaba cargado en el inicio en vez de descargarlo otra vez.
- Ya no faltan los subtítulos que trae la fuente cuando algo empieza muy rápido desde Seguir viendo.
- Los subtítulos **Muy grande** ya se ven (antes desaparecían), la vista previa del estilo ya no oscurece la parte de arriba de la imagen, y el estilo también se aplica a los subtítulos integrados del video.
- Si el video se queda cargando después de adelantar o atrasar mucho, el canal lo vuelve a abrir justo en ese minuto.
- Si tu cuenta de Nuvio responde un momento sin datos, tus colecciones se conservan en vez de borrarse.
- **Saltar resumen / Saltar introducción** vuelve a aparecer cuando la primera fuente falla y el canal pasa a otra. Los tiempos que se encontraban durante el cambio se tiraban y ya no se volvían a buscar.
- Moverte rápido por el inicio y luego saltar al menú, Buscar, Ajustes o una colección ya no se traba unos segundos. Ahora el inicio actualiza la imagen grande y prepara los siguientes títulos solo cuando te detienes en uno, no en cada título por el que pasas.

Gracias a **@BenedettiLucca** por las mejoras de subtítulos, debrid y TorBox (PR #32) y a **@JoshRob297** por el arreglo de los catálogos en Descubrir (PR #33).

## [0.1.6] - 2026-11-16

### Agregado
- **Ajustes → Acerca de → Imágenes animadas (GIF)** muestra cómo cargó el último GIF: cuántos de sus cuadros llegaron y por qué camino. Si los GIF no se mueven en tu Roku, esta línea ayuda a saber por qué.

### Corregido
- El canal ya no se congela ni se cierra después de sincronizar una cuenta con muchos ajustes, y el inicio se mueve más fluido para todos. El canal volvía a leer tus ajustes guardados cada vez que necesitaba uno, muchas veces por segundo mientras te movías por el inicio; con un perfil grande eso se volvía tan lento que el Roku cerraba el canal. Ahora los lee una vez y solo los vuelve a leer cuando algo cambia.
- Los GIF de las colecciones vuelven a funcionar en todos los Roku. Algunos Roku descargaban el GIF y lo reproducían, pero nunca lo dibujaban, así que la tarjeta solo mostraba la imagen de portada o se veía transparente. Ahora el canal trae los cuadros del GIF como imágenes normales y los muestra uno tras otro (hasta 30 cuadros y luego vuelve a empezar).
- Los pósteres del inicio ya no se ponen grises cuando bajas y vuelves a subir. Desde la 0.1.5, los fondos y logos que el canal traía por adelantado se quedaban en la memoria de imágenes del Roku, lo que sacaba a los pósteres y no dejaba espacio para los GIF. Ahora se guardan en el almacenamiento del Roku, así siguen cargando rápido sin ocupar esa memoria. El logo de la portada también se carga del tamaño en que se muestra.

## [0.1.5] - 2026-11-14

### Cambiado
- **Solo audio estéreo (2.0)** ahora ordena las fuentes en cuatro grupos: primero las que dicen que son estéreo (2.0, stereo, AAC 2.0, DD 2.0), luego las que no dicen qué audio traen, luego las que traen una pista 5.1 y otra 2.0, y al final las 5.1/7.1/Atmos. La reproducción automática elige del primer grupo que tenga algo. "DD 2.0" y parecidos ahora cuentan como estéreo.

### Corregido
- Los GIF de las colecciones vuelven a moverse. En la 0.1.4 se quedaban en negro en los Roku que antes sí los mostraban. Mientras se mueve un GIF, se oculta la imagen de la tarjeta de abajo para que no se vea una orilla blanca alrededor.
- Con muchos perfiles, la pantalla de "¿Quién está viendo?" ya no corta perfiles en las orillas: los círculos se hacen un poco más chicos para que quepan todos.
- El inicio carga los títulos más rápido mientras te mueves: el canal ahora trae por adelantado el fondo, el logo y la información de los títulos que están junto al que tienes seleccionado, así casi siempre ya están listos cuando llegas. Los fondos y logos de TMDB se cargan del tamaño que el Roku realmente muestra (misma calidad en pantalla), y el fondo ya no se queda vacío mientras carga el siguiente.

## [0.1.4] - 2026-11-11

### Agregado
- **Ocultar spoilers**, como en Nuvio TV (**Ajustes → Diseño → Ficha de series → Ocultar spoilers**), apagado por defecto. En los episodios que todavía no has visto, la imagen se ve borrosa y se oculta la descripción. Los episodios que ya viste o empezaste se ven normal.
- Botón **Aleatorio** en la ficha de las series, como en Nuvio TV. Reproduce un episodio al azar de los que ya salieron (sin contar los especiales). Lo puedes ocultar en **Ajustes → Diseño → Ficha de series → Botón Aleatorio**.
- **Calificación de cada episodio** en la lista de temporadas: cada episodio muestra su calificación con una estrella junto a la fecha. Vienen del addon (IMDb) o de TMDB cuando el addon no las tiene, y la vista del episodio a pantalla completa (`*`) dice de cuál es.

### Cambiado
- **Solo audio estéreo (2.0)** ahora solo lee el nombre, la descripción y el nombre del archivo de la fuente (no el enlace), así que un enlace que por casualidad tenga "2.0" o algo parecido ya no se cuela. También reconoce las fuentes marcadas solo como "DD". Las fuentes que traen una pista 5.1 y otra 2.0 quedan después de las de estéreo y antes de las que solo son 5.1, y la reproducción automática elige una en estéreo siempre que haya.
- Con **Solo audio estéreo (2.0)** encendido, las fuentes marcadas como 5.1, 7.1, Atmos, Dolby o DTS ahora pasan al final de la lista de fuentes en vez de quedar mezcladas, así las fuentes en estéreo salen primero. No se ocultan, así que todavía puedes elegirlas. Con **Saltar audio que tu Roku no reproduce** encendido, las fuentes con un audio que tu Roku no reproduce también pasan al final.
- Cuando una fuente trae sus propias imágenes de badges desde un addon o tu cuenta de Nuvio, se ocultan los badges que pone el canal por defecto (calidad, códec, tamaño).

### Corregido
- El canal vuelve a abrir en los modelos de Roku que no pueden mostrar imágenes animadas (como algunas TV Roku más antiguas). Desde la 0.1.3 se cerraba justo después de la pantalla de inicio en esos modelos. En ellos, los GIF de las colecciones solo muestran la imagen normal.
- Los badges de las fuentes ya no se enciman cuando una fuente tiene muchos.
- Los GIF de las colecciones ya no muestran una orilla blanca ni esquinas cuadradas alrededor.
- El tráiler dentro de la tarjeta horizontal ampliada ya no muestra esquinas cuadradas fuera del marco.

## [0.1.3] - 2026-11-10

### Agregado
- **Recordar el último perfil** (**Ajustes → Perfiles → Recordar el último perfil**), apagado por defecto. Al abrir el canal entra directo al último perfil que usaste en vez de mostrar la lista de perfiles. Si ese perfil tiene PIN, te lo sigue pidiendo.
- **Audio que tu Roku puede reproducir** (**Ajustes → Reproducción → Audio de tu Roku**). El canal revisa qué formatos de audio puede reproducir tu Roku (y la TV o barra de sonido conectada): estéreo, 5.1, Dolby Digital, Dolby Digital Plus, DTS y TrueHD, y muestra cuáles soporta y cuáles no. Con **Saltar audio que tu Roku no reproduce** (encendido por defecto), la reproducción automática y **Si una fuente falla** saltan las fuentes cuyo nombre dice que usan un audio de la lista de No, y luego aplican tu regex a las que quedan. **Solo audio estéreo (2.0)**, apagado por defecto, salta las fuentes marcadas como 5.1, 7.1, Atmos, Dolby o DTS, salvo que también digan 2.0 o estéreo.

### Corregido
- **Ver todo** en el inicio en cuadrícula ya no cierra el canal. Ahora abre el catálogo completo del addon, como Nuvio TV, en vez de solo los títulos que se ven en el inicio.
- Las **listas de Trakt** en colecciones ya no fallan con 403. Algunos números de lista llegaban de tu cuenta de Nuvio en un formato que el Roku redondeaba, así que el canal le pedía a Trakt una lista que no existía. Ahora lee el número exacto.
- **Sincronizar ahora** ya no falla con "Tu cuenta de Nuvio no tiene perfiles". Si tu cuenta de Nuvio todavía no tiene perfiles, el canal sincroniza usando tu perfil actual, así Seguir viendo y el resto de tus datos quedan ligados a él.
- Las imágenes animadas (GIF) de las tarjetas de colecciones ahora se mueven en todos los estilos del inicio, no solo en cuadrícula. Quedan justo sobre la tarjeta enfocada, con las esquinas redondeadas. 
- Los detalles de los títulos vuelven a abrir rápido. Los comentarios de Trakt ahora cargan después de que los detalles ya están en pantalla, y otra vez se traducen al idioma del canal, con un traductor de respaldo cuando el primero no responde.
- Los pósteres ya no muestran esquinas cuadradas oscuras sobre los fondos en los Roku con pantalla en HD.
- La **barra lateral moderna** ahora llega hasta abajo de la pantalla, con las opciones centradas, como en Nuvio TV.

## [0.1.2] - 2026-11-07

### Agregado
- **Estilos del inicio como en Nuvio TV** (**Ajustes → Diseño → Estilo del inicio**): **Moderno** (la portada se queda fija arriba con una fila activa, como antes), **Clásico** (una portada arriba que cambia sola entre títulos de tus catálogos, y las filas se recorren hacia abajo) y **Cuadrícula** (cada catálogo en varias filas de pósteres, con un recuadro **Ver todo** que abre el catálogo completo en cuadrícula). El estilo del inicio de tu cuenta de Nuvio también se sincroniza.
- **Más opciones de diseño del inicio de Nuvio TV** en **Ajustes → Diseño**: fondo de la portada a pantalla completa (Moderno), fondo del título enfocado del lado derecho (Clásico), mostrar u ocultar la portada y elegir de qué catálogos sale (Clásico y Cuadrícula), nombres debajo de los pósteres, ocultar películas y series que todavía no se estrenan, y mostrar u ocultar la calificación de IMDb en la portada. Se sincronizan con tu cuenta de Nuvio.
- **Opciones de la barra lateral como en Nuvio TV** (**Ajustes → Diseño → Barra lateral**): la **barra lateral moderna** es un panel flotante que se abre al ir a la izquierda, con una pequeña pastilla arriba a la izquierda que dice dónde estás. Puedes hacerla translúcida (Roku no puede desenfocar, así que se ve semitransparente) u ocultar la pastilla. Con la barra normal puedes contraerla para que solo aparezca al ir a la izquierda.
- **Crea tu propio color de acento**, como el tema personalizado de Nuvio TV. **Ajustes → Apariencia → Color de acento** ahora muestra cada color con una vista previa, y **Crear un color** te deja elegir entre más colores o escribir cualquier código de color (por ejemplo FF5CA8). También lo puedes elegir con el selector de color de la página del celular. Un color personalizado de tu cuenta de Nuvio ahora se ve tal cual, y uno que crees en el Roku se envía a tu cuenta.
- **Modo ambiente como en Nuvio TV** (**Ajustes → Apariencia → Modo ambiente**), apagado de inicio. Si no tocas el control por un rato en el inicio, la biblioteca, Buscar o Descubrir, muestra en pantalla completa fondos de tus primeros catálogos, moviéndose despacio, con el logo o el título y los géneros. Cualquier botón lo cierra y quedas donde estabas. Tú eliges cuándo empieza (de 1 a 30 minutos). El protector de pantalla de tu Roku puede aparecer antes si su tiempo es menor. Si lo tienes en tu cuenta de Nuvio, también se sincroniza.

### Corregido
- **TorBox**: algunos torrents en caché fallaban con "torrent_id: Input should be a valid integer". Ahora el canal lee los números del torrent y del archivo tal como los manda TorBox, aunque sean muy grandes, para siempre mandar un número válido.

## [0.1.1] - 2026-11-05

### Agregado
- **Pantalla de carga como en Nuvio TV**: al presionar Reproducir aparecen enseguida el fondo y el logo del título mientras el canal busca y elige la fuente, en vez del cuadro de "Buscando enlaces". Debajo del logo dice lo que está pasando (buscando fuentes, eligiendo una, revisando el enlace, cargando, probando otra forma de abrirlo). Si prefieres ver solo el fondo y el logo, apaga **Ajustes → Reproducción → Pantalla de carga → Mostrar lo que está pasando**.
- **Probar otra fuente cuando una falla** (**Ajustes → Reproducción → Si una fuente falla**), apagado de inicio. Cuando una fuente no abre, el canal elige otra compatible de los resultados, siguiendo tus reglas de reproducción automática (regex o primera fuente) y sin repetir ninguna que ya falló, todo mientras sigue la pantalla de carga. Tú eliges cuántas fuentes puede probar (de 1 a 5). Después te muestra la lista para que elijas tú.

### Cambiado
- Cuando una lista de Trakt de una colección falla, el mensaje también muestra el número de lista que el canal le pidió a Trakt.

### Corregido
- Los torrents en caché con **TorBox** podían fallar con "TorBox no pudo preparar este enlace". Ahora el canal le pide el enlace a TorBox de la misma forma que Nuvio TV, espera un momento cuando TorBox todavía no lo tiene listo, y si aun así falla, el mensaje dice qué contestó TorBox y en qué paso.
- **TorBox**: algunos torrents en caché fallaban con "(paso 2 · 422)". Cuando TorBox no acepta el número del torrent, ahora el canal lo busca en tu lista de TorBox, y el mensaje dice exactamente qué rechazó TorBox.

## [0.1.0] - 2026-11-03

### Agregado
- Botón **Cambiar forma de abrir** en el reproductor, junto a Fuentes, que funciona como el de cambiar reproductor de Nuvio. Cada enlace se puede abrir de varias formas (automática, HLS, MKV, MP4, limpiado en el Roku...). Si un video no carga, se atora o no tiene sonido, presiónalo para probar la siguiente forma. Cada vez que lo presionas pasa a la siguiente, sigue desde donde ibas y te muestra en cuál estás.
- **Trakt y MDBList como fuentes**, como en Nuvio TV: en **Ajustes → Seguimiento → Fuentes** elige de dónde sale **Seguir viendo** (Nuvio, Trakt o MDBList) y de dónde sale tu **biblioteca** (Mi lista, Trakt o MDBList). Con Trakt o MDBList, Seguir viendo muestra lo que dejaste a medias ahí y tus siguientes episodios, la biblioteca muestra tu watchlist y tus listas personales, y agregar o quitar de Mi lista también cambia tu watchlist en ese servicio.
- **Comentarios de Trakt** en la página de detalles, en una pestaña nueva de **Comentarios** junto a Reparto y Más como esto. Los comentarios en otro idioma se traducen al idioma del canal, y puedes ver el original. Los comentarios con spoilers quedan ocultos hasta que presionas OK. Puedes apagar los comentarios o su traducción en **Ajustes → Seguimiento**.
- Lo que ves ahora también se registra en **MDBList** (inicio, pausa y fin) cuando tu cuenta de MDBList está conectada, como ya pasaba con Trakt y Simkl.

### Corregido
- Al presionar `*` para elegir una fuente, a veces la lista no mostraba qué fuente o filtro estaba seleccionado, aunque sí te podías mover por ella. Ahora el resaltado siempre se ve.
- Las listas de Trakt en las colecciones que fallaban con "Trakt (403)" ahora vuelven a intentarlo de la misma forma en que Nuvio TV se las pide a Trakt, y si aun así fallan, el mensaje dice por qué.

## [0.0.9] - 2026-11-01

### Agregado
- **Servicios conectados** (TorBox y Premiumize), como en Nuvio TV: en **Ajustes → Servicios conectados**, vincula tu cuenta de TorBox con un código QR o escribe tu clave de API de TorBox o Premiumize. También llegan desde tu cuenta de Nuvio. Los resultados de torrent de tus addons que ya están en la caché de tu servicio ahora aparecen como fuentes (con la etiqueta TB o PM) y se reproducen directo. Los torrents que no están en caché se siguen omitiendo.
- **Servidores multimedia** (Jellyfin y Emby), como en Nuvio TV: en **Ajustes → Servidores multimedia**, inicia sesión con la dirección de tu servidor, tu usuario y tu contraseña. Tus bibliotecas de películas y series aparecen como filas en el inicio, y cuando un título está en tu servidor aparece primero en las fuentes, como el archivo original o convertido por el servidor (HLS) para archivos que tu Roku no puede reproducir. Puedes desactivar el servidor, elegir qué bibliotecas mostrar, actualizarlas o quitar el servidor.

### Cambiado
- En la página de detalles ahora puedes seleccionar una productora o cadena para ver sus películas y series, como en Nuvio TV.

### Corregido
- Al presionar Atrás mientras veías algo, a veces salía el error "'Dot' Operator attempted with invalid BrightScript Component" y no podías salir del video. Ahora el video siempre se cierra y regresas a la pantalla anterior.
- Algunos videos se reproducían sin sonido, y el reproductor mostraba una sola pista de audio aunque el archivo tuviera más. Pasaba con enlaces que no terminan en `.mkv` o `.mp4` (como muchos de AIOStreams, TorBox y otros servicios debrid). Ahora el canal revisa qué tipo de archivo es y se lo indica al Roku, así aparecen todas las pistas de audio.
- Los pósters de Más como esto y de la colección mostraban esquinas cuadradas oscuras alrededor de los bordes redondeados.
- En Descubrir, el selector tardaba en moverse y a veces se veían dos pósters seleccionados al mismo tiempo. Además, al entrar a Descubrir se veía un póster seleccionado aunque estabas en los filtros de arriba.
- Cuando la primera forma de abrir un enlace falla y otra sí funciona, el canal lo recuerda para ese sitio, así la próxima vez abre directo.
- En el panel de Episodios del reproductor se veía el video en las esquinas de las imágenes de los episodios, y en la tarjeta de Siguiente episodio podía pasar lo mismo.

## [0.0.8] - 2026-10-31

### Agregado
- **Opciones de episodio**, como en Nuvio TV: en la página de detalles, presiona `*` en un episodio para verlo en pantalla completa con su imagen, calificación y descripción, y marcarlo como visto o no visto, marcar toda la temporada, marcar los episodios anteriores de la temporada, reproducirlo, reproducirlo manualmente o empezarlo desde el inicio. Usa izquierda y derecha para pasar de un episodio a otro. Los cambios se envían a tu cuenta de Nuvio.
- **PIN de perfiles**: los perfiles con PIN en tu cuenta de Nuvio ahora piden el PIN de 4 dígitos en el Roku antes de abrirse, y muestran un candado en la pantalla de perfiles. El PIN lo revisa tu cuenta de Nuvio. Para poner, cambiar o quitar un PIN, usa Nuvio en otro dispositivo.
- **Panel de episodios en el reproductor**, como en Nuvio TV: el botón Episodios abre un panel lateral sobre el video con las temporadas y los episodios, con imágenes y descripciones, en lugar de cerrar el video.
- **Más como esto, colección y productoras** en la página de detalles, como en Nuvio TV: debajo de los episodios hay pestañas de Reparto, Más como esto y la colección de la película (por ejemplo, todas las películas de una saga), y al final se muestran las productoras o cadenas. Necesitan una clave de TMDB.

### Cambiado
- Las **recomendaciones al final de una película** Pantalla completa con el fondo, el logo, la calificación, el año y la descripción, mientras la película sigue en una ventana pequeña. Cambian solas cada 10 segundos, y también puedes moverte entre ellas.
- **Descubrir** ahora mueve la selección por la cuadrícula en lugar de deslizar toda la fila, como en Nuvio TV.
- Cuando un video se queda cargando, el canal muestra el fondo y el logo del título con el porcentaje de carga, como Nuvio, en lugar de una pantalla negra.
- TMDB ahora solo funciona con una clave de TMDB de tu cuenta de Nuvio o una que agregues tú. Su idioma sigue el idioma del canal, a menos que elijas otro en **Ajustes → Integraciones → Idioma de la metadata**.

### Corregido
- Los tráilers de YouTube en tu idioma no se reproducían, así que el canal terminaba usando el tráiler en inglés de IMDb. Ahora el canal abre YouTube igual que Nuvio TV en Android: prueba varios clientes de YouTube y renueva su sesión cuando YouTube lo pide. **Ajustes → Acerca de** muestra qué pasó con el último tráiler de YouTube.
- Algunas fuentes se reproducían sin sonido porque el canal elegía una pista de audio que el Roku no puede reproducir (como DTS o TrueHD). Ahora se salta esas pistas y elige una que el Roku sí pueda reproducir.
- **Next up** no aparecía arriba en Seguir viendo. Ahora el canal lo arma con tus episodios vistos, como Nuvio, y actualiza tu Seguir viendo desde tu cuenta de Nuvio cada pocos minutos y al dejar de ver algo.
- Ver más del 95% de una película o episodio ahora lo marca como visto y lo envía a tu cuenta de Nuvio.
- Después de recargar las fuentes, a veces las flechas dejaban de responder hasta presionarlas muchas veces.
- Después de ver algo, algunos pósters del inicio podían quedarse grises. Ahora vuelven a cargar.
- Las fotos del reparto tardaban mucho o no cargaban en algunos Roku. Ahora cargan directo de TMDB.

## [0.0.7] - 2026-10-27

### Agregado
- Nuevo preset de reproducción automática **HDR sin Dolby Vision**, para TVs con HDR pero sin Dolby Vision.
- Si tu TV no es compatible con Dolby Vision, la reproducción automática se salta las fuentes que solo son Dolby Vision (se ven verdes o moradas). Las fuentes marcadas DV + HDR10 se siguen reproduciendo. **Ajustes → Acerca de** muestra si tu tele es compatible con Dolby Vision.
- **Ajustes → Acerca de** muestra el modelo de tu Roku, el modo de video y qué formatos admite (HEVC, HDR10, Dolby Vision y 4K).

### Corregido
- Los addons cuyo enlace lleva algo después de `manifest.json` (como `manifest.json?token=...`) mostraban sus catálogos pero nunca daban fuentes. Ahora el canal pone esa parte al final de cada petición, como Nuvio en Android y en el celular. Estos enlaces también se pueden agregar ya desde la página del celular.
- Con un color de tema claro (como el tema Blanco de Nuvio), los botones del reproductor, los filtros de fuentes y los interruptores seleccionados se veían completamente blancos y sus íconos desaparecían. Ahora los íconos y textos sobre el resaltado se ponen oscuros cuando el color es claro.
- Las series con muchas temporadas no dejaban avanzar más allá de las temporadas que cabían en la pantalla. Ahora las pestañas de temporadas se desplazan con el foco.
- Los archivos `.ts` sueltos se quedaban congelados en 0:00 con una duración enorme (unas 10 horas). Ahora el canal revisa qué es realmente el enlace antes de reproducirlo, y reproduce estos archivos con una pequeña lista armada en el Roku, para que se puedan ver y adelantar.
- Si una fuente nunca empieza a reproducirse, a los 20 segundos el canal prueba la siguiente forma de abrirla y al final muestra un error, en lugar de quedarse congelado.

## [0.0.6] - 2026-10-26

### Agregado
- **Descubrir**, como en Nuvio TV: explora cualquier catálogo de tus addons por tipo, catálogo y género, y se cargan más títulos conforme bajas. Por defecto es un botón debajo del teclado en Buscar. En **Ajustes → Diseño → Ubicación de Descubrir** puedes moverlo a su propio lugar en el menú lateral o desactivarlo. Este ajuste se sincroniza con tu cuenta de Nuvio.
- **Búsquedas recientes** en Buscar, como en Nuvio TV. Tus últimas 8 búsquedas aparecen cuando el buscador está vacío. Elige una para buscarla otra vez, usa la X de al lado para quitarla o usa **Borrar historial**. Cada perfil tiene su propio historial.
- **Cuenta de MDBList**, como en Nuvio: en **Ajustes → Integraciones → Cuenta de MDBList**, escanea el código QR con tu celular y aprueba el acceso. Las calificaciones y las listas de MDBList funcionan con tu cuenta, sin escribir ninguna clave.

### Cambiado
- El tráiler que se reproduce en el inicio después de unos segundos en un título ahora ocupa toda la pantalla, como en Nuvio TV para Android. Las filas, el menú lateral y la descripción se ocultan y solo queda el logo del título. Presiona cualquier botón para detenerlo y volver a las filas.

### Corregido
- Las calificaciones de MDBList se descargaban pero nunca se mostraban. Ahora aparecen en la página de detalles debajo de la información del título, con el ícono de cada sitio, como en Nuvio.
- La clave de MDBList de tu cuenta de Nuvio (y la cuenta de MDBList) se guardaba, pero el canal la leía vacía, así que siempre decía que faltaba. Esto también podía afectar otros ajustes que llegan de tu cuenta.

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
