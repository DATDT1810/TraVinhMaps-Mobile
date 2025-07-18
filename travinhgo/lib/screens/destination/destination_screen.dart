import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../models/destination/destination.dart';
import '../../providers/destination_type_provider.dart';
import '../../services/destination_service.dart';
import '../../utils/constants.dart';
import '../../widget/destination_widget/destination_item.dart';

class DestinationScreen extends StatefulWidget {
  const DestinationScreen({super.key});

  @override
  State<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends State<DestinationScreen> {
  List<String> _destinationNames = [];
  List<Destination> _destinations = [];
  bool _isLoading = true;
  String? _selectedDestinationTypeId;

  String _searchQuery = '';

  // List<Destination> _searchSuggestions = [];

  @override
  void initState() {
    fetchDestinations();
    super.initState();
  }

  Future<void> fetchDestinations() async {
    final data = await DestinationService().getDestination();

    for (final destination in data) {
      if (destination.images.isNotEmpty) {
        await precacheImage(
          CachedNetworkImageProvider(destination.images.first),
          context,
        );
      }
    }

    setState(() {
      _destinations = data;
      _destinationNames = data.map((e) => e.name).toList();
      _isLoading = false;
    });
  }

  List<Destination> get _filteredDestinations {
    return _destinations.where((destination) {
      final matchesType = _selectedDestinationTypeId == null ||
          destination.destinationTypeId == _selectedDestinationTypeId;

      final matchesSearch = _searchQuery.isEmpty ||
          destination.name.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              title: Text(AppLocalizations.of(context)!.destination),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<String>.empty();
                      return _destinationNames.where((name) => name
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      setState(() {
                        _searchQuery = selection;
                      });
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onSubmitted: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context)!.searchOcopProduct,
                          prefixIcon: Icon(Icons.search,
                              color: theme.colorScheme.onSurfaceVariant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(60),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.6),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withOpacity(0.2)),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (BuildContext context, int index) {
                                final option = options.elementAt(index);
                                return InkWell(
                                  onTap: () {
                                    onSelected(option);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12.0, vertical: 12.0),
                                    child: Text(
                                      option,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  )),
            ),
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            destinationTypeProvider.destinationTypes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedDestinationTypeId = null;
                                  _searchQuery = '';
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.rectangle,
                                  color: _selectedDestinationTypeId == null
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.apps,
                                      size: 20,
                                      color: _selectedDestinationTypeId == null
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      AppLocalizations.of(context)!.all,
                                      style: TextStyle(
                                        color:
                                            _selectedDestinationTypeId == null
                                                ? theme.colorScheme.onPrimary
                                                : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          final type = destinationTypeProvider
                              .destinationTypes[index - 1];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDestinationTypeId = type.id;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.rectangle,
                                color: type.id == _selectedDestinationTypeId
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              child: Row(
                                children: [
                                  Image.network(
                                    type.marker?.image ?? "",
                                    width: 20,
                                    height: 20,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    type.name,
                                    style: TextStyle(
                                      color:
                                          type.id == _selectedDestinationTypeId
                                              ? theme.colorScheme.onPrimary
                                              : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                      ),
                    ),
                  ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return DestinationItem(
                      destination: _filteredDestinations[index],
                    );
                  },
                  childCount: _filteredDestinations.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
