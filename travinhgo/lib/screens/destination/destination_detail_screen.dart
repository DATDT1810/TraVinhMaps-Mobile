import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:travinhgo/models/destination/destination.dart';
import 'package:travinhgo/providers/tag_provider.dart';
import 'package:travinhgo/services/destination_service.dart';
import 'package:travinhgo/widget/data_field_row.dart';
import 'package:travinhgo/widget/description_fm.dart';

import '../../Models/review/rating_summary.dart';
import '../../Models/review/reply.dart';
import '../../Models/review/review.dart';
import '../../providers/destination_type_provider.dart';
import '../../Models/interaction/item_type.dart';
import '../../providers/favorite_provider.dart';
import '../../providers/interaction_log_provider.dart';
import '../../services/review_service.dart';
import '../../utils/constants.dart';
import '../../utils/string_helper.dart';
import '../../widget/destination_widget/destination_detail_image_slider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../widget/review_widget/review_item.dart';
import 'comment_screen.dart';

class DestinationDetailScreen extends StatefulWidget {
  final String id;

  const DestinationDetailScreen({super.key, required this.id});

  @override
  State<DestinationDetailScreen> createState() =>
      _DestinationDetailScreenState();
}

class _DestinationDetailScreenState extends State<DestinationDetailScreen> {
  int currentImage = 0;
  int cuttentIndex = 0;
  late Destination destinationDetail;
  bool _isLoading = true;
  bool _isExpanded = false;
  late bool _isReviewsAllowed;

  late String desc;
  late String history;

  late List<String> allImageDestination;

  late List<ReviewResponse> reviews;
  RatingSummary? _ratingSummary;

  Timer? _interactionTimer;

  // for comment
  final TextEditingController _commentController = TextEditingController();

  var ratingData = [
  ];
  
  @override
  void initState() {
    super.initState();
    // fetchReviews(widget.id);
    // fetchDestination(widget.id);
    loadData();

    // Đặt timer 8 giây để log interaction
    _interactionTimer = Timer(Duration(seconds: 8), () {
      // Gọi provider để add log
      final interactionLogProvider =
      InteractionLogProvider.of(context, listen: false);
      interactionLogProvider.addInteracLog(
        widget.id,
        ItemType.Destination,
        8,
      );
    });
  }

  @override
  void dispose() {
    _interactionTimer?.cancel();
    super.dispose();
  }

