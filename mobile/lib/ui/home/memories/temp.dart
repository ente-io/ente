import 'package:flutter/material.dart';
import "package:photos/models/memories/memory.dart";
import "package:photos/ui/home/memories/full_screen_memory.dart";

class TempPage extends StatelessWidget {
  final int page;
  final int initialIndex;
  final List<List<Memory>> allMemories; 
  
  const TempPage({
    super.key,
    required this.page,
    required this.allMemories, 
    this.initialIndex = 0,
  });

  static Route route({
    required List<List<Memory>> allMemories,
    required List<String> titles,
    int initialIndex = 0,
  }) {
    return MaterialPageRoute(
      builder: (_) => TempPage(
        page: allMemories.length,
        initialIndex: initialIndex,
        allMemories: allMemories, 
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pageController = PageController(initialPage: initialIndex);

    return Scaffold(
      body: PageView.builder(
        controller: pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: allMemories.length,
        itemBuilder: (context, index) {
          return FullScreenMemoryDataUpdater(
            initialIndex: 0,
            memories: allMemories[index],
            child:const  FullScreenMemory(
               
               "asdasdasd",
              0,
            ),
          );
        },
      ),
    );
  }
}