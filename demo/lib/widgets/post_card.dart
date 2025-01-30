import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../screens/profile_page.dart';
import 'dart:async';


class PostCard extends StatelessWidget {

  final Post post;
  final VoidCallback? onLikePressed;

  const PostCard({
    super.key,
    required this.post,
    this.onLikePressed,
  });
  
  Future<Size> _getImageDimension(String imageUrl) async {
    final Completer<Size> completer = Completer<Size>();
    final Image image = Image.network(imageUrl);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color(0xFFfafafa),
      margin: const EdgeInsets.all(1.0),  // gap between post card
      elevation: 1, // outside shallow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),  // outside corner radius
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info with navigation
            // InkWell(
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //         builder: (context) => ProfilePage(userId: post.user.id),
            //       ),
            //     );
            //   },
            //   child: Padding(
            //     padding: const EdgeInsets.symmetric(
            //         horizontal: 8.0), 
            //     child: Row(
            //       children: [
            //         CircleAvatar(
            //           backgroundImage: NetworkImage(post.user.profilePictureUrl),
            //           radius: 10,
            //         ),

            //         Expanded(
            //           child: Text(
            //             post.user.username,
            //             style: const TextStyle(
            //               fontWeight: FontWeight.bold,
            //               fontSize: 14,
            //             ),
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),


            // Cover Photo
            if (post.images.isNotEmpty)
              FutureBuilder(
                future: _getImageDimension(post.images.first.imageUrl),
                builder: (context, AsyncSnapshot<Size> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(); // Show loading indicator while image dimensions are being fetched
                  } else if (snapshot.hasError || !snapshot.hasData) {
                    return Text("Error loading image");
                  } else {
                    double aspectRatio = snapshot.data!.width / snapshot.data!.height;

                    // Set upper and lower bounds for aspect ratio
                    const double minAspectRatio = 5 / 7;
                    const double maxAspectRatio = 4 / 3;

                    aspectRatio = aspectRatio.clamp(minAspectRatio, maxAspectRatio);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      child: AspectRatio(
                        aspectRatio: aspectRatio,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4), // image corner radius
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                post.images.first.imageUrl,
                                fit: BoxFit.cover,
                              ),
                              // Location inside image
                              if (post.location.name.isNotEmpty)
                                Positioned(
                                  bottom: 0,  // Position from the bottom
                                  left: 0,    // Position from the left
                                  right: 0,   // Optional: Keep text within bounds
                                  child: Container(
                                    // margin: const EdgeInsets.symmetric(horizontal: 12),  // side border
                                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        // Smooth gradient color
                                        colors: [
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.6),
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.6),
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.5),
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.4),
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.2),
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.1),
                                          const Color.fromARGB(255, 116, 116, 116).withOpacity(0.05),
                                        ],
                                        stops: [0.0, 0.2, 0.4, 0.55, 0.8, 0.9, 1.0],

                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),

                                        Expanded(
                                          child: Text(
                                            ' ${post.location.name}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),



            // Content Section
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 4,
                horizontal: 10.0), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    post.title.isNotEmpty
                        ? post.title
                        : 'No Title',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    maxLines: 2,  // Allow up to 2 lines
                    overflow: TextOverflow.ellipsis,  // Show ellipsis if the text overflows
                    textAlign: TextAlign.start,  // Optional: Align the text properly
                  ),
                ],
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Ensures space between author and like button
              children: [
                // Author Info with navigation
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(userId: post.user.id),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(post.user.profilePictureUrl),
                          radius: 10,
                        ),
                        const SizedBox(width: 5),  // Space between avatar and username
                        Text(
                          post.user.username,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

                // Like Button and Count
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),  // Adds space to the right side
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : Colors.grey,
                        ),
                        iconSize: 20,
                        onPressed: onLikePressed,
                      ),
                      const SizedBox(width: 4),  // Space between the icon and count
                      Text(
                        '${post.likesCount}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            )


          ],
        ),
      ),
    );
  }
}

