import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ImageService {
    final FirebaseStorage _storage = FirebaseStorage.instance;
    final ImagePicker _imagePicker = ImagePicker();

    //chọn ảnh từ thư viện
    Future<File?> pickImageFromGallery() async {
        try{
            final XFile? image = await _imagePicker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
            );
            if(image != null){
                return File(image.path);
            }
            return null;
        } catch (e) {
            throw Exception('Lỗi khi chọn ảnh từ thư viện: $e');
        }
    }

    //chọn ảnh từ camera    
    Future<File?> pickImageFromCamera() async {
        try{
            final XFile? image = await _imagePicker.pickImage(
                source: ImageSource.camera,
                maxWidth: 1024,
                maxHeight: 1024,
                imageQuality: 80,
            );

            if(image != null){
                return File(image.path);
            }
            return null;
        } catch (e) {
            throw Exception('Lỗi khi chụp ảnh: $e');
        }
    }

    //upload ảnh lên Firebase Storage va tra ve URL
    Future<String> uploadImageToFirebase(File imageFile, String fileName) async {
        try{
            // Kiểm tra user đã đăng nhập chưa
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) {
                throw Exception('User chưa đăng nhập. Vui lòng đăng nhập trước khi upload ảnh.');
            }
            
            final Reference ref = _storage.ref().child('food_images').child(fileName);
            final UploadTask uploadTask = ref.putFile(imageFile);
            final TaskSnapshot snapshot = await uploadTask;
            final String downloadUrl = await snapshot.ref.getDownloadURL();
            return downloadUrl;
        } catch (e) {
            throw Exception('Lỗi khi upload ảnh: $e');
        }
    }

    //xoa ảnh khỏi Firebase Storage
    Future<void> deleteImageFromFirebase(String imageUrl) async {
        try{
            final Reference ref = _storage.refFromURL(imageUrl);
            await ref.delete();
        } catch (e) {
            throw Exception('Lỗi khi xóa ảnh: $e');
        }
    }

    //Tạo tên file duy nhất
    String generateUniqueFileName(String originalName) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final extension = originalName.split('.').last;
        return 'food_${timestamp}.$extension';
    }
            
}