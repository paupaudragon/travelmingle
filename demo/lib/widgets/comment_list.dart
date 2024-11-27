import 'package:demo/widgets/comment_title.dart';
import 'package:flutter/material.dart';
import '../models/comment_model.dart';

class CommentsList extends StatelessWidget {
  final List<Comment> comments;

  const CommentsList({Key? key, required this.comments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      itemBuilder: (context, index) {
        return CommentTile(comment: comments[index]);
      },
    );
  }
}
