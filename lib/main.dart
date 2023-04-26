import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/views/dough.dart';
import 'package:sourbuddy/views/timer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = getDatabase();

  runApp(ChangeNotifierProvider(
    create: (ctx) => AppState(
        doughRepository: DoughRepository(db: db),
        timerRepository: TimerService(db: db)),
    child: const MyApp(),
  ));
}

class AppState extends ChangeNotifier {
  bool loading = true;
  Map<int, Dough> doughs = {};
  Map<int, List<DoughEvent>> doughEvents = {};
  Map<int, Timer> timers = {};
  final DoughRepository _doughRepository;
  final TimerService _timerRepository;

  AppState({required doughRepository, required timerRepository})
      : _doughRepository = doughRepository,
        _timerRepository = timerRepository {
    init();
  }

  init() async {
    loadDoughs();
    loadTimers();
  }

  loadDoughs() async {
    var doughs = await _doughRepository.listDoughs();
    this.doughs.clear();
    for (Dough dough in doughs) {
      this.doughs[dough.id] = dough;
    }
    loading = false;
    notifyListeners();
  }

  loadDoughEvents(int doughId) async {
    doughEvents[doughId] = (await _doughRepository.listEvents(doughId)).toList();
    notifyListeners();
  }

  Future<void> addDoughEvent(Dough dough, DoughEvent event) async {
    await _doughRepository.addEvent(dough, event);
    // Invalidate dough and it's events
    loadDoughs();
    loadDoughEvents(dough.id);
  }

  loadTimers() async {
    final timers = await _timerRepository.listTimers();
    this.timers.clear();
    for (Timer timer in timers) {
      this.timers[timer.id] = timer;
    }
    notifyListeners();
  }

  void addDough(Dough dough) async {
    debugPrint("$dough");
    await _doughRepository.addDough(dough);
    loadDoughs();
  }
}

enum LoadingState {
  notLoaded,
  loading,
  loaded,
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SourBuddy',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.brown,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _navigationIndex = 0;
  final List<Widget> _pages = <Widget>[
    const Center(
      child: DoughsOverview(),
    ),
    const Center(
      child: TimerOverview(),
    ),
  ];

  void _onNavigationItemTapped(int index) {
    setState(() {
      _navigationIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SourBuddy')),
      body: _pages.elementAt(_navigationIndex),
      floatingActionButton: (_navigationIndex == 0)
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => CreateDoughPage()));
              },
              child: Icon(Icons.add))
          : FloatingActionButton(
              onPressed: () {}, child: Icon(Icons.add_alarm)),
      bottomNavigationBar:
          BottomNavigationBar(items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.science), label: "Doughs"),
        BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timers"),
      ], currentIndex: _navigationIndex, onTap: _onNavigationItemTapped),
    );
  }
}
