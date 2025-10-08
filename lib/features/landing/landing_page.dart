import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});
  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final _homeKey = GlobalKey();
  final _bizKey = GlobalKey();
  final _featKey = GlobalKey();
  final _priceKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: 0.1,
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
            onBiz: () => _scrollTo(_bizKey),
            onFeatures: () => _scrollTo(_featKey),
            onPricing: () => _scrollTo(_priceKey),
            onLogin: () { /* TODO: ir a login */ },
            onCta: () { /* TODO: registro de pyme */ },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _Section(
                    key: _homeKey,
                    padding:
                        const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
                    child: const _HeroSection(),
                  ),
                  _Section(
                    key: _bizKey,
                    color: const Color(0xFF0F1324),
                    child: const _BusinessesSection(),
                  ),
                  _Section(
                    key: _featKey,
                    child: const _FeaturesSection(),
                  ),
                  _Section(
                    key: _priceKey,
                    color: const Color(0xFF0F1324),
                    child: const _PricingSection(),
                  ),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ========================= NAVBAR ========================= */

class _Navbar extends StatelessWidget {
  final VoidCallback onHome, onBiz, onFeatures, onPricing, onLogin, onCta;

  const _Navbar({
    required this.onHome,
    required this.onBiz,
    required this.onFeatures,
    required this.onPricing,
    required this.onLogin,
    required this.onCta,
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
            // Marca
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
                const Text('TuEmpresa',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              ],
            ),
            const Spacer(),

            // Inicio
            _NavBtn(text: 'Inicio', onTap: onHome),

            // Negocios (hover menu)
            _HoverMenuButton(
              label: 'Negocios',
              menuBuilder: (close) => _MenuCard(
                columns: [
                  _MenuColumn(title: 'ESTÉTICA Y BELLEZA', items: [
                    _MenuItem(
                      icon: Icons.content_cut,
                      text: 'Barberías',
                      onTap: () {
                        close();
                        onBiz();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.cut,
                      text: 'Peluquerías',
                      onTap: () {
                        close();
                        onBiz();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.spa,
                      text: 'Spas',
                      onTap: () {
                        close();
                        onBiz();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.brush,
                      text: 'Salones de belleza',
                      onTap: () {
                        close();
                        onBiz();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.local_hospital,
                      text: 'Centros de estética',
                      onTap: () {
                        close();
                        onBiz();
                      },
                    ),
                  ]),
                ],
              ),
            ),

            // Funcionalidades (hover menu CAPTA / GESTIONA)
            _HoverMenuButton(
              label: 'Funcionalidades',
              menuBuilder: (close) => _MenuCard(
                columns: [
                  _MenuColumn(title: 'CAPTA', items: [
                    _MenuItem(
                      icon: Icons.event_available,
                      text: 'Agenda online',
                      onTap: () {
                        close();
                        onFeatures();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.calendar_month,
                      text: 'Reservas online',
                      onTap: () {
                        close();
                        onFeatures();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.notifications_active,
                      text: 'Recordatorios automáticos',
                      onTap: () {
                        close();
                        onFeatures();
                      },
                    ),
                  ]),
                  _MenuColumn(title: 'GESTIONA', items: [
                    _MenuItem(
                      icon: Icons.inventory_2,
                      text: 'Control de inventario',
                      onTap: () {
                        close();
                        onFeatures();
                      },
                    ),
                    _MenuItem(
                      icon: Icons.bar_chart,
                      text: 'Reportes de gestión',
                      onTap: () {
                        close();
                        onFeatures();
                      },
                    ),
                  ]),
                ],
              ),
            ),

            _NavBtn(text: 'Precios (Pro)', onTap: onPricing),
            const SizedBox(width: 8),
            TextButton(onPressed: onLogin, child: const Text('Ir a mi cuenta')),
            const SizedBox(width: 8),
            ElevatedButton(onPressed: onCta, child: const Text('Prueba gratis')),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _NavBtn({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

/* ========================= SECCIONES ========================= */

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

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'El software para salones, estética y salud',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          'Reservas online sin login, recordatorios por WhatsApp y panel de ventas/stock para tu pyme.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Colors.white70),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text('Prueba gratis')),
            OutlinedButton(
                onPressed: () {}, child: const Text('Ver funcionalidades')),
          ],
        ),
      ],
    );
  }
}

class _BusinessesSection extends StatelessWidget {
  const _BusinessesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Para tu negocio',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: const [
            _CardFeature(
                title: 'Agenda Online',
                desc: 'Reserva en 2 pasos — sin crear cuenta.'),
            _CardFeature(
                title: 'Recordatorios WhatsApp',
                desc: 'Reduce no-shows con confirmación S/N.'),
            _CardFeature(
                title: 'Dashboard de Ventas',
                desc: 'Ingresos, comisiones y no-shows.'),
            _CardFeature(
                title: 'Stock en el Móvil',
                desc: 'Controla inventario por servicio.'),
          ],
        ),
      ],
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('Funcionalidades',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        _Bullet(text: 'Link único por sucursal: /b/tu-negocio'),
        _Bullet(text: 'Reserva sin login (cliente invitado)'),
        _Bullet(text: 'Correo con archivo .ics + Google Calendar'),
        _Bullet(text: 'WhatsApp 24h antes: confirma S/N y re-agenda'),
        _Bullet(text: 'Panel admin (ventas, comisiones, stock)'),
        _Bullet(text: 'Seguridad OWASP: tokens firmados y RBAC'),
      ],
    );
  }
}

