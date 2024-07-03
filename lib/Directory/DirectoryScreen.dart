import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ProblemDetail/ProblemDetailScreen.dart';
import '../Service/ProblemService.dart';
import '../Service/AuthService.dart';
import 'DirectoryService.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({Key? key}) : super(key: key);

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen>
    with WidgetsBindingObserver {
  late final DirectoryService directoryService;
  final String defaultImage = 'assets/process_image.png'; // default image 경로 설정

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ProblemService 인스턴스를 Provider에서 가져와 DirectoryService 생성
    directoryService =
        DirectoryService(Provider.of<ProblemService>(context, listen: false));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthService>(context, listen: false).addListener(_onAuthChanged);
    });
    loadData(); // 문제 데이터 로드
  }

  void _onAuthChanged() {
    if (Provider.of<AuthService>(context, listen: false).isLoggedIn) {
      loadData(); // 로그인 상태가 변경되면 데이터 새로고침
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Provider.of<AuthService>(context, listen: false).removeListener(_onAuthChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadData(); // 앱이 다시 활성화될 때 데이터 새로고침
    }
  }

  Future<void> loadData() async {
    await directoryService.fetchAndSaveProblems(); // 최신 데이터로 캐시 업데이트
    setState(() {}); // 화면 갱신
  }

  Future<void> _refreshData() async {
    await loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData, // 새로고침 콜백
        child: FutureBuilder<List<ProblemThumbnail>>(
          future: directoryService.loadProblemsFromCache(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text('${snapshot.error}'));
              } else if (snapshot.hasData) {
                // Switching to a grid view display
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10), // 좌우 공백 추가
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      childAspectRatio: 0.7, // Aspect ratio of each grid cell
                      crossAxisSpacing: 10, // Horizontal space between cells
                      mainAxisSpacing: 10, // Vertical space between cells
                    ),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      var problem = snapshot.data![index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ProblemDetailScreen(problemId: problem.id)),
                          );
                        },
                        child: GridTile(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Image.file(
                                  File(problem.imageUrl),
                                  fit: BoxFit
                                      .contain, // 이미지가 잘리지 않고 축소되어 전체가 보이도록 설정
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(defaultImage,
                                        fit: BoxFit
                                            .contain); // 이미지 로드 실패 시 default 이미지 표시
                                  },
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8), // 텍스트 주변 패딩
                                child: Text(
                                  '${problem.title}',
                                  style: const TextStyle(
                                      color: Colors.green,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}