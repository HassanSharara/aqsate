class Customer {
  final int? id;
  final String name;
  final String phone;
  final String address;
  final String notes;
  final String createdAt;

  Customer({
    this.id,
    required this.name,
    this.phone = '',
    this.address = '',
    this.notes = '',
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? address,
    String? notes,
    String? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      createdAt: map['created_at'] as String? ?? '',
    );
  }
}
