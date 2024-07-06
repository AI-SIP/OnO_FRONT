import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/DisplayImage.dart';
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
        child: Padding(
          padding: const EdgeInsets.all(20), // 화면 바깥쪽 여백 추가
          child: FutureBuilder<List<ProblemThumbnail>>(
            future: directoryService.loadProblemsFromCache(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(child: Text('${snapshot.error}'));
                } else if (snapshot.hasData) {
                  // Switching to a grid view display
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of columns
                      childAspectRatio: 0.7, // Aspect ratio of each grid cell
                      crossAxisSpacing: 20, // Horizontal space between cells
                      mainAxisSpacing: 20, // Vertical space between cells
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
                          ).then((value) {
                            if (value == true) {
                              _refreshData(); // 새로고침 콜백 호출
                            }
                          });
                        },
                        child: GridTile(
                          child: Column(
                            children: <Widget>[
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.green, width: 1.0), // 얇은 테두리
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 1, // 1:1 비율로 설정
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8.0),
                                      child: Image.file(
                                        File(problem.imageUrl),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Image.asset(
                                            defaultImage,
                                            fit: BoxFit.cover,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8), // 이미지와 텍스트 사이의 공백 추가
                              Text(
                                '${problem.title}',
                                style: const TextStyle(
                                    color: Colors.green,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}