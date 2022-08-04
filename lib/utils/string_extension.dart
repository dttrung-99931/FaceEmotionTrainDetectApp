extension StringExtensions on String {
  String upperCaseFirstChar() {
    return substring(0, 1).toUpperCase() + substring(1);
  }
}
