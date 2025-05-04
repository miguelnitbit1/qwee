import '../models/geocerca_model.dart';

List<Geocerca> getMockGeocercas() {
  return [
    Geocerca(
      id: '1',
      name: 'Geocerca 1',
      latitude: -34.6037,
      longitude: -58.3816,
      radius: 100, // 100 metros
    ),
    Geocerca(
      id: '2',
      name: 'Geocerca 2',
      latitude: -34.6100,
      longitude: -58.3800,
      radius: 150,
    ),
    Geocerca(
      id: '3',
      name: 'Geocerca 3',
      latitude: -34.6150,
      longitude: -58.3750,
      radius: 200,  
    ),
    Geocerca(
      id: '4',
      name: 'Geocerca 4',
      latitude: -34.6170,
      longitude: -58.3780,  
      radius: 250,
    ),
    Geocerca(
      id: '5',
      name: 'Geocerca 5',
      latitude: -34.6190,
      longitude: -58.3730,
      radius: 300,
    ),
    Geocerca(
      id: '6',
      name: 'Geocerca 6',   
      latitude: -34.6210, 
      longitude: -58.3710,
      radius: 350,
    ),
    Geocerca(
      id: '7',
      name: 'Saavedra CABA Buenos Aires',
      latitude: -34.5833,
      longitude: -58.4667,
      radius: 400,
    )
    // Agrega más geocercas según sea necesario
  ];
}