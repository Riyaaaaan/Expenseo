import 'dart:developer';

import 'package:expenseo/bar_graph/bar_graph.dart';
import 'package:expenseo/database/expense_database.dart';
import 'package:expenseo/helper/helper_functions.dart';
import 'package:expenseo/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../components/my_list_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();

  //future to load graph data & monthly total
  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _calculateCurrentMonthTotal;

  @override
  void initState() {
    //read db on startup
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    //load future on startup
    refreshData();
    super.initState();
  }

  //refresh graph data
  void refreshData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
    _calculateCurrentMonthTotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateCurrentMonthTotal();
  }

  //open expense
  void openExpenseBox() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Name'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(hintText: 'Amount'),
            ),
          ],
        ),
        actions: [
          // cancel
          _cancelButton(),
          // save
          _saveButton()
        ],
      ),
    );
  }

  // open edit box
  void openEditBox(Expense expense) {
    //load existing values
    String existingName = expense.name;
    String existingamount = expense.amount.toString();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: existingName),
            ),
            TextField(
              controller: amountController,
              decoration: InputDecoration(hintText: existingamount),
            ),
          ],
        ),
        actions: [
          // cancel
          _cancelButton(),
          // save
          _editExpenseButton(expense)
        ],
      ),
    );
  }

  //open delete box
  void openDeleteBox(Expense expense) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete expense?'),
        actions: [
          // cancel
          _cancelButton(),
          // save
          _deleteExpenseButton(expense.id)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(builder: (context, value, child) {
      // get dates
      int startMonth = value.getStartMonth();
      int startYear = value.getStartYear();
      int currentMonth = DateTime.now().month;
      int currentYear = DateTime.now().year;

      // calculate the no.of months since first month
      int monthCount =
          calculateMonthCount(startYear, startMonth, currentYear, currentMonth);
      // display expense of current month
      List<Expense> currentMonthExpense = value.allExpenses.where((expense) {
        return expense.date.year == currentYear &&
            expense.date.month == currentMonth;
      }).toList();
      //return UI
      return Scaffold(
        backgroundColor: Colors.grey.shade300,
        floatingActionButton: FloatingActionButton(
          onPressed: openExpenseBox,
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: FutureBuilder(
            future: _calculateCurrentMonthTotal,
            builder: (context, snapshot) {
              //loaded
              if (snapshot.connectionState == ConnectionState.done) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //total
                    Text('₹ ${snapshot.data!.toStringAsFixed(2)}'),
                    //month
                    Text(getCurrentMonthName()),
                  ],
                );
              }
              //loading
              else {
                return const Text('Loading....');
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              //GRAPH UI
              // SizedBox(height: screenHeight * 0.05),
              SizedBox(
                height: 400,
                child: FutureBuilder(
                  future: _monthlyTotalsFuture,
                  builder: (context, snapshot) {
                    // Data is loaded
                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, double> monthlyTotals = snapshot.data ?? {};

                      // Create list of summary
                      List<double> monthlySummary = List.generate(
                        monthCount,
                        (index) {
                          // calculate year month with start month & index
                          int year = startYear + (startMonth + index - 1) ~/ 12;
                          int month = (startMonth + index - 1) % 12 + 1;

                          // create key in year month frmat
                          String yearMonthKey = '$year-$month';

                          // return the total or 0
                          return monthlyTotals[yearMonthKey] ?? 0.0;
                        },
                      );

                      return MyBarGraph(
                        monthlySummary: monthlySummary,
                        startMonth: startMonth,
                      );
                    } else {
                      return const Center(
                        child: Text('Loading....'),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 25),

              //EXPENSE LIST UI

              Expanded(
                child: ListView.builder(
                  itemCount: currentMonthExpense.length,
                  itemBuilder: (context, index) {
                    // reverse list to show latest first
                    int reversedIndex = currentMonthExpense.length - 1 - index;
                    //get individual expense
                    Expense individualExpense =
                        currentMonthExpense[reversedIndex];
                    //return list to  ui
                    return MyListTile(
                      title: individualExpense.name,
                      trailing: FormatAmount(individualExpense.amount),
                      onEditPressed: (context) =>
                          openEditBox(individualExpense),
                      onDeletePressed: (context) =>
                          openDeleteBox(individualExpense),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // CANCEL BUTTON
  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        nameController.clear();
        amountController.clear();
      },
      child: const Text('cancel'),
    );
  }

  // SAVE BUTTON
  Widget _saveButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          // pop
          Navigator.pop(context);
          // create new expense
          Expense newExpense = Expense(
            name: nameController.text,
            amount: convertStringToDouble(amountController.text),
            date: DateTime.now(),
          );

          //save to db
          await context.read<ExpenseDatabase>().createNewExpense(newExpense);

          //refresh
          refreshData();

          //clr controller
          nameController.clear();
          amountController.clear();
        }
      },
      child: const Text('Save'),
    );
  }

  // EDIT EXPENSE BUTTON
  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          //pop
          Navigator.pop(context);
          //new updated
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            amount: amountController.text.isNotEmpty
                ? convertStringToDouble(amountController.text)
                : expense.amount,
            date: DateTime.now(),
          );
          //old expense id
          int existingId = expense.id;
          // save to db
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense);
        }
        refreshData();
      },
      child: const Text('Save'),
    );
  }

  // DELETE BUTTON
  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);
        await context.read<ExpenseDatabase>().deleteExpense(id);
        refreshData();
      },
      child: const Text('Delete'),
    );
  }
}
