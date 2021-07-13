import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:layout_builder/form/form.dart';
import 'package:layout_builder/platform/platform.dart';
import 'package:layout_builder/platform/platform_alert_dialog.dart';
import 'package:layout_builder/platform/platform_icons.dart';
import 'package:layout_builder/platform/platform_list_tile.dart';
import 'package:layout_builder/platform/platform_navigation_bar_button.dart';
import 'package:layout_builder/platform/platform_navigation_bar.dart';
import 'package:layout_builder/platform/platform_scaffold.dart';
import 'package:layout_builder/theme/theme.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

showPlatformMultiPicker<T>(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  String? subtitle,
  required List<T> data,
  required List<T> selectedValues,
  required Widget Function(T) itemBuilder,
  required Function(List<T>) onSave,
}) {
  final selectedValuesProvider = StateProvider<List<T>>((_) {
    throw UnimplementedError();
  });

  _onChanged(WidgetRef ref, T item, bool isSelected) {
    final _selectedValues = ref.read(selectedValuesProvider).state;
    if (isSelected) {
      ref.read(selectedValuesProvider).state = [..._selectedValues]
        ..remove(item);
    } else {
      ref.read(selectedValuesProvider).state = [..._selectedValues, item];
    }
  }

  _onSave(BuildContext context, WidgetRef ref) {
    onSave(ref.read(selectedValuesProvider).state);
    Navigator.of(context).pop();
  }

  if (isMaterial()) {
    showDialog(
      context: context,
      builder: (context) {
        return ProviderScope(
          overrides: [
            selectedValuesProvider.overrideWithValue(
              StateController<List<T>>(selectedValues),
            ),
          ],
          child: Consumer(builder: (context, ref, child) {
            final _selectedValues = ref.watch(selectedValuesProvider).state;
            return AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    for (T item in data)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: itemBuilder(item),
                        value: _selectedValues.contains(item),
                        onChanged: (_) => _onChanged(
                          ref,
                          item,
                          _selectedValues.contains(item),
                        ),
                      ),
                  ],
                ),
              ),
              actions: <Widget>[
                PlatformDialogAction(
                  buttonText: MaterialLocalizations.of(context)
                      .cancelButtonLabel
                      .toUpperCase(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                PlatformDialogAction(
                  buttonText: MaterialLocalizations.of(context)
                      .saveButtonLabel
                      .toUpperCase(),
                  onPressed: () => _onSave(context, ref),
                  isDefaultAction: true,
                ),
              ],
            );
          }),
        );
      },
    );
  } else {
    showCupertinoModalBottomSheet(
      context: context,
      duration: Duration(milliseconds: 300),
      builder: (context) => ProviderScope(
        overrides: [
          selectedValuesProvider.overrideWithValue(
            StateController<List<T>>(selectedValues),
          ),
        ],
        child: Consumer(builder: (context, ref, child) {
          final appTheme = ref.watch(appThemeProvider);
          final _selectedValues = ref.watch(selectedValuesProvider).state;

          return PlatformModalScaffold(
            appBar: PlatformNavigationBar(
              title: title,
              leading: PlatformNavigationBarCloseButton(
                onPressed: () => Navigator.pop(context),
              ),
              trailing: PlatformNavigationBarButton(
                onPressed: () => _onSave(context, ref),
                buttonText: MaterialLocalizations.of(context).okButtonLabel,
              ),
            ),
            body: FormPage(
              children: [
                FormSection(
                  children: data
                      .map((item) => PlatformListTile(
                            leading: itemBuilder(item),
                            trailing: Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: _selectedValues.contains(item)
                                  ? Icon(
                                      PlatformIcons.checkmarkFill,
                                      size: 26,
                                      color: appTheme.primaryColor,
                                    )
                                  : Icon(
                                      CupertinoIcons.circle,
                                      size: 26,
                                      color: Colors.grey.shade300,
                                    ),
                            ),
                            onTap: () => _onChanged(
                              ref,
                              item,
                              _selectedValues.contains(item),
                            ),
                          ))
                      .toList(),
                  caption: subtitle,
                ),
              ],
            ),
          );
        }),
      ),
      useRootNavigator: true,
    );
  }
}
