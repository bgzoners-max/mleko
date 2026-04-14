import 'web_seo_stub.dart' if (dart.library.html) 'web_seo_web.dart' as impl;

void setPageMetadata({
  required String title,
  String? description,
  String? path,
  String? imageUrl,
  String? type,
}) {
  impl.setPageMetadata(
    title: title,
    description: description,
    path: path,
    imageUrl: imageUrl,
    type: type,
  );
}
