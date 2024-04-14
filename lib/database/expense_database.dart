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

  //* O P E R A T I O N S

  //create
  Future<void> createNewExpense(Expense newExpense) async {
    //add to db
    await isar.writeTxn(() => isar.expenses.put(newExpense));

    // refresh db
    await readExpenses();
  }

  //read
  Future<void> readExpenses() async {
    //fetch expenses
    List<Expense> fetchExpenses = await isar.expenses.where().findAll();

    //local expense
    _allExpenses.clear();
    _allExpenses.addAll(fetchExpenses);

    //display
    notifyListeners();
  }

  //update
  Future<void> updateExpense(int id, Expense updatedExpense) async {
    // id validation
    updatedExpense.id = id;

    //update db
    await isar.writeTxn(() => isar.expenses.put(updatedExpense));

    // refresh db
    await readExpenses();
  }

  //delete
  Future<void> deleteExpense(int id) async {
    //delete from db
    await isar.writeTxn(() => isar.expenses.delete(id));
    //refresh db
    await readExpenses();
  }
}
