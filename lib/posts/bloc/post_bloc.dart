
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_infinite_list_bloc/posts/bloc/post_event.dart';
import 'package:flutter_infinite_list_bloc/posts/bloc/post_state.dart';
import 'package:flutter_infinite_list_bloc/posts/models/post.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';


class PostBloc extends Bloc<PostEvent, PostState> {
  final http.Client httpClient;
  PostBloc({required this.httpClient}) : super(const PostState());
  static const _postLimit = 20;

  @override
  Stream<Transition<PostEvent, PostState>> transformEvents(
      Stream<PostEvent> events,
      TransitionFunction<PostEvent, PostState> transitionFn,
      ) {
    return super.transformEvents(
      events.throttleTime(const Duration(milliseconds: 500)),
      transitionFn,
    );
  }

  @override
  Stream<PostState> mapEventToState(PostEvent event) async*{
    if(event is PostFetched){
      yield await _mapPostFetchToState(state);
    }
  }

  Future <PostState> _mapPostFetchToState(PostState state) async{
    if(state.hasReachedMax) return state;
    try {
      if(state.status == PostStatus.initial) {
        final posts = await _fetchPosts();
        return state.copyWith(
          status: PostStatus.success,
          posts: posts,
          hasReachedMax: false
        );
      }
      final posts = await _fetchPosts(state.posts.length);
      return posts.isEmpty
          ? state.copyWith(hasReachedMax: true)
          : state.copyWith(
        status: PostStatus.success,
        posts: List.of(state.posts)..addAll(posts),
        hasReachedMax: false,
      );
    } on Exception {
      return state.copyWith(status: PostStatus.failure);
    }
  }

  Future<List<Post>> _fetchPosts([int startIndex = 0]) async {
    final response = await httpClient.get(
      Uri.https(
        'jsonplaceholder.typicode.com',
        '/posts',
        <String, String>{'_start': '$startIndex', '_limit': '$_postLimit'},
      ),
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body) as List;
      return body.map((dynamic json) {
        return Post(
          id: json['id'] as int,
          title: json['title'] as String,
          body: json['body'] as String,
        );
      }).toList();
    }
    throw Exception('error fetching posts');
  }

}