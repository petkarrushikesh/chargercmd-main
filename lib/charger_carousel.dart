import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ChargerCarousel extends StatefulWidget {
  const ChargerCarousel({Key? key}) : super(key: key);

  @override
  State<ChargerCarousel> createState() => _ChargerCarouselState();
}

class _ChargerCarouselState extends State<ChargerCarousel> {
  final List<String> imageUrls = [
    // New Scharge charger image (you can replace this URL with any other Scharge image)
    "https://www.scharge.co.in/web/image/36107-25f0f885/image%20render.263%20copy.webp",
    "https://m.media-amazon.com/images/I/61+I6kBOWzL.jpg",
    "https://www.scharge.co.in/web/image/36114-fee8e4f2/D1_30.webp",
  ];

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 210.0,
            autoPlay: true,
            enlargeCenterPage: true,
            viewportFraction: 0.9,
            aspectRatio: 16 / 9,
            autoPlayInterval: const Duration(seconds: 4),
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          items: imageUrls.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.fill,
                      height: 80,
                      width: 400,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: imageUrls.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => setState(() {
                _currentIndex = entry.key;
              }),
              child: Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentIndex == entry.key
                      ? Colors.blueAccent
                      : Colors.grey.shade400,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
