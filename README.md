🧾 Proyecto Final - Sistema de Agendamiento de Servicios
🧩 Descripción general

Aplicación móvil desarrollada en Flutter para la administración de horarios y gestión de servicios.
Permite a los usuarios registrarse, iniciar sesión y agendar citas, mientras los administradores pueden visualizar, crear, editar o eliminar reservas, además de administrar personal y servicios ofrecidos.

La aplicación incluye:

Formularios con validación por campo y al enviar.

Estados visuales de carga, éxito y error.

Reglas de negocio y validaciones cruzadas para evitar conflictos de horarios.

Flujo funcional por rol (cliente y administrador).

Contrato de datos coherente con ejemplos JSON.

Diseño responsivo y pruebas de accesibilidad en diferentes dispositivos.

📱 Tecnologías principales

Flutter 3.35.7

Dart SDK 3.x

Firebase Authentication

Cloud Firestore

GoRouter (navegación)

TableCalendar (gestión de calendario)

fl_chart (visualización de datos y estadísticas)

⚙️ Instalación y ejecución
1️⃣ Clonar el repositorio
git clone https://github.com/tuusuario/Proyecto-Final.git
cd Proyecto-Final

2️⃣ Instalar dependencias
flutter pub get

3️⃣ Ejecutar la aplicación
flutter run -d chrome

🧠 Estructura general del proyecto
lib/
 ├── features/
 │    ├── auth/              # Login, registro y recuperación
 │    ├── dashboard/         # Panel administrativo
 │    ├── booking/           # Agendamiento de citas
 │    ├── profile/           # Perfil del usuario
 │    └── shared/            # Componentes reutilizables
 │
 ├── services/               # Servicios Firebase y autenticación
 └── main.dart               # Punto de entrada de la app

🧩 Reglas de Negocio y Validaciones

No se permite el registro de correos duplicados.

Los usuarios deben estar autenticados para acceder a funciones protegidas.

No se pueden agendar citas en fechas u horas pasadas.

Las citas no pueden solaparse para el mismo trabajador.

Solo administradores pueden crear o eliminar personal.

🧪 Pruebas

Para ejecutar las pruebas unitarias:

flutter test


💡 Autor: Enrique Burotto
📅 Versión: 1.0
📂 Repositorio: https://github.com/tuusuario/Proyecto-Final.git