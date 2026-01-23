import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotikit/models/auth_state.dart';
import 'package:spotikit/models/spotify/playback_state.dart';
import 'package:spotikit/spotikit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  runApp(const SpotikitExampleApp());
}

class SpotikitExampleApp extends StatelessWidget {
  const SpotikitExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spotikit Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1DB954), // Spotify green
          brightness: Brightness.dark,
        ),
      ),
      home: const SpotikitHomePage(),
    );
  }
}

class SpotikitHomePage extends StatefulWidget {
  const SpotikitHomePage({super.key});

  @override
  State<SpotikitHomePage> createState() => _SpotikitHomePageState();
}

class _SpotikitHomePageState extends State<SpotikitHomePage> {
  // Spotikit instance
  final Spotikit _spotikit = Spotikit.instance;

  // Stream subscriptions
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<SpotifyPlaybackState>? _playbackSub;

  // State variables
  AuthState? _authState;
  SpotifyPlaybackState? _playbackState;
  bool _isInitialized = false;
  bool _isRemoteConnected = false;
  bool _isLoading = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _uriController = TextEditingController(
    text: 'spotify:track:4cOdK2wGLETKBW3PvgPWqT', // Never Gonna Give You Up
  );

  // Progress ticker for smooth playback progress
  Timer? _progressTicker;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initialize();
  }

  /// Sets up auth and playback state listeners
  void _setupListeners() {
    _authSub = _spotikit.onAuthStateChanged.listen(_handleAuthState);
    _playbackSub = _spotikit.onPlaybackStateChanged.listen((state) {
      setState(() => _playbackState = state);
    });
  }

  /// Handles authentication state changes
  void _handleAuthState(AuthState state) {
    setState(() => _authState = state);

    switch (state) {
      case AuthSuccess():
        _showSnackBar('✓ Authenticated successfully', isSuccess: true);
        _connectToRemote();
      case AuthFailure(:final error, :final message):
        _showSnackBar('Authentication failed: ${message ?? error}');
      case AuthCancelled():
        _showSnackBar('Authentication cancelled');
    }
  }

  /// Initialize Spotikit with credentials from .env
  Future<void> _initialize() async {
    if (_isInitialized) return;

    setState(() => _isLoading = true);

    try {
      //TODO: PASTE YOUR CREDENTIALS IN .env FILE OR REPLACE BELOW WITH STRINGS
      final clientId = dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
      final redirectUri = dotenv.env['SPOTIFY_REDIRECT_URI'] ?? '';
      final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';

      if (clientId.isEmpty || redirectUri.isEmpty || clientSecret.isEmpty) {
        _showSnackBar('Missing credentials in .env file');
        return;
      }

      _spotikit.configureLogging(loggingEnabled: true);

      await _spotikit.initialize(
        clientId: clientId,
        redirectUri: redirectUri,
        clientSecret: clientSecret,
      );

      setState(() => _isInitialized = true);
      await _spotikit.authenticateSpotify();
    } catch (e) {
      _showSnackBar('Initialization failed: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Connect to Spotify App Remote
  Future<void> _connectToRemote() async {
    setState(() => _isLoading = true);
    try {
      final connected = await _spotikit.connectToSpotify();
      setState(() => _isRemoteConnected = connected);
      if (connected) {
        _showSnackBar('✓ Connected to Spotify', isSuccess: true);
        _startProgressTicker();
      } else {
        _showSnackBar('Failed to connect to Spotify');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Starts a timer to update progress bar smoothly
  void _startProgressTicker() {
    _progressTicker?.cancel();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_playbackState != null && !_playbackState!.isPaused) {
        setState(() {});
      }
    });
  }

  /// Shows a snackbar with the given message
  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green.shade700 : null,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Playback Controls
  Future<void> _togglePlayPause() async {
    if (_playbackState == null) return;
    if (_playbackState!.isPaused) {
      await _spotikit.resume();
    } else {
      await _spotikit.pause();
    }
  }

  Future<void> _seekTo(double value) async {
    if (_playbackState == null) return;
    final positionMs = (value * _playbackState!.durationMs).round();
    await _spotikit.seekTo(positionMs: positionMs);
  }

  Future<void> _playUri() async {
    final uri = _uriController.text.trim();
    if (uri.isEmpty) {
      _showSnackBar('Please enter a Spotify URI');
      return;
    }
    await _spotikit.playUri(spotifyUri: uri);
  }

  Future<void> _searchAndPlay() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _showSnackBar('Please enter a search query');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _spotikit.playSong(query: query);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _playbackSub?.cancel();
    _progressTicker?.cancel();
    _searchController.dispose();
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading && !_isInitialized
            ? const _LoadingView()
            : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList.list(
                      children: [
                        _buildConnectionStatus(),
                        const SizedBox(height: 20),
                        if (_playbackState != null) ...[
                          _buildNowPlaying(),
                          const SizedBox(height: 20),
                        ],
                        _buildSearchSection(),
                        const SizedBox(height: 16),
                        _buildPlayByUriSection(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      title: Row(
        children: [
          Icon(Icons.music_note, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Spotikit Demo'),
        ],
      ),
      actions: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        IconButton(
          icon: Icon(
            _isRemoteConnected ? Icons.bluetooth_connected : Icons.bluetooth,
            color: _isRemoteConnected ? Colors.green : null,
          ),
          tooltip: _isRemoteConnected ? 'Connected' : 'Reconnect',
          onPressed: _connectToRemote,
        ),
        PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: () => _spotikit.logout(),
              child: const Row(
                children: [
                  Icon(Icons.logout),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
            ),
            PopupMenuItem(
              onTap: () => _spotikit.disconnect(),
              child: const Row(
                children: [
                  Icon(Icons.link_off),
                  SizedBox(width: 8),
                  Text('Disconnect'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    final authStatus = switch (_authState) {
      AuthSuccess() => ('Authenticated', Colors.green),
      AuthFailure() => ('Auth Failed', Colors.red),
      AuthCancelled() => ('Auth Cancelled', Colors.orange),
      _ => ('Not Authenticated', Colors.grey),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatusIndicator(
              label: 'Auth',
              status: authStatus.$1,
              color: authStatus.$2,
            ),
            const SizedBox(width: 24),
            _StatusIndicator(
              label: 'Remote',
              status: _isRemoteConnected ? 'Connected' : 'Disconnected',
              color: _isRemoteConnected ? Colors.green : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNowPlaying() {
    final ps = _playbackState!;
    final progress = ps.progress.clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art and track info
          Row(
            children: [
              // Album artwork
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: ps.imageUrl != null
                    ? Image.network(
                        ps.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.album, size: 48),
                      )
                    : const Icon(Icons.album, size: 48),
              ),
              const SizedBox(width: 16),
              // Track info
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ps.isPaused
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ps.isPaused ? 'PAUSED' : 'NOW PLAYING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ps.isPaused
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ps.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ps.artist,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                  ),
                  child: Slider(
                    value: progress.isNaN ? 0 : progress,
                    onChanged: _seekTo,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(ps.positionMs),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatDuration(ps.durationMs),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Playback controls
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  tooltip: 'Rewind 10s',
                  onPressed: () => _spotikit.skipBackward(seconds: 10),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 36,
                  tooltip: 'Previous',
                  onPressed: () => _spotikit.previousTrack(),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _togglePlayPause,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: Icon(
                    ps.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 36,
                  tooltip: 'Next',
                  onPressed: () => _spotikit.skipTrack(),
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  tooltip: 'Forward 10s',
                  onPressed: () => _spotikit.skipForward(seconds: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Search & Play',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Artist, song, or album...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _searchAndPlay,
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchAndPlay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayByUriSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Play by URI',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _uriController,
              decoration: InputDecoration(
                hintText: 'spotify:track:...',
                prefixIcon: const Icon(Icons.link),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: _playUri,
                ),
              ),
              onSubmitted: (_) => _playUri(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Play',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickPlayChip(
                  label: 'Bohemian Rhapsody',
                  onTap: () =>
                      _spotikit.playSong(query: 'Bohemian Rhapsody Queen'),
                ),
                _QuickPlayChip(
                  label: 'Blinding Lights',
                  onTap: () =>
                      _spotikit.playSong(query: 'Blinding Lights The Weeknd'),
                ),
                _QuickPlayChip(
                  label: 'Shape of You',
                  onTap: () =>
                      _spotikit.playSong(query: 'Shape of You Ed Sheeran'),
                ),
                _QuickPlayChip(
                  label: 'Bad Guy',
                  onTap: () =>
                      _spotikit.playSong(query: 'Bad Guy Billie Eilish'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// Helper Widgets

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing Spotikit...'),
        ],
      ),
    );
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final String status;
  final Color color;

  const _StatusIndicator({
    required this.label,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickPlayChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPlayChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.play_arrow, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
