/// A subtitle returned by an online provider. URLs remain provider-owned.
class SubtitleCandidate {
  const SubtitleCandidate({
    required this.name,
    required this.releaseName,
    required this.language,
    required this.downloadPath,
    this.season,
    this.episode,
  });

  final String name;
  final String releaseName;
  final String language;
  final String downloadPath;
  final int? season;
  final int? episode;

  bool get isArchive => downloadPath.toLowerCase().endsWith('.zip');
}

abstract interface class SubtitleProvider {
  Future<List<SubtitleCandidate>> searchByFileName(
    String fileName, {
    required String apiKey,
    required List<String> languages,
  });

  Future<List<SubtitleCandidate>> searchByTitle(
    String title, {
    required String apiKey,
    required List<String> languages,
  });

  Future<List<int>> download(
    SubtitleCandidate candidate, {
    required String apiKey,
    void Function(int received, int total)? onProgress,
  });

  Future<String> accountStatus(String apiKey);
}
