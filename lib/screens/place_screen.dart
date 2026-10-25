import 'package:flutter/material.dart';

import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

/// Choose where the times are for: "Use my location", or a place with an
/// official timetable (searchable in English and Arabic). Closes with true
/// once a choice is made, so the main screen knows to reload.
class PlaceScreen extends StatefulWidget {
  const PlaceScreen({super.key, required this.place, required this.places});

  /// The saved choice: a place, or null for "Use my location".
  final ValueNotifier<Place?> place;

  /// Every place with an official timetable, mosque first.
  final List<Place> places;

  @override
  State<PlaceScreen> createState() => _PlaceScreenState();
}

class _PlaceScreenState extends State<PlaceScreen> {
  String _query = '';

  void _choose(Place? place) {
    widget.place.value = place;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final matches = searchPlaces(widget.places, _query);
    return Scaffold(
      appBar: AppBar(title: Text(text.location)),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(text.useMyLocation),
            subtitle: Text(text.useMyLocationHint),
            selected: widget.place.value == null,
            onTap: () => _choose(null),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                labelText: text.searchPlaces,
              ),
              onChanged: (query) {
                setState(() {
                  _query = query;
                });
              },
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? Center(child: Text(text.noPlacesFound))
                : ListView.builder(
                    itemCount: matches.length,
                    itemBuilder: (context, index) =>
                        _placeTile(matches[index], text.localeName),
                  ),
          ),
        ],
      ),
    );
  }

  /// A place in the app's language, with its name in the other language
  /// underneath, so either can be recognised.
  Widget _placeTile(Place place, String language) => ListTile(
    leading: Icon(place.isMosque ? Icons.mosque : Icons.place),
    title: Text(place.nameFor(language)),
    subtitle: Text(place.nameFor(language == 'ar' ? 'en' : 'ar')),
    selected: widget.place.value?.id == place.id,
    onTap: () => _choose(place),
  );
}
