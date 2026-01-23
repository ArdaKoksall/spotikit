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
      title: 'Spotikit Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
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
  StreamSubscription<AuthState>? _authSub;
  StreamSubscription<SpotifyPlaybackState>? _playbackSub;
  AuthState? _authState;
  SpotifyPlaybackState? _playbackState;
  bool _initialized = false;
  bool _connectingRemote = false;
  String _status = 'Idle';
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _uriCtrl = TextEditingController(
    text: 'spotify:track:11dFghVXANMlKmJXsNCbNl',
  );
  Timer? _progressTicker;

  final Spotikit _spotikit = Spotikit.instance;

  @override
  void initState() {
    super.initState();
    _spotikit.enableLogging();
    _init();
    _listen();
  }

  void _listen() {
    _authSub = _spotikit.onAuthStateChanged.listen((s) {
      setState(() => _authState = s);
      if (s is AuthSuccess) {
        _statusMsg('Authenticated');
        _connectRemote();
      } else if (s is AuthFailure) {
        _statusMsg('Auth failed: ${s.error}');
      } else if (s is AuthCancelled) {
        _statusMsg('Auth cancelled');
      }
    });
    _playbackSub = _spotikit.onPlaybackStateChanged.listen((ps) {
      setState(() => _playbackState = ps);
    });
  }

  Future<void> _init() async {
    if (_initialized) return;
    // TODO: Replace with your real credentials.
    final clientId = dotenv.env['SPOTIFY_CLIENT_ID']!;
    final redirectUri = dotenv.env['SPOTIFY_REDIRECT_URI']!;
    final clientSecret = dotenv.env['SPOTIFY_CLIENT_SECRET']!;

    final ok = await _spotikit.initialize(
      clientId: clientId,
      redirectUri: redirectUri,
      clientSecret: clientSecret,
    );
    setState(() => _initialized = ok);
    if (!ok) {
      _statusMsg('Initialization failed');
      return;
    }
    _statusMsg('Initialized, authenticating…');
    await _spotikit.authenticateSpotify();
  }

  Future<void> _connectRemote() async {
    if (_connectingRemote) return;
    setState(() => _connectingRemote = true);
    final ok = await _spotikit.connectToSpotify();
    _statusMsg(ok ? 'Remote connected' : 'Remote connect failed');
    setState(() => _connectingRemote = false);
  }

  void _statusMsg(String msg) {
    setState(() => _status = msg);
    debugPrint('[SpotikitExample] $msg');
  }

  Future<void> _playUri() async {
    final uri = _uriCtrl.text.trim();
    if (uri.isEmpty) return;
    await _spotikit.playUri(spotifyUri: uri);
  }

  Future<void> _playSearch() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    await _spotikit.playSong(query: q);
  }

  Future<void> _togglePlayPause() async {
    final ps = _playbackState;
    if (ps == null) return;
    if (ps.isPaused) {
      await _spotikit.resume();
    } else {
      await _spotikit.pause();
    }
  }

  Future<void> _seekTo(double v) async {
    final ps = _playbackState;
    if (ps == null) return;
    final positionMs = (v * ps.durationMs).round();
    await _spotikit.seekTo(positionMs: positionMs);
  }

  void _startProgressTicker() {
    _progressTicker?.cancel();
    _progressTicker = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final ps = _playbackState;
      if (ps == null) return;
      // UI rebuild for progress animation when playing
      if (!ps.isPaused) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startProgressTicker();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _playbackSub?.cancel();
    _progressTicker?.cancel();
    _searchCtrl.dispose();
    _uriCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ps = _playbackState;
    final playing = ps != null && !ps.isPaused;
    final progress = ps == null
        ? 0.0
        : (ps.positionMs / (ps.durationMs == 0 ? 1 : ps.durationMs)).clamp(
            0.0,
            1.0,
          );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotikit Example'),
        actions: [
          IconButton(
            tooltip: 'Reconnect',
            onPressed: _connectRemote,
            icon: const Icon(Icons.link),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 12),
          _buildPlaybackCard(ps, playing, progress),
          const SizedBox(height: 12),
          _buildUriCard(),
          const SizedBox(height: 12),
          _buildSearchCard(),
          const SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lifecycle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _kv('Initialized', _initialized.toString()),
            _kv(
              'Auth State',
              _authState.runtimeType.toString().replaceAll('Instance of ', ''),
            ),
            _kv('Status', _status),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackCard(
    SpotifyPlaybackState? ps,
    bool playing,
    double progress,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //image of the track if available
            if (ps?.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Image.network(
                  ps!.imageUrl!,
                  height: 150,
                  width: 150,
                  fit: BoxFit.cover,
                ),
              ),
            Row(
              children: [
                const Text(
                  'Playback',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (ps != null)
                  Text(
                    ps.isPaused ? 'Paused' : 'Playing',
                    style: TextStyle(
                      color: ps.isPaused ? Colors.orange : Colors.green,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (ps == null)
              const Text('No playback yet.')
            else ...[
              Text(
                ps.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(ps.artist, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              Slider(
                min: 0,
                max: 1,
                value: progress.isNaN ? 0 : progress,
                onChanged: (v) => _seekTo(v),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _spotikit.previousTrack(),
                    icon: const Icon(Icons.skip_previous),
                  ),
                  IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(
                      playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill,
                    ),
                    iconSize: 40,
                  ),
                  IconButton(
                    onPressed: () => _spotikit.skipTrack(),
                    icon: const Icon(Icons.skip_next),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Back 5s',
                    onPressed: () => _spotikit.skipBackward(seconds: 5),
                    icon: const Icon(Icons.replay_5),
                  ),
                  IconButton(
                    tooltip: 'Fwd 5s',
                    onPressed: () => _spotikit.skipForward(seconds: 5),
                    icon: const Icon(Icons.forward_5),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUriCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Play by URI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _uriCtrl,
              decoration: const InputDecoration(labelText: 'spotify:track:...'),
              onSubmitted: (_) => _playUri(),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _playUri,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play URI'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search & Play First Result',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(labelText: 'Search query'),
              onSubmitted: (_) => _playSearch(),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _playSearch,
              icon: const Icon(Icons.search),
              label: const Text('Search & Play'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Spotikit Example • Playback state stream demo',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(child: Text(v, overflow: TextOverflow.ellipsis)),
      ],
    ),
  );
}
