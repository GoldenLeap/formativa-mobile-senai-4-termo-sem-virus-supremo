import 'package:flutter/material.dart';

class AppBottomBar extends StatelessWidget {
  const AppBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAF9),
        border: Border(top: BorderSide(color: Color(0xFFE5E7E6))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _item(0, 'Mapa', Icons.map_outlined, Icons.map),
              _item(1, 'Favoritos', Icons.favorite_border, Icons.favorite),
              _item(2, 'Perfil', Icons.person_outline, Icons.person),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(int index, String label, IconData icon, IconData selectedIcon) {
    final selected = currentIndex == index;
    final color = selected ? const Color(0xFF353B3D) : const Color(0xFF858C89);
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? selectedIcon : icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
