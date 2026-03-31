import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env").catchError((_) {});
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  runApp(const KrasibApp());
}

final supabase = Supabase.instance.client;

// --- 🎨 Color Palette ---
class AppColors {
  static const background = Color(0xFF060E20);
  static const surface = Color(0xFF060E20);
  static const surfaceContainerLowest = Color(0xFF000000);
  static const surfaceContainerLow = Color(0xFF06122C);
  static const surfaceContainer = Color(0xFF0A1836);
  static const surfaceContainerHigh = Color(0xFF0F1E3F);
  static const surfaceContainerHighest = Color(0xFF11244C);

  static const primary = Color(0xFFB8C4FF);
  static const primaryDim = Color(0xFFA3B2FA);
  static const primaryContainer = Color(0xFF3F4E8F);

  static const secondary = Color(0xFFB9C8DE);
  static const secondaryContainer = Color(0xFF2E3C4E);
  static const secondaryFixedDim = Color(0xFFC6D6EC);

  static const tertiary = Color(0xFFFFB6BE);
  static const tertiaryDim = Color(0xFFEC96A1);
  static const tertiaryContainer = Color(0xFFFCA3AE);

  static const onSurface = Color(0xFFDEE5FF);
  static const onSurfaceVariant = Color(0xFF99AAD9);

  static const outlineVariant = Color(0xFF364770);
  static const errorDim = Color(0xFFC44B5F);
  static const onTertiary = Color(0xFF6D2D38);
  static const onPrimaryFixed = Color(0xFF021657);
  static const onSecondaryContainer = Color(0xFFB1C0D6);
}

class KrasibApp extends StatelessWidget {
  const KrasibApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'กระซิบ (Krasib)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  String guestId = '';
  String identityName = '';
  List<Offset> _starsOffset = [];

  @override
  void initState() {
    super.initState();
    _initGuestSession();
  }

  void _generateStars(Size size) {
    if (_starsOffset.isNotEmpty) return;
    _starsOffset = List.generate(
      40,
      (i) => Offset(
        Random().nextDouble() * size.width,
        Random().nextDouble() * size.height,
      ),
    );
  }

  String _generateThaiName() {
    final adjs = [
      'หิวโหย',
      'ขี้เซา',
      'นักล่า',
      'ตาหวาน',
      'ในตำนาน',
      'สีพาสเทล',
      'ขี้เล่น',
      'นักฝัน',
      'จอมขี้เกียจ',
    ];
    final animals = [
      'แมวส้ม',
      'แพนด้า',
      'กระต่าย',
      'สลอธ',
      'นกฮูก',
      'หมาจู',
      'จระเข้',
      'ไดโนเสาร์',
      'วาฬชุบแป้งทอด',
      'กระรอกน้อย',
    ];
    final rand = Random();
    adjs.shuffle();
    animals.shuffle();
    return '${animals[rand.nextInt(animals.length)]}${adjs[rand.nextInt(adjs.length)]}';
  }

  void _initGuestSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString('guest_id');
    String? name = prefs.getString('identity_name');

    if (id == null) {
      id = 'guest_${const Uuid().v4().substring(0, 8)}';
      await prefs.setString('guest_id', id);
    }
    if (name == null) {
      name = _generateThaiName();
      await prefs.setString('identity_name', name);
    }

    if (!mounted) return;
    setState(() {
      guestId = id!;
      identityName = name!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    _generateStars(size);

    if (guestId.isEmpty)
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    final pages = [
      HomeFeed(guestId: guestId),
      CreateWhisper(guestId: guestId, identityName: identityName),
      ProfilePage(guestId: guestId, identityName: identityName),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          for (var star in _starsOffset)
            Positioned(
              top: star.dy,
              left: star.dx,
              child: Container(
                width: 1,
                height: 1,
                color: Colors.white.withOpacity(Random().nextDouble() * 0.4),
              ),
            ),

          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width / 2 - 150,
            child: _buildGlow(AppColors.primary.withOpacity(0.05), 300),
          ),
          pages[_selectedIndex],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom
              : 24,
          left: 24,
          right: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh.withOpacity(0.7),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _navItem(Icons.auto_awesome, "หน้าแรก", 0),
                  _navItem(Icons.add_circle, "สร้างโพสต์", 1),
                  _navItem(Icons.person_outline, "โปรไฟล์", 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlow(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 120, spreadRadius: 50)],
    ),
  );

