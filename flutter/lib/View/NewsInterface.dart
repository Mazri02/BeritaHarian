import 'package:flutter/material.dart';
import '../Model/News.dart';
import '../Controller/NewsAPI.dart';
import 'package:cached_network_image/cached_network_image.dart';
import './ArticleDetails.dart';

class NewsApp extends StatelessWidget {
  const NewsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News App Lab',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        cardColor: Colors.grey[800],
        appBarTheme: AppBarTheme(color: Colors.grey[900]),
      ),
      themeMode: ThemeMode.dark,
      home: const NewsHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class NewsHomePage extends StatefulWidget {
  const NewsHomePage({Key? key}) : super(key: key);

  @override
  _NewsHomePageState createState() => _NewsHomePageState();
}

class _NewsHomePageState extends State<NewsHomePage> {
  final NewsApiService newsApiService = NewsApiService();
  List<Article> _allArticles = [];
  List<Article> _displayedArticles = [];
  List<Article> _filteredArticles = [];
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _articlesPerPage = 4;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialArticles();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> _loadInitialArticles() async {
    try {
      final articles = await newsApiService.getNews();
      setState(() {
        _allArticles = articles;
        _filteredArticles = articles;
        _loadMoreArticles();
      });
    } catch (e) {
      // Handle error
    }
  }

  void _loadMoreArticles() {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    final startIndex = nextPage * _articlesPerPage;

    if (startIndex >= _filteredArticles.length) {
      setState(() {
        _isLoadingMore = false;
      });
      return;
    }

    final endIndex = startIndex + _articlesPerPage;
    final newArticles = _filteredArticles.sublist(
      startIndex,
      endIndex > _filteredArticles.length ? _filteredArticles.length : endIndex,
    );

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _displayedArticles.addAll(newArticles);
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    });
  }

  void _scrollListener() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_scrollController.position.outOfRange) {
      _loadMoreArticles();
    }
  }

  void _searchArticles(String query) {
    setState(() {
      _filteredArticles =
          _allArticles
              .where(
                (article) =>
                    article.title.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
      _displayedArticles = [];
      _currentPage = -1;
      _loadMoreArticles();
    });
  }

  Future<void> _refreshArticles() async {
    try {
      final articles = await newsApiService.generateNews();
      setState(() {
        _allArticles = articles;
        _filteredArticles = articles;
        _displayedArticles = [];
        _currentPage = -1;
        _loadMoreArticles();
      });
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search articles...',
                    hintStyle: TextStyle(color: Colors.white70),
                    border: InputBorder.none,
                  ),
                  onChanged: _searchArticles,
                )
                : Row(
                  children: [
                    Icon(Icons.newspaper),
                    SizedBox(width: 8),
                    Text(
                      'Berita Harian',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _filteredArticles = _allArticles;
                  _displayedArticles = [];
                  _currentPage = -1;
                  _loadMoreArticles();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshArticles,
        child:
            _displayedArticles.isEmpty && !_isLoadingMore
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                  controller: _scrollController,
                  itemCount:
                      _displayedArticles.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _displayedArticles.length) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return NewsArticleTile(article: _displayedArticles[index]);
                  },
                ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class NewsArticleTile extends StatelessWidget {
  final Article article;
  const NewsArticleTile({Key? key, required this.article}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        child: Column(
          children: [
            SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.urlToImage,
                    fit: BoxFit.cover,
                    placeholder:
                        (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                    errorWidget:
                        (context, url, error) => Container(
                          color: Colors.grey,
                          child: const Icon(Icons.error, color: Colors.red),
                        ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(color: Colors.grey[800]),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  article.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
