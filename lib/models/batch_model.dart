class TimelineStepModel {
  final String title;
  final String description;
  final String timestamp;
  final String location;
  final String responsiblePerson;
  final bool isCompleted;

  TimelineStepModel({
    required this.title,
    required this.description,
    required this.timestamp,
    required this.location,
    required this.responsiblePerson,
    this.isCompleted = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'timestamp': timestamp,
      'location': location,
      'responsiblePerson': responsiblePerson,
      'isCompleted': isCompleted,
    };
  }

  factory TimelineStepModel.fromMap(Map<String, dynamic> map) {
    return TimelineStepModel(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      timestamp: map['timestamp'] ?? '',
      location: map['location'] ?? '',
      responsiblePerson: map['responsiblePerson'] ?? '',
      isCompleted: map['isCompleted'] ?? true,
    );
  }
}

class BatchModel {
  final String id; // e.g. BATCH-DL-2026-01
  final String productId;
  final String productName;
  final String imageUrl;
  final String farmId;
  final String farmName;
  final String farmLocation;
  final String harvestDate;
  final String expiryDate;
  final String certType; // VietGAP, GlobalGAP, Organic
  final String certNumber;
  final String certAuthority;
  final String inspectorName;
  final String testResults;
  final int totalYieldKg;
  final List<TimelineStepModel> timeline;

  BatchModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.imageUrl = '',
    required this.farmId,
    required this.farmName,
    required this.farmLocation,
    required this.harvestDate,
    required this.expiryDate,
    required this.certType,
    required this.certNumber,
    required this.certAuthority,
    required this.inspectorName,
    required this.testResults,
    required this.totalYieldKg,
    required this.timeline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'farmId': farmId,
      'farmName': farmName,
      'farmLocation': farmLocation,
      'harvestDate': harvestDate,
      'expiryDate': expiryDate,
      'certType': certType,
      'certNumber': certNumber,
      'certAuthority': certAuthority,
      'inspectorName': inspectorName,
      'testResults': testResults,
      'totalYieldKg': totalYieldKg,
      'timeline': timeline.map((e) => e.toMap()).toList(),
    };
  }

  factory BatchModel.fromMap(Map<String, dynamic> map) {
    return BatchModel(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      farmId: map['farmId'] ?? '',
      farmName: map['farmName'] ?? '',
      farmLocation: map['farmLocation'] ?? '',
      harvestDate: map['harvestDate'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      certType: map['certType'] ?? 'VietGAP',
      certNumber: map['certNumber'] ?? '',
      certAuthority: map['certAuthority'] ?? '',
      inspectorName: map['inspectorName'] ?? '',
      testResults: map['testResults'] ?? '',
      totalYieldKg: (map['totalYieldKg'] as num?)?.toInt() ?? 500,
      timeline:
          (map['timeline'] as List<dynamic>?)
              ?.map(
                (item) =>
                    TimelineStepModel.fromMap(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
