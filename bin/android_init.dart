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

//todo add manifest placeholders
Future<void> main(List<String> args) async {
  print('🎵 Initializing Spotikit Android setup...\n');

  try {
    if (!await File('pubspec.yaml').exists()) {
      throw Exception(
        'pubspec.yaml not found. Make sure you\'re running this from the root of your Flutter project.',
      );
    }

    final androidAppDir = Directory('android/app');
    if (!await androidAppDir.exists()) {
      throw Exception(
        'android/app directory not found. This command must be run from a Flutter project with Android support.',
      );
    }

    await checkDirectories();

    await downloadFile(_spotifyAppRemoteUrl, spotifyAppRemotePath);
    await downloadFile(_spotifyAuthUrl, spotifyAuthPath);

    await createGradle();
    await prependSettingsGradle();

    print('\n✅ Spotikit Android initialization completed successfully!');
    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> downloadFile(String url, String targetPath) async {
  print('⬇️  Downloading $url ...');

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final file = File(targetPath);
      await file.writeAsBytes(response.bodyBytes);
      print('✅ Downloaded $url');
    } else {
      throw Exception(
        'Failed to download $url (Status: ${response.statusCode})',
      );
    }
  } catch (e) {
    throw Exception('Failed to download $url: $e');
  }
}

Future<void> createGradle() async {
  final remoteFile = File(spotifyAppRemoteGradlePath);
  if (!await remoteFile.exists()) {
    await remoteFile.writeAsString(_spotifyAppRemoteGradle);
    print('✅ Created $spotifyAppRemoteGradlePath');
  } else {
    print('ℹ️ $spotifyAppRemoteGradlePath already exists, skipping.');
  }

  final authFile = File(spotifyAuthGradlePath);
  if (!await authFile.exists()) {
    await authFile.writeAsString(_spotifyAuthGradle);
    print('✅ Created $spotifyAuthGradlePath');
  } else {
    print('ℹ️ $spotifyAuthGradlePath already exists, skipping.');
  }
}

Future<void> checkDirectories() async {
  final appRemoteDir = Directory('android/spotify-app-remote');
  final authDir = Directory('android/spotify-auth');
  if (!await appRemoteDir.exists()) {
    await appRemoteDir.create(recursive: true);
    print('✅ Created directory: ${appRemoteDir.path}');
  }
  if (!await authDir.exists()) {
    await authDir.create(recursive: true);
    print('✅ Created directory: ${authDir.path}');
  }
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
    throw Exception(
      '⚠️ Neither settings.gradle nor settings.gradle.kts exists.',
    );
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

  if (alreadyPrepended) {
    print('ℹ️ Lines already present at the top of ${file.path}, skipping.');
    return;
  }

  final newContent = (linesToAdd + existingLines).join('\n');

  await file.writeAsString(newContent);

  print('✅ Prepended Spotify includes to ${file.path}');
}
