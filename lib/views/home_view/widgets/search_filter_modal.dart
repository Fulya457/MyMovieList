// Dosya: lib/views/home_view/widgets/search_filter_modal.dart

import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';
import 'package:mymovielist/data/movie_manager.dart';

class SearchFilterModal extends StatefulWidget {
  final VoidCallback onApply;

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
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, color: Colors.grey)),
          const SizedBox(height: 20),

          Text(
            "Filter",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 20),

          Text(
            "Person",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildFilterChip("Actor", manager.filterActor, (val) {
                setState(() => manager.filterActor = val);
              }),
              const SizedBox(width: 10),
              _buildFilterChip("Director", manager.filterDirector, (val) {
                setState(() => manager.filterDirector = val);
              }),
            ],
          ),

          const SizedBox(height: 20),

          Text(
            "Genres",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: manager.genreMap.entries.map((genre) {
                  final isSelected = manager.activeGenreFilters.contains(
                    genre.key,
                  );
                  return FilterChip(
                    label: Text(genre.value),

                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryBlue,
                    backgroundColor: AppTheme.backgroundBlack,
                    checkmarkColor: Colors.white,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          manager.activeGenreFilters.add(genre.key);
                        } else {
                          manager.activeGenreFilters.remove(genre.key);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {
                Navigator.pop(context);
                widget.onApply();
              },
              child: const Text(
                "Uygula",
                style: TextStyle(color: Colors.white, fontSize: 16),
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

      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textColor,
        fontWeight: FontWeight.bold,
      ),
      selected: isSelected,
      selectedColor: AppTheme.primaryBlue,
      backgroundColor: AppTheme.backgroundBlack,
      checkmarkColor: Colors.white,
      onSelected: onSelected,
    );
  }
}
