import 'product_model.dart';

typedef HomeProductsData = ({
  List<ProductModel> products,
  Map<String, int> salesCounts,
  Map<String, ({double avg, int count})> ratings,
});
