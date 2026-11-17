import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../utils/snackbar_helper.dart';

class DetailScreen extends StatefulWidget {
  final ContentType type;
  final int id;
  final ApiService? apiService;
  final Future<bool> Function(Uri, {LaunchMode mode})? urlLauncher;

  const DetailScreen({
    super.key,
    this.type = ContentType.news,
    this.id = 0,
    this.apiService,
    this.urlLauncher,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final ApiService _apiService;
  ArticleModel? _article;
  bool _isLoading = true;
  String? _errorMessage;

  // Variabel state lokal untuk ikon hati
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchDetail(widget.type, widget.id);
      if (mounted) {
        setState(() {
          _article = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException ? e.message : e.toString();
        });
      }
    }
  }

  Future<void> _openWeb(String? urlString) async {
    if (urlString == null || urlString.trim().isEmpty) {
      if (mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
      return;
    }

    final uri = Uri.tryParse(urlString.trim());
    if (uri == null) {
      if (mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
      return;
    }

    try {
      final launched = widget.urlLauncher != null
          ? await widget.urlLauncher!(uri, mode: LaunchMode.externalApplication)
          : await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched && mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
    } catch (_) {
      if (mounted) {
        SnackbarHelper.showError(context, AppConstants.openWebErrorMessage);
      }
    }
  }

  Widget _buildBannerImage(String? imageUrl) {
    const double bannerHeight = 250.0;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        height: bannerHeight,
        width: double.infinity,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl,
      height: bannerHeight,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          height: bannerHeight,
          width: double.infinity,
          color: Colors.grey.shade200,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: bannerHeight,
          width: double.infinity,
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('detail_loading_indicator'),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                key: const Key('detail_retry_button'),
                onPressed: _fetchDetail,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_article == null) {
      return const Center(
        child: Text('Data tidak tersedia.'),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Gambar Utama
          _buildBannerImage(_article!.imageUrl),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Judul Lengkap
                Text(
                  _article!.title.isNotEmpty
                      ? _article!.title
                      : 'Tidak ada judul',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Author / Publisher (news_site)
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 18,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _article!.author.isNotEmpty
                            ? _article!.author
                            : 'Unknown',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Tanggal Publish (string ISO apa adanya)
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _article!.publishedAt.isNotEmpty
                            ? _article!.publishedAt
                            : '-',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),

                // Summary
                Text(
                  _article!.summary.isNotEmpty
                      ? _article!.summary
                      : 'Tidak ada ringkasan tersedia.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                // Padding ekstra agar tidak tertutup FAB
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail ${widget.type.displayName}'),
        actions: [
          IconButton(
            key: const Key('detail_favorite_button'),
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: _isFavorite ? 'Hapus dari favorite' : 'Tambah ke favorite',
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              // - StorageService.toggleFavorite(_article!)
              // - Tampilkan SnackBar: _isFavorite ? AppConstants.addedToFavoriteMessage : AppConstants.removedFromFavoriteMessage
            },
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _article == null
          ? null
          : FloatingActionButton(
              key: const Key('detail_open_web_fab'),
              tooltip: 'Buka Web',
              onPressed: () => _openWeb(_article!.url),
              child: const Icon(Icons.open_in_new),
            ),
    );
  }
}
