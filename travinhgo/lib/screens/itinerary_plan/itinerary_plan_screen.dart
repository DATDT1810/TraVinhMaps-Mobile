import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Models/itinerary_plan/itinerary_plan.dart';
import '../../providers/destination_type_provider.dart';
import '../../services/itinerary_plan_service.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';

class ItineraryPlanScreen extends StatefulWidget {
  const ItineraryPlanScreen({super.key});

  @override
  State<ItineraryPlanScreen> createState() => _ItineraryPlanScreenState();
}

class _ItineraryPlanScreenState extends State<ItineraryPlanScreen> {
  List<ItineraryPlan> _itineraryPlans = [];
  List<String> listOptions = [];
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchItineraryPlan();
  }

  Future<void> fetchItineraryPlan() async {
    final data = (await ItineraryPlanService().getItineraryPlan()).reversed.toList();

    setState(() {
      _itineraryPlans = data;
      listOptions = data.map((e) => e.name).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    return Scaffold(
      backgroundColor: kbackgroundColor,
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Colors.white,
            title: const Text('Itinerary Plan'),
            centerTitle: true,
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
                  child: SizedBox(
                    height: 60,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: listOptions.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              color: index == _selectedIndex
                                  ? kprimaryColor
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            child: Row(
                              children: [
                                Text(
                                  StringHelper.toTitleCase(
                                      listOptions[index]),
                                  style: TextStyle(
                                    color:
                                    index == _selectedIndex
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
          _isLoading
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Scaffold(),
                    ),
                  ),
                )
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  StringHelper.toTitleCase(
                                      _itineraryPlans[_selectedIndex].name),
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              SizedBox(width: 26), // khoảng cách nhỏ
                              Text(_itineraryPlans[_selectedIndex].duration ?? "Unknow", style: TextStyle(fontSize: 14),)
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount:
                                _itineraryPlans[_selectedIndex].touristDestinations.length,
                            itemBuilder: (context, index) {
                              final item =
                                  _itineraryPlans[_selectedIndex].touristDestinations[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Thời gian
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 60,
                                          alignment: Alignment.center,
                                          // Căn giữa nội dung nếu cần
                                          child: Text(
                                            index.toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),
                                    // Nội dung
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: kprimaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Image.network(
                                                destinationTypeProvider
                                                        .getDestinationtypeById(
                                                            item.destinationTypeId)
                                                        .marker
                                                        ?.image ??
                                                    '',
                                                width: 25,
                                                height: 25,
                                              ),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              Expanded(
                                                child: Text(
                                                  item.address.toString(),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: true,
                                                  style:
                                                      TextStyle(fontSize: 14),
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
        ],
      )),
    );
  }
}
