import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ono/Model/LoginStatus.dart';
import 'package:ono/Provider/FoldersProvider.dart';
import 'package:provider/provider.dart';
import '../GlobalModule/Theme/DecorateText.dart';
import '../GlobalModule/Image/DisplayImage.dart';
import '../GlobalModule/Theme/ThemeHandler.dart';
import '../Service/ScreenUtil/DirectoryScreenService.dart';
import '../Model/ProblemModel.dart';
import '../Service/Auth/AuthService.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  final String defaultImage = 'assets/no_image.png';
  String _selectedSortOption = 'newest';
  final String _directoryName = '메인';

  late DirectoryScreenService _directoryService;

  @override
  void initState() {
    super.initState();
    _directoryService = DirectoryScreenService(
      Provider.of<FoldersProvider>(context, listen: false),
    );

    _directoryService.sortProblems(_selectedSortOption);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider), // 상단 AppBar 추가
      body: !(authService.isLoggedIn == LoginStatus.login)
          ? _buildLoginPrompt(themeProvider)
          : RefreshIndicator(
              onRefresh: () async {
                _directoryService.sortProblems(_selectedSortOption);
                await _directoryService.fetchProblems();
              },
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

  AppBar _buildAppBar(ThemeHandler themeProvider) {
    return AppBar(
      elevation: 0, // AppBar 그림자 제거
      centerTitle: true, // 제목을 항상 가운데로 배치
      title: DecorateText(
        text: _directoryName,
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: IconButton(
            icon: Icon(
              Icons.create_new_folder,
              color: themeProvider.primaryColor,
              size: 24,
            ),
            onPressed: () => _showCreateFolderDialog(), // 폴더 생성 다이얼로그 호출
          ),
        ),
      ],
    );
  }

  Future<void> _showCreateFolderDialog() async {
    TextEditingController folderNameController = TextEditingController();
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: DecorateText(
            text: '폴더 생성',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8, // 화면 너비의 80%로 다이얼로그의 가로 길이를 설정
            child: TextField(
              controller: folderNameController,
              style: TextStyle(
                color: themeProvider.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'font1',
              ),
              decoration: InputDecoration(
                hintText: '폴더 이름을 입력하세요',
                hintStyle: TextStyle(
                  color: themeProvider.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'font1',
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: themeProvider.primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 2.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                  BorderSide(color: themeProvider.primaryColor, width: 2.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 20.0, horizontal: 12.0), // 입력창 크기 조정
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: DecorateText(
                text: '취소',
                fontSize: 18,
                color: themeProvider.primaryColor,
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (folderNameController.text.isNotEmpty) {
                  await _createFolder(folderNameController.text);
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: themeProvider.primaryColor),
              child: const DecorateText(
                text: '생성',
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFolder(String folderName) async {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    await foldersProvider.createFolder(folderName);
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

          return Consumer<FoldersProvider>(
            builder: (context, foldersProvider, child) {
              var problems = foldersProvider.problems;
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
                  childAspectRatio: 0.55,
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
    String formatDateTime(DateTime dateTime) {
      return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
    }

    return GestureDetector(
      onTap: () {
        _directoryService.navigateToProblemDetail(context, problem.problemId);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          double height = constraints.maxHeight * 0.7;
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
                const SizedBox(height: 2),
                DecorateText(
                  text: problem.updateAt != null
                      ? '작성 일시 : ${formatDateTime(problem.createdAt!)}'
                      : '작성 일시 : 정보 없음',
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
