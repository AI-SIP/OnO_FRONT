import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
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
  String _selectedSortOption = 'name'; // 기본 정렬 옵션

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProblemsProvider>(context, listen: false).fetchProblems();
    });
  }

  void _sortProblems(String option) {
    final problemsProvider =
        Provider.of<ProblemsProvider>(context, listen: false);

    if (option == 'name') {
      problemsProvider.sortProblemsByName('root');
    } else if (option == 'newest') {
      problemsProvider.sortProblemsByNewest('root');
    } else if (option == 'oldest') {
      problemsProvider.sortProblemsByOldest('root');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      body: !authService.isLoggedIn
          ? Center(
              child: DecorateText(
                  text: '로그인을 통해 작성한 오답노트를 확인해보세요!',
                  fontSize: 24,
                  color: themeProvider.primaryColor))
          : RefreshIndicator(
              onRefresh: () =>
                  Provider.of<ProblemsProvider>(context, listen: false)
                      .fetchProblems(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: DropdownButton<String>(
                        value: _selectedSortOption,
                        iconEnabledColor: themeProvider.primaryColor,
                        underline: Container(),
                        items: [
                          DropdownMenuItem(
                            value: 'name',
                            child: DecorateText(
                              text: '이름순',
                              fontSize: 18,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'newest',
                            child: DecorateText(
                              text: '최신순',
                              fontSize: 18,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'oldest',
                            child: DecorateText(
                              text: '오래된순',
                              fontSize: 18,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSortOption = value!;
                            _sortProblems(_selectedSortOption);
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: Consumer<ProblemsProvider>(
                        builder: (context, problemsProvider, child) {
                          var problems = problemsProvider.problems;
                          if (problems.isEmpty) {
                            return Center(
                                child: DecorateText(
                                    text: '오답노트가 등록되어 있지 않습니다!',
                                    fontSize: 24,
                                    color: themeProvider.primaryColor));
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
                  ],
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
          final themeProvider = Provider.of<ThemeHandler>(context);
          return GridTile(
            child: Column(
              children: <Widget>[
                Container(
                  width: width, // 비율로 설정된 너비
                  height: height, // 고정된 높이
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: themeProvider.primaryColor, width: 2.0),
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
                  style: TextStyle(
                    fontFamily: 'font1',
                    color: themeProvider.primaryColor,
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
