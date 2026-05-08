class MusicGenres {
  static const List<Map<String, String>> genres = [
    {'tag': 'telugu', 'name': 'Telugu', 'emoji': '🇮🇳'},
    {'tag': 'hindi', 'name': 'Hindi', 'emoji': '🇮🇳'},
    {'tag': 'punjabi', 'name': 'Punjabi', 'emoji': '💃'},
    {'tag': 'pop', 'name': 'Pop', 'emoji': '🎤'},
    {'tag': 'romantic', 'name': 'Romantic', 'emoji': '💕'},
    {'tag': 'dance', 'name': 'Dance', 'emoji': '🕺'},
    {'tag': 'hip hop', 'name': 'Hip Hop', 'emoji': '🎧'},
    {'tag': 'electronic', 'name': 'Electronic', 'emoji': '⚡'},
    {'tag': 'indie', 'name': 'Indie', 'emoji': '🎸'},
    {'tag': 'devotional', 'name': 'Devotional', 'emoji': '🙏'},
  ];

  // FIX: home_screen._MoodGrid reads 'label', 'emoji', and 'color' (as int).
  // The old moods map used 'name' (not 'label') and had no 'color' key → crash.
  // Now using Map<String, dynamic> so the int color value can be stored.
  static const List<Map<String, dynamic>> moodTiles = [
    {
      'tag': 'happy',
      'label': 'Happy',
      'emoji': '😊',
      'color': 0xFF48BB78, // green
    },
    {
      'tag': 'chill',
      'label': 'Chill',
      'emoji': '😌',
      'color': 0xFF4A90D9, // blue
    },
    {
      'tag': 'energy',
      'label': 'Energy',
      'emoji': '⚡',
      'color': 0xFFFFB830, // amber
    },
    {
      'tag': 'sad',
      'label': 'Sad',
      'emoji': '😢',
      'color': 0xFF7B5EA7, // violet
    },
    {
      'tag': 'romance',
      'label': 'Romance',
      'emoji': '💕',
      'color': 0xFFFF6B9D, // pink
    },
    {
      'tag': 'party',
      'label': 'Party',
      'emoji': '🎉',
      'color': 0xFFFC8181, // red
    },
  ];

  // Keep the old moods list as a plain String map for any other usages.
  static const List<Map<String, String>> moods = [
    {'tag': 'happy', 'name': 'Happy', 'emoji': '😊'},
    {'tag': 'chill', 'name': 'Chill', 'emoji': '😌'},
    {'tag': 'energy', 'name': 'Energy', 'emoji': '⚡'},
    {'tag': 'sad', 'name': 'Sad', 'emoji': '😢'},
    {'tag': 'romance', 'name': 'Romance', 'emoji': '💕'},
    {'tag': 'party', 'name': 'Party', 'emoji': '🎉'},
  ];
}