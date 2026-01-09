import "dart:async";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/comment_deleted_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/social/comment.dart";
import "package:photos/models/social/reaction.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/social/widgets/collection_selector_widget.dart";
import "package:photos/ui/social/widgets/comment_bubble_widget.dart";
import "package:photos/ui/social/widgets/comment_input_widget.dart";

/// Shows the file comments bottom sheet
Future<void> showFileCommentsBottomSheet(
  BuildContext context, {
  required int collectionID,
  required int fileID,
  String? highlightCommentID,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DraggableCommentsSheet(
      collectionID: collectionID,
      fileID: fileID,
      highlightCommentID: highlightCommentID,
    ),
  );
}

class _DraggableCommentsSheet extends StatefulWidget {
  final int collectionID;
  final int fileID;
  final String? highlightCommentID;

  const _DraggableCommentsSheet({
    required this.collectionID,
    required this.fileID,
    this.highlightCommentID,
  });

  @override
  State<_DraggableCommentsSheet> createState() =>
      _DraggableCommentsSheetState();
}

class _DraggableCommentsSheetState extends State<_DraggableCommentsSheet> {
  final sheetController = DraggableScrollableController();

  @override
  void dispose() {
    sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 60;
    return DraggableScrollableSheet(
      controller: sheetController,
      initialChildSize: isKeyboardOpen ? 0.95 : 0.6,
      minChildSize: isKeyboardOpen ? 0.8 : 0.4,
      maxChildSize: 0.95,
      snap: isKeyboardOpen ? false : true,
      snapSizes: isKeyboardOpen ? null : const [0.6],
      expand: false,
      builder: (context, scrollController) => FileCommentsBottomSheet(
        collectionID: widget.collectionID,
        fileID: widget.fileID,
        highlightCommentID: widget.highlightCommentID,
        dragController: scrollController,
        sheetController: sheetController,
      ),
    );
  }
}

class FileCommentsBottomSheet extends StatefulWidget {
  final int collectionID;
  final int fileID;

  /// Optional comment ID to scroll to and highlight.
  final String? highlightCommentID;

  /// Scroll controller for the drag handle (from DraggableScrollableSheet).
  final ScrollController dragController;

  /// Controller to programmatically expand/collapse the sheet.
  final DraggableScrollableController sheetController;

  const FileCommentsBottomSheet({
    required this.collectionID,
    required this.fileID,
    required this.dragController,
    required this.sheetController,
    this.highlightCommentID,
    super.key,
  });

  @override
  State<FileCommentsBottomSheet> createState() =>
      _FileCommentsBottomSheetState();
}

class _FileCommentsBottomSheetState extends State<FileCommentsBottomSheet> {
  static final _logger = Logger('FileCommentsBottomSheet');

  final List<Comment> _comments = [];

