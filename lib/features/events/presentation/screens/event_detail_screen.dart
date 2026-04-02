// lib/features/events/presentation/screens/event_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/web_image.dart' as webimg;
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/event.dart';
import '../../../tickets/presentation/providers/ticket_providers.dart';

// Stateful widget'a dönüştürüyoruz ki like durumunu yönetebileyelim
class EventDetailScreen extends ConsumerStatefulWidget {
  final EventItem event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  late bool isLiked;
  late int likeCount;

  @override
  void initState() {
    super.initState();
    // Başlangıçta event'in like durumunu alıyoruz
    final cache = ref.read(genericLikeStateCacheProvider);
    isLiked = cache[widget.event.id] ?? widget.event.isLiked;
    likeCount = widget.event.likeCount;
  }

  /// Like butonuna tıklandığında çalışacak fonksiyon
  /// Gerçek uygulamada burada bir API çağrısı yapılır
  void _toggleLike() {
    final current = ref.read(genericLikeStateCacheProvider)[widget.event.id] ?? isLiked;
    final next = !current;
    setState(() {
      if (next) {
        likeCount++;
        isLiked = true;
      } else {
        likeCount = likeCount > 0 ? likeCount - 1 : 0;
        isLiked = false;
      }
    });

    // Global önbelleği güncelle - diğer ekranlarla senkron kalp durumu
    ref.read(genericLikeStateCacheProvider.notifier).setLikeState(widget.event.id, next);

    // Haptic feedback (titreşim) ekleyelim
    HapticFeedback.lightImpact();

    // Kullanıcıya bildirim gösterelim
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isLiked ? '❤️ Etkinlik beğenildi!' : '💔 Beğeni kaldırıldı'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Etkinliği paylaşma fonksiyonu
  /// Event bilgilerini metin olarak paylaşır
  void _shareEvent() {
    final eventText = '''
🎪 ${widget.event.name}

📅 ${widget.event.dateTime != null ? DateFormat('dd MMMM yyyy EEEE', 'tr_TR').format(widget.event.dateTime!.toLocal()) : 'Tarih belirtilmemiş'}
⏰ ${widget.event.dateTime != null ? DateFormat('HH:mm', 'tr_TR').format(widget.event.dateTime!.toLocal()) : ''}

📍 ${_formatVenue()}

${widget.event.description?.isNotEmpty == true ? '📝 ${widget.event.description}\n' : ''}
${widget.event.priceRange?.isNotEmpty == true ? '💰 Fiyat: ${widget.event.priceRange}\n' : ''}
${widget.event.ticketUrl?.isNotEmpty == true ? '🎫 Bilet: ${widget.event.ticketUrl}\n' : ''}

📱 StubStreet uygulaması ile paylaşıldı
''';

    Share.share(
      eventText,
      subject: widget.event.name,
    );
  }

  /// Ticketmaster URL'ini açar
  void _launchTicketmasterUrl() async {
    final url = widget.event.ticketUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('URL açılamıyor: $url')),
          );
        }
      }
    } else {
      // Fallback - ID ile Ticketmaster sayfasını oluştur
      final fallbackUrl = 'https://www.ticketmaster.com/event/${widget.event.id}';
      final uri = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Venue ve şehir bilgisini formatlar
  String _formatVenue() {
    final parts = <String>[];
    if (widget.event.venueName?.isNotEmpty == true) {
      parts.add(widget.event.venueName!);
    }
    if (widget.event.city?.isNotEmpty == true) {
      parts.add(widget.event.city!);
    }
    return parts.isEmpty ? 'Mekan belirtilmemiş' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final cached = ref.watch(genericLikeStateCacheProvider);
    final effectiveIsLiked = cached[widget.event.id] ?? isLiked;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.event.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Like butonu
          IconButton(
            onPressed: _toggleLike,
            icon: Icon(
              effectiveIsLiked ? Icons.favorite : Icons.favorite_border,
              color: effectiveIsLiked ? Colors.red : null,
            ),
            tooltip: isLiked ? 'Beğeniyi Kaldır' : 'Beğen',
          ),
          // Paylaş butonu
          IconButton(
            onPressed: _shareEvent,
            icon: const Icon(Icons.share),
            tooltip: 'Paylaş',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero resim
            if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty)
              Hero(
                tag: 'eventImage_${widget.event.id}',
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(webimg.webSafeImageUrl(widget.event.imageUrl!)),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {
                        debugPrint('Event image load error: $error for URL: ${widget.event.imageUrl}');
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Like sayısını resmin üzerinde gösterelim
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount beğeni',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etkinlik başlığı
                  Text(
                    widget.event.name,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  // Kategori bilgileri (genre/segment)
                  if (widget.event.genre != null || widget.event.segment != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (widget.event.segment != null)
                          Chip(
                            label: Text(widget.event.segment!),
                            backgroundColor: colorScheme.primaryContainer,
                            labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                          ),
                        if (widget.event.genre != null)
                          Chip(
                            label: Text(widget.event.genre!),
                            backgroundColor: colorScheme.secondaryContainer,
                            labelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Tarih bilgisi
                  _buildInfoCard(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Tarih',
                    content: widget.event.dateTime != null
                        ? DateFormat('dd MMMM yyyy EEEE', 'tr_TR')
                            .format(widget.event.dateTime!.toLocal())
                        : 'Belirtilmemiş',
                  ),

                  const SizedBox(height: 16),

                  // Saat bilgisi
                  _buildInfoCard(
                    context,
                    icon: Icons.access_time,
                    title: 'Saat',
                    content: widget.event.dateTime != null
                        ? DateFormat('HH:mm', 'tr_TR')
                            .format(widget.event.dateTime!.toLocal())
                        : 'Belirtilmemiş',
                  ),

                  const SizedBox(height: 16),

                  // Mekan bilgisi
                  _buildInfoCard(
                    context,
                    icon: Icons.location_on,
                    title: 'Mekan',
                    content: _formatVenue(),
                  ),

                  // Fiyat bilgisi (varsa)
                  if (widget.event.priceRange?.isNotEmpty == true) ...[
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      context,
                      icon: Icons.attach_money,
                      title: 'Fiyat Aralığı',
                      content: widget.event.priceRange!,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Etkinlik hakkında - Her zaman göster
                  Text(
                    'Etkinlik Hakkında',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.event.description?.isNotEmpty == true) ...[
                            Text(
                              widget.event.description!,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            'Bu etkinlik Ticketmaster üzerinden sunulmaktadır. '
                            'Detaylı bilgi ve bilet satın alma için aşağıdaki butonu kullanabilirsiniz. '
                            'StubStreet olarak güvenli ve kolay bilet alım deneyimi sunuyoruz.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bilet satın alma butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _launchTicketmasterUrl,
                      icon: const Icon(Icons.confirmation_number),
                      label: const Text('Ticketmaster\'da Bilet Al'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: textTheme.titleMedium,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Güvenlik bildirimi
                  Card(
                    color: colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Güvenlik Bildirimi',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bu uygulama sadece etkinlikleri listelemektedir. Bilet alım satım işlemleri için lütfen Ticketmaster\'ın resmi web sitesini kullanın.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bilgi kartları için yardımcı widget
  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}