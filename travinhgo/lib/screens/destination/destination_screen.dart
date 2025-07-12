import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:developer' as developer;

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

    developer.log('tourist_destination: Retrieved ${data.length} destinations',
        name: 'destination_screen');
    if (data.isNotEmpty) {
      final firstDestination = data.first;
      developer.log(
          'tourist_destination: First destination details - '
          'ID: ${firstDestination.id}, '
          'Name: ${firstDestination.name}, '
          'Rating: ${firstDestination.avarageRating}, '
          'Description: ${firstDestination.description}, '
          'Address: ${firstDestination.address}, '
          'Location: ${firstDestination.location.coordinates}, '
          'Images: ${firstDestination.images}, '
          'Type ID: ${firstDestination.destinationTypeId}',
          name: 'destination_screen');
    }

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.white,
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
                          if (textEditingValue.text == '')
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
                              hintText: AppLocalizations.of(context)!
                                  .searchDestination,
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(60),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: kSearchBackgroundColor,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
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
                                      ? kprimaryColor
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(Icons.apps,
                                        size: 20,
                                        color:
                                            _selectedDestinationTypeId == null
                                                ? Colors.white
                                                : Colors.black),
                                    const SizedBox(width: 5),
                                    Text(
                                      AppLocalizations.of(context)!.all,
                                      style: TextStyle(
                                        color:
                                            _selectedDestinationTypeId == null
                                                ? Colors.white
                                                : Colors.black,
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
                                    ? kprimaryColor
                                    : Colors.white,
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
                                              ? Colors.white
                                              : Colors.black,
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
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
