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

## Configurar Google Sign-In

En Google Cloud Console, creá los clientes OAuth para Android, iOS y Web dentro del mismo proyecto:

- Android: paquete `com.entrenaya.app` y SHA-1/SHA-256 de la clave usada para firmar la app. Registrá también el SHA de debug durante el desarrollo.
- iOS: bundle ID `com.entrenaya.app`. Agregá el URL scheme reverso del cliente iOS a `ios/Runner/Info.plist` en `CFBundleURLTypes`.
- Web: usá el cliente Web como `GOOGLE_WEB_CLIENT_ID` en Flutter y como `GOOGLE_CLIENT_ID` en el servicio FastAPI de Railway. El servidor valida el ID token emitido para ese cliente.

Los IDs OAuth son valores de configuración públicos de la app. No guardes client secrets, contraseñas de base de datos ni claves privadas en Flutter.

## Estado de los datos

El login de Google se valida en FastAPI y la identidad de usuario se guarda en PostgreSQL. El perfil de entrenamiento, las rutinas, el progreso y el seguimiento de nutrición de esta primera versión son datos de interfaz/locales; todavía no se sincronizan con la API.
