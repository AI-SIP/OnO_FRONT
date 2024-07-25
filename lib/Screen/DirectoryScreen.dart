import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/DisplayImage.dart';
import 'ProblemDetailScreen.dart';
import '../Model/ProblemModel.dart';
import '../Provider/ProblemsProvider.dart'; // ProblemsProvider import
import '../Service/AuthService.dart'; // AuthService import

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({Key? key}) : super(key: key);

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final String defaultImage = 'assets/process_image.png'; // Default image 경로 설정

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ProblemsProvider에서 데이터를 로드
      Provider.of<ProblemsProvider>(context, listen: false).fetchProblems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      body: !authService.isLoggedIn
          ? Center(child: Text('로그인 해주세요!'))
          : RefreshIndicator(
        onRefresh: () =>
            Provider.of<ProblemsProvider>(context, listen: false)
                .fetchProblems(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Consumer<ProblemsProvider>(
            builder: (context, problemsProvider, child) {
              var problems = problemsProvider.problems;
              if (problems.isEmpty) {
                return Center(child: Text('오답노트가 등록되어 있지 않습니다'));
              }
              return GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: problems.length,
                itemBuilder: (context, index) {
                  var problem = problems[index];
                  return buildProblemTile(problem);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildProblemTile(ProblemModel problem) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProblemDetailScreen(problemId: problem.problemId),
          ),
        ).then((value) {
          if (value == true) {
            Provider.of<ProblemsProvider>(context, listen: false).fetchProblems();
          }
        });
      },
      child: GridTile(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Container(
                height: 150, // 고정된 높이 설정
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 1.0),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: DisplayImage(
                    imagePath: problem.processImageUrl, // 이미지 경로 업데이트
                    defaultImagePath: defaultImage,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              problem.reference ?? '제목 없음',
              style: TextStyle(
                fontFamily: 'font1',
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis, // 넘치는 텍스트는 말줄임표로 처리
              maxLines: 1, // 텍스트를 한 줄로 제한
            ),
          ],
        ),
      ),
    );
  }
}