import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../Models/review/reply_user_information.dart';
import '../../Models/review/review.dart';
import '../../utils/constants.dart';

// Time ago utility
String timeAgo(DateTime date) {
  final duration = DateTime.now().difference(date);
  if (duration.inMinutes < 1) return 'Just now';
  if (duration.inHours < 1) return '${duration.inMinutes} min ago';
  if (duration.inDays < 1) return '${duration.inHours} hr ago';
  return '${duration.inDays} day(s) ago';
}

class ReviewItem extends StatefulWidget {
  final ReviewResponse review;
  final void Function(ReplyUserInformation replyUserInformation)? onReplyTap;

  const ReviewItem({super.key, required this.review, this.onReplyTap});

  @override
  State<ReviewItem> createState() => _ReviewItemState();
}

class _ReviewItemState extends State<ReviewItem> {
  bool isExpanded = false; // trạng thái để show/hide replies

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final replies = review.reply ?? [];

    // Số lượng reply hiển thị ban đầu
    final repliesToShow = isExpanded ? replies : replies.take(1).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(
              image: (review.avatar != null && review.avatar!.isNotEmpty)
                  ? NetworkImage(review.avatar!)
                  : const AssetImage('assets/images/profile/profile.png') as ImageProvider,
              fit: BoxFit.fill,
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        const SizedBox(width: 10),
        // Review content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: name, time, rating
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeAgo(review.createdAt.toLocal()),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 72,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: kprimaryColor,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const Icon(Icons.star, size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (review.comment != null)
                Text(
                  review.comment!,
                  style: const TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 15),

              if (review.images != null && review.images!.isNotEmpty)
                SizedBox(
                  height: 55,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: review.images!.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Bạn đã bấm vào ảnh số ${index + 1}"),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 55,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10.0),
                            image: DecorationImage(
                              image: NetworkImage(review.images![index]),
                              fit: BoxFit.fill,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                        ),
                      );
                    },
                  ),
                ),

              GestureDetector(
                onTap: () {
                  if (widget.onReplyTap != null) {
                    widget.onReplyTap!(ReplyUserInformation(
                      reviewId: review.id,
                      userId: review.userId,
                      fullname: review.userName,
                    ));
                  }
                },
                child: const Text(
                  "Reply",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Reply list
              if (replies.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...repliesToShow.map((reply) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.reply, size: 18, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: (review.avatar != null && review.avatar!.isNotEmpty)
                                            ? NetworkImage(review.avatar!)
                                            : const AssetImage('assets/images/profile/profile.png')
                                        as ImageProvider,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    reply.userName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    timeAgo(reply.createdAt.toLocal()),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                              if (reply.content != null && reply.content!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    reply.content!,
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              if (reply.images != null && reply.images!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: SizedBox(
                                    height: 55,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      shrinkWrap: true,
                                      itemCount: reply.images!.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          width: 55,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10.0),
                                            image: DecorationImage(
                                              image: NetworkImage(reply.images![index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Show more / Show less button
                    if (replies.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              isExpanded = !isExpanded;
                            });
                          },
                          child: Text(
                            isExpanded ? "hide less" : "Show mmore ${replies.length - 1} reply",
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
