import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:sourbuddy/db.dart';
import 'package:sourbuddy/views/dough.dart';
import 'package:sourbuddy/views/timer.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  runApp(MultiProvider(
    providers: [
      Provider(create: (context) {
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        flutterLocalNotificationsPlugin.initialize(const InitializationSettings(
            android: AndroidInitializationSettings('app_icon'),
            linux: LinuxInitializationSettings(defaultActionName: 'sourbuddy')));
        return flutterLocalNotificationsPlugin;
      }),
      Provider(create: (context) => DatabaseConnection()),
      Provider(create: (context) => DoughRepository(db: context.read())),
      Provider(create: (context) => TimerRepository(db: context.read())),
      ChangeNotifierProvider(
        create: (context) => AppState(
          doughRepository: context.read(),
          timerRepository: context.read(),
          notificationsPlugin: context.read(),
        ),
      )
    ],
    child: const MyApp(),
  ));
}

class AppState extends ChangeNotifier {
  bool loading = true;
  Map<int, Dough> doughs = {};
  Map<int, List<DoughEvent>> doughEvents = {};
  Map<int, Timer> timers = {};
  final DoughRepository _doughRepository;
  final TimerRepository _timerRepository;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  AppState(
      {required DoughRepository doughRepository,
      required TimerRepository timerRepository,
      required FlutterLocalNotificationsPlugin notificationsPlugin})
      : _doughRepository = doughRepository,
        _timerRepository = timerRepository,
        _notificationsPlugin = notificationsPlugin {
    init();
  }

  init() async {
    _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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

  Future<int> addDoughEvent(Dough dough, DoughEvent event) async {
    final id = await _doughRepository.addEvent(dough, event);
    // Invalidate dough and it's events
    loadDoughs();
    loadDoughEvents(dough.id);
    return id;
  }

  loadTimers() async {
    final timers = await _timerRepository.listTimers();
    this.timers.clear();
    for (Timer timer in timers) {
      this.timers[timer.id] = timer;
    }
    notifyListeners();
  }

  void addDough(Dough dough, double initialWeight) async {
    debugPrint("$dough");
    int id = await _doughRepository.addDough(dough.copyWith(weight: 0));
    await loadDoughs();
    final dbDough = doughs[id]!;
    await _doughRepository.addEvent(
        dbDough,
        DoughEvent(
            type: DoughEventType.created, timestamp: dough.lastFed, weightModifier: initialWeight, payload: Created()));
    loadDoughs();
    loadDoughEvents(dough.id);
    notifyListeners();
  }

  void deleteDough(Dough dough) async {
    debugPrint("$dough");
    await _doughRepository.deleteDough(dough);
    loadDoughs();
    notifyListeners();
  }

  void deleteDoughEvent(Dough dough, DoughEvent doughEvent) async {
    await _doughRepository.deleteEvent(dough, doughEvent);
    loadDoughEvents(dough.id);
    loadDoughs();
    notifyListeners();
  }

  void addTimer(Timer timer) async {
    final id = await _timerRepository.addTimer(timer);
    await loadTimers();
    _notificationsPlugin.zonedSchedule(
        id,
        "Teigalarm",
        "",
        tz.TZDateTime.from(timer.timestamp, tz.getLocation("Europe/Berlin")),
        const NotificationDetails(android: AndroidNotificationDetails("dough_alert", "Teigalarm")),
        androidScheduleMode: AndroidScheduleMode.inexact);
  }

  void deleteTimer(Timer timer) async {
    await _notificationsPlugin.cancel(timer.id);
    await _timerRepository.deleteTimer(timer);
    await loadTimers();
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown, brightness: Brightness.dark)),
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
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateDoughPage()));
              },
              child: const Icon(Icons.add))
          : FloatingActionButton(
              onPressed: () {
                context.read<AppState>().addTimer(Timer(
                    id: -1,
                    type: TimerType.finishFeeding,
                    timestamp: DateTime.now().add(const Duration(seconds: 10)),
                    created: DateTime.now(),
                    doughId: 0,
                    eventId: 0));
              },
              child: const Icon(Icons.add_alarm)),
      bottomNavigationBar: BottomNavigationBar(items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.science), label: "Doughs"),
        BottomNavigationBarItem(icon: Icon(Icons.timer), label: "Timers"),
      ], currentIndex: _navigationIndex, onTap: _onNavigationItemTapped),
    );
  }
}
