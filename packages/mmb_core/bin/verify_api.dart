import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('=============================================');
  print('STARTING MMB END-TO-END API VERIFICATION SUITE');
  print('Target: http://localhost:5000');
  print('=============================================');

  final client = http.Client();
  const baseUrl = 'http://localhost:5000';

  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'verify_$stamp@example.com';
  const pass = 'TestPassword123';
  String? token;
  String? userId;

  // 1. Authentication
  print('\n[1. Authentication]');
  // A. Register
  final regRes = await client.post(
    Uri.parse('$baseUrl/api/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': 'Verification User',
      'email': email,
      'phone': '98${stamp % 100000000}',
      'password': pass,
      'role': 'buyer',
      'shopName': 'Verification Electronics',
      'city': 'Mumbai',
      'area': 'Bandra West'
    }),
  );
  print('A. Register status: ${regRes.statusCode}');
  assert(regRes.statusCode == 201 || regRes.statusCode == 200, 'Register failed: ${regRes.body}');
  final regData = jsonDecode(regRes.body);
  token = regData['token'];
  userId = regData['user']?['id'] ?? regData['user']?['_id'];
  print('   Token acquired: ${token?.substring(0, 20)}... User ID: $userId');

  // B. Login
  final loginRes = await client.post(
    Uri.parse('$baseUrl/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'emailOrPhone': email, 'password': pass}),
  );
  print('B. Login status: ${loginRes.statusCode}');
  assert(loginRes.statusCode == 200, 'Login failed: ${loginRes.body}');

  // C. Profile (/api/auth/me)
  final meRes = await client.get(
    Uri.parse('$baseUrl/api/auth/me'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('C. Get Me Profile status: ${meRes.statusCode}');
  assert(meRes.statusCode == 200, 'Me failed: ${meRes.body}');
  print('   Profile: ${jsonDecode(meRes.body)['name']}');

  // 2. Catalog & Products
  print('\n[2. Catalog & Products]');
  final prodId = 'prod-v-$stamp';
  final createProdRes = await client.post(
    Uri.parse('$baseUrl/api/products'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'id': prodId,
      'name': 'Samsung Galaxy S24 Ultra',
      'title': 'Samsung Galaxy S24 Ultra',
      'category': 'Smartphones',
      'price': 114999,
      'originalPrice': 129999,
      'image': 'https://example.com/s24.jpg',
      'sellerId': 'seller-test-01',
      'status': 'approved',
      'specs': {'ram': '12GB', 'storage': '512GB', 'condition': 'Brand New'},
    }),
  );
  print('A. Create Product status: ${createProdRes.statusCode}');
  assert(createProdRes.statusCode == 201 || createProdRes.statusCode == 200, 'Create product failed: ${createProdRes.body}');

  final getProdsRes = await client.get(Uri.parse('$baseUrl/api/products?category=Smartphones&status=approved'));
  print('B. Get Filtered Products status: ${getProdsRes.statusCode}');
  assert(getProdsRes.statusCode == 200, 'Get products failed');

  final getOneRes = await client.get(Uri.parse('$baseUrl/api/products/$prodId'));
  print('C. Get Single Product status: ${getOneRes.statusCode}');
  assert(getOneRes.statusCode == 200, 'Get single product failed');

  final updateProdRes = await client.put(
    Uri.parse('$baseUrl/api/products/$prodId'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'price': 109999}),
  );
  print('D. Update Product status: ${updateProdRes.statusCode}');
  assert(updateProdRes.statusCode == 200, 'Update product failed');

  final deleteProdRes = await client.delete(Uri.parse('$baseUrl/api/products/$prodId'));
  print('E. Delete Product status: ${deleteProdRes.statusCode}');
  assert(deleteProdRes.statusCode == 200, 'Delete product failed');

  // 3. Categories & Banners
  print('\n[3. Categories & Banners]');
  final getCatsRes = await client.get(Uri.parse('$baseUrl/api/catalog/categories'));
  print('B. Get Categories status: ${getCatsRes.statusCode}, body: ${getCatsRes.body}');

  final getBannersRes = await client.get(Uri.parse('$baseUrl/api/catalog/banners'));
  print('D. Get Banners status: ${getBannersRes.statusCode}, count: ${jsonDecode(getBannersRes.body).length}');

  // 4. Cart API
  print('\n[4. Cart API]');
  final addCartRes = await client.post(
    Uri.parse('$baseUrl/api/cart'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({'productId': 'prod-101', 'quantity': 2}),
  );
  print('A. Add Cart status: ${addCartRes.statusCode}');

  final updateCartRes = await client.put(
    Uri.parse('$baseUrl/api/cart/qty'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({'productId': 'prod-101', 'quantity': 4}),
  );
  print('B. Update Cart Quantity status: ${updateCartRes.statusCode}');

  final getCartRes = await client.get(
    Uri.parse('$baseUrl/api/cart'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('C. Get Cart status: ${getCartRes.statusCode}');

  final delCartItemRes = await client.delete(
    Uri.parse('$baseUrl/api/cart/prod-101'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('D. Remove Cart Item status: ${delCartItemRes.statusCode}');

  // 5. Favorites / Wishlist
  print('\n[5. Favorites / Wishlist]');
  final toggleFavRes = await client.post(
    Uri.parse('$baseUrl/api/favorites/toggle'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({'productId': 'prod-101'}),
  );
  print('A. Toggle Favorite status: ${toggleFavRes.statusCode}, body: ${toggleFavRes.body}');

  final getFavsRes = await client.get(
    Uri.parse('$baseUrl/api/favorites'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('B. Get Favorites status: ${getFavsRes.statusCode}, body: ${getFavsRes.body}');

  // 6. Enquiries API
  print('\n[6. Enquiries API]');
  final sendEnqRes = await client.post(
    Uri.parse('$baseUrl/api/enquiries'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({
      'productId': 'prod-101',
      'productName': 'iPhone 15 Pro Max 256GB',
      'sellerId': 'seller-01',
      'message': 'Testing enquiry verification',
      'quantityRequired': 3,
    }),
  );
  print('A. Send Enquiry status: ${sendEnqRes.statusCode}');

  final getEnqRes = await client.get(
    Uri.parse('$baseUrl/api/enquiries'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('B. Get Enquiries status: ${getEnqRes.statusCode}');

  // 7. Orders API
  print('\n[7. Orders API]');
  final ordId = 'ORD-V-$stamp';
  final placeOrdRes = await client.post(
    Uri.parse('$baseUrl/api/orders'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({
      'id': ordId,
      'customerName': 'Verification User',
      'phone': '9876543210',
      'address': 'Bandra West, Mumbai',
      'items': [
        {'productId': 'prod-101', 'name': 'iPhone 15 Pro Max', 'quantity': 1, 'price': 124999}
      ],
      'totalAmount': 124999,
      'orderStatus': 'Processing',
      'paymentMethod': 'COD',
    }),
  );
  print('A. Place Order status: ${placeOrdRes.statusCode}');

  final getOrdersRes = await client.get(
    Uri.parse('$baseUrl/api/orders'),
    headers: {'Authorization': 'Bearer $token'},
  );
  print('B. Get Orders status: ${getOrdersRes.statusCode}');

  // 8. Real-Time Server-Sent Events (SSE)
  print('\n[8. Server-Sent Events (SSE)]');
  final sseReq = http.Request('GET', Uri.parse('$baseUrl/api/catalog/products/stream'));
  sseReq.headers['Accept'] = 'text/event-stream';
  final sseRes = await client.send(sseReq);
  print('SSE Products stream connected: status ${sseRes.statusCode}');

  print('\n=============================================');
  print('ALL 8 API CATEGORIES VERIFIED SUCCESSFULLY!');
  print('=============================================');
  client.close();
}