  Comment? _replyingTo;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  SendButtonState _sendState = SendButtonState.idle;
  Timer? _sendLoadingTimer;
  bool _hasMoreComments = true;
  int _offset = 0;
  final Map<int, User> _userCache = {};
  Map<String, String> _anonDisplayNames = {};
  String? _highlightedCommentID;
  bool _hasScrolledToHighlight = false;
  GlobalKey? _highlightedCommentKey;

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
    _inputFocusNode = FocusNode()..addListener(_onInputFocusChange);
    _scrollController = ScrollController()..addListener(_onScroll);
    _currentUserID = Configuration.instance.getUserID()!;
    _selectedCollectionID = widget.collectionID;
    _highlightedCommentID = widget.highlightCommentID;
    _loadSharedCollections();
  }

  void _onInputFocusChange() {
    if (_inputFocusNode.hasFocus && widget.sheetController.isAttached) {
      widget.sheetController.animateTo(
        0.95,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _sendLoadingTimer?.cancel();
    _textController.dispose();
    _inputFocusNode.removeListener(_onInputFocusChange);
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      // Phase 1: Jump to approximate position to bring item into view
      const estimatedItemHeight = 120.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final scrollPosition =
          (index * estimatedItemHeight).clamp(0.0, maxScroll);

      _scrollController.jumpTo(scrollPosition);

      // Phase 2: After item is built, use ensureVisible for precise positioning
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final context = _highlightedCommentKey?.currentContext;
        if (context == null) return;

        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutExpo,
        );
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
    if (text.isEmpty || _sendState != SendButtonState.idle) return;

    // Mark as sending internally (blocks duplicate sends) but don't show UI yet
    _sendState = SendButtonState.sending;

    // Only show loading indicator after 400ms delay
    _sendLoadingTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted && _sendState == SendButtonState.sending) {
        setState(() {});
      }
    });

    try {
      final result = await SocialDataProvider.instance.addComment(
        collectionID: _selectedCollectionID,
        text: text,
        fileID: widget.fileID,
        parentCommentID: _replyingTo?.id,
      );
      _sendLoadingTimer?.cancel();

      if (result == null) {
        _logger.warning('Failed to save comment');
        _showSendError();
        return;
      }

      // Update UI only after successful persistence
      if (mounted) {
        setState(() {
          _sendState = SendButtonState.idle;
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
      _sendLoadingTimer?.cancel();
      _logger.severe('Failed to send comment', e);
      _showSendError();
    }
  }

  void _showSendError() {
    if (!mounted) return;
    setState(() => _sendState = SendButtonState.error);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && _sendState == SendButtonState.error) {
        setState(() => _sendState = SendButtonState.idle);
      }
    });
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

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = getEnteTextTheme(context);
    return SingleChildScrollView(
      controller: widget.dragController,
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: _sharedCollections.length > 1
                  ? CollectionSelectorWidget(
                      sharedCollections: _sharedCollections,
                      selectedCollectionID: _selectedCollectionID,
                      onCollectionSelected: _onCollectionSelected,
                    )
                  : Text(
                      l10n.commentsCount(count: _comments.length),
                      style: textTheme.bodyBold,
                    ),
            ),
            IconButtonWidget(
              iconButtonType: IconButtonType.rounded,
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final selectedCollection = _currentCollection;
    final canModerateAnonComments = selectedCollection != null &&
        (selectedCollection.isOwner(_currentUserID) ||
            selectedCollection.isAdmin(_currentUserID));

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF0E0E0E)
            : colorScheme.backgroundElevated,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: GestureDetector(
                  onTap: () => FocusScope.of(context).unfocus(),
                  behavior: HitTestBehavior.translucent,
                  child: _isLoading
                      ? const EnteLoadingWidget()
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.only(
                            top: 24,
                            left: 16,
                            right: 16,
                            bottom: 24,
                          ),
                          itemCount:
                              _comments.length + (_hasMoreComments ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _comments.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: EnteLoadingWidget(),
                              );
                            }
                            final comment = _comments[index];
                            final isHighlighted =
                                comment.id == _highlightedCommentID;
                            // Use widget.highlightCommentID (not state) to keep key stable after dismiss
                            final key =
                                (comment.id == widget.highlightCommentID)
                                    ? (_highlightedCommentKey ??= GlobalKey())
                                    : ValueKey(comment.id);
                            return CommentBubbleWidget(
                              key: key,
                              comment: comment,
                              user: _getUserForComment(comment),
                              isOwnComment: comment.userID == _currentUserID,
                              canModerateAnonComments: canModerateAnonComments,
                              currentUserID: _currentUserID,
                              collectionID: _selectedCollectionID,
                              isHighlighted: isHighlighted,
                              onFetchParent: comment.isReply
                                  ? () => _getParentComment(
                                        comment.parentCommentID!,
                                      )
                                  : null,
                              onFetchReactions: () =>
                                  _getReactionsForComment(comment.id),
                              onReplyTap: () => _onReplyTap(comment),
                              userResolver: _getUserForComment,
                              onCommentDeleted: () =>
                                  _handleCommentDeleted(comment.id),
                              onAutoHighlightDismissed: () {
                                if (mounted) {
                                  setState(() => _highlightedCommentID = null);
                                  // Don't clear _highlightedCommentKey - prevents avatar flicker
                                }
                              },
                            );
                          },
                        ),
                ),
              ),
              CommentInputWidget(
                replyingTo: _replyingTo,
                replyingToUser: _replyingTo != null
                    ? _getUserForComment(_replyingTo!)
                    : null,
                currentUserID: _currentUserID,
                onDismissReply: _dismissReply,
                controller: _textController,
                focusNode: _inputFocusNode,
                onSend: _sendComment,
                sendState: _sendState,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
