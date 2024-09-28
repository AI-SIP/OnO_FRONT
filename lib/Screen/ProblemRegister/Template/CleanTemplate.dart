import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Provider/FoldersProvider.dart';

class CleanTemplate extends StatefulWidget {
  final int problemId;
  final String problemImageUrl;
  final List<Map<String, int>?>? colors; // 추가된 부분

  const CleanTemplate({required this.problemId, required this.problemImageUrl, required this.colors, Key? key})
      : super(key: key);

  @override
  _CleanTemplateState createState() => _CleanTemplateState();
}

class _CleanTemplateState extends State<CleanTemplate> {
  String? processImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProcessImage();
  }

  Future<void> _fetchProcessImage() async {
    final provider = Provider.of<FoldersProvider>(context, listen: false);

    processImageUrl = await provider.fetchProcessImageUrl(widget.problemImageUrl, widget.colors);

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Clean Template 등록')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(child: Image.network(processImageUrl!)),
      ),
    );
  }
}