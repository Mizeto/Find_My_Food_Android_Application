import 'dart:convert';
import 'dart:io'; // ใช้เช็คว่าเป็น Android หรือ iOS
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart'; // ดึงไฟล์ Model มาใช้

class ApiService {
  // ⚠️ ส่วนสำคัญ: ตั้งค่าที่อยู่ของ Python Server
  static const String baseUrl = 'http://45.91.134.142';

  // ฟังก์ชันดึงรายการอาหาร
  static Future<List<Recipe>> fetchRecipes() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/recipes'));

      if (response.statusCode == 200) {
        // ถ้าคุยกันรู้เรื่อง (200 OK)
        final List<dynamic> data = json.decode(response.body);

        // แปลง JSON List -> Recipe List
        return data.map((json) => Recipe.fromJson(json)).toList();
      } else {
        throw Exception('เชื่อมต่อ Server ไม่ได้: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('เกิดข้อผิดพลาด: $e');
    }
  }
}
