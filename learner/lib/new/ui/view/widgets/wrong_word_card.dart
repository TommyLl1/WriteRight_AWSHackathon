import 'package:flutter/material.dart';
import 'package:writeright/new/data/models/wrong_character.dart';
import 'package:writeright/new/data/services/audio_service.dart';
import 'package:writeright/new/utils/logger.dart';
import 'package:writeright/new/ui/view_model/dictionary.dart';
import 'package:provider/provider.dart';

class WrongCharacterCard extends StatefulWidget {
  final WrongCharacter wrongCharacter;
  final VoidCallback onEdit;
  final VoidCallback? onPlaySound; // Made optional

  const WrongCharacterCard({
    required this.wrongCharacter,
    required this.onEdit,
    this.onPlaySound, // Made optional
    super.key,
  });

  @override
  State<WrongCharacterCard> createState() => _WrongCharacterCardState();
}

class _WrongCharacterCardState extends State<WrongCharacterCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isPlayingAudio = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _playPronunciation() async {
    if (widget.wrongCharacter.pronunciationUrl == null ||
        widget.wrongCharacter.pronunciationUrl!.isEmpty) {
      _showSnackBar('此字詞暫無發音資料');
      return;
    }

    try {
      setState(() {
        _isPlayingAudio = true;
      });

      await _audioService
          .playPronunciation(widget.wrongCharacter.pronunciationUrl!);

      // Reset the playing state after a reasonable duration
      // Most pronunciation audio should be short (1-3 seconds)
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isPlayingAudio = false;
          });
        }
      });

      AppLogger.info(
          'Playing pronunciation for: ${widget.wrongCharacter.character}');
    } catch (e) {
      AppLogger.error('Error playing pronunciation: $e');
      if (e.toString().contains('Failed to load audio')) {
        _showSnackBar('無法載入發音檔案，請檢查網路連線');
      } else {
        _showSnackBar('播放發音時發生錯誤');
      }
      if (mounted) {
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }

    // Call the original callback if provided
    widget.onPlaySound?.call();
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<DictionaryViewModel>(context);
    if (viewModel.isLoading) {
      // Show blank
      /// TODO: Use the same init with parent
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 6.0,
      ),
      child: GestureDetector(
        onTap: _toggleExpanded,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF012B44),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    // Character image or placeholder
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E4A5F),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: widget.wrongCharacter.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                widget.wrongCharacter.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                cacheWidth: 100,
                                cacheHeight: 100,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildCharacterPlaceholder(),
                              ),
                            )
                          : _buildCharacterPlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    // Character display
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.wrongCharacter.character,
                            style: const TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.wrongCharacter.wrongCount > 0 && viewModel.showWrongCountBadge)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '錯誤 ${widget.wrongCharacter.wrongCount} 次',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Row(
                      children: [
                        _buildActionButton(
                          icon: Icons.info_outline,
                          color: const Color(0xFF4CAF50),
                          onPressed: _toggleExpanded,
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.edit,
                          color: const Color(0xFF2196F3),
                          onPressed: widget.onEdit,
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: _isPlayingAudio
                              ? Icons.volume_off
                              : Icons.volume_up,
                          color:
                              widget.wrongCharacter.pronunciationUrl != null &&
                                      widget.wrongCharacter.pronunciationUrl!
                                          .isNotEmpty
                                  ? const Color(0xFFFF9800)
                                  : Colors.grey,
                          onPressed: _playPronunciation,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Expanded details section
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E4A5F),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.wrongCharacter.description != null)
                        _buildDetailSection(
                          '字義',
                          widget.wrongCharacter.description!,
                          Icons.lightbulb_outline,
                        ),
                      if (widget.wrongCharacter.description != null)
                        const SizedBox(height: 12),
                      _buildDetailSection(
                        '錯誤次數',
                        '${widget.wrongCharacter.wrongCount} 次',
                        Icons.error_outline,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailSection(
                        '最後錯誤時間',
                        _formatDateTime(widget.wrongCharacter.lastWrongAt),
                        Icons.access_time,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailSection(
                        '加入時間',
                        _formatDateTime(widget.wrongCharacter.createdAt),
                        Icons.calendar_today,
                      ),
                      // if (widget.wrongCharacter.pronunciationUrl != null) ...[
                      //   const SizedBox(height: 12),
                      //   _buildDetailSection(
                      //     '發音',
                      //     '點擊播放按鈕聆聽發音',
                      //     Icons.volume_up,
                      //   ),
                      // ],
                      if (widget.wrongCharacter.strokesUrl != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailSection(
                          '筆順',
                          '查看正確筆順',
                          Icons.edit,
                        ),
                      ],
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

  Widget _buildCharacterPlaceholder() {
    return Center(
      child: Text(
        widget.wrongCharacter.character,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小時前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分鐘前';
    } else {
      return '剛剛';
    }
  }
}
