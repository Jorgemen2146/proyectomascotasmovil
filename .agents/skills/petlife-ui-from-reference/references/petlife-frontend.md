# Frontend móvil real de PetLife

Consulta este documento antes de implementar una referencia. Verifica de nuevo el código si el repositorio cambió; estas rutas describen el estado inspeccionado al crear la skill.

## Estructura y arquitectura

- El repositorio es una app Flutter en la raíz. `lib/main.dart` inicializa `AppConfig`, envuelve la app con `ProviderScope` y usa `MaterialApp.router` con `AppTheme.light`.
- `lib/core/` contiene configuración, constantes, errores, excepciones, interceptores, red, resultado, router, servicios, storage, tema y widgets compartidos.
- `lib/features/<feature>/` usa capas verticales `presentation`, `application`, `domain` y `data`. Las features actuales incluyen authentication, home, profile, pets, matching, health, genealogy, notifications y legal.
- Presentación consume providers y entidades de dominio; no debe llamar a Dio ni DTOs directamente.
- Los data sources usan Dio y convierten `DioException` a `AppException`. Los repositorios convierten excepciones a `AppFailure` y devuelven `Result<T>`. No dejes escapar Dio hacia UI.

## Estado, datos y navegación

- State management: `flutter_riverpod`. Se usan `Provider`, `StateProvider.autoDispose`, `FutureProvider.autoDispose(.family)`, `AutoDisposeNotifier` y `AutoDisposeAsyncNotifier`.
- Las lecturas remotas suelen exponerse como `AsyncValue` y renderizarse con `when(loading:, error:, data:)`. Las mutaciones usan controllers con un booleano de operación en curso, devuelven `Result<T>` e invalidan providers relacionados al éxito.
- Navegación: `go_router` centralizado en `lib/core/router/app_router.dart` y rutas en `app_routes.dart`. Usa `context.go` para cambiar destino principal y `context.push` para pantallas apiladas. Conserva redirects de autenticación y aceptación legal.
- Red: `gatewayRawDioProvider` para auth/refresh y `gatewayDioProvider` con `AuthInterceptor` para llamadas autenticadas. Los tokens viven en `flutter_secure_storage`; nunca persistas contraseñas.
- Configuración de API y timeouts proviene de `AppConfig`, seleccionada con `--dart-define=ENV=dev|qa|prod`.

## Design system verificado

- Material 3 y fuente Poppins mediante `google_fonts`.
- Tokens en `lib/core/theme/`: `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppIcons` y `AppTheme`.
- Colores base: primary `#2563EB`, primaryDeep `#1D4ED8`, primarySoft `#EAF1FF`, primaryFaint `#F5F8FF`, background `#FBFCFF`, surface blanco, textPrimary `#0B132B`, textSecondary `#667085`, border `#E9EDF5`, success `#22C55E`, error `#DC2626`.
- Espaciado: 4, 8, 12, 16, 20, 24, 32 y 48. Radios: 8, 12, 16, 20 (card), 24, 28 (sheet) y pill. Usa estos valores cuando la referencia no especifique otro.
- Tipografía disponible: `display`, `h1`, `h2`, `h3`, `screenTitle`, `sectionTitle`, `cardTitle`, `body`, `bodySecondary`, `caption`, `small`, `eyebrow` y `button`.
- El lenguaje actual combina fondos muy claros, azul principal, superficies azul claro/lavanda, cards redondeadas, bordes tenues, sombras suaves e iconos Material mayormente outline.

## Componentes compartidos

Busca primero en `lib/core/widgets/`:

- `AppButton`: variantes primary, secondary, outlined y text; soporta loading e icono.
- `AppTextField`, `AppEmailField`, `AppPasswordField`: inputs alineados con `InputDecorationTheme`.
- `AppCard`, `AppBadge`, `AppTopBar`, `SectionTitle`, `FadeSlideIn`.
- `AppLoadingIndicator`, `EmptyState`, `ErrorState`, `AppSnackBar`, `AppDialog`.
- `AppBottomNavBar` es presentacional; `MainBottomNavigation` conecta Inicio, Mascotas, Pareja, Salud y Perfil con GoRouter.
- `ResponsiveCenter` limita contenido a 480 px; pantallas principales actuales suelen usar `Center > ConstrainedBox(maxWidth: 600)`.
- `AppNetworkImage` resuelve URLs del gateway, agrega bearer headers cuando corresponde, aplica `BoxFit`/clip y muestra fallback. Prefiérelo para imágenes remotas autenticadas. Comprueba antes de usar `AppAvatar`, porque actualmente usa `NetworkImage` directo.
- Revisa también widgets de feature, por ejemplo `features/pets/presentation/widgets/pet_design_widgets.dart`, antes de duplicar cards o selectores.

## Imágenes, assets y responsive

- `pubspec.yaml` declara `assets/images/`. Existen imágenes de login/splash, logos, elementos decorativos e iconos raster. No inventes una ruta: comprueba el archivo y su declaración.
- Las fotos de perfil y mascotas se seleccionan mediante `PhotoPickerService`/`image_picker`; conserva flujos de subida y refresco de providers.
- Patrones actuales: `SafeArea`, contenido desplazable con `ListView`/`SingleChildScrollView`, `Expanded`, `Flexible`, `Wrap`, ellipsis y constraints de ancho.
- Hay pruebas explícitas sin overflow para dashboards en 320x568 y 430x932, Pareja en 360/390/412 px, y autenticación con teclado simulado. Añade o ajusta pruebas equivalentes para la pantalla afectada y para textos largos cuando sea relevante.

## Convenciones de implementación

- Idioma de UI: español. Conserva semántica, keys y textos que las pruebas o flujos usan, salvo que el diseño requiera un cambio coordinado.
- Usa `const` cuando sea viable y widgets privados de archivo para piezas específicas. Eleva un widget a `core` solo si es genuinamente compartido.
- Los errores visibles deben usar mensajes de `AppFailure`/excepciones de feature y ofrecer reintento cuando corresponda.
- Refresh usa `RefreshIndicator` e invalidación/refresco del provider. Disabled/loading debe impedir mutaciones duplicadas.
- Mantén los cambios generados por el usuario que ya estén en el worktree; no los reviertas ni reformatees fuera del alcance.
