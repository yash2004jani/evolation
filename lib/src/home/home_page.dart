import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../model/product_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Product> _products = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String _priceFilter = "";
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchProducts();
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.univia.cc/api/ProductList'),
      );
      request.fields.addAll({
        "RegisterId": "1",
        "Iswishlist": "",
        "Pagination": _currentPage.toString(),
        "CategoryId": "",
        "SubCategoryId": "",
        "BrandId": "",
        "PriceFilter": _priceFilter,
        "SearchProductName": "",
        "LanguageId": "",
      });
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        List<dynamic> productList = [];
        if (data['Result'] is List) {
          productList = data['Result'];
        } else if (data['data'] is List) {
          productList = data['data'];
        }
        if (productList.isEmpty) {
          setState(() {
            _hasMore = false;
          });
        } else {
          setState(() {
            _products.addAll(
              productList.map((json) => Product.fromJson(json)).toList(),
            );
            // Client-side sorting as a fallback if API sorting is not reflecting
            if (_priceFilter == '1') {
              _products.sort((a, b) => double.parse(a.price).compareTo(double.parse(b.price)));
            } else if (_priceFilter == '2') {
              _products.sort((a, b) => double.parse(b.price).compareTo(double.parse(a.price)));
            }
            _currentPage++;
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text(
          'All Products',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              if (_priceFilter != value) {
                setState(() {
                  _priceFilter = value;
                  _products.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                _fetchProducts();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: '',
                child: Text('Default'),
              ),
              const PopupMenuItem<String>(
                value: '1',
                child: Text('Price Low To High'),
              ),
              const PopupMenuItem<String>(
                value: '2',
                child: Text('Price High To Low'),
              ),
            ],
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_vert, color: Colors.black54, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _priceFilter == '1'
                        ? 'Price Low To High'
                        : _priceFilter == '2'
                            ? 'Price High To Low'
                            : 'Sort By',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _products.isEmpty
          ? (_isLoading
                ? const Center(child: CircularProgressIndicator())
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No products found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchProducts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _products.clear();
                  _currentPage = 1;
                  _hasMore = true;
                });
                await _fetchProducts();
              },
              child: GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1 / 1.5,
                  crossAxisSpacing: 0,
                  mainAxisSpacing: 5,
                ),
                itemCount: _products.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final product = _products[index];
                  return Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: double.infinity,
                                width: double.infinity,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: (index % 4 == 0 || index % 4 == 3)
                                      ? Colors.green[50]
                                      : Colors.red[50],
                                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                                ),
                                child: product.imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                                        child: Image.network(
                                          product.imageUrl,
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(Icons.inventory, size: 50),
                                        ),
                                      )
                                    : const Icon(Icons.inventory, size: 50,),
                              ),
                              Positioned(
                                top: 8,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      product.isFavorite = !product.isFavorite;
                                    });
                                  },
                                  child: Icon(
                                    product.isFavorite ? Icons.star : Icons.star_border,
                                    color: Colors.green
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,

                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                '${product.price}',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
