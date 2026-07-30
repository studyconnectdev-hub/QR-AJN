import 'package:flutter/material.dart';
import '../../core/services/premium_service.dart';
import '../business/business_profile_screen.dart';
import '../premium/premium_screen.dart';
import 'generator_detail_screen.dart';
import 'generator_models.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key, this.onHome});
  final VoidCallback? onHome;

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  String _query = '';

  Future<void> _open(GeneratorCategory category) async {
    if (category.type == GeneratorType.businessProfile) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfileScreen()));
      return;
    }
    if (category.premium && !PremiumService.instance.isPremium) {
      final openPremium = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Premium business tool'),
          content: const Text('This category is part of QR AJN Pro or Business. You can review the plans or continue when premium is active.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('View Premium')),
          ],
        ),
      );
      if (openPremium == true && mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
      }
      if (!PremiumService.instance.isPremium) return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GeneratorDetailScreen(category: category)));
  }

  @override
  Widget build(BuildContext context) {
    final visible = generatorCategories.where((category) {
      final query = _query.trim().toLowerCase();
      return query.isEmpty || category.title.toLowerCase().contains(query) || category.shortLabel.toLowerCase().contains(query);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: widget.onHome ?? () => Navigator.maybePop(context)),
        title: const Text('Create QR • 30 Categories'),
        actions: [
          IconButton(
            tooltip: 'Premium',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen())),
            icon: const Icon(Icons.workspace_premium_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: Theme.of(context).brightness == Brightness.dark
                ? const [Color(0xFF07111F), Color(0xFF111A37), Color(0xFF102A2E)]
                : const [Color(0xFFF5FAFF), Color(0xFFF8F4FF), Color(0xFFF0FFF8)],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Choose a QR category', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  const Text('Each category opens its own guided form, preview, quality check and export page.'),
                  const SizedBox(height: 14),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search website, UPI, Wi-Fi, business…'),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.08, crossAxisSpacing: 12, mainAxisSpacing: 12),
                itemCount: visible.length,
                itemBuilder: (context, index) => _CategoryCard(category: visible[index], onTap: () => _open(visible[index])),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final GeneratorCategory category;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? .965 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: widget.category.colors),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: widget.category.colors.last.withValues(alpha: .28), blurRadius: 18, offset: const Offset(0, 9))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(16)), child: Icon(widget.category.icon, color: Colors.white, size: 27)),
                const Spacer(),
                if (widget.category.premium) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .2), borderRadius: BorderRadius.circular(999)), child: const Row(children: [Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 13), SizedBox(width: 3), Text('PRO', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900))])),
              ]),
              const Spacer(),
              Text(widget.category.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 4),
              Text(widget.category.shortLabel, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withValues(alpha: .84), fontSize: 11.5, height: 1.25)),
              const SizedBox(height: 9),
              const Align(alignment: Alignment.bottomRight, child: Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20)),
            ]),
          ),
        ),
      );
}
