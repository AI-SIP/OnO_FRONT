import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/DecorateText.dart';
import '../GlobalModule/DisplayImage.dart';
import 'ProblemDetailScreen.dart';
import '../Model/ProblemModel.dart';
import '../Provider/ProblemsProvider.dart';
import '../Service/AuthService.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final String defaultImage = 'assets/no_image.png'; // Default image 경로 설정

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemsProvider>(context, listen: false).fetchProblems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return Scaffold(
      body: !authService.isLoggedIn
          ? const Center(
          child: DecorateText(text: '로그인을 통해 작성한 오답노트를 확인해보세요!', fontSize: 24))
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
                      return const Center(
                          child: DecorateText(text: '오답노트가 등록되어 있지 않습니다!', fontSize: 24));
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
            builder: (context) =>
                ProblemDetailScreen(problemId: problem.problemId),
          ),
        ).then((value) {
          if (value == true) {
            Provider.of<ProblemsProvider>(context, listen: false)
                .fetchProblems();
          }
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          double height = constraints.maxHeight * 0.8;
          double width = constraints.maxWidth * 0.9; // 가로 길이 비율 설정
          return GridTile(
            child: Column(
              children: <Widget>[
                Container(
                  width: width, // 비율로 설정된 너비
                  height: height, // 고정된 높이
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2.0),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: DisplayImage(
                        imagePath: problem.processImageUrl,
                        fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  problem.reference ?? '제목 없음',
                  style: const TextStyle(
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
          );
        },
      ),
    );
  }
}
