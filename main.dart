import 'package:flutter/material.dart';
import 'api_service.dart';
import 'article_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Berita Terkini',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE85D91),
        ),
        scaffoldBackgroundColor: const Color(0xFFFFE8F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE875A0),
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFF5F8),
          elevation: 3,
          margin: const EdgeInsets.symmetric(
            horizontal: 2,
            vertical: 7,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(
              color: Color(0xFFFFB7D0),
            ),
          ),
        ),
      ),
      home: const NewsScreen(),
    );
  }
}

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<List<Article>> _articlesFuture;

  final ScrollController _scrollController = ScrollController();

  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();

    _articlesFuture = ApiService().fetchArticles();

    _scrollController.addListener(_handleScroll);
  }

  // Menampilkan tombol kembali ke atas ketika scroll cukup jauh.
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final shouldShow = _scrollController.offset > 300;

    if (shouldShow != _showBackToTop) {
      setState(() {
        _showBackToTop = shouldShow;
      });
    }
  }

  // Memuat ulang berita saat pengguna melakukan pull-to-refresh.
  Future<void> _refreshArticles() async {
    final newFuture = ApiService().fetchArticles();

    setState(() {
      _articlesFuture = newFuture;
    });

    try {
      await newFuture;
    } catch (_) {
      // Pesan error ditampilkan oleh FutureBuilder.
    }
  }

  // Mengembalikan halaman ke posisi paling atas.
  void _scrollToTop() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Berita Terkini',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          // Tampilan ketika data sedang dimuat.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE85D91),
              ),
            );
          }

          // Tampilan ketika terjadi kesalahan.
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: Color(0xFFE85D91),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat berita',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshArticles,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final articles = snapshot.data ?? [];

          // Tampilan jika berita tidak ditemukan.
          if (articles.isEmpty) {
            return RefreshIndicator(
              color: const Color(0xFFE85D91),
              backgroundColor: Colors.white,
              onRefresh: _refreshArticles,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(
                    Icons.newspaper,
                    size: 60,
                    color: Color(0xFFE85D91),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: Text('Tidak ada berita tersedia'),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              // Pull-to-refresh membungkus daftar berita.
              RefreshIndicator(
                color: const Color(0xFFE85D91),
                backgroundColor: Colors.white,
                onRefresh: _refreshArticles,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: article.urlToImage != null &&
                                  article.urlToImage!.isNotEmpty
                              ? Image.network(
                                  article.urlToImage!,
                                  width: 85,
                                  height: 85,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) {
                                    return Container(
                                      width: 85,
                                      height: 85,
                                      color: const Color(0xFFFFD6E4),
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Color(0xFFE85D91),
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: 85,
                                  height: 85,
                                  color: const Color(0xFFFFD6E4),
                                  child: const Icon(
                                    Icons.newspaper,
                                    color: Color(0xFFE85D91),
                                  ),
                                ),
                        ),
                        title: Text(
                          article.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            article.description ??
                                'Tidak ada deskripsi berita.',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        onTap: () {
                          if (article.url != null &&
                              article.url!.isNotEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'URL berita tersedia untuk dibuka.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Tombol kembali ke atas.
              if (_showBackToTop)
                Positioned(
                  right: 18,
                  bottom: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFFE85D91),
                    foregroundColor: Colors.white,
                    tooltip: 'Kembali ke atas',
                    onPressed: _scrollToTop,
                    child: const Icon(Icons.arrow_upward),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}