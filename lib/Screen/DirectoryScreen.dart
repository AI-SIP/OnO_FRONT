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
import '../Model/FolderThumbnailModel.dart';
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
    final foldersProvider = Provider.of<FoldersProvider>(context);

    return Scaffold(
      appBar: _buildAppBar(themeProvider, foldersProvider), // 상단 AppBar 추가
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
                    _buildFolderAndProblemGrid(themeProvider),
                  ],
                ),
              ),
            ),
    );
  }

  AppBar _buildAppBar(
      ThemeHandler themeProvider, FoldersProvider foldersProvider) {
    return AppBar(
      elevation: 0, // AppBar 그림자 제거
      centerTitle: true, // 제목을 항상 가운데로 배치
      title: DecorateText(
        text: foldersProvider.currentFolder?.folderName ?? _directoryName,
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      leading: foldersProvider.currentFolder?.parentFolder != null
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: themeProvider.primaryColor,
              ),
              onPressed: () {
                foldersProvider.moveToParentFolder(
                    foldersProvider.currentFolder!.parentFolder?.folderId);
              },
            )
          : null, // 루트 폴더일 경우 leading 버튼 없음
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0), // 우측에 여백 추가
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.create_new_folder,
                  color: themeProvider.primaryColor,
                  size: 24,
                ),
                onPressed: () => _showCreateFolderDialog(), // 폴더 생성 다이얼로그 호출
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    _showDeleteFolderDialog(foldersProvider);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: DecorateText(
                      text: '폴더 삭제하기',
                      fontSize: 18,
                      color: Colors.red,
                    ),
                  ),
                ],
                icon: Icon(
                  Icons.more_vert,
                  color: themeProvider.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 폴더 생성 다이얼로그 출력
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
            width: MediaQuery.of(context).size.width *
                0.8, // 화면 너비의 80%로 다이얼로그의 가로 길이를 설정
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
                      BorderSide(color: themeProvider.primaryColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: themeProvider.primaryColor, width: 1.5),
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
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () async {
                if (folderNameController.text.isNotEmpty) {
                  await _createFolder(folderNameController.text);
                  Navigator.pop(context);
                }
              },
              child: DecorateText(
                text: '생성',
                fontSize: 20,
                color: themeProvider.primaryColor,
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

  Future<void> _showDeleteFolderDialog(FoldersProvider foldersProvider) async {
    final themeProvider = Provider.of<ThemeHandler>(context, listen: false);
    bool isRootFolder = foldersProvider.currentFolder?.parentFolder == null;

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: DecorateText(
            text: '폴더 삭제',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
          content: DecorateText(
            text: isRootFolder ? '메인 폴더는 삭제할 수 없습니다!' : '정말로 이 폴더를 삭제하시겠습니까?',
            fontSize: 20,
            color: themeProvider.primaryColor,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const DecorateText(
                text: '취소',
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            if (!isRootFolder) // 루트 폴더가 아닌 경우에만 삭제 버튼을 표시
              TextButton(
                onPressed: () async {
                  if (foldersProvider.currentFolder != null) {
                    await foldersProvider
                        .deleteFolder(foldersProvider.currentFolder!.folderId);
                    Navigator.pop(context); // 다이얼로그 닫기
                  }
                },
                child: const DecorateText(
                  text: '삭제',
                  fontSize: 20,
                  color: Colors.red,
                ),
              ),
          ],
        );
      },
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

  Widget _buildFolderAndProblemGrid(ThemeHandler themeProvider) {
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
              var folders = foldersProvider.currentFolder?.subFolders ?? [];
              var problems = foldersProvider.problems;

              if (folders.isEmpty && problems.isEmpty) {
                return Center(
                  child: DecorateText(
                    text: '폴더나 문제가 등록되어 있지 않습니다!',
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
                itemCount: folders.length + problems.length,
                itemBuilder: (context, index) {
                  if (index < folders.length) {
                    var folder = folders[index];
                    return _buildFolderTile(folder, themeProvider);
                  } else {
                    var problem = problems[index - folders.length];
                    return _buildProblemTile(problem, themeProvider);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFolderTile(
      FolderThumbnailModel folder, ThemeHandler themeProvider) {
    return GestureDetector(
      onTap: () {
        Provider.of<FoldersProvider>(context, listen: false)
            .fetchFolderContents(folderId: folder.folderId);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          double height = constraints.maxHeight * 0.7;
          double width = constraints.maxWidth * 0.9;
          return GridTile(
            child: Column(
              children: <Widget>[
                Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: themeProvider.primaryColor,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: themeProvider.primaryColor,
                    size: 60, // 폴더 아이콘 크기를 더 크게 설정
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  folder.folderName,
                  style: TextStyle(
                    fontFamily: 'font1',
                    color: themeProvider.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
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
          double width = constraints.maxWidth * 0.9;
          return GridTile(
            child: Column(
              children: <Widget>[
                Container(
                  width: width,
                  height: height,
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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
