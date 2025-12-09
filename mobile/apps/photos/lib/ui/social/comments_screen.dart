import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/social/widgets/comment_bubble_widget.dart";
import "package:photos/ui/social/widgets/comment_input_widget.dart";
import "package:uuid/uuid.dart";

class CommentsScreen extends StatefulWidget {
  final int collectionID;
  final int? fileID;

  const CommentsScreen({
    required this.collectionID,
    this.fileID,
    super.key,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final List<Comment> _comments = [];

  Comment? _replyingTo;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreComments = true;
  int _offset = 0;
  final Map<int, User> _userCache = {};

  late final TextEditingController _textController;
  late final FocusNode _inputFocusNode;
  late final ScrollController _scrollController;
  late final int _currentUserID;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _inputFocusNode = FocusNode();
    _scrollController = ScrollController()..addListener(_onScroll);
    _currentUserID = Configuration.instance.getUserID()!;
    _loadInitialComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialComments() async {
    setState(() => _isLoading = true);

    final comments = widget.fileID != null
        ? await SocialDataProvider.instance.getCommentsForFilePaginated(
            widget.fileID!,
            limit: _pageSize,
            offset: 0,
          )
        : await SocialDataProvider.instance.getCommentsForCollectionPaginated(
            widget.collectionID,
            limit: _pageSize,
            offset: 0,
          );

    setState(() {
      _comments.addAll(comments);
      _offset = comments.length;
      _hasMoreComments = comments.length == _pageSize;
      _isLoading = false;
    });
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;

    setState(() => _isLoadingMore = true);

    final comments = widget.fileID != null
        ? await SocialDataProvider.instance.getCommentsForFilePaginated(
            widget.fileID!,
            limit: _pageSize,
            offset: _offset,
          )
        : await SocialDataProvider.instance.getCommentsForCollectionPaginated(
            widget.collectionID,
            limit: _pageSize,
            offset: _offset,
          );

    setState(() {
      _comments.addAll(comments);
      _offset += comments.length;
      _hasMoreComments = comments.length == _pageSize;
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreComments();
    }
  }

  Future<Comment?> _getParentComment(String parentCommentId) {
    return SocialDataProvider.instance.getCommentById(parentCommentId);
  }

  Future<List<Reaction>> _getReactionsForComment(String commentId) {
    return SocialDataProvider.instance.getReactionsForComment(commentId);
  }

  void _onReplyTap(Comment comment) {
    setState(() => _replyingTo = comment);
    _inputFocusNode.requestFocus();
  }

  User _getUserForComment(Comment comment) {
    if (_userCache.containsKey(comment.userID)) {
      return _userCache[comment.userID]!;
    }

    if (comment.isAnonymous) {
      final user = User(
        id: comment.userID,
        email: "${comment.anonUserID ?? "anonymous"}@unknown.com",
        name: comment.anonUserID ?? "Anonymous",
      );
      _userCache[comment.userID] = user;
      return user;
    }

    final user = CollectionsService.instance
        .getFileOwner(comment.userID, widget.collectionID);
    _userCache[comment.userID] = user;
    return user;
  }

  void _dismissReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final newComment = Comment(
      id: const Uuid().v4(),
      collectionID: widget.collectionID,
      fileID: widget.fileID,
      data: text,
      parentCommentID: _replyingTo?.id,
      userID: _currentUserID,
      createdAt: now,
      updatedAt: now,
    );

    // Optimistic update
    setState(() {
      _comments.insert(0, newComment);
      _replyingTo = null;
    });
    _textController.clear();

    // Persist
    await SocialDataProvider.instance.addComment(newComment);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 28,
        backgroundColor: colorScheme.backgroundBase,
        elevation: 0,
        title: Text(
          "${_comments.length} comments",
          style: textTheme.bodyBold,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: IconButtonWidget(
              iconButtonType: IconButtonType.rounded,
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 16,
                      right: 16,
                      bottom: 24,
                    ),
                    itemCount: _comments.length + (_hasMoreComments ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _comments.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      final comment = _comments[index];
                      return CommentBubbleWidget(
                        key: ValueKey(comment.id),
                        comment: comment,
                        user: _getUserForComment(comment),
                        isOwnComment: comment.userID == _currentUserID,
                        currentUserID: _currentUserID,
                        collectionID: widget.collectionID,
                        onFetchParent: comment.isReply
                            ? () => _getParentComment(comment.parentCommentID!)
                            : null,
                        onFetchReactions: () =>
                            _getReactionsForComment(comment.id),
                        onReplyTap: () => _onReplyTap(comment),
                      );
                    },
                  ),
          ),
          CommentInputWidget(
            replyingTo: _replyingTo,
            onDismissReply: _dismissReply,
            controller: _textController,
            focusNode: _inputFocusNode,
            onSend: _sendComment,
          ),
        ],
      ),
    );
  }
}
