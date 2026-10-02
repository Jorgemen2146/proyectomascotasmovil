# Configuración de autenticación externa

La app intercambia las credenciales de Google, Facebook y Apple con
Identity.API. No agregues secretos ni tokens de usuarios al repositorio.

## Google

- Registra `com.dogplatform.dogplatform` y los SHA-1/SHA-256 de cada firma en
  Google Cloud.
- Ejecuta Flutter con `--dart-define=GOOGLE_SERVER_CLIENT_ID=<web-client-id>`.
- En iOS agrega también `--dart-define=GOOGLE_IOS_CLIENT_ID=<ios-client-id>` y
  define `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID` y
  `GOOGLE_REVERSED_CLIENT_ID` en la configuración local de Xcode.

## Facebook

- Configura el package/bundle ID en Meta for Developers y los key hashes de
  Android.
- En Android define `FACEBOOK_APP_ID` y `FACEBOOK_CLIENT_TOKEN` en el
  `~/.gradle/gradle.properties` local (no en el repositorio).
- En iOS define esas mismas variables como User-Defined Build Settings de
  Xcode. Añade el URL de retorno indicado por Meta.

## Apple

- Activa Sign in with Apple para el App ID y regenera el provisioning profile.
- iOS ya incluye el entitlement requerido.
- Para Android crea un Service ID y una Return URL. Inicia con
  `--dart-define=APPLE_SERVICE_ID=<service-id>` y
  `--dart-define=APPLE_REDIRECT_URI=<https-return-url>`.
- El endpoint de retorno debe redirigir al esquema
  `signinwithapple://callback` usando el package
  `com.dogplatform.dogplatform`, según la documentación del plugin.

Los valores reales dependen de las consolas de cada proveedor y deben coincidir
con los audiences, client IDs y redirect URIs configurados en Identity.API.
