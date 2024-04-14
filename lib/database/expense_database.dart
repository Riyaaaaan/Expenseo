import 'dart:core';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  List<Expense> _allExpenses = [];

  //init db
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  //getter method

  List<Expense> get allExpenses => _allExpenses;

  //*--------------- O P E R A T I O N S -------------------------------->

  // CREATE
  Future<void> createNewExpense(Expense newExpense) async {
    //add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    // refresh db
    await readExpenses();
  }

  // READ
  Future<void> readExpenses() async {
    //fetch expenses
    List<Expense> fetchExpenses = await isar.expenses.where().findAll();

    //local expense
    _allExpenses.clear();
    _allExpenses.addAll(fetchExpenses);

    //display
    notifyListeners();
  }

  //UPDATE
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    // id validation
    updatedExpense.id = id;

    //update db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));

    // refresh db
    await readExpenses();
  }

  //DELETE
  Future<void> deleteExpense(int id) async {
    //delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));
    //refresh db
    await readExpenses();
  }
// --------------------------------------------------->

// calculate total expense of each month
  Future<Map<String, double>> calculateMonthlyTotals() async {
    await readExpenses();

    Map<String, double> monthlyTotals = {};

    // Go through all expenses
    for (var expense in _allExpenses) {
      // Extract year & month from date
      String yearMonth = '${expense.date.year}-${expense.date.month}';
      // If year month not in map, initialize to 0
      if (!monthlyTotals.containsKey(yearMonth)) {
        monthlyTotals[yearMonth] = 0;
      }
      // Add expense to the total of the month
      monthlyTotals[yearMonth] = monthlyTotals[yearMonth]! + expense.amount;
    }
    return monthlyTotals;
  }

  // calculate current month total
  Future<double> calculateCurrentMonthTotal() async {
    //espense read from db
    await readExpenses();
    //get current month & year
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;
    // include only this month
    List<Expense> currentMonthExpenses = _allExpenses.where((expense) {
      return expense.date.month == currentMonth &&
          expense.date.year == currentYear;
    }).toList();
    // calculate total of the month
    double total =
        currentMonthExpenses.fold(0, (sum, expense) => sum + expense.amount);

    return total;
  }

  // get start month
  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().month;
      // default to current month is no expenses are recorded
    }
    //sort expense by date to find the earliest
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );
    return _allExpenses.first.date.month;
  }

  // get start year
  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
      // default to current month is no expenses are recorded
    }
    //sort expense by date to find the earliest
    _allExpenses.sort(
      (a, b) => a.date.compareTo(b.date),
    );
    return _allExpenses.first.date.year;
  }
}
