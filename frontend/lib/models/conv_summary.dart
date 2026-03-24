class ConvSummary {
  final int id;
  final String title;

  ConvSummary({required this.id, required this.title});

  factory ConvSummary.fromJson(Map<String, dynamic> j) =>
      ConvSummary(id: j['id'], title: j['title']);
}
