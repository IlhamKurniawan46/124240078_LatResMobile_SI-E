import 'package:flutter/material.dart';
import '../models/content_type.dart';

class DetailScreen extends StatelessWidget {
  final ContentType? type;
  final int? id;

  const DetailScreen({
    super.key,
    this.type,
    this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          type != null ? 'Detail ${type!.displayName}' : 'Detail Content',
        ),
      ),
      body: Center(
        child: Text(
          id != null
              ? 'Detail Screen Placeholder (type: ${type?.name}, id: $id)'
              : 'Detail Screen Placeholder',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