class _PricingSection extends StatelessWidget {
  const _PricingSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('Precios (Pro)',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
        SizedBox(height: 16),
        _PriceCard(title: 'Gratis', price: '\$0', features: [
          'Reservas web',
          'Recordatorio por email',
        ]),
        SizedBox(height: 12),
        _PriceCard(title: 'Pro', price: '\$X.990/mes', features: [
          'WhatsApp + confirmación S/N',
          'Google Calendar (negocio)',
          'Dashboard de ventas y stock',
        ]),
      ],
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String title, price;
  final List<String> features;
  const _PriceCard(
      {required this.title, required this.price, required this.features});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(price,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  ...features.map((f) => Row(
                        children: [
                          const Icon(Icons.check,
                              size: 18, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Text(f),
                        ],
                      )),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(onPressed: () {}, child: const Text('Elegir plan')),
          ],
        ),
      ),
    );
  }
}

class _CardFeature extends StatelessWidget {
  final String title, desc;
  const _CardFeature({required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(desc),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.arrow_right, color: Color(0xFF7C3AED)),
        const SizedBox(width: 4),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x22FFFFFF))),
      ),
      child: Center(
        child: Text(
          '© ${DateTime.now().year} TuEmpresa — Reservas y gestión para pymes',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
      ),
    );
  }
}

/* ====================== HOVER MENU infra ====================== */

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
  bool _hoveringButton = false;
  bool _hoveringMenu = false;

  void _showMenu() {
    if (_entry != null) return;
    final render = _key.currentContext!.findRenderObject() as RenderBox;
    final offset = render.localToGlobal(Offset.zero);
    final size = render.size;

    _entry = OverlayEntry(
      builder: (context) {
        return Positioned(
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
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  void _maybeClose() async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (!_hoveringButton && !_hoveringMenu) _close();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _hoveringButton = true;
        if (_key.currentContext != null) _showMenu();
      },
      onExit: (_) {
        _hoveringButton = false;
        _maybeClose();
      },
      child: Container(
        key: _key,
        child: TextButton(
          onPressed: () {},
          child: Text(widget.label,
              style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}

/* ------- Tarjeta/columnas/items del menú ------- */

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
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 8))
        ],
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns
            .map((c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: c,
                  ),
                ))
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
        Text(title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Colors.white70,
            )),
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
  const _MenuItem({required this.icon, required this.text, required this.onTap});

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
