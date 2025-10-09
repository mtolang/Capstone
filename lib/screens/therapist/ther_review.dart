import 'package:flutter/material.dart';
import 'package:kindora/screens/therapist/ther_tab.dart';

class TherapistReview extends StatelessWidget {
  const TherapistReview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size mq = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Therapist Review',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF006A5B),
      ),
      body: Stack(
        children: [
          // Bottom Background Image
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.3),
              child: Image.asset(
                'asset/images/Ellipse 2.png', // bottom background
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Background Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ConstrainedBox(
              constraints: BoxConstraints.expand(height: mq.height * 0.30),
              child: Image.asset(
                'asset/images/Ellipse 1.png', // top background
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Custom Tab bar (Centered on the top background)
          const Positioned(
            top: 50, // Adjust the position as needed
            left: 0,
            right: 0,
            child: Center(
              child: TherDashTab(initialTabIndex: 2), // Reviews tab active
            ),
          ),

          // Content Below CustomTabBar
          Positioned(
            top: mq.height * 0.30,
            left: 0,
            right: 0,
            bottom: mq.height * 0.3, // Adjust the bottom position
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Review 1
                  ReviewWidget(
                    userName: 'User 1',
                    reviewText: 'Great experience at The Tiny House!',
                    rating: 5,
                    reviewDate: DateTime.now().toString(),
                  ),

                  // Reply Text Field for Review 1
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Write your reply here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ),

                  // Reply Button for Review 1
                  ElevatedButton(
                    onPressed: () {
                      // Handle reply submission for Review 1
                    },
                    child: const Text('Reply'),
                  ),

                  // Review 2
                  ReviewWidget(
                    userName: 'User 2',
                    reviewText: 'Highly recommended!',
                    rating: 4,
                    reviewDate: DateTime.now().toString(),
                  ),

                  // Reply Text Field for Review 2
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        hintText: 'Write your reply here...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                    ),
                  ),

                  // Reply Button for Review 2
                  ElevatedButton(
                    onPressed: () {
                      // Handle reply submission for Review 2
                    },
                    child: const Text('Reply'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewWidget extends StatelessWidget {
  final String userName;
  final String reviewText;
  final int rating;
  final String reviewDate;

  const ReviewWidget({
    Key? key,
    required this.userName,
    required this.reviewText,
    required this.rating,
    required this.reviewDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const CircleAvatar(
            // You can use the reviewer's profile image here
            // Example: AssetImage('asset/images/user_avatar.png'),
            radius: 30, // Adjust the size
          ),
          title: Text(userName),
          subtitle: Text('Date: $reviewDate'), // Include the review date
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rating: $rating/5',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle reply button click
                    },
                    child: const Text('Reply'),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(reviewText),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class CustomTabBar extends StatelessWidget {
  const CustomTabBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TabBarItem(text: 'Profile'),
        TabBarItem(text: 'Gallery'),
        TabBarItem(text: 'Reviews'),
      ],
    );
  }
}

class TabBarItem extends StatelessWidget {
  final String text;

  const TabBarItem({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF006A5B),
      ),
    );
  }
}
