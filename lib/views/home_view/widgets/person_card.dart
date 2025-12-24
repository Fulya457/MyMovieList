import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/models/person_model.dart';

class PersonCard extends StatelessWidget {
  final Person person;

  const PersonCard({super.key, required this.person});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/person-detail', extra: person),
      child: Column(
        children: [
          Expanded(
            child: Hero(
              tag: 'person_${person.id}',
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surfaceDark,
                ),
                clipBehavior: Clip.antiAlias,
                child: person.profilePath.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: person.profilePath,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(color: Colors.grey),
                        errorWidget: (c, u, e) => Container(
                          color: Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            person.name,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            person.knownFor,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
