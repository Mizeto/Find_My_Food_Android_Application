class Recipe {
  final int id;
  final String title;
  final String description;
  final String cookingMethod; // ✅ เพิ่มตัวนี้
  final String imageUrl;
  final int prepTime;

  Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.cookingMethod, // ✅ เพิ่มตรงนี้
    required this.imageUrl,
    required this.prepTime,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['recipe_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      cookingMethod: json['cooking_method'] ?? 'ไม่มีข้อมูลวิธีทำ',

      // ⚠️ แก้บรรทัดนี้ครับ:
      // เราจะเช็คว่าถ้าเป็นลิงก์จาก placehold.co และยังไม่มี .png ให้เติมเข้าไป
      imageUrl: _fixImageUrl(
        json['image_url'] ?? 'https://placehold.co/600x400.png',
      ),

      prepTime: json['prep_time'] ?? 0,
    );
  }

  // เพิ่มฟังก์ชันช่วยแปลงลิงก์ข้างล่างนี้ (ในไฟล์เดียวกัน แต่ออยู่นอก Class หรือใน Class ก็ได้)
  static String _fixImageUrl(String url) {
    // ถ้าเป็นลิงก์ placehold.co และไม่มี .png ให้เติม .png ไปก่อนเครื่องหมาย ?
    if (url.contains('placehold.co') && !url.contains('.png')) {
      return url.replaceFirst('?', '.png?');
    }
    return url;
  }
}
