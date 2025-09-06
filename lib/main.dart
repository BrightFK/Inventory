import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);

  // Register adapters
  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(CategoryAdapter());

  // Open boxes
  await Hive.openBox<InventoryItem>('inventory');
  await Hive.openBox<Category>('categories');
  await Hive.openBox('settings');

  runApp(const InventoryApp());
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
}

// Hive models
@HiveType(typeId: 0)
class InventoryItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String sku;

  @HiveField(3)
  String category;

  @HiveField(4)
  double price;

  @HiveField(5)
  int quantity;

  @HiveField(6)
  String supplier;

  @HiveField(7)
  String? imagePath;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.quantity,
    required this.supplier,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });
}

class InventoryItemAdapter extends TypeAdapter<InventoryItem> {
  @override
  final int typeId = 0;

  @override
  InventoryItem read(BinaryReader reader) {
    return InventoryItem(
      id: reader.readString(),
      name: reader.readString(),
      sku: reader.readString(),
      category: reader.readString(),
      price: reader.readDouble(),
      quantity: reader.readInt(),
      supplier: reader.readString(),
      imagePath: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
      updatedAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, InventoryItem obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.sku);
    writer.writeString(obj.category);
    writer.writeDouble(obj.price);
    writer.writeInt(obj.quantity);
    writer.writeString(obj.supplier);
    writer.writeString(obj.imagePath ?? '');
    writer.writeString(obj.createdAt.toIso8601String());
    writer.writeString(obj.updatedAt.toIso8601String());
  }
}

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
  });
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 1;

  @override
  Category read(BinaryReader reader) {
    return Category(
      id: reader.readString(),
      name: reader.readString(),
      description: reader.readString(),
      createdAt: DateTime.parse(reader.readString()),
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.description);
    writer.writeString(obj.createdAt.toIso8601String());
  }
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventory Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        iconTheme: const IconThemeData(color: Colors.blueAccent, size: 24),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .copyWith(
              headlineMedium: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
              bodyMedium: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.black87,
              ),
              bodySmall: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Initialize default categories if none exist
    _initializeDefaultData();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    });
  }

  void _initializeDefaultData() async {
    final categoriesBox = Hive.box<Category>('categories');
    if (categoriesBox.isEmpty) {
      final defaultCategories = [
        Category(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: 'Electronics',
          description: 'Electronic devices and components',
          createdAt: DateTime.now(),
        ),
        Category(
          id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
          name: 'Office Supplies',
          description: 'Office stationery and supplies',
          createdAt: DateTime.now(),
        ),
        Category(
          id: (DateTime.now().millisecondsSinceEpoch + 2).toString(),
          name: 'Computer Parts',
          description: 'Computer hardware components',
          createdAt: DateTime.now(),
        ),
      ];

      for (var category in defaultCategories) {
        await categoriesBox.add(category);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.inventory,
                  size: 60,
                  color: Color(0xFF0A2463),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Inventory Pro',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Offline Inventory Management',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Inventory Pro',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E88E5), Color(0xFF0A2463)],
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.inventory, size: 60, color: Colors.white),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatsRow(),
                  const SizedBox(height: 30),
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    children: [
                      _buildCategoryCard(
                        context,
                        'Add Item',
                        Icons.add_box,
                        const Color(0xFF1E88E5),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddItemScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCategoryCard(
                        context,
                        'View Inventory',
                        Icons.list_alt,
                        const Color(0xFF42A5F5),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoryScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCategoryCard(
                        context,
                        'Categories',
                        Icons.category,
                        const Color(0xFF64B5F6),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoriesScreen(),
                            ),
                          );
                        },
                      ),
                      _buildCategoryCard(
                        context,
                        'Reports',
                        Icons.analytics,
                        const Color(0xFF90CAF9),
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Low Stock Items',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildLowStockList(),
                  const SizedBox(height: 45),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddItemScreen()),
          );
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF0A2463)),
      ),
    );
  }

  Widget _buildStatsRow() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<InventoryItem>('inventory').listenable(),
      builder: (context, Box<InventoryItem> box, widget) {
        final totalItems = box.length;
        final lowStockItems = box.values
            .where((item) => item.quantity < 5)
            .length;
        final categoriesBox = Hive.box<Category>('categories');
        final totalCategories = categoriesBox.length;

        return Container(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildStatCard(
                'Total Items',
                totalItems.toString(),
                Icons.inventory,
              ),
              _buildStatCard(
                'Categories',
                totalCategories.toString(),
                Icons.category,
              ),
              _buildStatCard(
                'Low Stock',
                lowStockItems.toString(),
                Icons.warning,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 100,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0A2463)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, const Color(0xFF0A2463)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<InventoryItem>('inventory').listenable(),
      builder: (context, Box<InventoryItem> box, widget) {
        final lowStockItems = box.values
            .where((item) => item.quantity < 5)
            .toList();

        if (lowStockItems.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'No low stock items',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
          );
        }

        return Column(
          children: lowStockItems.map((item) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF1E88E5),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.inventory, color: Color(0xFF0A2463)),
                  ),
                  title: Text(
                    item.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    '${item.quantity} left',
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  trailing: Icon(Icons.warning, color: Colors.amber),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _supplierController = TextEditingController();

  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Generate a default SKU
    _skuController.text = 'SKU${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final inventoryBox = Hive.box<InventoryItem>('inventory');

      final newItem = InventoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        sku: _skuController.text,
        category: _categoryController.text,
        price: double.parse(_priceController.text),
        quantity: int.parse(_quantityController.text),
        supplier: _supplierController.text,
        imagePath: _imagePath,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await inventoryBox.add(newItem);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item saved successfully!')));

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      appBar: AppBar(
        title: Text(
          'Add New Item',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2463),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFF1E88E5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _imagePath != null
                                ? CircleAvatar(
                                    radius: 50,
                                    backgroundImage: FileImage(
                                      File(_imagePath!),
                                    ),
                                  )
                                : const CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 40,
                                      color: Color(0xFF0A2463),
                                    ),
                                  ),
                            const SizedBox(height: 10),
                            Text(
                              _imagePath != null
                                  ? 'Change Image'
                                  : 'Add Product Image',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildFormField(
                  'Product Name',
                  Icons.title,
                  _nameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                _buildFormField(
                  'SKU',
                  Icons.confirmation_number,
                  _skuController,
                ),
                _buildCategoryDropdown(),
                _buildFormField(
                  'Price',
                  Icons.attach_money,
                  _priceController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                _buildFormField(
                  'Quantity',
                  Icons.format_list_numbered,
                  _quantityController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                _buildFormField(
                  'Supplier',
                  Icons.business,
                  _supplierController,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'SAVE ITEM',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0A2463),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          prefixIcon: Icon(icon, color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white54),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Category>('categories').listenable(),
      builder: (context, Box<Category> box, widget) {
        final categories = box.values.toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Category',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.category, color: Colors.white70),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white54),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            value: _categoryController.text.isEmpty
                ? null
                : _categoryController.text,
            items: [
              const DropdownMenuItem(value: '', child: Text('Select Category')),
              ...categories.map((category) {
                return DropdownMenuItem(
                  value: category.name,
                  child: Text(category.name),
                );
              }).toList(),
              const DropdownMenuItem(
                value: 'add_new',
                child: Text('+ Add New Category'),
              ),
            ],
            onChanged: (value) {
              if (value == 'add_new') {
                _showAddCategoryDialog();
              } else if (value != null) {
                setState(() {
                  _categoryController.text = value;
                });
              }
            },
            style: const TextStyle(color: Colors.black),
            dropdownColor: Colors.white,
          ),
        );
      },
    );
  }

  void _showAddCategoryDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final categoriesBox = Hive.box<Category>('categories');
                  final newCategory = Category(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descController.text,
                    createdAt: DateTime.now(),
                  );
                  await categoriesBox.add(newCategory);

                  setState(() {
                    _categoryController.text = nameController.text;
                  });

                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = "";
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      appBar: AppBar(
        title: Text(
          'Inventory',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2463),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showSearchDialog(context),
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => _showFilterDialog(context),
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<InventoryItem>('inventory').listenable(),
        builder: (context, Box<InventoryItem> box, widget) {
          List<InventoryItem> items = box.values.toList();

          // 🔎 Apply Search
          if (_searchQuery.isNotEmpty) {
            items = items
                .where(
                  (item) =>
                      item.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      item.sku.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
          }

          // 📂 Apply Filter
          if (_selectedCategory != null) {
            items = items
                .where((item) => item.category == _selectedCategory)
                .toList();
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No inventory items found',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildInventoryItem(item, context, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildInventoryItem(
    InventoryItem item,
    BuildContext context,
    int index,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0A2463)],
          ),
        ),
        child: ListTile(
          leading: item.imagePath != null
              ? CircleAvatar(backgroundImage: FileImage(File(item.imagePath!)))
              : const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.inventory, color: Color(0xFF0A2463)),
                ),
          title: Text(
            item.name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            "${item.sku} • ${item.category}",
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${item.price.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Stock: ${item.quantity}',
                style: GoogleFonts.poppins(
                  color: item.quantity < 5 ? Colors.amber : Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          onTap: () => _showItemDetails(context, item, index),
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, InventoryItem item, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item.name),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imagePath != null)
                  Image.file(File(item.imagePath!), height: 100),
                const SizedBox(height: 10),
                Text('SKU: ${item.sku}'),
                Text('Category: ${item.category}'),
                Text('Price: \$${item.price.toStringAsFixed(2)}'),
                Text('Quantity: ${item.quantity}'),
                Text('Supplier: ${item.supplier}'),
                Text(
                  'Added: ${DateFormat('yyyy-MM-dd').format(item.createdAt)}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            TextButton(
              onPressed: () => _adjustStock(context, item, index, true),
              child: const Text('Supply More'),
            ),
            TextButton(
              onPressed: () => _adjustStock(context, item, index, false),
              child: const Text('Sell'),
            ),
            TextButton(
              onPressed: () => _editItem(context, item, index),
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => _deleteItem(context, index),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _editItem(BuildContext context, InventoryItem item, int index) {
    // Implementation for editing an item
    Navigator.pop(context); // Close details dialog first
    // Navigate to edit screen or show edit dialog
    _showEditDialog(context, item, index);
  }

  void _showEditDialog(BuildContext context, InventoryItem item, int index) {
    final TextEditingController nameController = TextEditingController(
      text: item.name,
    );
    final TextEditingController skuController = TextEditingController(
      text: item.sku,
    );
    final TextEditingController categoryController = TextEditingController(
      text: item.category,
    );
    final TextEditingController priceController = TextEditingController(
      text: item.price.toString(),
    );
    final TextEditingController quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final TextEditingController supplierController = TextEditingController(
      text: item.supplier,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                ),
                TextField(
                  controller: skuController,
                  decoration: const InputDecoration(labelText: 'SKU'),
                ),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: supplierController,
                  decoration: const InputDecoration(labelText: 'Supplier'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final inventoryBox = Hive.box<InventoryItem>('inventory');
                final updatedItem = InventoryItem(
                  id: item.id,
                  name: nameController.text,
                  sku: skuController.text,
                  category: categoryController.text,
                  price: double.parse(priceController.text),
                  quantity: int.parse(quantityController.text),
                  supplier: supplierController.text,
                  imagePath: item.imagePath,
                  createdAt: item.createdAt,
                  updatedAt: DateTime.now(),
                );

                await inventoryBox.putAt(index, updatedItem);
                Navigator.pop(context);
                Navigator.pop(context); // Also close the details dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item updated successfully!')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteItem(BuildContext context, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final box = Hive.box<InventoryItem>('inventory');
      await box.deleteAt(index);
      Navigator.pop(context); // Close details dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully!')),
      );
    }
  }

  // 📦 Increase or decrease stock
  void _adjustStock(
    BuildContext context,
    InventoryItem item,
    int index,
    bool isSupply,
  ) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSupply ? "Supply More" : "Sell Products"),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: isSupply
                  ? "Enter supplied quantity"
                  : "Enter sold quantity",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final qty = int.tryParse(controller.text) ?? 0;
                if (qty <= 0) return;

                final box = Hive.box<InventoryItem>('inventory');
                final newQty = isSupply
                    ? item.quantity + qty
                    : item.quantity - qty;

                if (newQty < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Not enough stock to complete sale"),
                    ),
                  );
                  return;
                }

                final updatedItem = item
                  ..quantity = newQty
                  ..updatedAt = DateTime.now();

                await box.putAt(index, updatedItem);

                Navigator.pop(context);
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isSupply
                          ? "Stock increased successfully!"
                          : "Sale recorded successfully!",
                    ),
                  ),
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    final TextEditingController searchController = TextEditingController(
      text: _searchQuery,
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Inventory'),
          content: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name or SKU',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = searchController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Search'),
            ),
          ],
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    final box = Hive.box<InventoryItem>('inventory');
    final categories = box.values.map((e) => e.category).toSet().toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Filter by Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final category in categories)
                RadioListTile<String>(
                  value: category,
                  groupValue: _selectedCategory,
                  title: Text(category),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    Navigator.pop(context);
                  },
                ),
              RadioListTile<String>(
                value: "",
                groupValue: _selectedCategory ?? "",
                title: const Text("All Categories"),
                onChanged: (_) {
                  setState(() {
                    _selectedCategory = null;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      appBar: AppBar(
        title: Text(
          'Categories',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A2463),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Category>('categories').listenable(),
        builder: (context, Box<Category> box, widget) {
          final categories = box.values.toList();

          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No categories yet',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.8,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, context, index);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context),
        backgroundColor: Colors.white,
        child: const Icon(Icons.add, color: Color(0xFF0A2463)),
      ),
    );
  }

  Widget _buildCategoryCard(
    Category category,
    BuildContext context,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsScreen(category: category),
          ),
        );
      },
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E88E5), Color(0xFF0A2463)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.category, size: 40, color: Colors.white),
              const SizedBox(height: 15),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                category.description,
                style: GoogleFonts.poppins(color: Colors.white70),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final categoriesBox = Hive.box<Category>('categories');
                  final newCategory = Category(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    description: descController.text,
                    createdAt: DateTime.now(),
                  );
                  await categoriesBox.add(newCategory);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Category added successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      appBar: AppBar(
        title: Text(
          'Reports',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0A2463),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory Reports',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            _buildReportCard(
              'Stock Summary',
              Icons.summarize,
              () => _generateStockReport(context),
            ),
            _buildReportCard(
              'Low Stock Alert',
              Icons.warning,
              () => _generateLowStockReport(context),
            ),
            _buildReportCard(
              'Category Report',
              Icons.category,
              () => _generateCategoryReport(context),
            ),
            _buildReportCard(
              'Value Report',
              Icons.attach_money,
              () => _generateValueReport(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E88E5), Color(0xFF0A2463)],
          ),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.white, size: 30),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white),
          onTap: onTap,
        ),
      ),
    );
  }

  void _generateStockReport(BuildContext context) async {
    final inventoryBox = Hive.box<InventoryItem>('inventory');
    final items = inventoryBox.values.toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Stock Summary Report'),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Name', 'SKU', 'Category', 'Quantity', 'Price'],
                  ...items.map(
                    (item) => [
                      item.name,
                      item.sku,
                      item.category,
                      item.quantity.toString(),
                      '\$${item.price.toStringAsFixed(2)}',
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Save and share the PDF
    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'stock-summary.pdf');
  }

  void _generateLowStockReport(BuildContext context) async {
    final inventoryBox = Hive.box<InventoryItem>('inventory');
    final lowStockItems = inventoryBox.values
        .where((item) => item.quantity < 5)
        .toList();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Low Stock Alert Report'),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Name', 'SKU', 'Current Stock', 'Price'],
                  ...lowStockItems.map(
                    (item) => [
                      item.name,
                      item.sku,
                      item.quantity.toString(),
                      '\$${item.price.toStringAsFixed(2)}',
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'low-stock-alert.pdf');
  }

  void _generateCategoryReport(BuildContext context) async {
    final inventoryBox = Hive.box<InventoryItem>('inventory');
    final items = inventoryBox.values.toList();
    final categoriesBox = Hive.box<Category>('categories');
    final categories = categoriesBox.values.toList();

    // Group items by category
    final Map<String, List<InventoryItem>> itemsByCategory = {};
    for (var item in items) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Category Report'),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              ...itemsByCategory.entries.map((entry) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Header(level: 1, text: entry.key),
                    pw.Table.fromTextArray(
                      context: context,
                      data: [
                        ['Name', 'SKU', 'Quantity', 'Price'],
                        ...entry.value.map(
                          (item) => [
                            item.name,
                            item.sku,
                            item.quantity.toString(),
                            '\$${item.price.toStringAsFixed(2)}',
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(bytes: bytes, filename: 'category-report.pdf');
  }

  void _generateValueReport(BuildContext context) async {
    final inventoryBox = Hive.box<InventoryItem>('inventory');
    final items = inventoryBox.values.toList();

    // Calculate total value
    double totalValue = 0;
    for (var item in items) {
      totalValue += item.price * item.quantity;
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Inventory Value Report'),
              pw.Text(
                'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              ),
              pw.SizedBox(height: 20),
              pw.Header(
                level: 1,
                text:
                    'Total Inventory Value: \$${totalValue.toStringAsFixed(2)}',
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                data: [
                  ['Name', 'SKU', 'Quantity', 'Unit Price', 'Total Value'],
                  ...items.map(
                    (item) => [
                      item.name,
                      item.sku,
                      item.quantity.toString(),
                      '\$${item.price.toStringAsFixed(2)}',
                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'inventory-value-report.pdf',
    );
  }
}

class CategoryProductsScreen extends StatelessWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2463),
      appBar: AppBar(
        title: Text(
          category.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0A2463),
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<InventoryItem>('inventory').listenable(),
        builder: (context, Box<InventoryItem> box, _) {
          final products = box.values
              .where((item) => item.category == category.name)
              .toList();

          if (products.isEmpty) {
            return Center(
              child: Text(
                'No products in this category yet',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.inventory,
                    color: Color(0xFF0A2463),
                  ),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Qty: ${product.quantity} | Price: ₦${product.price.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
