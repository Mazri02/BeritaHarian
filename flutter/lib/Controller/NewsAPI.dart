import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Model/News.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NewsApiService {
  Future<List<Article>> getNews({String country = 'us'}) async {
    final response = await http.get(
      Uri.parse(dotenv.env['BASE_URL']! + "/api/getNews"),
    );
    print(response.body);

    if (response.statusCode == 200) {
      final List<dynamic> articlesJson = json.decode(response.body);
      return articlesJson
          .map((jsonItem) => Article.fromJson(jsonItem))
          .toList();
    } else {
      throw Exception('Failed to load news');
    }
  }

  Future<List<Article>> generateNews() async {
    final response = await http.get(
      Uri.parse(dotenv.env['BASE_URL']! + "/api/generateNews"),
    );
    print(response.body);

    if (response.statusCode == 200) {
      return getNews();
    } else {
      throw Exception('Failed to Generate News');
    }
  }
}
