import 'package:flutter/material.dart';
import '../models/article_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'favorite_screen.dart';

class ListScreen extends StatefulWidget {
  final ContentType type;
  final ApiService? apiService;

  const ListScreen({
    super.key,
    this.type = ContentType.news,
    this.apiService,
  });

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late final ApiService _apiService;
  List<ArticleModel> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.fetchList(widget.type);
      if (mounted) {
        setState(() {
          _articles = results;
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

  Widget _buildThumbnail(String? imageUrl) {
    const double size = 70.0;

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.broken_image,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade300,
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Widget _buildItemCard(ArticleModel article) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailScreen(
                type: widget.type,
                id: article.id,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildThumbnail(article.imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title.isNotEmpty
                          ? article.title
                          : 'Tidak ada judul',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.author.isNotEmpty ? article.author : 'Unknown',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          key: Key('list_loading_indicator'),
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
                key: const Key('list_retry_button'),
                onPressed: _fetchArticles,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_articles.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchArticles,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: const Center(
                child: Text(
                  'Belum ada data tersedia saat ini.',
                  key: Key('list_empty_text'),
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchArticles,
      child: ListView.builder(
        itemCount: _articles.length,
        itemBuilder: (context, index) {
          final article = _articles[index];
          return _buildItemCard(article);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type.displayName),
        actions: [
          IconButton(
            key: const Key('list_favorite_button'),
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorite',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FavoriteScreen(
                    apiService: _apiService,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}
