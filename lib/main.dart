import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(WeatherApp());
}

class WeatherApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Zambian Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WeatherHomeScreen(),
      routes: {
        '/home': (context) => WeatherHomeScreen(),
        '/details': (context) => WeatherDetailsScreen(),
        '/cities': (context) => WeatherCitiesScreen(),
      },
    );
  }
}

class WeatherHomeScreen extends StatefulWidget {
  @override
  _WeatherHomeScreenState createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  Map<String, dynamic>? weatherData;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    // Refresh every 30 minutes
    _timer = Timer.periodic(Duration(minutes: 30), (timer) {
      _fetchWeatherData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.techiqsmart.farm/api/weather/getweather/?lat=-15.4167&lon=28.2833'));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  String _getCurrentTemperature() {
    if (weatherData == null) return '--';
    return weatherData!['data']['current']['temp'].toStringAsFixed(0);
  }

  String _getWeatherCondition() {
    if (weatherData == null) return 'Loading...';
    return weatherData!['data']['current']['condition']['text'] ?? 'N/A';
  }

  String _getHighTemp() {
    if (weatherData == null) return '--';
    return weatherData!['data']['forecast']['forecastday'][0]['day']['maxtemp_c'].toStringAsFixed(0);
  }

  String _getLowTemp() {
    if (weatherData == null) return '--';
    return weatherData!['data']['forecast']['forecastday'][0]['day']['mintemp_c'].toStringAsFixed(0);
  }

  List<Widget> _buildHourlyForecast() {
    if (weatherData == null) return [];

    List<Widget> hourlyItems = [];
    final now = DateTime.now();
    final currentHour = now.hour;
    final hourlyData = weatherData!['data']['forecast']['forecastday'][0]['hour'];

    for (int i = 0; i < 24; i++) {
      final hourData = hourlyData[i];
      final time = DateTime.parse(hourData['time']);
      final isNow = time.hour == currentHour;

      IconData icon;
      if (hourData['will_it_rain'] == 1) {
        icon = Icons.grain;
      } else if (hourData['cloud'] > 50) {
        icon = Icons.wb_cloudy;
      } else {
        icon = Icons.wb_sunny;
      }

      hourlyItems.add(
          _buildHourlyItem(
              DateFormat.j().format(time),
              icon,
              '${hourData['temp_c'].toStringAsFixed(0)}°',
              isNow
          )
      );
    }

    return hourlyItems;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    SizedBox(height: screenHeight * 0.02),

                // City name
                Text(
                  'Lusaka',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.08,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                // Temperature
                Text(
                  '${_getCurrentTemperature()}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: screenWidth * 0.2,
                    fontWeight: FontWeight.w100,
                  ),
                ),

                // Weather description
                Text(
                  _getWeatherCondition(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                // High/Low temperatures
                Text(
                  'H:${_getHighTemp()}° L:${_getLowTemp()}°',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // House illustration
                Container(
                  width: screenWidth * 0.35,
                  height: screenWidth * 0.35,
                  child: Image.asset('assets/House.jpg', fit: BoxFit.contain),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Forecast tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hourly Forecast',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Weekly Forecast',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Hourly forecast
                Container(
                  height: screenHeight * 0.12,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _buildHourlyForecast(),
                  ),
                ),

                SizedBox(height: screenHeight * 0.02),

                // Bottom navigation
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.1,
                        vertical: screenHeight * 0.02
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                        GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/cities'),
                child: Icon(Icons.location_on, color: Colors.white, size: screenWidth * 0.06),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/details'),
                child: Container(
                  width: screenWidth * 0.14,
                  height: screenWidth * 0.14,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                  BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                  ],

                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: screenWidth * 0.07,
                ),
              ),
            ),
            Icon(Icons.menu, color: Colors.white, size: screenWidth * 0.06),
            ],
          ),
        ),
        ],
      ),
    ),
    ),
    ),
    ),
    ),
    );
  }

  Widget _buildHourlyItem(String time, IconData icon, String temp, bool isNow) {
    return Container(
      width: 60,
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isNow ? Color(0xFF4A3B8C) : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(35),
        border: isNow ? Border.all(color: Colors.white.withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isNow ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          Text(
            temp,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherDetailsScreen extends StatefulWidget {
  @override
  _WeatherDetailsScreenState createState() => _WeatherDetailsScreenState();
}

class _WeatherDetailsScreenState extends State<WeatherDetailsScreen> {
  Map<String, dynamic>? weatherData;

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  Future<void> _fetchWeatherData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.techiqsmart.farm/api/weather/getweather/?lat=-15.4167&lon=28.2833'));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  String _getCurrentTemperature() {
    if (weatherData == null) return '--';
    return weatherData!['data']['current']['temp'].toStringAsFixed(0);
  }

  String _getWeatherCondition() {
    if (weatherData == null) return 'Loading...';
    return weatherData!['data']['current']['condition']['text'] ?? 'N/A';
  }

  String _getUVIndex() {
    if (weatherData == null) return '--';
    return weatherData!['data']['current']['uv'].toStringAsFixed(0);
  }

  String _getWindSpeed() {
    if (weatherData == null) return '--';
    return weatherData!['data']['current']['wind_kph'].toStringAsFixed(1);
  }

  String _getWindDirection() {
    if (weatherData == null) return '--';
    return weatherData!['data']['current']['wind_dir'];
  }

  String _getSunrise() {
    if (weatherData == null) return '--:--';
    return weatherData!['data']['forecast']['forecastday'][0]['astro']['sunrise'];
  }

  String _getSunset() {
    if (weatherData == null) return '--:--';
    return weatherData!['data']['forecast']['forecastday'][0]['astro']['sunset'];
  }

  String _getRainfall() {
    if (weatherData == null) return '--';
    return weatherData!['data']['forecast']['forecastday'][0]['day']['totalprecip_mm'].toStringAsFixed(1);
  }

  List<Widget> _buildHourlyForecast() {
    if (weatherData == null) return [];

    List<Widget> hourlyItems = [];
    final now = DateTime.now();
    final currentHour = now.hour;
    final hourlyData = weatherData!['data']['forecast']['forecastday'][0]['hour'];

    for (int i = 0; i < 24; i++) {
      final hourData = hourlyData[i];
      final time = DateTime.parse(hourData['time']);
      final isNow = time.hour == currentHour;

      IconData icon;
      if (hourData['will_it_rain'] == 1) {
        icon = Icons.grain;
      } else if (hourData['cloud'] > 50) {
        icon = Icons.wb_cloudy;
      } else {
        icon = Icons.wb_sunny;
      }

      hourlyItems.add(
          _buildHourlyItem(
              DateFormat.j().format(time),
              icon,
              '${hourData['temp_c'].toStringAsFixed(0)}°',
              hourData['humidity'].toInt(),
              isNow
          )
      );
    }

    return hourlyItems;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
              child: Column(
                children: [
                  // Status bar
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: screenWidth * 0.05),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // City and weather info
                  Text(
                    'Lusaka',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.07,
                      fontWeight: FontWeight.w300,
                    ),
                  ),

                  Text(
                    '${_getCurrentTemperature()}° | ${_getWeatherCondition()}',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Forecast tabs
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hourly Forecast',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.2),
                      Text(
                        'Weekly Forecast',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: screenWidth * 0.035,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Hourly forecast
                  Container(
                    height: screenHeight * 0.15,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _buildHourlyForecast(),
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Air Quality section
                  Container(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AIR QUALITY',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          '3-Low Health Risk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                Colors.green,
                                Colors.yellow,
                                Colors.orange,
                                Colors.red,
                              ],
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        GestureDetector(
                          onTap: () {},
                          child: Row(
                            children: [
                              Text(
                                'See more',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: screenWidth * 0.035,
                                ),
                              ),
                              Icon(Icons.chevron_right, color: Colors.white70, size: screenWidth * 0.04),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Weather details grid
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: screenWidth * 0.025),
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.wb_sunny, color: Colors.white70, size: screenWidth * 0.04),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'UV INDEX',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                _getUVIndex(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.07,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                _getUVIndex() == '--' ? '' : (_getUVIndex().compareTo('6') > 0 ? 'High' : 'Moderate'),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.04,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: screenWidth * 0.025),
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.wb_sunny_outlined, color: Colors.white70, size: screenWidth * 0.04),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'SUNRISE',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                _getSunrise(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                'Sunset: ${_getSunset()}',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Wind and Rainfall
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: screenWidth * 0.025),
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.air, color: Colors.white70, size: screenWidth * 0.04),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'WIND',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Row(
                                children: [
                                  Text(
                                    _getWindDirection(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.04,
                                    ),
                                  ),
                                  SizedBox(width: screenWidth * 0.02),
                                  Text(
                                    _getWindSpeed(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.05,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'km/h',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: EdgeInsets.only(left: screenWidth * 0.025),
                          padding: EdgeInsets.all(screenWidth * 0.05),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.water_drop, color: Colors.white70, size: screenWidth * 0.04),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    'RAINFALL',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                '${_getRainfall()} mm',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: screenWidth * 0.05,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                              Text(
                                'in last 24h',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: screenWidth * 0.03,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyItem(String time, IconData icon, String temp, int humidity, bool isNow) {
    return Container(
      width: 60,
      margin: EdgeInsets.only(right: 15),
      child: Column(
        children: [
          Text(
            time,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isNow ? Colors.white.withOpacity(0.3) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 10),
          Text(
            '$humidity%',
            style: TextStyle(
              color: Colors.lightBlueAccent,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 5),
          Text(
            temp,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherCitiesScreen extends StatefulWidget {
  @override
  _WeatherCitiesScreenState createState() => _WeatherCitiesScreenState();
}

class _WeatherCitiesScreenState extends State<WeatherCitiesScreen> {
  List<Map<String, dynamic>> citiesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCitiesData();
  }

  Future<void> _fetchCitiesData() async {
    try {
      // List of Zambian cities with their coordinates
      final cities = [
        {'name': 'Lusaka', 'lat': -15.4167, 'lon': 28.2833},
        {'name': 'Ndola', 'lat': -12.9683, 'lon': 28.6337},
        {'name': 'Kitwe', 'lat': -12.8167, 'lon': 28.2000},
        {'name': 'Livingstone', 'lat': -17.8536, 'lon': 25.8603},
        {'name': 'Kabwe', 'lat': -14.4350, 'lon': 28.4528},
      ];

      List<Map<String, dynamic>> fetchedData = [];

      for (var city in cities) {
        final response = await http.get(Uri.parse(
            'https://api.techiqsmart.farm/api/weather/getweather/?lat=${city['lat']}&lon=${city['lon']}'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          fetchedData.add({
            'name': city['name'],
            'data': data,
          });
        }
      }

      setState(() {
        citiesData = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching cities data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getCityTemperature(Map<String, dynamic>? cityData) {
    if (cityData == null) return '--';
    return cityData['data']['current']['temp'].toStringAsFixed(0);
  }

  String _getCityHighTemp(Map<String, dynamic>? cityData) {
    if (cityData == null) return '--';
    return cityData['data']['forecast']['forecastday'][0]['day']['maxtemp_c'].toStringAsFixed(0);
  }

  String _getCityLowTemp(Map<String, dynamic>? cityData) {
    if (cityData == null) return '--';
    return cityData['data']['forecast']['forecastday'][0]['day']['mintemp_c'].toStringAsFixed(0);
  }

  String _getCityCondition(Map<String, dynamic>? cityData) {
    if (cityData == null) return 'Loading...';
    return cityData['data']['current']['condition']['text'] ?? 'N/A';
  }

  IconData _getCityConditionIcon(Map<String, dynamic>? cityData) {
    if (cityData == null) return Icons.cloud;
    final condition = cityData['data']['current']['condition']['text'].toString().toLowerCase();

    if (condition.contains('rain')) {
      return Icons.grain;
    } else if (condition.contains('cloud')) {
      return Icons.wb_cloudy;
    } else {
      return Icons.wb_sunny;
    }
  }

  Color _getCityConditionColor(Map<String, dynamic>? cityData) {
    if (cityData == null) return Colors.grey;
    final condition = cityData['data']['current']['condition']['text'].toString().toLowerCase();

    if (condition.contains('rain')) {
      return Colors.lightBlueAccent;
    } else if (condition.contains('cloud')) {
      return Colors.grey;
    } else {
      return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Status bar and header
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.02
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.arrow_back_ios, color: Colors.white, size: screenWidth * 0.05),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Weather title
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: screenWidth * 0.05),
                  child: Text(
                    'Weather',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.08,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.02),

              // Search bar
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.white70, size: screenWidth * 0.05),
                    SizedBox(width: screenWidth * 0.03),
                    Text(
                      'Search for a city or airport',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: screenWidth * 0.04,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.03),

              // Cities list
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  children: citiesData.map((cityData) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
                      child: _buildCityWeatherCard(
                        '${cityData['name']}, Zambia',
                        _getCityTemperature(cityData),
                        'H:${_getCityHighTemp(cityData)}° L:${_getCityLowTemp(cityData)}°',
                        _getCityCondition(cityData),
                        _getCityConditionIcon(cityData),
                        _getCityConditionColor(cityData),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityWeatherCard(
      String cityName,
      String temperature,
      String highLow,
      String condition,
      IconData weatherIcon,
      Color iconColor,
      ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  temperature,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w100,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  highLow,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  cityName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  weatherIcon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              SizedBox(height: 10),
              Text(
                condition,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}