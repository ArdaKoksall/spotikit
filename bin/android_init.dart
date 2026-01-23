#!/usr/bin/env dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:http/http.dart' as http;

const String _spotifyAppRemoteUrl =
    'https://github.com/spotify/android-sdk/releases/download/v0.8.0-appremote_v2.1.0-auth/spotify-app-remote-release-0.8.0.aar';
const String _spotifyAuthUrl =
    'https://github.com/spotify/android-sdk/releases/download/v0.8.0-appremote_v2.1.0-auth/spotify-auth-release-2.1.0.aar';

const String _spotifyAppRemoteGradle =
    "configurations.create(\"default\")\nartifacts.add(\"default\", file('spotify-app-remote-release-0.8.0.aar'))";
const String _spotifyAuthGradle =
    "configurations.create(\"default\")\nartifacts.add(\"default\", file('spotify-auth-release-2.1.0.aar'))";

const String spotifyAppRemotePath =
    'android/spotify-app-remote/spotify-app-remote-release-0.8.0.aar';
const String spotifyAuthPath =
    'android/spotify-auth/spotify-auth-release-2.1.0.aar';

const String spotifyAppRemoteGradlePath =
    'android/spotify-app-remote/build.gradle';
const String spotifyAuthGradlePath = 'android/spotify-auth/build.gradle';

const String _defaultFallbackUrl = 'spotify-sdk://auth';

Future<void> main(List<String> args) async {
  print('🎵 Spotikit Android Setup\n');

  try {
    // Parse fallback URL from arguments
    String fallbackUrl = _defaultFallbackUrl;
    for (int i = 0; i < args.length; i++) {
      if (args[i] == '--fallback-url' && i + 1 < args.length) {
        fallbackUrl = args[i + 1];
      } else if (args[i].startsWith('--fallback-url=')) {
        fallbackUrl = args[i].substring('--fallback-url='.length);
      }
    }

    // Extract scheme and host from fallback URL
    final uri = Uri.parse(fallbackUrl);
    final schemeName = uri.scheme;
    final hostName = uri.host;

    if (schemeName.isEmpty || hostName.isEmpty) {
      throw Exception(
        'Invalid fallback URL: $fallbackUrl. Expected format: scheme://host',
      );
    }

    print('📋 Config: redirect=$schemeName://$hostName');

    if (!await File('pubspec.yaml').exists()) {
      throw Exception('Not a Flutter project root (pubspec.yaml not found)');
    }

    if (!await Directory('android/app').exists()) {
      throw Exception('No Android support (android/app not found)');
    }

    await checkDirectories();
    await downloadFile(_spotifyAppRemoteUrl, spotifyAppRemotePath);
    await downloadFile(_spotifyAuthUrl, spotifyAuthPath);
    await createGradle();
    await prependSettingsGradle();
    await addManifestPlaceholders(schemeName, hostName);

    print('\n✅ Setup complete!');
    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> downloadFile(String url, String targetPath) async {
  final fileName = targetPath.split('/').last;
  print('⬇️  Downloading $fileName...');

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(targetPath);
      await file.writeAsBytes(response.bodyBytes);
    } else {
      throw Exception('Failed (Status: ${response.statusCode})');
    }
  } catch (e) {
    throw Exception('Failed to download $fileName: $e');
  }
}

Future<void> createGradle() async {
  final remoteFile = File(spotifyAppRemoteGradlePath);
  if (!await remoteFile.exists()) {
    await remoteFile.writeAsString(_spotifyAppRemoteGradle);
  }

  final authFile = File(spotifyAuthGradlePath);
  if (!await authFile.exists()) {
    await authFile.writeAsString(_spotifyAuthGradle);
  }
  print('📝 Gradle files configured');
}

Future<void> checkDirectories() async {
  final appRemoteDir = Directory('android/spotify-app-remote');
  final authDir = Directory('android/spotify-auth');
  if (!await appRemoteDir.exists()) {
    await appRemoteDir.create(recursive: true);
  }
  if (!await authDir.exists()) {
    await authDir.create(recursive: true);
  }
  print('📁 Directories ready');
}

