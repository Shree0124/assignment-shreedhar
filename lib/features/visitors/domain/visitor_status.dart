enum VisitorStatus {
  registered('Registered'),
  checkedIn('Checked In'),
  checkedOut('Checked Out');

  const VisitorStatus(this.label);

  final String label;

  static VisitorStatus parse(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
    for (final status in VisitorStatus.values) {
      if (status.label.toLowerCase() == normalized) return status;
    }
    throw FormatException('Unknown visitor status: $raw');
  }
}
