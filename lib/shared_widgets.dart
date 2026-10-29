part of 'main.dart';

class SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const SectionHeading({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9AA8C7) : const Color(0xFF667085);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(uiText(title), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 21, letterSpacing: -0.4)),
        const SizedBox(height: 5),
        Text(uiText(subtitle), style: TextStyle(color: muted, fontSize: 12, height: 1.4)),
      ],
    );
  }
}

class FormSectionTitle extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const FormSectionTitle({super.key, required this.number, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9AA8C7) : const Color(0xFF667085);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 33, height: 33, alignment: Alignment.center, decoration: BoxDecoration(color: primary.withOpacity(0.14), borderRadius: BorderRadius.circular(10)), child: Text(number, style: TextStyle(color: primary, fontWeight: FontWeight.w800, fontSize: 12))),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(uiText(title), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(uiText(subtitle), style: TextStyle(fontSize: 11, color: muted))])),
    ]);
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  const EmptyState({super.key, required this.icon, required this.title, required this.message, required this.buttonLabel, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF9AA8C7) : const Color(0xFF667085);
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF151D33) : Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF303B5A) : const Color(0xFFE4E7F0))),
      child: Column(children: [
        Container(width: 68, height: 68, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.14), shape: BoxShape.circle), child: Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 7),
        Text(uiText(message), textAlign: TextAlign.center, style: TextStyle(color: muted, height: 1.5, fontSize: 12)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
      ]),
    );
  }
}