Future<void> prependSettingsGradle() async {
  final gradleFiles = [
    File('android/settings.gradle'),
    File('android/settings.gradle.kts'),
  ];

  File? file;
  for (var f in gradleFiles) {
    if (await f.exists()) {
      file = f;
      break;
    }
  }

  if (file == null) {
    throw Exception('settings.gradle(.kts) not found');
  }

  final linesToAdd = [
    'include(":spotify-app-remote")',
    'include(":spotify-auth")',
  ];

  final existingLines = await file.readAsLines();

  bool alreadyPrepended =
      existingLines.length >= 2 &&
      existingLines[0].trim() == linesToAdd[0] &&
      existingLines[1].trim() == linesToAdd[1];

  if (!alreadyPrepended) {
    final newContent = (linesToAdd + existingLines).join('\n');
    await file.writeAsString(newContent);
  }
  print('⚙️  Settings.gradle updated');
}

Future<void> addManifestPlaceholders(String schemeName, String hostName) async {
  final ktsFile = File('android/app/build.gradle.kts');
  final groovyFile = File('android/app/build.gradle');

  if (await ktsFile.exists()) {
    await _addPlaceholdersKts(ktsFile, schemeName, hostName);
  } else if (await groovyFile.exists()) {
    await _addPlaceholdersGroovy(groovyFile, schemeName, hostName);
  } else {
    throw Exception('build.gradle(.kts) not found in android/app');
  }
  print('🔗 Manifest placeholders configured');
}

Future<void> _addPlaceholdersKts(
    File file, String schemeName, String hostName) async {
  final content = await file.readAsString();

  // Check if placeholders already exist
  if (content.contains('manifestPlaceholders["redirectSchemeName"]') &&
      content.contains('manifestPlaceholders["redirectHostName"]')) {
    return;
  }

  // Find defaultConfig block and add placeholders
  final defaultConfigRegex = RegExp(r'defaultConfig\s*\{');
  final match = defaultConfigRegex.firstMatch(content);

  if (match == null) {
    throw Exception('defaultConfig block not found in build.gradle.kts');
  }

  final placeholders =
      '\n        manifestPlaceholders["redirectSchemeName"] = "$schemeName"'
      '\n        manifestPlaceholders["redirectHostName"] = "$hostName"'
      '\n    }';

  // Find the closing brace of defaultConfig
  int braceCount = 0;
  int startIndex = match.end;
  int endIndex = startIndex;

  for (int i = startIndex; i < content.length; i++) {
    if (content[i] == '{') braceCount++;
    if (content[i] == '}') {
      if (braceCount == 0) {
        endIndex = i;
        break;
      }
      braceCount--;
    }
  }

  final newContent =
      content.substring(0, endIndex).trimRight() + placeholders + content.substring(endIndex + 1);

  await file.writeAsString(newContent);
}

Future<void> _addPlaceholdersGroovy(
    File file, String schemeName, String hostName) async {
  final content = await file.readAsString();

  // Check if placeholders already exist
  if (content.contains('redirectSchemeName') &&
      content.contains('redirectHostName')) {
    return;
  }

  // Find defaultConfig block and add placeholders
  final defaultConfigRegex = RegExp(r'defaultConfig\s*\{');
  final match = defaultConfigRegex.firstMatch(content);

  if (match == null) {
    throw Exception('defaultConfig block not found in build.gradle');
  }

  final placeholders =
      '\n        manifestPlaceholders = ['
      '\n            redirectSchemeName: "$schemeName",'
      '\n            redirectHostName: "$hostName"'
      '\n        ]'
      '\n    }';

  // Find the closing brace of defaultConfig
  int braceCount = 0;
  int startIndex = match.end;
  int endIndex = startIndex;

  for (int i = startIndex; i < content.length; i++) {
    if (content[i] == '{') braceCount++;
    if (content[i] == '}') {
      if (braceCount == 0) {
        endIndex = i;
        break;
      }
      braceCount--;
    }
  }

  final newContent =
      content.substring(0, endIndex).trimRight() + placeholders + content.substring(endIndex + 1);

  await file.writeAsString(newContent);
}
