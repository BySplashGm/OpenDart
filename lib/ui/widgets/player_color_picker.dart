import 'package:flutter/material.dart';
import 'package:flutter_color_picker_plus/flutter_color_picker_plus.dart';

class PlayerColorPicker extends StatefulWidget {
  //Color pickerColor;
  const PlayerColorPicker({super.key /*, required this.pickerColor*/});

  @override
  State<PlayerColorPicker> createState() => _PlayerColorPickerState();
}

class _PlayerColorPickerState extends State<PlayerColorPicker> {
  Color _pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);

  // ValueChanged<Color> callback
  void changeColor(Color color) {
    setState(() => _pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return ColorPicker(pickerColor: _pickerColor, onColorChanged: changeColor);
  }
}
