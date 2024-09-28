import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:ono/Model/ProblemModel.dart';
import 'package:provider/provider.dart';
import '../../../GlobalModule/Util/LatexTextHandler.dart';
import '../../../Provider/FoldersProvider.dart';

class SpecialTemplate extends StatefulWidget {
  final ProblemModel problemModel;
  final List<Map<String, int>?>? colors; // 추가된 부분

  const SpecialTemplate(
      {required this.problemModel,
      required this.colors,
      Key? key})
      : super(key: key);

  @override
  _SpecialTemplateState createState() => _SpecialTemplateState();
}

class _SpecialTemplateState extends State<SpecialTemplate> {
  late ProblemModel problemModel;
  String? processImageUrl;
  String? analysisResult;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    problemModel = widget.problemModel;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<FoldersProvider>(context, listen: false);

    // processImageUrl 먼저 fetch
    processImageUrl = await provider.fetchProcessImageUrl(
        problemModel.problemImageUrl, widget.colors);

    // analysisResult fetch
    analysisResult = await provider.fetchAnalysisResult(problemModel.problemImageUrl);

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Image.network(processImageUrl!),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: analysisResult != null
                        ? TeXView(
                            fonts: const [
                              TeXViewFont(
                                  fontFamily: 'HandWrite',
                                  src: 'assets/fonts/HandWrite.ttf'),
                            ],
                            renderingEngine:
                                const TeXViewRenderingEngine.mathjax(),
                            child:
                                LatexTextHandler.renderLatex(analysisResult!),
                            style: const TeXViewStyle(
                              elevation: 5,
                              borderRadius: TeXViewBorderRadius.all(10),
                              backgroundColor: Colors.white,
                            ),
                          )
                        : const Text('No analysis result available'),
                  ),
                ],
              ),
            ),
    );
  }
}
