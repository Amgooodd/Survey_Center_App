import 'package:flutter/material.dart';
import 'package:student_questionnaire/Features/upload_excel.dart';
import '../../widgets/Bottom_bar.dart';

class Group extends StatefulWidget {
  const Group({super.key});

  @override
  _Group createState() => _Group();
}

class _Group extends State<Group> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Groups", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 28, 51, 95),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.popUntil(
              context,
              (route) => route.settings.name == '/firsrforadminn',
            );
          },
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 50),
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  children: [
                    SubjectCard(
                      title: "CS/STAT",
                      image: "assets/CS_STAT.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "CS/STAT",
                        );
                      },
                    ),
                    SubjectCard(
                      title: "CS/MATH",
                      image: "assets/CS_MATH.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "CS/MATH",
                        );
                      },
                    ),
                    SubjectCard(
                      title: "CHEMISTRY",
                      image: "assets/chemistry.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "CHEMISTRY",
                        );
                      },
                    ),
                    SubjectCard(
                      title: "CS",
                      image: "assets/cs.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "CS",
                        );
                      },
                    ),
                    SubjectCard(
                      title: "BIOLOGY",
                      image: "assets/biology.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "BIOLOGY",
                        );
                      },
                    ),
                    SubjectCard(
                      title: "CS/PHY",
                      image: "assets/cs.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "CS/PHY",
                        );
                      },
                    ),
                    SubjectCard(
                      title: "MATH",
                      image: "assets/math.png",
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/groupDetails',
                          arguments: "MATH",
                        );
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 253, 200, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      FileUploader().pickFile(context);
                    },
                    child: Row(
                      children: [
                        Icon(Icons.person_add_alt_1, color: Colors.black),
                        Text(' Upload Data ',
                            style: TextStyle(color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        groupp: true,
      ),
    );
  }
}

class SubjectCard extends StatelessWidget {
  final String title;
  final String image;
  final VoidCallback onTap;

  const SubjectCard({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
          ),
          SizedBox(height: 10),
          GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(image),
            ),
          )
        ],
      ),
    );
  }
}