  Future<void> loadData() async {
    await Future.wait([
      fetchDestination(widget.id),
      fetchReviews(widget.id),
    ]);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> preloadImages(List<String> urls) async {
    await Future.wait(urls.map(
          (url) => precacheImage(CachedNetworkImageProvider(url), context),
    ));
  }

  Future<void> fetchDestination(String id) async {
    final data = await DestinationService().getDestinationById(id);
    if (data == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.noDestinationFound)),
        );
        Navigator.pop(context);
      }
      return;
    }

    preloadImages(data.images);
    if (data.historyStory != null &&
        data.historyStory?.images?.isNotEmpty == true) {
      preloadImages(data.historyStory!.images!);
    }

    if (mounted) {
      setState(() {
        destinationDetail = data;
        desc = (destinationDetail.description ?? '').trim();
        history = (destinationDetail.historyStory?.content ?? '').trim();
        allImageDestination = [
          ...destinationDetail.images,
          ...?destinationDetail.historyStory?.images
        ];
      });
    }
  }

  Future<void> fetchReviews(String id) async {
    final reviewList = await ReviewService().getReviewsByDestinationId(id);
    debugPrint('is allow: ${reviewList?.hasReviewed ?? false}');

    if (reviewList == null) return;
    _isReviewsAllowed = reviewList.hasReviewed;
    _ratingSummary = reviewList.ratingSummary;
    

    if (mounted) {
      setState(() {
        reviews = reviewList.reviews;
        ratingData = [
          {'stars': 5, 'percent': _ratingSummary!.oneStarPercent},
          {'stars': 4, 'percent': _ratingSummary!.twoStarPercent},
          {'stars': 3, 'percent': _ratingSummary!.threeStarPercent},
          {'stars': 2, 'percent': _ratingSummary!.fourStarPercent},
          {'stars': 1, 'percent': _ratingSummary!.fiveStarPercent},
        ];
      });
    }
  }

  void updateRating() {
    // clear old data
    setState(() {
      _ratingSummary = null;
      ratingData = [];
    });
    
    int oneStar = 0;
    int twoStar = 0;
    int threeStar = 0;
    int fourStar = 0;
    int fiveStar = 0;

    for (var review in reviews) {
      switch (review.rating) {
        case 1:
          oneStar++;
          break;
        case 2:
          twoStar++;
          break;
        case 3:
          threeStar++;
          break;
        case 4:
          fourStar++;
          break;
        case 5:
          fiveStar++;
          break;
      }
    }

    int total = reviews.length;

    double getPercent(int count) => total == 0 ? 0 : (count / total) * 100;

    setState(() {
      _ratingSummary = RatingSummary(
        oneStar: oneStar,
        twoStar: twoStar,
        threeStar: threeStar,
        fourStar: fourStar,
        fiveStar: fiveStar,
        oneStarPercent: getPercent(oneStar),
        twoStarPercent: getPercent(twoStar),
        threeStarPercent: getPercent(threeStar),
        fourStarPercent: getPercent(fourStar),
        fiveStarPercent: getPercent(fiveStar),
      );
      
      ratingData = [
        {'stars': 5, 'percent': _ratingSummary!.fiveStarPercent},
        {'stars': 4, 'percent': _ratingSummary!.fourStarPercent},
        {'stars': 3, 'percent': _ratingSummary!.threeStarPercent},
        {'stars': 2, 'percent': _ratingSummary!.twoStarPercent},
        {'stars': 1, 'percent': _ratingSummary!.oneStarPercent},
      ];
    });
  }



  String timeAgo(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inMinutes < 1) return 'Just now';
    if (duration.inHours < 1) return '${duration.inMinutes} min ago';
    if (duration.inDays < 1) return '${duration.inHours} hr ago';
    return '${duration.inDays} day(s) ago';
  }

  @override
  Widget build(BuildContext context) {
    final destinationTypeProvider = DestinationTypeProvider.of(context);
    final favoriteProvider = FavoriteProvider.of(context);

    void _toggleExpanded() {
      setState(() {
        _isExpanded = !_isExpanded;
      });
    }

    final tagProvider = TagProvider.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          child: Column(
            children: [
              Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        DestinationDetailImageSlider(
                          onChange: (index) {
                            setState(() {
                              currentImage = index;
                            });
                            // Preload ảnh liền kề để tránh load chậm khi vuốt nhanh
                            if (index + 1 < allImageDestination.length) {
                              precacheImage(
                                  CachedNetworkImageProvider(
                                      allImageDestination[index + 1]),
                                  context);
                            }
                            if (index - 1 >= 0) {
                              precacheImage(
                                  CachedNetworkImageProvider(
                                      allImageDestination[index - 1]),
                                  context);
                            }
                          },
                          imageList: allImageDestination,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 8,
                    right: 8,
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Center(
                                  child: IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      icon: Image.asset(
                                          'assets/images/navigations/leftarrowwhile.png')),
                                ),
                              )),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: IconButton(
                                  iconSize: 18,
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  icon: Image.asset(
                                      'assets/images/navigations/share.png')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 230,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                          allImageDestination.length,
                              (index) =>
                              AnimatedContainer(
                                duration:
                                const Duration(microseconds: 300),
                                width: 20,
                                height: 8,
                                margin: EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: currentImage == index
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              )),
                    ),
                  ),
                  Positioned(
                    top: 210,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        favoriteProvider
                            .toggleDestinationFavorite(destinationDetail);
                      },
                      child: Icon(
                        favoriteProvider.isExist(destinationDetail.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.network(
                          tagProvider
                              .getTagById(destinationDetail.tagId)
                              .image,
                          width: 36,
                          height: 36,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          AppLocalizations.of(context)!.destination,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.favorite_sharp,
                          color: Colors.red,
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Text(
                          "82",
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        Text(
                          AppLocalizations.of(context)!.favorite,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          destinationDetail.name,
                          style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: kprimaryColor),
                        )),
                    const SizedBox(
                      height: 8,
                    ),
                    if (desc.isNotEmpty || history.isNotEmpty)
                      DescriptionFm(
                        description: [desc, history]
                            .where((e) => e.isNotEmpty)
                            .join('<br>'),
                        isExpanded: _isExpanded,
                        onToggle: _toggleExpanded,
                      ),
                    Divider(
                      color: Colors.grey.withOpacity(0.1),
                      thickness: 0.4,
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.openingHours,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        Text(
                          AppLocalizations.of(context)!.opening,
                          style: const TextStyle(
                              fontSize: 16, color: kprimaryColor),
                        ),
                        const SizedBox(
                          width: 6,
                        ),
                        if (destinationDetail.openingHours != null)
                          Text(
                            '${destinationDetail.openingHours?.openTime
                                .toString() ?? AppLocalizations.of(context)!
                                .notAvailable} - ${destinationDetail
                                .openingHours?.closeTime.toString() ??
                                AppLocalizations.of(context)!.notAvailable}',
                            style: const TextStyle(fontSize: 16),
                          )
                        else
                          Text(
                            AppLocalizations.of(context)!.notAvailable,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                      ],
                    ),
                    Divider(
                      color: Colors.grey.withOpacity(0.1),
                      thickness: 0.4,
                      height: 10,
                    ),
                    DataFieldRow(
                      title: AppLocalizations.of(context)!.ticket,
                      value: StringHelper.normalizeName(
                          destinationDetail.ticket) ??
                          AppLocalizations.of(context)!.notAvailable,
                    ),
                    DataFieldRow(
                      title: AppLocalizations.of(context)!.type,
                      value: StringHelper.toTitleCase(
                          destinationTypeProvider
                              .getDestinationtypeById(
                              destinationDetail.destinationTypeId)
                              .name),
                    ),
                    DataFieldRow(
                      title: AppLocalizations.of(context)!.address,
                      value: destinationDetail.address,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)!.location,
                          style: const TextStyle(
                              fontSize: 24, color: kprimaryColor),
                        )),
                    Divider(
                      color: Colors.grey.withOpacity(0.1),
                      thickness: 0.4,
                      height: 10,
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          AppLocalizations.of(context)!.rating(
                              destinationDetail.avarageRating.toString()),
                          style: const TextStyle(
                              fontSize: 24, color: kprimaryColor),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: ratingData.map((data) {
                          return Padding(
                            padding:
                            const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text('${data['stars']}'),
                                const SizedBox(width: 4),
                                Icon(Icons.star,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Container(
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          borderRadius:
                                          BorderRadius.circular(5),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: (data['percent'] ?? 0).toDouble() / 100,
                                        child: Container(
                                          height: 10,
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                            BorderRadius.circular(5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 60, 
                                  child: Text(
                                    '${(data['percent'] ?? 0).toStringAsFixed(1)}%',
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reviews', style: TextStyle(fontSize: 24, color: kprimaryColor),),
                        TextButton(
                          onPressed: () async {
                            final updatedReviews = await Navigator.push<List<ReviewResponse>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CommentScreen(
                                  destination: destinationDetail,
                                  reviews: reviews,
                                  isReviewsAllowed: _isReviewsAllowed,
                                ),
                              ),
                            );

                            // Nếu có dữ liệu trả về thì cập nhật lại
                            if (updatedReviews != null && mounted) {
                              setState(() {
                                reviews = updatedReviews;
                                updateRating();
                              });
                            }
                          },
                          child: Text('Show all', style: TextStyle(color: kprimaryColor)),
                        ),

                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Column(
                      children: reviews.map((review) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: ReviewItem(review: review),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
