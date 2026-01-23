#!/usr/bin/env dart

import 'dart:io';

// ignore_for_file: avoid_print
const String _spotifyAppRemoteDir = 'android/spotify-app-remote';
const String _spotifyAuthDir = 'android/spotify-auth';

Future<void> main() async {
  print('🧹 Spotikit Android Cleanup\n');
  try {
    await deleteSpotify();
    await resetGradle();
    await removeManifestPlaceholders();
    print('\n✅ Cleanup complete!');
    exit(0);
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}

Future<void> deleteSpotify() async {
  final remoteFolder = Directory(_spotifyAppRemoteDir);
  if (await remoteFolder.exists()) {
    await remoteFolder.delete(recursive: true);
  }

  final authFolder = Directory(_spotifyAuthDir);
  if (await authFolder.exists()) {
    await authFolder.delete(recursive: true);
  }
  print('📁 Spotify directories removed');
}

Future<void> resetGradle() async {
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

  final spotifyLines = [
    'include(":spotify-app-remote")',
    'include(":spotify-auth")',
  ];

  final existingLines = await file.readAsLines();

  if (existingLines.length >= 2 &&
      existingLines[0].trim() == spotifyLines[0] &&
      existingLines[1].trim() == spotifyLines[1]) {
    final newContent = existingLines.sublist(2).join('\n');
    await file.writeAsString(newContent);
  }
  print('⚙️  Settings.gradle cleaned');
}

Future<void> removeManifestPlaceholders() async {
  final ktsFile = File('android/app/build.gradle.kts');
  final groovyFile = File('android/app/build.gradle');

  if (await ktsFile.exists()) {
    await _removePlaceholdersKts(ktsFile);
  } else if (await groovyFile.exists()) {
    await _removePlaceholdersGroovy(groovyFile);
  }
  print('🔗 Manifest placeholders removed');
}

Future<void> _removePlaceholdersKts(File file) async {
  var content = await file.readAsString();

  // Remove KTS style placeholders
  final schemeRegex = RegExp(
    r'\s*manifestPlaceholders\["redirectSchemeName"\]\s*=\s*"[^"]*"\s*\n?',
  );
  final hostRegex = RegExp(
    r'\s*manifestPlaceholders\["redirectHostName"\]\s*=\s*"[^"]*"\s*\n?',
  );

  content = content.replaceAll(schemeRegex, '\n');
  content = content.replaceAll(hostRegex, '');

  await file.writeAsString(content);
}

Future<void> _removePlaceholdersGroovy(File file) async {
  var content = await file.readAsString();

  // Remove Groovy style manifestPlaceholders block
  final placeholdersRegex = RegExp(
    r'\s*manifestPlaceholders\s*=\s*\[\s*redirectSchemeName\s*:\s*"[^"]*"\s*,\s*redirectHostName\s*:\s*"[^"]*"\s*\]\s*\n?',
  );

  content = content.replaceAll(placeholdersRegex, '\n');

  await file.writeAsString(content);
}
