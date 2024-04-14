import 'package:expenseo/database/expense_database.dart';
import 'package:expenseo/helper/helper_functions.dart';
import 'package:expenseo/models/expense.dart';
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();
    super.initState();
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
    return Consumer<ExpenseDatabase>(
      builder: (context, value, child) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: openExpenseBox,
          child: const Icon(Icons.add),
        ),
        body: ListView.builder(
          itemCount: value.allExpenses.length,
          itemBuilder: (context, index) {
            //get individual expense
            Expense individualExpense = value.allExpenses[index];
            //return list to  ui
            return MyListTile(
              title: individualExpense.name,
              trailing: FormatAmount(individualExpense.amount),
              onEditPressed: (context) => openEditBox(individualExpense),
              onDeletePressed: (context) => openDeleteBox(individualExpense),
            );
          },
        ),
      ),
    );
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
      },
      child: const Text('Delete'),
    );
  }
}
