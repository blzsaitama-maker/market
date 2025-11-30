import 'package:flutter/material.dart';

InputDecoration customInputDecoration(String label, {bool enabled = true}) {
  return InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: enabled ? Colors.black54 : Colors.grey),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    floatingLabelStyle: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
    ),
    fillColor: enabled ? Colors.white : Colors.grey.shade200,
    filled: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none,
    ),
  );
}
