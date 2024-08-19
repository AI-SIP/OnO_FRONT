import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Service/ScreenUtil/DirectoryScreenService.dart';
import '../Model/ProblemModel.dart';
import '../Provider/ProblemsProvider.dart';
import '../Service/Auth/AuthService.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final String defaultImage = 'assets/no_image.png'; // Default image path
  String _selectedSortOption = 'newest'; // Default sorting option

  late DirectoryScreenService _directoryService; // Instance of DirectoryService

  @override
  void initState() {
    super.initState();
    _directoryService = DirectoryScreenService(
      Provider.of<ProblemsProvider>(context, listen: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      body: !authService.isLoggedIn
          ? _buildLoginPrompt(themeProvider)
          : RefreshIndicator(
        onRefresh: () => _directoryService.fetchProblems(),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            children: [
              _buildSortDropdown(themeProvider),
              _buildProblemGrid(themeProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeHandler themeProvider) {
    return Center(
      child: DecorateText(
        text: '로그인을 통해 작성한 오답노트를 확인해보세요!',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
    );
  }

  Widget _buildSortDropdown(ThemeHandler themeProvider) {
    return Align(
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
            _directoryService.sortProblems(_selectedSortOption);
          });
        },
      ),
    );
  }

  Widget _buildProblemGrid(ThemeHandler themeProvider) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 가로/세로 모드에 따라 그리드 레이아웃을 변경
          int crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
          if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
          }

          return Consumer<ProblemsProvider>(
            builder: (context, problemsProvider, child) {
              var problems = problemsProvider.problems;
              if (problems.isEmpty) {
                return Center(
                  child: DecorateText(
                    text: '오답노트가 등록되어 있지 않습니다!',
                    fontSize: 24,
                    color: themeProvider.primaryColor,
                  ),
                );
              }
              return GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.7,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: problems.length,
                itemBuilder: (context, index) {
                  var problem = problems[index];
                  return _buildProblemTile(problem, themeProvider);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProblemTile(ProblemModel problem, ThemeHandler themeProvider) {
    return GestureDetector(
      onTap: () {
        _directoryService.navigateToProblemDetail(context, problem.problemId);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          double height = constraints.maxHeight * 0.8;
          double width = constraints.maxWidth * 0.9; // Set width ratio
          return GridTile(
            child: Column(
              children: <Widget>[
                Container(
                  width: width, // Set width ratio
                  height: height, // Fixed height
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeProvider.primaryColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: DisplayImage(
                      imagePath: problem.processImageUrl,
                      fit: BoxFit.contain,
                    ),
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
                  overflow: TextOverflow.ellipsis, // Handle text overflow
                  maxLines: 1, // Limit to one line
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}