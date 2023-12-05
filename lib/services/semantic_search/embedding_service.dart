abstract class EmbeddingService {
  Future<List<double>> getImageEmbedding(String imagePath);
  Future<List<double>> getTextEmbedding(String text);

  double computeScore(List<double> imageEmbedding, List<double> textEmbedding) {
    assert(
      imageEmbedding.length == textEmbedding.length,
      "The two embeddings should have the same length",
    );
    double score = 0;
    for (int index = 0; index < imageEmbedding.length; index++) {
      score += imageEmbedding[index] * textEmbedding[index];
    }
    return score;
  }
}
