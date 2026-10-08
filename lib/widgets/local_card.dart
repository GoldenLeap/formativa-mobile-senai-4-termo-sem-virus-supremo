import 'package:flutter/material.dart';

import '../models/local.dart';
import 'local_image.dart';

class LocalCard extends StatelessWidget {
  const LocalCard({super.key, required this.local, required this.onTap});

  final Local local;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const muted = Color(0xFF777D7A);
    return Material(
      color: const Color(0xFFFAFBFA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: Color(0xFFE6E9E7)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: LocalImage(url: local.fotos.firstOrNull),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF353B3D),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      local.categoria,
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: muted,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${local.distancia.toStringAsFixed(1).replaceAll('.', ',')} km',
                          style: const TextStyle(fontSize: 11, color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 13,
                          color: Color(0xFF353B3D),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          local.avaliacao.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (local.favorito)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.favorite,
                    size: 16,
                    color: Color(0xFF777D7A),
                  ),
                ),
              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFF777D7A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
