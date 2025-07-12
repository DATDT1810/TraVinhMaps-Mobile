import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/local_specialties/local_specialties.dart';
import 'package:travinhgo/services/local_specialtie_service.dart';
import 'package:travinhgo/widget/local_specialty_widget/local_specialty_item.dart';

import '../../utils/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalSpecialtyScreen extends StatefulWidget {
  const LocalSpecialtyScreen({super.key});

  @override
  State<LocalSpecialtyScreen> createState() => _LocalSpecialtyScreenState();
}

class _LocalSpecialtyScreenState extends State<LocalSpecialtyScreen> {
  List<String> _localSpecialtyName = [];
  List<LocalSpecialties> _localSpecialties = [];
  bool _isLoading = true;

  String _searchQuery = '';

  @override
  void initState() {
    fetchLocalSpecialty();
    super.initState();
  }

  Future<void> fetchLocalSpecialty() async {
    final data = await LocalSpecialtieService().getLocalSpecialtie();

    for (final localItem in data) {
      if (localItem.images.isNotEmpty) {
        await precacheImage(
          CachedNetworkImageProvider(localItem.images.first),
          context,
        );
      }
    }

    setState(() {
      _localSpecialties = data;
      _localSpecialtyName = data.map((e) => e.foodName).toList();
      _isLoading = false;
    });
  }

  List<LocalSpecialties> get _filteredLocals {
    return _localSpecialties.where((local) {
      final matchesSearch = _searchQuery.isEmpty ||
          local.foodName.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
          child: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          snap: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text(AppLocalizations.of(context)!.localSpecialty),
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
                      return _localSpecialtyName.where((name) => name
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
                          hintText: AppLocalizations.of(context)!.searchOcopProduct,
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1, childAspectRatio: 1.5),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return LocalSpecialtyItem(
                          localSpecialty: _filteredLocals[index]);
                    },
                    childCount: _filteredLocals.length,
                  ),
                ),
              ),
      ])),
    );
  }
}
