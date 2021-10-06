part of platform;

showPlatformNumberPicker(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required int minValue,
  required int maxValue,
  required int selectedValue,
  required Function(int) onChanged,
}) {
  if (isMaterial()) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: NumberPicker(
            value: selectedValue,
            minValue: 0,
            maxValue: 100,
            onChanged: onChanged,
          ),
        );
      },
    );
  } else {}
}
