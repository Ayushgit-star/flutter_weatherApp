import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'my_widgets.dart';
import 'package:http/http.dart' as http;
import 'secrets.dart'; // Ensure this contains your API key

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

String cityName = 'Kolkata';

class _MyHomePageState extends State<MyHomePage> {
  late Future<Map<String, dynamic>> weather;
  bool isDarkTheme = false; // Variable to hold the theme state

  Future<Map<String, dynamic>> getCurrentWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&APPID=$openWeatherAPIkey'),
      );
      if (response.statusCode != 200) {
        throw 'Error: ${response.statusCode}'; // Handle status codes properly
      }
      final data = jsonDecode(response.body);
      if (data['cod'] != '200') {
        throw data['message']; // Handle API error responses
      }
      return data;
    } catch (e) {
      rethrow; // Preserve the original stack trace
    }
  }

  @override
  void initState() {
    super.initState();
    weather = getCurrentWeather();
  }

  void toggleTheme() {
    setState(() {
      isDarkTheme = !isDarkTheme; // Toggle the theme state
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: isDarkTheme
          ? ThemeData.dark()
          : ThemeData.light(), // Set theme based on state
      home: Scaffold(
        appBar: AppBar(
          title: Text(
            'Weather App for $cityName',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () {
                  setState(() {
                    weather = getCurrentWeather();
                  });
                },
                icon: const Icon(Icons.refresh)),
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: weather,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator.adaptive());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: Text('No data available'));
            }

            final data = snapshot.data!;
            final currentData = data['list'][0];
            final currentTemp = currentData['main']['temp'];
            final currentFeelsLike = currentData['main']['feels_like'];
            final currentWeather = currentData['weather'][0]['main'];
            final description = currentData['weather'][0]['description'];
            final pressure = currentData['main']['pressure'];
            final windSpeed = currentData['wind']['speed'];
            final humidity = currentData['main']['humidity'];

            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 20,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: Text(
                                  '${(currentTemp - 273.15).toStringAsFixed(2)} °C',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                'Feels like  ${(currentFeelsLike - 273.15).toStringAsFixed(2)} °C',
                                style: const TextStyle(
                                  fontSize: 20,
                                ),
                              ),
                              Icon(
                                currentWeather == 'Clouds'
                                    ? Icons.cloud
                                    : currentWeather == 'Rain'
                                        ? Icons.grain
                                        : Icons.sunny,
                                size: 65,
                              ),
                              Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 25,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'Hourly Forecast',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 15,
                      itemBuilder: (context, index) {
                        final hourlyForecast = data['list'][index + 1];
                        final hourlyIcon = hourlyForecast['weather'][0]['main'];
                        final time = DateTime.parse(hourlyForecast['dt_txt']);

                        return WeatherForecast(
                          time: DateFormat.j().format(time),
                          icon: hourlyIcon == 'Clouds'
                              ? Icons.cloud
                              : hourlyIcon == 'Rain'
                                  ? Icons.grain
                                  : Icons.sunny,
                          temperature:
                              '${(hourlyForecast['main']['temp'] - 273.15).toStringAsFixed(1)} °C',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      AdditionalInfo(
                        icon: Icons.opacity,
                        label: 'Humidity',
                        val: '${humidity.toString()} %',
                      ),
                      AdditionalInfo(
                        icon: Icons.air,
                        label: 'Wind Speed',
                        val: '${windSpeed.toString()} m/s',
                      ),
                      AdditionalInfo(
                        icon: Icons.compress,
                        label: 'Pressure',
                        val: '${pressure.toString()} hPa',
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: toggleTheme, // Call the toggleTheme method
          child: Icon(isDarkTheme
              ? Icons.wb_sunny
              : Icons.nightlight_round), // Change icon based on theme
        ),
      ),
    );
  }
}
