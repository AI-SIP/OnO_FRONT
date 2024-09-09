import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Model/FolderThumbnailModel.dart';
import '../../Provider/FoldersProvider.dart';
import '../Theme/DecorateText.dart';
import '../Theme/ThemeHandler.dart';

class FolderSelectionDialog extends StatefulWidget {
  @override
  _FolderSelectionDialogState createState() => _FolderSelectionDialogState();
}

class _FolderSelectionDialogState extends State<FolderSelectionDialog> {
  int? _selectedFolderId;
  String? _selectedFolderName;

  @override
  Widget build(BuildContext context) {
    final foldersProvider =
        Provider.of<FoldersProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeHandler>(context);

    return AlertDialog(
      title: DecorateText(
        text: '위치 선택',
        fontSize: 24,
        color: themeProvider.primaryColor,
      ),
      content: Container(
        width: double.maxFinite,
        child: FutureBuilder<List<FolderThumbnailModel>>(
          future: foldersProvider.fetchAllFolderThumbnails(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                  child: DecorateText(
                text: '폴더를 불러오는 중 오류 발생',
                fontSize: 24,
                color: themeProvider.primaryColor,
              ));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                  child: DecorateText(
                text: '폴더가 없습니다!',
                fontSize: 24,
                color: themeProvider.primaryColor,
              ));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var folder = snapshot.data![index];
                  return ListTile(
                    title: DecorateText(text: folder.folderName, fontSize: 20, color: themeProvider.primaryColor,),
                    leading: Icon(Icons.folder, color: themeProvider.primaryColor,),
                    trailing: _selectedFolderId == folder.folderId
                        ? Icon(Icons.check, color: themeProvider.primaryColor, )
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedFolderId = folder.folderId;
                        _selectedFolderName = folder.folderName;
                      });
                    },
                  );
                },
              );
            }
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, null); // 취소 시 아무 값도 넘기지 않음
          },
          child: const DecorateText(
            text: '취소',
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        TextButton(
          onPressed: () {
            if (_selectedFolderId != null && _selectedFolderName != null) {
              // 선택된 폴더 ID와 이름을 Map으로 전달
              Navigator.pop(context, {
                'folderId': _selectedFolderId,
                'folderName': _selectedFolderName,
              });
            } else {
              // 선택되지 않으면 그대로 취소
              Navigator.pop(context, null);
            }
          },
          child: DecorateText(
            text: '확인',
            fontSize: 24,
            color: themeProvider.primaryColor,
          ),
        ),
      ],
    );
  }
}
