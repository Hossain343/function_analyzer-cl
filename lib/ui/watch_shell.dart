import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app_controller.dart';
import 'graph_page.dart';
import 'input_page.dart';
import 'number_line_page.dart';
import 'steps_page.dart';
import 'theme.dart';

class WatchShell extends StatefulWidget {
  const WatchShell({super.key});
  @override
  State<WatchShell> createState() => _WatchShellState();
}

class _WatchShellState extends State<WatchShell> {
  late final AppController c = AppController();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  bool get _desktopPreview =>
      kIsWeb ||
      const {TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS}
          .contains(defaultTargetPlatform);

  @override
  Widget build(BuildContext context) {
    if (!_desktopPreview) return _Screen(c: c);
    // On a PC: show the app inside a round watch frame.
    return LayoutBuilder(builder: (context, box) {
      final frame = math.max(200.0, math.min(box.maxWidth, box.maxHeight) - 24);
      final ring = frame * 0.022;
      return ColoredBox(
        color: const Color(0xFF020203),
        child: Center(
          child: Container(
            width: frame,
            height: frame,
            padding: EdgeInsets.all(ring),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFF30343B)),
            child: ClipOval(
              child: ColoredBox(color: AppColors.bg, child: _Screen(c: c)),
            ),
          ),
        ),
      );
    });
  }
}

class _Screen extends StatelessWidget {
  final AppController c;
  const _Screen({required this.c});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final d = math.min(box.maxWidth, box.maxHeight);
      return Center(
        child: SizedBox(
          width: d,
          height: box.maxHeight,
          child: Dim(
            d: d,
            child: Builder(
              builder: (ctx) => ListenableBuilder(
                listenable: c,
                builder: (ctx, _) => _body(ctx, d),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _page() {
    final r = c.result;
    switch (c.page) {
      case 0:
        return InputPage(c: c);
      case 1:
        return r == null ? const _Empty() : StepsPage(r: r);
      case 2:
        return r == null ? const _Empty() : NumberLinePage(key: ObjectKey(r), r: r);
      default:
        return r == null ? const _Empty() : GraphPage(key: ObjectKey(r), r: r);
    }
  }

  Widget _body(BuildContext ctx, double d) {
    final s = Dim.of(ctx).s;
    final keyboardOpen = MediaQuery.viewInsetsOf(ctx).bottom > 0;
    final navH = keyboardOpen ? 0.0 : d * 0.17;

    return Scaffold(
      backgroundColor: AppColors.bg,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Content area. It ends exactly where the bottom button starts,
          // so nothing can ever be drawn underneath the button.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) {
                  final h = rect.height;
                  final a = (d * 0.085 / h).clamp(0.0, 0.4).toDouble();
                  final b = (d * 0.13 / h).clamp(0.0, 0.45).toDouble();
                  final e = (1 - d * 0.05 / h).clamp(0.55, 1.0).toDouble();
                  return LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Color(0x00FFFFFF),
                      Color(0xFFFFFFFF),
                      Color(0xFFFFFFFF),
                      Color(0x00FFFFFF),
                    ],
                    stops: [a, b > a ? b : a + 0.01, e, 1.0],
                  ).createShader(rect);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: SingleChildScrollView(
                    key: ValueKey(c.page),
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                        d * 0.14, d * 0.135, d * 0.14, d * 0.07),
                    child: _page(),
                  ),
                ),
              ),
            ),
          ),
          if (navH > 0)
            SizedBox(
              height: navH,
              width: double.infinity,
              child: Material(
                color: AppColors.accent,
                child: InkWell(
                  onTap: c.next,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: d * 0.02),
                      child: Text(
                        c.nextLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: sans(18 * s,
                            color: Colors.black, weight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final s = Dim.of(context).s;
    return Text('Go back to Input and fix the entries first.',
        textAlign: TextAlign.center,
        style: sans(14 * s, color: AppColors.muted, weight: FontWeight.w500));
  }
}
