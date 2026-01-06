import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/comment_deleted_event.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/social/widgets/collection_selector_widget.dart";
import "package:photos/ui/social/widgets/comment_bubble_widget.dart";
import "package:photos/ui/social/widgets/comment_input_widget.dart";

class FileCommentsScreen extends StatefulWidget {
  final int collectionID;
  final int fileID;

  /// Optional comment ID to scroll to and highlight.
  final String? highlightCommentID;

  const FileCommentsScreen({
    required this.collectionID,
    required this.fileID,
    this.highlightCommentID,
    super.key,
  });

  @override
  State<FileCommentsScreen> createState() => _FileCommentsScreenState();
}

class _FileCommentsScreenState extends State<FileCommentsScreen> {
  static final _logger = Logger('FileCommentsScreen');

  final List<Comment> _comments = [];

  Comment? _replyingTo;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreComments = true;
  int _offset = 0;
  final Map<int, User> _userCache = {};
  Map<String, String> _anonDisplayNames = {};
  String? _highlightedCommentID;
  bool _hasScrolledToHighlight = false;

  List<CollectionCommentInfo> _sharedCollections = [];
  late int _selectedCollectionID;

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
    _selectedCollectionID = widget.collectionID;
    _highlightedCommentID = widget.highlightCommentID;
    _loadSharedCollections();
  }

  @override
  void dispose() {
    _textController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedCollections() async {
    final collectionIDs = await FilesDB.instance.getAllCollectionIDsOfFile(
      widget.fileID,
    );

    // Filter to shared collections first (sync operation)
    var sharedCollectionsList = collectionIDs
        .map((id) => CollectionsService.instance.getCollectionByID(id))
        .whereType<Collection>()
        .where(
          (c) => c.hasSharees || c.hasLink || !c.isOwner(_currentUserID),
        )
        .toList();

    // Filter out hidden collections unless viewing from a hidden collection
    final hiddenCollectionIds =
        CollectionsService.instance.getHiddenCollectionIds();
    final isInitialCollectionHidden =
        hiddenCollectionIds.contains(widget.collectionID);
    if (!isInitialCollectionHidden) {
      sharedCollectionsList = sharedCollectionsList
          .where((c) => !hiddenCollectionIds.contains(c.id))
          .toList();
    }

    // Fetch data in parallel
    final sharedCollections = await Future.wait(
      sharedCollectionsList.map((collection) async {
        final commentCount = await SocialDataProvider.instance
            .getCommentCountForFileInCollection(widget.fileID, collection.id);
        final thumbnail =
            await CollectionsService.instance.getCover(collection);
        return CollectionCommentInfo(
          collection: collection,
          commentCount: commentCount,
          thumbnail: thumbnail,
        );
      }),
    );

    if (mounted) {
      if (sharedCollections.isEmpty) {
        _logger.warning(
          'FileCommentsScreen opened for file ${widget.fileID} with no shared collections',
        );
        Navigator.of(context).pop();
        return;
      }

      final isSelectedInShared = sharedCollections.any(
        (info) => info.collection.id == _selectedCollectionID,
      );

      setState(() {
        _sharedCollections = sharedCollections;

        if (!isSelectedInShared) {
          _selectedCollectionID = sharedCollections.first.collection.id;
        }
      });

      unawaited(_loadInitialComments());
    }
  }

  Future<void> _loadInitialComments() async {
    setState(() => _isLoading = true);

    // Load local data first for immediate display
    final results = await Future.wait([
      SocialDataProvider.instance.getCommentsForFilePaginated(
        widget.fileID,
        collectionID: _selectedCollectionID,
        limit: _pageSize,
        offset: 0,
      ),
      SocialDataProvider.instance
          .getAnonDisplayNamesForCollection(_selectedCollectionID),
    ]);

    final comments = results[0] as List<Comment>;
    final anonNames = results[1] as Map<String, String>;

    setState(() {
      _comments.addAll(comments);
      _anonDisplayNames = anonNames;
      _offset = comments.length;
      _hasMoreComments = comments.length == _pageSize;
      _isLoading = false;
    });

    // Scroll to highlighted comment if specified
    _scrollToHighlightedComment();

    // Sync in background and refresh if there are changes
    unawaited(_syncAndRefresh());
  }

  Future<void> _syncAndRefresh() async {
    try {
      await SocialDataProvider.instance.syncFileSocialData(
        _selectedCollectionID,
        widget.fileID,
      );

      if (!mounted) return;

      // Reload comments after sync
      final freshComments =
          await SocialDataProvider.instance.getCommentsForFilePaginated(
        widget.fileID,
        collectionID: _selectedCollectionID,
        limit: _pageSize,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _comments.clear();
          _comments.addAll(freshComments);
          _offset = freshComments.length;
          _hasMoreComments = freshComments.length == _pageSize;
        });
      }
    } catch (_) {
      // Ignore sync errors, local data is already displayed
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;

    setState(() => _isLoadingMore = true);

    final comments =
        await SocialDataProvider.instance.getCommentsForFilePaginated(
      widget.fileID,
      collectionID: _selectedCollectionID,
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

  void _scrollToHighlightedComment() {
    if (_highlightedCommentID == null || _hasScrolledToHighlight) return;

    final index = _comments.indexWhere((c) => c.id == _highlightedCommentID);
    if (index == -1) return;

    _hasScrolledToHighlight = true;

    // Use post-frame callback to ensure layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      // Estimate scroll position (since ListView is reversed, index 0 is at bottom)
      // Each comment is roughly 100-150px, we'll use 120px as estimate
      const estimatedItemHeight = 120.0;
      final scrollPosition = index * estimatedItemHeight;

      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      // Clear highlight after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _highlightedCommentID = null);
        }
      });
    });
  }

  void _onCollectionSelected(int collectionID) {
    setState(() {
      _selectedCollectionID = collectionID;
      _comments.clear();
      _offset = 0;
      _hasMoreComments = true;
      _userCache.clear();
      _anonDisplayNames = {};
    });
    _loadInitialComments();
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
      final anonID = comment.anonUserID;
      final displayName =
          anonID != null ? (_anonDisplayNames[anonID] ?? anonID) : "Anonymous";
      final user = User(
        id: comment.userID,
        email: "${anonID ?? "anonymous"}@unknown.com",
        name: displayName,
      );
      _userCache[comment.userID] = user;
      return user;
    }

    final user = CollectionsService.instance
        .getFileOwner(comment.userID, _selectedCollectionID);
    _userCache[comment.userID] = user;
    return user;
  }

  void _dismissReply() {
    setState(() => _replyingTo = null);
  }

  Future<void> _sendComment() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      final result = await SocialDataProvider.instance.addComment(
        collectionID: _selectedCollectionID,
        text: text,
        fileID: widget.fileID,
        parentCommentID: _replyingTo?.id,
      );
      if (result == null) {
        _logger.warning('Failed to save comment');
        if (mounted) {
          showShortToast(context, "Failed to send comment");
        }
        return;
      }

      // Update UI only after successful persistence
      if (mounted) {
        setState(() {
          _comments.insert(0, result);
          _replyingTo = null;

          // Update comment count in shared collections list
          final index = _sharedCollections.indexWhere(
            (c) => c.collection.id == _selectedCollectionID,
          );
          if (index != -1) {
            final old = _sharedCollections[index];
            _sharedCollections[index] = CollectionCommentInfo(
              collection: old.collection,
              commentCount: old.commentCount + 1,
              thumbnail: old.thumbnail,
            );
          }
        });
        _textController.clear();
      }
    } catch (e) {
      _logger.severe('Failed to send comment', e);
      if (mounted) {
        showShortToast(context, "Failed to send comment");
      }
    }
  }

  void _handleCommentDeleted(String commentId) {
    Bus.instance.fire(CommentDeletedEvent(commentId));
    setState(() {
      _comments.removeWhere((c) => c.id == commentId);

      // Decrement comment count in shared collections list
      final index = _sharedCollections.indexWhere(
        (c) => c.collection.id == _selectedCollectionID,
      );
      if (index != -1) {
        final old = _sharedCollections[index];
        _sharedCollections[index] = CollectionCommentInfo(
          collection: old.collection,
          commentCount: old.commentCount - 1,
          thumbnail: old.thumbnail,
        );
      }
    });
  }

  Collection? get _currentCollection {
    if (_sharedCollections.isEmpty) {
      return null;
    }
    return _sharedCollections
        .firstWhere(
          (c) => c.collection.id == _selectedCollectionID,
          orElse: () => _sharedCollections.first,
        )
        .collection;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final selectedCollection = _currentCollection;
    final canModerateAnonComments = selectedCollection != null &&
        (selectedCollection.isOwner(_currentUserID) ||
            selectedCollection.isAdmin(_currentUserID));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: _sharedCollections.length > 1 ? 16 : 28,
        backgroundColor: colorScheme.backgroundBase,
        elevation: 0,
        title: _sharedCollections.length > 1
            ? CollectionSelectorWidget(
                sharedCollections: _sharedCollections,
                selectedCollectionID: _selectedCollectionID,
                onCollectionSelected: _onCollectionSelected,
              )
            : Text(
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
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
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
                          canModerateAnonComments: canModerateAnonComments,
                          currentUserID: _currentUserID,
                          collectionID: _selectedCollectionID,
                          isHighlighted: comment.id == _highlightedCommentID,
                          onFetchParent: comment.isReply
                              ? () =>
                                  _getParentComment(comment.parentCommentID!)
                              : null,
                          onFetchReactions: () =>
                              _getReactionsForComment(comment.id),
                          onReplyTap: () => _onReplyTap(comment),
                          userResolver: _getUserForComment,
                          onCommentDeleted: () =>
                              _handleCommentDeleted(comment.id),
                        );
                      },
                    ),
            ),
          ),
          CommentInputWidget(
            replyingTo: _replyingTo,
            replyingToUser:
                _replyingTo != null ? _getUserForComment(_replyingTo!) : null,
            currentUserID: _currentUserID,
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
