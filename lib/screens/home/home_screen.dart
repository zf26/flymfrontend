import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/screens/profile/profile_screen.dart';
import 'package:flymfrontend/screens/consultation/symptom_input_screen.dart';
import 'package:flymfrontend/screens/consultation/create_consultation_screen.dart';
import 'package:flymfrontend/widgets/toast/glassmorphism_toast.dart';

/// 首页
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomePage(),
    const CreateConsultationScreen(showAppBar: false),
    const _ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services),
            label: '问诊',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

/// 首页内容
class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    if (!_isSearching) {
      setState(() {
        _isSearching = true;
      });
      // 使用 WidgetsBinding 确保在下一帧渲染后请求焦点
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    }
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.pink.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部搜索栏
              _buildSearchBar(),
              // 内容区域
              Expanded(
                child: _isSearching
                    ? _buildSearchPage()
                    : _buildHomePage(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.blue.shade600),
              onPressed: _closeSearch,
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Icon(Icons.search, color: Colors.blue.shade600, size: 24),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (!_isSearching) {
                  _openSearch();
                }
              },
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                enabled: _isSearching,
                decoration: InputDecoration(
                  hintText: '搜索医生、科室、疾病',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  // TODO: 实时搜索
                },
              ),
            ),
          ),
          if (_isSearching)
            IconButton(
              icon: Icon(Icons.mic, color: Colors.grey.shade400, size: 22),
              onPressed: () {
                // TODO: 语音搜索
              },
            )
          else
            const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _buildHomePage(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // 标题
          Text(
            '快捷服务',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          // 功能卡片网格
          // 快速问诊单独占一行
          SizedBox(
            width: double.infinity,
            child: _FeatureCard(
              icon: Icons.medical_services_rounded,
              title: '快速问诊',
              subtitle: '通过知识图谱与AI助手快速问诊',
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.teal.shade500],
              ),
              onTap: () {
                // 跳转到症状输入页面（带顶部栏）
                context.push(AppConstants.routeSymptomInput);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.history_rounded,
                  title: '问诊记录',
                  subtitle: '查看历史记录',
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                  ),
                  isCompact: true,
                  onTap: () {
                    context.go(AppConstants.routeConsultation);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.health_and_safety_rounded,
                  title: '健康档案',
                  subtitle: '管理健康信息',
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.deepPurple.shade500],
                  ),
                  isCompact: true,
                  onTap: () {
                    // TODO: 跳转到健康档案页面
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  icon: Icons.chat_bubble_rounded,
                  title: '医生聊天',
                  subtitle: '即时沟通',
                  gradient: LinearGradient(
                    colors: [Colors.cyan.shade400, Colors.blue.shade500],
                  ),
                  isCompact: true,
                  onTap: () {
                    context.go(AppConstants.routeChatContacts);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FeatureCard(
                  icon: Icons.spa_rounded,
                  title: '健康工具',
                  subtitle: '实用工具',
                  gradient: LinearGradient(
                    colors: [Colors.pink.shade400, Colors.red.shade400],
                  ),
                  isCompact: true,
                  onTap: () {
                    // TODO: 跳转到健康工具
                    GlassmorphismToast.showSuccess(context, '功能开发中');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSearchPage() {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 热门搜索
            Text(
              '热门搜索',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SearchTag('感冒发烧', Icons.local_fire_department, Colors.red),
                _SearchTag('皮肤科', Icons.face, Colors.orange),
                _SearchTag('儿科', Icons.child_care, Colors.pink),
                _SearchTag('心理咨询', Icons.psychology, Colors.purple),
                _SearchTag('内科', Icons.medical_services, Colors.blue),
                _SearchTag('外科', Icons.healing, Colors.teal),
              ],
            ),
            const SizedBox(height: 32),
            // 推荐科室
            Text(
              '推荐科室',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            _DepartmentItem('内科', '呼吸、消化、心血管等', Icons.favorite, Colors.red),
            _DepartmentItem('外科', '普外、骨科、神经外科等', Icons.healing, Colors.blue),
            _DepartmentItem('妇产科', '妇科、产科检查', Icons.pregnant_woman, Colors.pink),
            _DepartmentItem('儿科', '儿童健康咨询', Icons.child_care, Colors.orange),
            _DepartmentItem('皮肤科', '皮肤问题诊疗', Icons.face, Colors.purple),
            _DepartmentItem('眼科', '视力、眼部疾病', Icons.remove_red_eye, Colors.teal),
          ],
        ),
      ),
    );
  }
}

/// 搜索标签
class _SearchTag extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _SearchTag(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          // TODO: 执行搜索
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 科室项目
class _DepartmentItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _DepartmentItem(this.title, this.subtitle, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: 跳转到科室详情
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 功能卡片
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isCompact;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: isCompact ? 28 : 36,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: isCompact ? 12 : 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isCompact ? 15 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 个人中心页内容
/// 直接使用 ProfileScreen 的内容
class _ProfilePage extends StatelessWidget {
  const _ProfilePage();

  @override
  Widget build(BuildContext context) {
    // 直接返回 ProfileScreen 的内容
    return const ProfileScreen();
  }
}
