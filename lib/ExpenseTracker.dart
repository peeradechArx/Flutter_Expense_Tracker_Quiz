import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; // Import package for displaying charts
import 'package:flutter_con_database_9624/screen/screen_Login.dart';
import 'package:intl/intl.dart'; // For date formatting

class ExpenseTracker extends StatefulWidget {
  const ExpenseTracker({Key? key}) : super(key: key);

  @override
  _ExpenseTrackerState createState() => _ExpenseTrackerState();
}

class _ExpenseTrackerState extends State<ExpenseTracker> {
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'Income'; // Default type

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addTransaction() {
    final user = FirebaseAuth.instance.currentUser;
    if (_amountController.text.isNotEmpty && user != null) {
      FirebaseFirestore.instance.collection('transactions').add({
        'userId': user.uid,
        'amount': double.parse(_amountController.text),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'type': _selectedType,
        'note': _noteController.text,
      }).then((_) {
        _amountController.clear();
        _noteController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added!')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add transaction: $error')),
        );
      });
    }
  }

  Future<void> _showGraph() async {
    final DateTime twoMonthsAgo = DateTime.now().subtract(const Duration(days: 60));

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(twoMonthsAgo))
          .get();

      final transactions = snapshot.docs;
      double totalIncome = 0.0;
      double totalExpense = 0.0;

      for (var doc in transactions) {
        double amount = doc['amount'];
        if (doc['type'] == 'Income') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      // Open a new screen to display the pie chart
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Transaction Pie Chart'),
            ),
            body: Center(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: totalIncome,
                      color: Colors.green,
                      title: 'Income\n${totalIncome.toStringAsFixed(2)}',
                      radius: 120, // Increased radius for thicker sections
                      titleStyle: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16, // Increased font size for better visibility
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PieChartSectionData(
                      value: totalExpense,
                      color: Colors.red,
                      title: 'Expense\n${totalExpense.toStringAsFixed(2)}',
                      radius: 120, // Increased radius for thicker sections
                      titleStyle: const TextStyle(
                        color: Colors.white, 
                        fontSize: 16, // Increased font size for better visibility
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  centerSpaceRadius: 80, // Adjusted to match the increased section thickness
                  sectionsSpace: 2,
                ),
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load transactions: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Select Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDate),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(child: Text('Income'), value: 'Income'),
                    DropdownMenuItem(child: Text('Expense'), value: 'Expense'),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedType = value as String;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addTransaction,
                  child: const Text('Add Transaction'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions = snapshot.data!.docs;
                final totalIncome = _calculateTotal(transactions, 'Income');
                final totalExpense = _calculateTotal(transactions, 'Expense');

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Total Income: $totalIncome\nTotal Expense: $totalExpense',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _showGraph,
                      child: const Text('Show Graph (Last 2 Months)'),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          var doc = transactions[index];
                          return ListTile(
                            title: Text(
                              '${doc['type']} - ${doc['amount']}',
                              style: TextStyle(
                                color: doc['type'] == 'Income'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                            subtitle: Text('${doc['date']} - ${doc['note']}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('transactions')
                                    .doc(doc.id)
                                    .delete();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal(List<DocumentSnapshot> transactions, String type) {
    return transactions
        .where((doc) => doc['type'] == type)
        .map((doc) => doc['amount'] as double)
        .fold(0.0, (prev, amount) => prev + amount);
  }
}
