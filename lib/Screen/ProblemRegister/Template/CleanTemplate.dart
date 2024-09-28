import 'package:flutter/material.dart';
import 'package:ono/Model/ProblemModel.dart';
import 'package:provider/provider.dart';
import '../../../Provider/FoldersProvider.dart';

class CleanTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final List<Map<String, int>?>? colors; // 추가된 부분

  const CleanTemplate({required this.problemModel, required this.colors, Key? key})
      : super(key: key);

  @override
  _CleanTemplateState createState() => _CleanTemplateState();
}

class _CleanTemplateState extends State<CleanTemplate> {
  late ProblemModel problemModel;
  String? processImageUrl;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProcessImage();
  }

  Future<void> _fetchProcessImage() async {
    final provider = Provider.of<FoldersProvider>(context, listen: false);

    processImageUrl = await provider.fetchProcessImageUrl(problemModel.problemImageUrl, widget.colors);

    setState(() {
      isLoading = false;
      problemModel = widget.problemModel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Center(child: Image.network(processImageUrl!)),
      ),
    );
  }
}