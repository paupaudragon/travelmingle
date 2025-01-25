class LocationData {
  final String? placeId;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;

  LocationData({
    this.placeId,
    required this.name,
    this.address,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'place_id': placeId ?? 'temp_${name.replaceAll(' ', '_')}',
        'name': name,
        'address': address ?? name,
        'latitude': latitude,
        'longitude': longitude,
      };
}
