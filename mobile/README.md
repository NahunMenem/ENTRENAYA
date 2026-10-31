# EntrenaYa para iOS y Android

Aplicación Flutter multiplataforma con identidad visual EntrenaYa. Incluye bienvenida, configuración del perfil de entrenamiento y una navegación inicial con Inicio, Entrenar, Progreso, Nutrición y Perfil. El flujo de Google envía el ID token al backend FastAPI y recibe la sesión de EntrenaYa.

## Requisitos

- Flutter estable y Dart incluidos en Flutter.
- Android Studio con Android SDK para ejecutar en Android.
- macOS con Xcode para compilar y ejecutar en iOS.

## Ejecutar

Desde esta carpeta, primero ejecutá `flutter pub get` y después:

```bash
flutter run \
  --dart-define=GOOGLE_WEB_CLIENT_ID=tu-cliente-web.apps.googleusercontent.com \
  --dart-define=GOOGLE_IOS_CLIENT_ID=tu-cliente-ios.apps.googleusercontent.com
```

`GOOGLE_IOS_CLIENT_ID` es necesario en iOS y se puede omitir en Android. Para apuntar a otro backend, agregá `--dart-define=API_BASE_URL=https://tu-api`.

El backend predeterminado es `https://entrenaya-production.up.railway.app`.

Para previsualizar en navegador, ejecutá `flutter pub get` y `flutter run -d chrome`. Después de agregar imágenes al pubspec o plugins nuevos, detené la ejecución por completo y volvé a iniciarla: hot reload no reconstruye el registro de plugins ni siempre incorpora los assets nuevos. La vista web usa el almacenamiento del navegador para los datos locales de esta demostración.

## Acceso temporal de demostración

Por pedido del prototipo, `DEMO_MODE` está activado por defecto: Comenzar, Continuar con Google e Iniciá sesión abren el inicio directamente con un perfil local de demostración. Estos botones no autentican ni crean cuentas en el servidor. Para recuperar el flujo real de Google y el onboarding, ejecutá la app con `--dart-define=DEMO_MODE=false` y los clientes OAuth configurados.

## Configurar Google Sign-In

En Google Cloud Console, creá los clientes OAuth para Android, iOS y Web dentro del mismo proyecto:

- Android: paquete `com.entrenaya.app` y SHA-1/SHA-256 de la clave usada para firmar la app. Registrá también el SHA de debug durante el desarrollo.
- iOS: bundle ID `com.entrenaya.app`. Agregá el URL scheme reverso del cliente iOS a `ios/Runner/Info.plist` en `CFBundleURLTypes`.
- Web: usá el cliente Web como `GOOGLE_WEB_CLIENT_ID` en Flutter y como `GOOGLE_CLIENT_ID` en el servicio FastAPI de Railway. El servidor valida el ID token emitido para ese cliente.

Los IDs OAuth son valores de configuración públicos de la app. No guardes client secrets, contraseñas de base de datos ni claves privadas en Flutter.

## Estado de los datos

El login de Google se valida en FastAPI y la identidad de usuario se guarda en PostgreSQL. El perfil de entrenamiento, las rutinas, el progreso y el seguimiento de nutrición de esta primera versión son datos de interfaz/locales; todavía no se sincronizan con la API.

El entrenamiento activo permite registrar kilos y repeticiones por serie, guardar un borrador automáticamente y finalizar la sesión. Los registros se guardan en el teléfono; la próxima sesión muestra las últimas series completadas de cada ejercicio. No hay sincronización de entrenamientos con PostgreSQL todavía.

En Progreso → Medidas se pueden guardar registros con fecha de brazo izquierdo/derecho, pierna izquierda/derecha, cintura y espalda, en centímetros. Cada registro admite medidas parciales. La vista muestra el historial, un gráfico por zona y las diferencias desde el primer registro y respecto al anterior. Permite editar y eliminar registros con confirmación. Las medidas también se guardan localmente en el teléfono, sin sincronización entre dispositivos todavía.

En Progreso → Registrar peso se puede registrar el peso corporal en kilogramos, con fecha, historial, edición y eliminación. La vista de peso muestra el gráfico y diferencias desde el primer registro y respecto al anterior. Mi progreso muestra el último peso y su evolución real; no usa los valores de ejemplo del prototipo. El historial de medidas existente se conserva. El peso se guarda en este dispositivo, sin sincronización con PostgreSQL todavía.

## Rutinas personales

El inicio presenta tres accesos directos: Crear mi rutina, Elegir una rutina y Rutina de mi profe. Esta última recibe un código de una rutina publicada desde el monitoreo y conserva el nombre del profesor indicado por el usuario. Las rutinas recibidas se pueden entrenar desde esa sección. Mis rutinas guardadas reúne las rutinas disponibles y el inicio muestra las programadas para el día actual. No se presentan entrenadores asignados ni estadísticas ficticias en el inicio.

En Entrenar → Crear mi rutina podés elegir un nombre y varios días de la semana. La biblioteca incluye ejercicios agrupados por músculo y búsqueda por nombre; se combina con el catálogo del backend cuando hay conexión. Cada ejercicio admite series, repeticiones objetivo y descanso en segundos. Podés cambiar el orden, quitar ejercicios y editar o eliminar rutinas guardadas. El filtro semanal muestra las rutinas asignadas a cada día.

Entrenar esta rutina abre el registro de series con los ejercicios, el orden y los descansos que configuraste. Las repeticiones son un objetivo; las repeticiones y el peso que efectivamente hiciste se ingresan al entrenar. Las rutinas y sus borradores de entrenamiento se guardan localmente en el dispositivo; todavía no se sincronizan con PostgreSQL.

## Videos de técnica

Las portadas se cargan desde el monitoreo y se guardan en Cloudinary. La biblioteca muestra miniaturas; al abrir un ejercicio aparece su foto con el botón para ver el video encima, las indicaciones y la opción de agregarlo a la rutina. Sin video asociado se muestra “Video próximamente”. Las URL de foto llegan en `cover_url` desde el catálogo; no se incluyen claves de Cloudinary en la app.

El panel Next.js se encuentra en `../admin`. Su catálogo publicado se consulta con `GET /api/v1/exercises` y `GET /api/v1/routines`. En Entrenar → Explorar rutinas de EntrenaYa se puede filtrar por categoría y usar una copia de una rutina publicada; la copia personal se puede editar sin cambiar el catálogo. Cuando hay conexión, la biblioteca del servidor reemplaza el listado de respaldo para respetar el estado de publicación.

La app consulta `GET /api/v1/exercises` para obtener el `video_url` de cada ejercicio y lo reproduce dentro de la app con controles de reproducción y avance. El backend prepara una tabla `exercises` con identificador, nombre y URL de video. El futuro panel administrador deberá guardar en ella una URL HTTPS de reproducción directa (por ejemplo, MP4 alojado en almacenamiento de archivos), no un enlace a una página de YouTube. Los identificadores del catálogo deben mantenerse estables para conservar el historial de cada ejercicio.

Si no hay un video asociado, la app informa que todavía no está disponible. El panel de carga, la subida de archivos y los permisos de administrador se implementarán después.
