class CategoryKeyword {
  final int? id;
  final int categoryId;
  final String keyword; // lowercase string

  CategoryKeyword({
    this.id,
    required this.categoryId,
    required this.keyword,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'keyword': keyword.toLowerCase(),
    };
  }

  factory CategoryKeyword.fromMap(Map<String, dynamic> map) {
    return CategoryKeyword(
      id: map['id'] as int?,
      categoryId: map['category_id'] as int,
      keyword: map['keyword'] as String,
    );
  }
}
