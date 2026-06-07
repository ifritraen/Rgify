import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../models/gif_info.dart';
import '../../providers/playback_queue_provider.dart';

class PlaybackQueueSidebar extends StatelessWidget {
  final PageController pageController;

  const PlaybackQueueSidebar({super.key, required this.pageController});

  @override
  Widget build(BuildContext context) {
    final queueProvider = Provider.of<PlaybackQueueProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width * 0.75;
    final sidebarBg = isDark ? Colors.black.withAlpha(180) : Colors.white.withAlpha(210);
    final textColor = isDark ? Colors.white : AppTheme.textPrimaryLight;
    final subtitleColor = isDark ? Colors.white60 : AppTheme.textSecondary;
    final borderColor = isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20);

    if (!queueProvider.showQueueSidebar) return const SizedBox.shrink();

    return Stack(
      children: [
        // Semi-transparent dismissible backdrop
        GestureDetector(
          onTap: () => queueProvider.setQueueSidebarVisible(false),
          child: Container(
            color: Colors.black45,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        // Frosted Glass Sidebar aligned to the right
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: width,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: sidebarBg,
                  border: Border(left: BorderSide(color: borderColor, width: 1)),
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'PLAYBACK QUEUE',
                              style: GoogleFonts.outfit(
                                color: textColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: textColor),
                              onPressed: () => queueProvider.setQueueSidebarVisible(false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 1),
                      // Reorderable Queue List
                      Expanded(
                        child: ReorderableListView.builder(
                          buildDefaultDragHandles: false, // drag from left side explicitly
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: queueProvider.queue.length,
                          onReorder: (oldIndex, newIndex) {
                            queueProvider.reorderVideos(oldIndex, newIndex);
                            // If index shifted, scroll page controller to correct page
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              pageController.jumpToPage(queueProvider.currentIndex);
                            });
                          },
                          itemBuilder: (context, index) {
                            final gif = queueProvider.queue[index];
                            final isActive = queueProvider.currentIndex == index;
                            
                            return _buildQueueItem(
                              key: ValueKey(gif.id + '_' + index.toString()),
                              context: context,
                              gif: gif,
                              index: index,
                              isActive: isActive,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              queueProvider: queueProvider,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQueueItem({
    required Key key,
    required BuildContext context,
    required GifInfo gif,
    required int index,
    required bool isActive,
    required Color textColor,
    required Color subtitleColor,
    required PlaybackQueueProvider queueProvider,
  }) {
    final itemBg = isActive ? AppTheme.primaryNeon.withAlpha(35) : Colors.transparent;
    final titleStyle = TextStyle(
      color: isActive ? AppTheme.primaryNeon : textColor,
      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
      fontSize: 13,
    );

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: itemBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? AppTheme.primaryNeon.withAlpha(80) : Colors.transparent,
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        // Left drag handle
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.drag_handle, color: Colors.white54, size: 20),
              ),
            ),
            const SizedBox(width: 4),
            // Video Preview Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.network(
                  (gif.urls.thumbnail ?? '').isNotEmpty ? gif.urls.thumbnail! : (gif.urls.poster ?? ''),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                ),
              ),
            ),
          ],
        ),
        // Title starts with creator name
        title: Text(
          '@${gif.userName} - ${gif.id}',
          style: titleStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${gif.duration.toStringAsFixed(1)}s • ${gif.views} views',
          style: TextStyle(color: subtitleColor, fontSize: 11),
        ),
        // Tap to play
        onTap: () {
          queueProvider.setCurrentIndex(index);
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        // Right remove button
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () {
            queueProvider.removeVideo(index, context);
            // Sync page controller if active item index shifted
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (queueProvider.queue.isNotEmpty) {
                pageController.jumpToPage(queueProvider.currentIndex);
              }
            });
          },
        ),
      ),
    );
  }
}
