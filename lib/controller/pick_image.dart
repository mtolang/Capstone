import 'package:image_picker/image_picker.dart';

class parentGovID {
  Future<XFile?> pickImageFromGallery() async {
    try {
      final imagePicker = ImagePicker();
      final pickedImageGallery =
          await imagePicker.pickImage(source: ImageSource.gallery);

      return pickedImageGallery;
    } catch (e) {
      print("Error picking an image from the gallery: $e");
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final imagePicker = ImagePicker();
      final pickedImageCamera =
          await imagePicker.pickImage(source: ImageSource.camera);

      return pickedImageCamera;
    } catch (e) {
      print("Error picking an image from the camera: $e");
      return null;
    }
  }
}

class therapistProID {
  Future<XFile?> pickImageFromGallery() async {
    try {
      final imagePicker = ImagePicker();
      final pickedImageGallery =
          await imagePicker.pickImage(source: ImageSource.gallery);

      return pickedImageGallery;
    } catch (e) {
      print("Error picking an image from the gallery: $e");
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final imagePicker = ImagePicker();
      final pickedImageCamera =
          await imagePicker.pickImage(source: ImageSource.camera);

      return pickedImageCamera;
    } catch (e) {
      print("Error picking an image from the camera: $e");
      return null;
    }
  }
}

class clinicGovFiles {
  Future<XFile?> pickImageFromGallery() async {
    try {
      final imagePicker = ImagePicker();
      final pickedImageGallery =
          await imagePicker.pickImage(source: ImageSource.gallery);

      return pickedImageGallery;
    } catch (e) {
      print("Error picking an image from the gallery: $e");
      return null;
    }
  }

  Future<XFile?> pickImageFromCamera() async {
    try {
      final imagePicker = ImagePicker();
      final pickedImageCamera =
          await imagePicker.pickImage(source: ImageSource.camera);

      return pickedImageCamera;
    } catch (e) {
      print("Error picking an image from the camera: $e");
      return null;
    }
  }
}
