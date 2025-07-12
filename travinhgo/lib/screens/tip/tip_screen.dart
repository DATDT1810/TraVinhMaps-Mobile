import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/tip/tip.dart';
import '../../providers/tag_provider.dart';
import '../../services/tip_service.dart';
import '../../utils/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../utils/string_helper.dart';

class TipScreen extends StatefulWidget {
  const TipScreen({super.key});

  @override
  State<TipScreen> createState() => _TipScreenState();
}

class _TipScreenState extends State<TipScreen> {
  List<Tip> _tips = [];
  List<String> _nameTips = [];
  bool _isLoading = true;
  List<bool> _expandedList = [];

  String _searchQuery = '';
  String? _selectedTipTypeId;

  @override
  void initState() {
    super.initState();
    fetchTips();
  }

  Future<void> fetchTips() async {
    final data = await TipService().getTips();

    setState(() {
      _tips = data;
      _nameTips = data.map((e) => e.title).toList();
      _expandedList = List.generate(data.length, (_) => false);
      _isLoading = false;
    });
  }

  List<Tip> get _filteredTips {
    return _tips.where((tip) {
      final matchesType = _selectedTipTypeId == null ||
          tip.tagId == _selectedTipTypeId;
      
      final matchesSearch = _searchQuery.isEmpty ||
          tip.title.toLowerCase().contains(_searchQuery.toLowerCase());
      
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tagProvider = Provider.of<TagProvider>(context);

    return Scaffold(
      backgroundColor: kbackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: Text(
                AppLocalizations.of(context)!.tipTravel,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Search field
            SliverToBoxAdapter(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty)
                        return const Iterable<String>.empty();
                      return _nameTips.where((name) => name
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
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                  tagProvider.tags.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTipTypeId = null;
                            _searchQuery = '';
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            color: _selectedTipTypeId == null ? kprimaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedTipTypeId == null ? kprimaryColor : Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.apps,
                                  size: 20,
                                  color:
                                  _selectedTipTypeId == null
                                      ? Colors.white
                                      : Colors.black),
                              const SizedBox(width: 5),
                              Text(
                                AppLocalizations.of(context)!.all,
                                style: TextStyle(
                                  color:
                                  _selectedTipTypeId == null
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final tag = tagProvider
                        .tags[index - 1];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTipTypeId = tag.id;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: tag.id == _selectedTipTypeId ? kprimaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: tag.id == _selectedTipTypeId ? kprimaryColor : Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            Image.network(
                              tag.image ?? "",
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tag.name,
                              style: TextStyle(
                                color:
                                tag.id == _selectedTipTypeId
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

            // Loading or list of tips
            _isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final tip = _filteredTips[index];
                        final tag = tagProvider.getTagById(tip.tagId);
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      StringHelper.toTitleCase(tip.title),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            tag.image,
                                            width: 26,
                                            height: 26,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 4,),
                                        Text(
                                          tag.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                trailing: Icon(_expandedList[index]
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                                onTap: () {
                                  setState(() {
                                    _expandedList[index] =
                                        !_expandedList[index];
                                  });
                                },
                              ),
                              if (_expandedList[index])
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: Text(
                                    tip.content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                      childCount: _filteredTips.length,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
