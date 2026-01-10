import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flymfrontend/config/app_constants.dart';
import 'package:flymfrontend/screens/profile/profile_screen.dart';

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
    const _ConsultationPage(),
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
class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快捷入口
            const Text(
              '快捷功能',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.search,
                    title: '找医生',
                    color: Colors.blue,
                    onTap: () {
                      // TODO: 跳转到医生列表
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.medical_services,
                    title: '快速问诊',
                    color: Colors.green,
                    onTap: () {
                      context.go(AppConstants.routeConsultation);
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
                    icon: Icons.history,
                    title: '问诊记录',
                    color: Colors.orange,
                    onTap: () {
                      context.go(AppConstants.routeConsultation);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.health_and_safety,
                    title: '健康档案',
                    color: Colors.purple,
                    onTap: () {
                      // TODO: 跳转到健康档案
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
                    icon: Icons.chat_bubble_outline,
                    title: '医生聊天',
                    color: Colors.teal,
                    onTap: () {
                      context.go(AppConstants.routeChatContacts);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FeatureCard(
                    icon: Icons.spa_outlined,
                    title: '健康工具',
                    color: Colors.indigo,
                    onTap: () {
                      // TODO: 跳转到健康工具
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 功能卡片
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
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

/// 问诊页内容
class _ConsultationPage extends StatelessWidget {
  const _ConsultationPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '暂无问诊记录',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go(AppConstants.routeConsultation);
              },
              child: const Text('开始问诊'),
            ),
          ],
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
