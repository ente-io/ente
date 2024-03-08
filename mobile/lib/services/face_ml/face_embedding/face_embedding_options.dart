class FaceEmbeddingOptions {
  final int inputWidth;
  final int inputHeight;
  final int embeddingLength;
  final int numChannels;
  final bool preWhiten;

  FaceEmbeddingOptions({
    required this.inputWidth,
    required this.inputHeight,
    this.embeddingLength = 192,
    this.numChannels = 3,
    this.preWhiten = false,
  });
}
