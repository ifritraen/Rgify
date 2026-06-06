import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/gif_info.dart';

class Playlist {
  final String id;
  final String name;
  final List<GifInfo> items;

  Playlist({
    required this.id,
    required this.name,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((i) => {
        'id': i.id,
        'duration': i.duration,
        'width': i.width,
        'height': i.height,
        'views': i.views,
        'likes': i.likes,
        'tags': i.tags,
        'urls': {
          'silent': i.urls.silent,
          'html': i.urls.html,
          'poster': i.urls.poster,
          'thumbnail': i.urls.thumbnail,
          'hd': i.urls.hd,
          'sd': i.urls.sd,
        },
        'userName': i.userName,
        'verified': i.verified,
      }).toList(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? [];
    return Playlist(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      items: rawItems.map((item) => GifInfo.fromJson(item)).toList(),
    );
  }
}

class LibraryProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  
  static const String _favoritesKey = 'rgify_favorites_list';
  static const String _playlistsKey = 'rgify_playlists_list';

  List<GifInfo> _favorites = [];
  List<Playlist> _playlists = [];
  bool _isInitialized = false;

  List<GifInfo> get favorites => _favorites;
  List<Playlist> get playlists => _playlists;
  bool get isInitialized => _isInitialized;

  LibraryProvider() {
    loadLibrary();
  }

  // Load favorites and playlists from local storage
  Future<void> loadLibrary() async {
    try {
      final favsJson = await _storage.read(key: _favoritesKey);
      if (favsJson != null) {
        final List decoded = jsonDecode(favsJson);
        _favorites = decoded.map((g) => GifInfo.fromJson(g)).toList();
      }

      final playlistsJson = await _storage.read(key: _playlistsKey);
      if (playlistsJson != null) {
        final List decoded = jsonDecode(playlistsJson);
        _playlists = decoded.map((p) => Playlist.fromJson(p)).toList();
      }
    } catch (_) {}
    _isInitialized = true;
    notifyListeners();
  }

  // Save favorites to storage
  Future<void> _saveFavorites() async {
    final encoded = _favorites.map((i) => {
      'id': i.id,
      'duration': i.duration,
      'width': i.width,
      'height': i.height,
      'views': i.views,
      'likes': i.likes,
      'tags': i.tags,
      'urls': {
        'silent': i.urls.silent,
        'html': i.urls.html,
        'poster': i.urls.poster,
        'thumbnail': i.urls.thumbnail,
        'hd': i.urls.hd,
        'sd': i.urls.sd,
      },
      'userName': i.userName,
      'verified': i.verified,
    }).toList();
    await _storage.write(key: _favoritesKey, value: jsonEncode(encoded));
  }

  // Save playlists to storage
  Future<void> _savePlaylists() async {
    final encoded = _playlists.map((p) => p.toJson()).toList();
    await _storage.write(key: _playlistsKey, value: jsonEncode(encoded));
  }

  // Check if a Gif is favorited
  bool isFavorited(String gifId) {
    return _favorites.any((g) => g.id == gifId);
  }

  // Toggle Favorite status
  Future<void> toggleFavorite(GifInfo gif) async {
    final index = _favorites.indexWhere((g) => g.id == gif.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(gif);
    }
    notifyListeners();
    await _saveFavorites();
  }

  // Create a new playlist
  Future<void> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPlaylist = Playlist(id: id, name: name, items: []);
    _playlists.add(newPlaylist);
    notifyListeners();
    await _savePlaylists();
  }

  // Add Gif to Playlist
  Future<void> addToPlaylist(String playlistId, GifInfo gif) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      // Avoid duplicate adds
      if (!_playlists[index].items.any((g) => g.id == gif.id)) {
        _playlists[index].items.add(gif);
        notifyListeners();
        await _savePlaylists();
      }
    }
  }

  // Remove Gif from Playlist
  Future<void> removeFromPlaylist(String playlistId, String gifId) async {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index >= 0) {
      _playlists[index].items.removeWhere((g) => g.id == gifId);
      notifyListeners();
      await _savePlaylists();
    }
  }

  // Delete an entire playlist
  Future<void> deletePlaylist(String playlistId) async {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    await _savePlaylists();
  }
}