  Widget _navItem(IconData icon, String label, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant.withOpacity(0.7),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// --- 📱 1. Home Feed ---
class HomeFeed extends StatefulWidget {
  final String guestId;
  const HomeFeed({super.key, required this.guestId});
  @override
  State<HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<HomeFeed> {
  String _selectedCategory = 'ทั้งหมด';
  final List<String> _categories = ['ทั้งหมด', 'ทั่วไป', 'คำถาม', 'ระบาย'];
  late Stream<List<Map<String, dynamic>>> _postStream;

  @override
  void initState() {
    super.initState();
    _updateStream();
  }

  void _updateStream() {
    if (_selectedCategory == 'ทั้งหมด') {
      _postStream = supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);
    } else {
      _postStream = supabase
          .from('posts')
          .stream(primaryKey: ['id'])
          .eq('category', _selectedCategory)
          .order('created_at', ascending: false);
    }
  }

  // 💡 ฟังก์ชันที่ลืมใส่รอบที่แล้ว เติมให้เรียบร้อย!
  void _onCategoryTapped(String category) {
    setState(() {
      _selectedCategory = category;
      _updateStream();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background.withOpacity(0.8),
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent),
            ),
          ),
          floating: true,
          pinned: true,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.star_outline, color: AppColors.primary),
            onPressed: () {},
          ),
          title: Text(
            'กระซิบ',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: 24,
              letterSpacing: 1,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  return _buildChip(cat, cat == _selectedCategory);
                },
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120,
          ),
          sliver: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _postStream,
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      "เกิดข้อผิดพลาด: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              if (!snapshot.hasData)
                return const SliverToBoxAdapter(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                );

              final posts = snapshot.data ?? [];
              if (posts.isEmpty)
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Text(
                      "ยังไม่มีข้อความในหมวดหมู่นี้...",
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                );

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(
                      milliseconds: 300 + (index * 50).clamp(0, 300),
                    ),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _WhisperCard(
                      post: posts[index],
                      guestId: widget.guestId,
                    ),
                  );
                }, childCount: posts.length),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () => _onCategoryTapped(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected
                ? AppColors.surfaceContainerLowest
                : AppColors.onSurfaceVariant,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// --- 📝 Post Card & Interactions ---
class _WhisperCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final String guestId;
  const _WhisperCard({required this.post, required this.guestId});

  @override
  State<_WhisperCard> createState() => _WhisperCardState();
}

