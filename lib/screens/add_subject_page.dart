import 'package:deadline_tracker/screens/subject_page.dart';
import 'package:deadline_tracker/widgets/horizontal_button.dart';
import 'package:deadline_tracker/widgets/page_container.dart';
import 'package:deadline_tracker/widgets/streambuilder_handler.dart';
import 'package:deadline_tracker/widgets/title_text.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'package:deadline_tracker/models/subject.dart';
import 'package:deadline_tracker/services/auth.dart';
import 'package:deadline_tracker/services/subject_service.dart';
import 'package:deadline_tracker/utils/show_dialog_utils.dart';
import 'package:deadline_tracker/utils/string_formatter.dart';
import 'package:deadline_tracker/widgets/decorated_container.dart';
import 'package:deadline_tracker/widgets/input_field.dart';

class AddSubjectPage extends StatefulWidget {
  AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  final _subjectService = GetIt.I<SubjectService>();
  final _authService = GetIt.I<Auth>();

  final _subjectCodeEditingController = TextEditingController();

  final _subjectNameEditingController = TextEditingController();

  final _searchTextController = TextEditingController();
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = _authService.currentUser!.uid;
    _searchTextController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitleText(text: "Crete new subject"),
            SizedBox(height: 20),
            InputField(
              controller: _subjectCodeEditingController,
              maxLength: 20,
              hintText: "Code",
            ),
            SizedBox(height: 10),
            InputField(
              controller: _subjectNameEditingController,
              maxLength: 100,
              hintText: "Name",
            ),
            SizedBox(height: 20),
            HorizontalButton(
              text: "Create",
              onTap: () {
                _onCreatePressed(context);
              },
            ),
            SizedBox(height: 10),
            Divider(),
            SizedBox(height: 10),
            TitleText(text: "Search community subjects"),
            SizedBox(height: 10),
            InputField(
              hintText: "Search",
              useSearchIcon: true,
              controller: _searchTextController,
            ),
            SizedBox(height: 20),
            _drawSearchResults(),
          ],
        ),
      ),
    );
  }

  void _onCreatePressed(BuildContext context) async {
    if (_subjectCodeEditingController.text.trim().isEmpty ||
        _subjectNameEditingController.text.trim().isEmpty) {
      ShowDialogUtils.showInfoDialog(
          context, 'Error', 'Code or Name cant be empty');
      _subjectNameEditingController.clear();
      _subjectCodeEditingController.clear();
    } else {
      final foundSubject = await _subjectService
          .getSubjectReferenceByCode(_subjectCodeEditingController.text);
      if (foundSubject == null) {
        _subjectService.createSubject(
          Subject(
              code: _subjectCodeEditingController.text,
              name: _subjectNameEditingController.text,
              authorId: _uid),
        );
        ShowDialogUtils.showInfoDialog(
            context, "Success", "Successfully created subject");
      } else {
        ShowDialogUtils.showInfoDialog(context, "Error",
            "Subject with this code already exists: ${_subjectCodeEditingController.text}");
      }
      _subjectCodeEditingController.clear();
      _subjectNameEditingController.clear();
    }
  }

  Widget _drawSearchResults() {
    return StreamBuilderHandler<List<Subject>>(
        stream: _subjectService.subjectStream,
        toReturn: _drawSearchResultHasData);
  }

  Widget _drawSearchResultHasData(AsyncSnapshot<List<Subject>> snapshot) {
    final subjects = snapshot.data!
        .where((subject) =>
            subject.code
                .toLowerCase()
                .contains(_searchTextController.text.toLowerCase()) ||
            subject.name
                .toLowerCase()
                .contains(_searchTextController.text.toLowerCase()))
        .toList();

    if (subjects.length == 0) {
      return Text(
        "0 Results found",
        style: TextStyle(color: Colors.grey),
      );
    }
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${StringFormatter.handlePlural(subjects.length, "Result")} found",
            style: TextStyle(color: Colors.grey),
          ),
          Container(
            child: Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(8.0),
                child: _searchResultListView(subjects),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchResultListView(List<Subject> subjects) {
    return ListView.separated(
      shrinkWrap: true,
      physics: ScrollPhysics(),
      itemCount: subjects.length,
      itemBuilder: (BuildContext context, int index) {
        return DecoratedContainer(
          child: InkWell(
            onTap: () {
              final subjectPage = MaterialPageRoute(
                builder: (BuildContext context) => SubjectPage(
                  subject: subjects[index],
                ),
              );
              Navigator.of(context).push(subjectPage);
            },
            child: Text(
              subjects[index].code + ": " + subjects[index].name,
            ),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) => SizedBox(
        height: 10,
      ),
    );
  }
}
