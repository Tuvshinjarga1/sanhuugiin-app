import 'package:flutter/material.dart';

// Өнгөнүүд
const Color kPrimaryColor = Color(0xFF6A62B7);
const Color kBackgroundColor = Color(0xFFF5F5F5);
const Color kCardColor = Colors.white;
const Color kTextColor = Color(0xFF333333);
const Color kTextLightColor = Color(0xFF757575);
const Color kIncomeColor = Color(0xFF4CAF50);
const Color kExpenseColor = Color(0xFFE53935);

// Категориуд
final List<String> incomeCategories = [
  'Цалин',
  'Бизнес орлого',
  'Тэтгэвэр/Тэтгэмж',
  'Урамшуулал',
  'Зээл',
  'Бусад орлого',
];

final List<String> expenseCategories = [
  'Хоол хүнс',
  'Ахуйн зардал',
  'Хувцас',
  'Гоо сайхан',
  'Боловсрол',
  'Эрүүл мэнд',
  'Зээлийн төлбөр',
  'Тээвэр',
  'Утас/Интернэт',
  'Бусад',
];

// Хэмжээ утгууд
const double kDefaultPadding = 16.0;
const double kDefaultBorderRadius = 16.0;
const double kDefaultMargin = 16.0;
