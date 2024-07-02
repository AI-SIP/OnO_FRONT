import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'DirectoryService.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({Key? key}) : super(key: key);

  @override
  _DirectoryScreenState createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> with WidgetsBindingObserver {
  final DirectoryService directoryService = DirectoryService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadData(); // 문제 데이터 로드
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadData(); // 앱이 다시 활성화될 때 데이터 새로고침
    }
  }

  void loadData() async {
    await directoryService.fetchAndSaveProblems(); // 최신 데이터로 캐시 업데이트
    setState(() {}); // 화면 갱신
  }

  void reloadData(){
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('문제 디렉토리'),
      ),
      body: FutureBuilder<List<ProblemThumbnail>>(
        future: directoryService.loadProblemsFromCache(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var problem = snapshot.data![index];
                  return ListTile(
                    leading: Container(
                      width: 56,
                      height: 56,
                      child: Image.file(File(problem.imageUrl), fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.error); // 이미지 로드 실패 시 아이콘 표시
                      }),
                    ),
                    title: Text('문제 ${problem.id}'),
                    onTap: () {
                      // 상세 페이지로 이동하는 기능 구현
                    },
                  );
                },
              );
            }
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}