class Product {
  final String productName;
  final String imageUrl;
  final String price;
  bool isFavorite;

  Product({
    required this.productName,
    required this.imageUrl,
    required this.price,
    this.isFavorite = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    String price = '0.0';
    if (json['Varient'] is List && (json['Varient'] as List).isNotEmpty) {
      for (var variant in json['Varient']) {
        final ugaPrice = variant['UgaPrice'];
        final ufaPrice = variant['UfaPrice'];

        double p = 0;
        if (ugaPrice != null) p = double.tryParse(ugaPrice.toString()) ?? 0;
        if (p == 0 && ufaPrice != null) p = double.tryParse(ufaPrice.toString()) ?? 0;

        if (p > 0) {
          price = p.toStringAsFixed(2);
          break;
        }
      }
    }

    return Product(
      productName: json['ProductName'] ?? json['product_name'] ?? 'Unknown Product',
      imageUrl: json['ProductCoverImage'] ?? json['ProductImage'] ?? json['image_url'] ?? '',
      price: price,
    );
  }
}
