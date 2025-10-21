// lib/features/landing/landing_page.dart
import 'dart:async';
import 'package:flutter/material.dart';

// --- RUTA CORREGIDA ---
// La ruta correcta es relativa, ya que 'public_booking' está dentro de 'landing'.
import '../public_booking/booking_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  // Anclas para el scroll (esto está perfecto, no se toca)
  final _homeKey = GlobalKey();
  final _servicesKey = GlobalKey();
  final _howKey = GlobalKey();
  final _featKey = GlobalKey();
  final _priceKey = GlobalKey();
  final _testimonialsKey = GlobalKey();
  final _faqKey = GlobalKey();
  final _adaptKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  // Esta función es para el BARBERO que inicia sesión
  void _navigateToAdminLogin() {
    Navigator.pushNamed(context, '/auth');
  }

  // Esta función es para el CLIENTE que quiere agendar
  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0F1A),
      body: Column(
        children: [
          _Navbar(
            onHome: () => _scrollTo(_homeKey),
            onServicios: () => _scrollTo(_servicesKey),
            onComoFunciona: () => _scrollTo(_howKey),
            onFuncionalidades: () => _scrollTo(_featKey),
            onFaq: () => _scrollTo(_faqKey),
            onPrecios: () => _scrollTo(_priceKey),
            onAdapt: () => _scrollTo(_adaptKey),
            onLogin: _navigateToAdminLogin,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _Section(
                    key: _homeKey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    // --- CAMBIO CLAVE: El botón del medio ahora va al login ---
                    child: _HeroWithTabs(onCta: _navigateToAdminLogin),
                  ),
                  _Section(
                    key: _servicesKey,
                    color: const Color(0xFF0F1324),
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: _ImpulsaTusHorarios(
                      onCardTap: (route) {
                        // Las tarjetas como "Agenda Online" SÍ deben llevar a la reserva del cliente
                        _navigateToBooking();
                      },
                    ),
                  ),
                  _UniqueValueAndMock(onCta: _navigateToAdminLogin),
                  _Section(
                    key: _howKey,
                    color: const Color(0xFF0F1324),
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: const _HowItWorks(),
                  ),
                  _Section(
                    key: _featKey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: const _FeaturesBullets(),
                  ),
                  _Section(
                    key: _testimonialsKey,
                    color: const Color(0xFF0F1324),
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: const _Testimonials(),
                  ),
                  _Section(
                    key: _faqKey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: const _Faqs(),
                  ),
                  _Section(
                    key: _adaptKey,
                    color: const Color(0xFF0F1324),
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: const _AdaptamosRubros(),
                  ),
                  _Section(
                    key: _priceKey,
                    padding: const EdgeInsets.symmetric(
                      vertical: 56,
                      horizontal: 24,
                    ),
                    child: _PricingSimple(onChoose: _navigateToAdminLogin),
                  ),
                  _FooterCTA(onCta: _navigateToAdminLogin),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// WIDGETS INTERNOS DE LA PÁGINA
// ======================================================================

class _Navbar extends StatelessWidget {
  final VoidCallback onHome;
  final VoidCallback onServicios;
  final VoidCallback onComoFunciona;
  final VoidCallback onFuncionalidades;
  final VoidCallback onFaq;
  final VoidCallback onPrecios;
  final VoidCallback onAdapt;
  final VoidCallback onLogin;

  // --- CAMBIO: Se elimina onCTA porque ya no existe el botón ---
  const _Navbar({
    required this.onHome,
    required this.onServicios,
    required this.onComoFunciona,
    required this.onFuncionalidades,
    required this.onFaq,
    required this.onPrecios,
    required this.onAdapt,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D0F1A).withOpacity(0.9),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x22FFFFFF))),
        ),
        child: Row(
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'TuEmpresa',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const Spacer(),
            _NavBtn('Inicio', onHome),
            _NavBtn('Servicios', onServicios),
            _NavBtn('Cómo funciona', onComoFunciona),
            _HoverMenuButton(
              label: 'Funcionalidades',
              menuBuilder: (close) => _MenuCard(
                columns: [
                  _MenuColumn(
                    title: 'CAPTA',
                    items: [
                      _MenuItem(
                        icon: Icons.event_available,
                        text: 'Agenda online',
                        onTap: () {
                          close();
                          onFuncionalidades();
                        },
                      ),
                      _MenuItem(
                        icon: Icons.calendar_month,
                        text: 'Sitio de reservas',
                        onTap: () {
                          close();
                          onFuncionalidades();
                        },
                      ),
                      _MenuItem(
                        icon: Icons.notifications_active,
                        text: 'WhatsApp notis',
                        onTap: () {
                          close();
                          onFuncionalidades();
                        },
                      ),
                    ],
                  ),
                  _MenuColumn(
                    title: 'GESTIONA',
                    items: [
                      _MenuItem(
                        icon: Icons.inventory_2,
                        text: 'Control de inventario',
                        onTap: () {
                          close();
                          onFuncionalidades();
                        },
                      ),
                      _MenuItem(
                        icon: Icons.bar_chart,
                        text: 'Reportes',
                        onTap: () {
                          close();
                          onFuncionalidades();
                        },
                      ),
                      _MenuItem(
                        icon: Icons.campaign,
                        text: 'Marketing',
                        onTap: () {
                          close();
                          onFuncionalidades();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _NavBtn('FAQs', onFaq),
            _NavBtn('Precios', onPrecios),
            _NavBtn('Rubros', onAdapt),
            const SizedBox(width: 16),
            // --- CAMBIO CLAVE: Eliminamos el botón "Registrarse" y dejamos solo "Iniciar Sesión" ---
            ElevatedButton(
              onPressed: onLogin,
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _NavBtn(this.text, this.onTap);
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _HeroWithTabs extends StatefulWidget {
  const _HeroWithTabs({required this.onCta});
  final VoidCallback onCta;

  @override
  State<_HeroWithTabs> createState() => _HeroWithTabsState();
}

class _HeroWithTabsState extends State<_HeroWithTabs> {
  final _controller = PageController();
  int _index = 0;
  Timer? _timer;

  final _tabs = const [
    ('Agenda Online', Icons.event_available, 'assets/img/hero1.jpg'),
    ('Sitio de Reservas', Icons.calendar_month, 'assets/img/hero2.jpg'),
    ('Whatsapp & Notis', Icons.sms, 'assets/img/hero3.jpg'),
    ('Ventas y Pagos', Icons.point_of_sale, 'assets/img/hero4.jpg'),
    ('Marketing', Icons.campaign, 'assets/img/hero5.jpg'),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _index = (_index + 1) % _tabs.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          _index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'El software n°1 para salones, centros de estética y salud',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          'Organiza citas, cobra sin fricciones y haz crecer tu negocio. Hazlo simple, hazlo Pro.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.85)),
        ),
        const SizedBox(height: 20),
        // --- CAMBIO DE NOMBRE ---
        ElevatedButton(
          onPressed: widget.onCta,
          child: const Text('Regístrate ahora ➜'),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              ChoiceChip(
                selected: i == _index,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_tabs[i].$2, size: 16),
                    const SizedBox(width: 6),
                    Text(_tabs[i].$1),
                  ],
                ),
                onSelected: (_) {
                  setState(() => _index = i);
                  _controller.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 22),
        AspectRatio(
          aspectRatio: 16 / 7.8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: _tabs.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _tabs[i].$3,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[800],
                      child: const Center(child: Text('Imagen no disponible')),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImpulsaTusHorarios extends StatelessWidget {
  final void Function(String route) onCardTap;
  const _ImpulsaTusHorarios({required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Agenda Online',
        'assets/img/serv1.jpg',
        Icons.event_available,
        'agenda',
      ),
      (
        'Sitio de reservas',
        'assets/img/serv2.jpg',
        Icons.calendar_month,
        'reservas',
      ),
      ('Whatsapp notis', 'assets/img/serv3.jpg', Icons.sms, 'whatsapp'),
      ('Marketing', 'assets/img/serv4.jpg', Icons.campaign, 'marketing'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Impulsa tus horarios',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Descubre cómo nuestros módulos aceleran tu agenda.',
          style: TextStyle(color: Colors.white.withOpacity(0.8)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (_, c) {
            final cols = c.maxWidth < 900 ? 1 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 16 / 6.5,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                return InkWell(
                  onTap: () => onCardTap(it.$4),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          it.$2,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Text('Imagen no disponible'),
                                ),
                              ),
                        ),
                        Container(color: Colors.black.withOpacity(0.45)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(
                                it.$3,
                                color: const Color(0xFF7C3AED),
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  it.$1,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _UniqueValueAndMock extends StatelessWidget {
  const _UniqueValueAndMock({required this.onCta});
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return _Section(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          const Text(
            'Una competencia única donde ordenarás y acelerarás tu crecimiento',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onCta,
            child: const Text('Crear tu cuenta gratis'),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (_, c) {
              final isNarrow = c.maxWidth < 900;
              return Flex(
                direction: isNarrow ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/img/dashboard.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Text('Imagen no disponible'),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: isNarrow ? 0 : 16, height: isNarrow ? 16 : 0),
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          'assets/img/mobile.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey[800],
                                child: const Center(
                                  child: Text('Imagen no disponible'),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1. Crea tu negocio', 'Registra tu pyme y servicios en minutos.'),
      ('2. Comparte tu link', 'Tus clientes reservan sin crear cuenta.'),
      (
        '3. Gestiona todo',
        'Confirmaciones, recordatorios y ventas en un panel.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cómo funciona',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        ...steps.map(
          (s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF7C3AED)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(s.$2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturesBullets extends StatelessWidget {
  const _FeaturesBullets();

  @override
  Widget build(BuildContext context) {
    Widget col(String title, List<String> items) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...items.map((t) => _Bullet(text: t)),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Funcionalidades',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            col('CAPTA', const [
              'Agenda online sin login',
              'Sitio de reservas por sucursal',
              'Recordatorios WhatsApp / Email',
            ]),
            const SizedBox(width: 24),
            col('GESTIONA', const [
              'Control de inventario vinculado a servicios',
              'Reportes y KPIs de ventas',
              'Usuarios y permisos por rol',
            ]),
          ],
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.arrow_right, color: Color(0xFF7C3AED)),
          const SizedBox(width: 4),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _Testimonials extends StatelessWidget {
  const _Testimonials();

  @override
  Widget build(BuildContext context) {
    final items = [
      ('“Bajamos los no-show a la mitad.”', 'Barbería Central'),
      ('“El panel nos simplificó las comisiones.”', 'Estética Bella'),
      ('“Reservar sin cuenta es un golazo.”', 'Spa Relax'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lo que dicen nuestros clientes',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: items
              .map(
                (t) => SizedBox(
                  width: 340,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(t.$1, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(
                            t.$2,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _Faqs extends StatelessWidget {
  const _Faqs();

  @override
  Widget build(BuildContext context) {
    final faqs = [
      (
        '¿Necesito que mis clientes creen cuenta?',
        'No. Reservan como invitados con sus datos básicos.',
      ),
      (
        '¿Puedo cancelar o re-agendar por WhatsApp?',
        'Sí, con el plan Pro el bot confirma asistencia y ofrece re-agendar.',
      ),
      (
        '¿Se integra con Google Calendar?',
        'Sí, para el negocio (opcional). Para el cliente enviamos .ics adjunto.',
      ),
      (
        '¿Puedo ver ventas y comisiones?',
        'Sí, el panel muestra KPIs y comisiones por staff.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preguntas frecuentes',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...faqs.map(
          (f) => Card(
            child: ExpansionTile(
              title: Text(f.$1),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(f.$2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AdaptamosRubros extends StatelessWidget {
  const _AdaptamosRubros();

  @override
  Widget build(BuildContext context) {
    final rubros = [
      'Barberías',
      'Peluquerías',
      'Salones de belleza',
      'Spa',
      'Psicólogos',
      'Nutricionistas',
      'Kinesiólogos',
      'Clínicas',
      'Manicure',
      'Cejas y pestañas',
      'Centros de estética',
      'Podología',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nos adaptamos a tu negocio',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        _AutoScrollChips(items: rubros),
      ],
    );
  }
}

class _AutoScrollChips extends StatefulWidget {
  final List<String> items;
  const _AutoScrollChips({required this.items});

  @override
  State<_AutoScrollChips> createState() => _AutoScrollChipsState();
}

class _AutoScrollChipsState extends State<_AutoScrollChips> {
  final ScrollController _sc = ScrollController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 35), (_) {
      if (!_sc.hasClients || !mounted) return;
      final max = _sc.position.maxScrollExtent;
      final next = _sc.offset + 1.5;
      _sc.jumpTo(next >= max ? 0 : next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = [...widget.items, ...widget.items];
    return SizedBox(
      height: 84,
      child: ListView.separated(
        controller: _sc,
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => Column(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: const Color(0xFF1F2340),
              child: Text(
                data[i][0],
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 6),
            Text(data[i], style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _PricingSimple extends StatelessWidget {
  const _PricingSimple({required this.onChoose});
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Precios',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        _PriceCard(
          title: 'Gratis',
          price: '\$0',
          features: const ['Reservas web', 'Recordatorio por email'],
          onChoose: onChoose,
        ),
        const SizedBox(height: 12),
        _PriceCard(
          title: 'Pro',
          price: '\$X.990/mes',
          features: const [
            'WhatsApp + confirmación S/N',
            'Dashboard ventas & stock',
            'Google Calendar (negocio)',
          ],
          onChoose: onChoose,
        ),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title, price;
  final List<String> features;
  final VoidCallback onChoose;
  const _PriceCard({
    required this.title,
    required this.price,
    required this.features,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 6),
                          Text(f),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onChoose,
              child: const Text('Elegir plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterCTA extends StatelessWidget {
  const _FooterCTA({required this.onCta});
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 46, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1324),
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              const Text(
                'Crea tu cuenta e inicia',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onCta,
                child: const Text('Crea tu cuenta YA'),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 32,
                runSpacing: 12,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _FooterCol(
                    title: 'TuEmpresa',
                    lines: ['© $year TuEmpresa Inc.'],
                    small: true,
                  ),
                  const _FooterCol(
                    title: 'Contacto',
                    lines: [
                      'Chile',
                      'contacto@tuempresa.com',
                      'Av. Dirección 123, Santiago',
                      '+56 2 XXXX XXXX',
                      'Instagram · Facebook · X · LinkedIn',
                    ],
                  ),
                  const _FooterCol(
                    title: 'Legal',
                    lines: ['Política de privacidad', 'Términos y condiciones'],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterCol extends StatelessWidget {
  final String title;
  final List<String> lines;
  final bool small;
  const _FooterCol({
    required this.title,
    required this.lines,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (l) => Text(
              l,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: small ? 12 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverMenuButton extends StatefulWidget {
  final String label;
  final Widget Function(VoidCallback close) menuBuilder;
  const _HoverMenuButton({required this.label, required this.menuBuilder});

  @override
  State<_HoverMenuButton> createState() => _HoverMenuButtonState();
}

class _HoverMenuButtonState extends State<_HoverMenuButton> {
  final _key = GlobalKey();
  OverlayEntry? _entry;
  bool _hoveringBtn = false;
  bool _hoveringMenu = false;

  void _show() {
    if (!mounted) return;
    final render = _key.currentContext?.findRenderObject() as RenderBox?;
    if (render == null) return;
    final offset = render.localToGlobal(Offset.zero);
    final size = render.size;

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 6,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveringMenu = true),
          onExit: (_) {
            _hoveringMenu = false;
            _maybeClose();
          },
          child: Material(
            color: Colors.transparent,
            child: widget.menuBuilder(_close),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  Future<void> _maybeClose() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!_hoveringBtn && !_hoveringMenu) _close();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hoveringBtn = true;
        _show();
      },
      onExit: (_) {
        _hoveringBtn = false;
        _maybeClose();
      },
      child: Container(
        key: _key,
        child: TextButton(
          onPressed: () {},
          child: Text(
            widget.label,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuColumn> columns;
  const _MenuCard({required this.columns});
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 420, maxWidth: 720),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111426),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: c,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MenuColumn extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuColumn({required this.title, required this.items});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.white10,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF9AA3B2)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const _Section({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color ?? Colors.transparent,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
