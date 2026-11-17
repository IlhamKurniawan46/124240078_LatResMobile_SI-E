import 'package:flutter/material.dart';
import 'models/article_model.dart';
import 'services/api_service.dart';
import 'utils/app_routes.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Temporary ApiService verification: Fetch 1 item to verify API connection & data parsing
  try {
    final apiService = ApiService();
    final articles = await apiService.fetchList(ContentType.news, limit: 1);
    if (articles.isNotEmpty) {
      debugPrint('----------------------------------------------------');
      debugPrint('[ApiService Verification] Data fetched successfully:');
      debugPrint('ID          : ${articles.first.id}');
      debugPrint('Title       : ${articles.first.title}');
      debugPrint('Author      : ${articles.first.author}');
      debugPrint('URL         : ${articles.first.url}');
      debugPrint('Image URL   : ${articles.first.imageUrl}');
      debugPrint('Type        : ${articles.first.type.displayName}');
      debugPrint('----------------------------------------------------');
    }
  } catch (e) {
    debugPrint('[ApiService Verification Error]: $e');
  }

  runApp(const SpaceflightApp());
}

class SpaceflightApp extends StatelessWidget {
  const SpaceflightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spaceflight News',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.login,
      routes: AppRoutes.routes,
    );
  }
}
