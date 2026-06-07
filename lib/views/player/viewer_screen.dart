import 'package:flutter/material.dart';
import '../../models/gif_info.dart';
import '../../services/video_cache_manager.dart';
import 'reels_player_item.dart';

class ViewerScreen extends StatefulWidget {
  final List<GifInfo> gifs;
  final int initialIndex;

  const ViewerScreen({
    super.key,
    required this.gifs,
    required this.initialIndex,
  });

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  late PageController _pageController;
  late int _currentPageIndex;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Preload current and next videos on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      VideoCacheManager.preloadVideo(widget.gifs[widget.initialIndex]);
      if (widget.initialIndex + 1 < widget.gifs.length) {
        VideoCacheManager.preloadVideo(widget.gifs[widget.initialIndex + 1]);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vertical PageView for Reels Player
          PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
              // Preload current and next videos
              VideoCacheManager.preloadVideo(widget.gifs[index]);
              if (index + 1 < widget.gifs.length) {
                VideoCacheManager.preloadVideo(widget.gifs[index + 1]);
              }
            },
            itemCount: widget.gifs.length,
            itemBuilder: (context, index) {
              return ReelsPlayerItem(
                gif: widget.gifs[index],
                isActive: index == _currentPageIndex,
              );
            },
          ),

          // Floating Back Button on Top-Left
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
