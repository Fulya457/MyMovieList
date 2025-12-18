import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class SearchFilterModal extends StatefulWidget {
  final VoidCallback onApply; // Uygula butonuna basılınca ne olacak?

  const SearchFilterModal({super.key, required this.onApply});

  @override
  State<SearchFilterModal> createState() => _SearchFilterModalState();
}

class _SearchFilterModalState extends State<SearchFilterModal> {
  @override
  Widget build(BuildContext context) {
    final manager = MovieManager.instance;

    return Container(
      padding: const EdgeInsets.all(20),
      height: 600,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Arama Filtreleri",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Rol Seçimi",
            style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip(
                "Aktör",
                manager.filterActor,
                (val) => setState(() => manager.filterActor = val),
              ),
              const SizedBox(width: 10),
              _buildFilterChip(
                "Yönetmen",
                manager.filterDirector,
                (val) => setState(() => manager.filterDirector = val),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Film Türleri",
            style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                children: manager.genreNameToId.entries.map((entry) {
                  final isSelected = manager.activeGenreFilters.contains(
                    entry.value,
                  );
                  return FilterChip(
                    label: Text(entry.key),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val)
                          manager.activeGenreFilters.add(entry.value);
                        else
                          manager.activeGenreFilters.remove(entry.value);
                      });
                    },
                    backgroundColor: AppTheme.surfaceDark,
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onApply(); // HomeView'daki aramayı tetikle
              },
              child: const Text(
                "Uygula",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: AppTheme.surfaceDark,
      selectedColor: AppTheme.primaryBlue,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
    );
  }
}