class _WhisperCardState extends State<_WhisperCard> {
  int likeCount = 0;
  int hahaCount = 0;
  int wowCount = 0;
  String? myReaction;
  int commentCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchReactions();
    _fetchCommentCount();
  }

  String _getTimeAgo(String? timestamp) {
    if (timestamp == null) return 'เมื่อกี้';
    final DateTime postTime = DateTime.parse(timestamp).toLocal();
    final Duration diff = DateTime.now().difference(postTime);

    if (diff.inSeconds < 60) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชม. ที่แล้ว';
    if (diff.inDays < 7) return '${diff.inDays} วันที่แล้ว';
    return '${postTime.day}/${postTime.month}/${postTime.year}';
  }

  Future<void> _fetchReactions() async {
    try {
      final res = await supabase
          .from('reactions')
          .select()
          .eq('post_id', widget.post['id']);
      int l = 0;
      int h = 0;
      int w = 0;
      String? mine;

      for (var r in res) {
        if (r['emoji_type'] == 'like') l++;
        if (r['emoji_type'] == 'haha') h++;
        if (r['emoji_type'] == 'wow') w++;
        if (r['guest_id'] == widget.guestId) mine = r['emoji_type'];
      }
      if (mounted)
        setState(() {
          likeCount = l;
          hahaCount = h;
          wowCount = w;
          myReaction = mine;
        });
    } catch (e) {
      debugPrint("Error loading reactions");
    }
  }

  Future<void> _fetchCommentCount() async {
    try {
      final res = await supabase
          .from('comments')
          .select('id')
          .eq('post_id', widget.post['id']);
      if (mounted) setState(() => commentCount = res.length);
    } catch (e) {
      debugPrint("Error loading comments count");
    }
  }

  Future<void> _toggleReaction(String type) async {
    final postId = widget.post['id'];
    final previousReaction = myReaction;

    setState(() {
      if (previousReaction != null) {
        if (previousReaction == 'like') likeCount--;
        if (previousReaction == 'haha') hahaCount--;
        if (previousReaction == 'wow') wowCount--;
      }
      if (previousReaction == type) {
        myReaction = null;
      } else {
        if (type == 'like') likeCount++;
        if (type == 'haha') hahaCount++;
        if (type == 'wow') wowCount++;
        myReaction = type;
      }
    });

    try {
      await supabase.from('reactions').delete().match({
        'post_id': postId,
        'guest_id': widget.guestId,
      });
      if (myReaction != null) {
        await supabase.from('reactions').insert({
          'post_id': postId,
          'guest_id': widget.guestId,
          'emoji_type': myReaction,
        });
      }
    } catch (e) {
      _fetchReactions();
    }
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(
        postId: widget.post['id'].toString(),
        guestId: widget.guestId,
      ),
    ).then((_) => _fetchCommentCount());
  }

  void _deletePost() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.errorDim),
            const SizedBox(width: 10),
            Text("ลบโพสต์?", style: GoogleFonts.manrope()),
          ],
        ),
        content: const Text(
          "คุณแน่ใจไหมว่าต้องการลบกระซิบนี้ถาวร? ข้อมูลจะหายไปเลยนะ",
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "ยกเลิก",
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorDim,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "ลบเลย",
              style: GoogleFonts.manrope(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('posts').delete().eq('id', widget.post['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'ลบโพสต์เรียบร้อยแล้ว!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              backgroundColor: AppColors.errorDim,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
            ),
          );
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("ลบไม่สำเร็จ กรุณาลองใหม่"),
              backgroundColor: Colors.red,
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMine = widget.post['guest_id'] == widget.guestId;
    String timeAgo = _getTimeAgo(widget.post['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.outlineVariant.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.secondaryContainer.withOpacity(0.4),
                child: const Icon(
                  Icons.person,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.post['author_nickname'] ?? 'ไม่ระบุตัวตน')
                          .toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondaryFixedDim,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: AppColors.onSurfaceVariant.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.post['category'] ?? 'ทั่วไป',
                  style: TextStyle(fontSize: 10, color: AppColors.primary),
                ),
              ),
              if (isMine)
                GestureDetector(
                  onTap: _deletePost,
                  child: Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.errorDim.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.errorDim,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.post['content'] ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              height: 1.6,
              color: AppColors.onSurface,
            ),
          ),
          const Divider(color: AppColors.outlineVariant, height: 32),
          Row(
            children: [
              _btn(Icons.favorite, likeCount, 'like', AppColors.tertiaryDim),
              const SizedBox(width: 8),
              _btn(
                Icons.sentiment_very_satisfied,
                hahaCount,
                'haha',
                Colors.orangeAccent,
              ),
              const SizedBox(width: 8),
              _btn(
                Icons.local_fire_department,
                wowCount,
                'wow',
                Colors.redAccent,
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openComments,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 18,
                        color: AppColors.primaryDim,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        commentCount.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, int count, String type, Color activeColor) {
    bool isMy = myReaction == type;
    return GestureDetector(
      onTap: () => _toggleReaction(type),
      child: AnimatedScale(
        scale: isMy ? 1.08 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isMy
                ? activeColor.withOpacity(0.15)
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isMy ? activeColor : AppColors.onSurfaceVariant,
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: isMy ? activeColor : AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// --- 💬 Comments Bottom Sheet ---
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final String guestId;
  const _CommentsSheet({required this.postId, required this.guestId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  void _sendComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final myName = prefs.getString('identity_name') ?? 'นักเดินทางยามวิกาล';

      await supabase.from('comments').insert({
        'post_id': widget.postId,
        'guest_id': widget.guestId,
        'author_nickname': myName,
        'content': _commentController.text.trim(),
      });
      _commentController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      debugPrint("Error posting comment: $e");
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "เสียงสะท้อน",
            style: GoogleFonts.manrope(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Divider(color: Colors.white10, height: 30),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('comments')
                  .stream(primaryKey: ['id'])
                  .eq('post_id', widget.postId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final comments = snapshot.data ?? [];
                if (comments.isEmpty)
                  return const Center(
                    child: Text(
                      "ยังไม่มีใครตอบกลับ เป็นคนแรกสิ!",
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  );

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final c = comments[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['author_nickname'] ?? 'Guest',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.tertiary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c['content'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 16,
              right: 16,
              top: 10,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "พิมพ์ความคิดเห็น...",
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isSending ? null : _sendComment,
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.background,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: AppColors.background),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- ✨ 2. Create Whisper ---
class CreateWhisper extends StatefulWidget {
  final String guestId;
  final String identityName;
  const CreateWhisper({
    super.key,
    required this.guestId,
    required this.identityName,
  });

  @override
  State<CreateWhisper> createState() => _CreateWhisperState();
}

class _CreateWhisperState extends State<CreateWhisper> {
  final _controller = TextEditingController();
  bool _isPosting = false;
  String _selectedCategory = 'ทั่วไป';
  final List<String> _categories = ['ทั่วไป', 'คำถาม', 'ระบาย'];

  void _post() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isPosting = true);
    try {
      await supabase.from('posts').insert({
        'content': _controller.text.trim(),
        'category': _selectedCategory,
        'guest_id': widget.guestId,
        'author_nickname': widget.identityName,
      });
      _controller.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'ส่งเสียงกระซิบเรียบร้อยแล้ว! 🌌',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.surfaceContainerLowest,
            ),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เกิดข้อผิดพลาด กรุณาลองใหม่'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "ปล่อยเสียงกระซิบ",
              style: GoogleFonts.manrope(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "ความลับของคุณจะปลอดภัยในความมืด",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Bento: Identity
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.surfaceContainerHigh,
                    AppColors.surfaceContainerLow,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.tertiary.withOpacity(0.2),
                    child: const Icon(
                      Icons.cruelty_free,
                      color: AppColors.tertiary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ตัวตนของคุณในโพสต์นี้",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.tertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.identityName,
                          style: GoogleFonts.manrope(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bento: Input Area
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.edit_note,
                        color: AppColors.primaryDim,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "เขียนอะไรสักอย่าง...",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDim,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    maxLength: 500,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      color: AppColors.onSurface,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: "เริ่มเล่าเลย...",
                      hintStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      counterStyle: TextStyle(
                        color: AppColors.onSurfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  Text(
                    "หมวดหมู่ของโพสต์",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories.map((cat) {
                      bool isSel = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSel
                                ? AppColors.primary
                                : AppColors.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              color: isSel
                                  ? AppColors.surfaceContainerLowest
                                  : AppColors.onSurfaceVariant,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            InkWell(
              onTap: _isPosting ? null : _post,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDim],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.surfaceContainerLowest,
                          ),
                        )
                      : Text(
                          "ส่งข้อความ",
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onPrimaryFixed,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }
}

// --- 👤 3. Profile Page ---
class ProfilePage extends StatelessWidget {
  final String guestId;
  final String identityName;
  const ProfilePage({
    super.key,
    required this.guestId,
    required this.identityName,
  });

  void _resetIdentity(BuildContext context) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "ยืนยันการล้างข้อมูล",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "ข้อมูลตัวตนเก่าของคุณจะหายไป และระบบจะสุ่มชื่อใหม่ให้ทันที แน่ใจหรือไม่?",
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "ยกเลิก",
              style: TextStyle(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorDim,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "ยืนยัน",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.cruelty_free,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "ผู้เยี่ยมชม",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              identityName,
              style: GoogleFonts.manrope(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "ไอดี: $guestId",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.tertiary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "ประวัติและตัวตนของคุณถูกเก็บไว้ในเครื่องนี้เท่านั้น หากล้างข้อมูลตัวตน ข้อมูลเก่าจะหายไปอย่างถาวร",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _actionBtn(
              icon: Icons.history,
              label: "ประวัติโพสต์ของฉัน",
              bgColor: AppColors.surfaceContainerHigh,
              textColor: AppColors.onSurface,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyPostsScreen(guestId: guestId),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _actionBtn(
              icon: Icons.refresh,
              label: "ล้างข้อมูลตัวตน (สุ่มชื่อใหม่)",
              bgColor: AppColors.surfaceContainerLow.withOpacity(0.5),
              textColor: AppColors.errorDim,
              onTap: () => _resetIdentity(context),
            ),

            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: textColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

class MyPostsScreen extends StatelessWidget {
  final String guestId;
  const MyPostsScreen({super.key, required this.guestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          "โพสต์ของฉัน",
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('posts')
            .stream(primaryKey: ['id'])
            .eq('guest_id', guestId)
            .order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return Center(
              child: Text(
                "เกิดข้อผิดพลาด: ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
              ),
            );
          if (!snapshot.hasData)
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );

          final posts = snapshot.data ?? [];
          if (posts.isEmpty)
            return const Center(
              child: Text(
                "คุณยังไม่เคยกระซิบอะไรเลย...",
                style: TextStyle(color: AppColors.onSurfaceVariant),
              ),
            );

          return ListView.builder(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 40,
            ),
            itemCount: posts.length,
            itemBuilder: (context, index) =>
                _WhisperCard(post: posts[index], guestId: guestId),
          );
        },
      ),
    );
  }
}
