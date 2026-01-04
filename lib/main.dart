import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // നിങ്ങൾ നൽകിയ Firebase വിവരങ്ങൾ ഇവിടെ സെറ്റ് ചെയ്യുന്നു
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAthFMO8zGT5BtiOkh4zkc71jL06LR_F9c",
      appId: "1:your_app_id", // Firebase കൺസോളിൽ നിന്ന് ഇത് മാറ്റുക
      messagingSenderId: "sender_id",
      projectId: "a-one-chat-19ad6",
      databaseURL: "https://a-one-chat-19ad6-default-rtdb.firebaseio.com",
    ),
  );
  runApp(const AOneMusic());
}

class AOneMusic extends StatelessWidget {
  const AOneMusic({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // മ്യൂസിക് ആപ്പിന് ചേരുന്ന ഡാർക്ക് തീം
      home: const LoginPage(),
    );
  }
}

// --- ലോഗിൻ പേജ് ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("A One Music - Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email/Username")),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // ലളിതമായ നാവിഗേഷൻ (Firebase Auth പിന്നീട് ചേർക്കാം)
                Navigator.push(context, MaterialPageRoute(builder: (context) => const MusicHomePage()));
              },
              child: const Text("Login"),
            )
          ],
        ),
      ),
    );
  }
}

// --- ഹോം പേജ് (Music Player & Upload) ---
class MusicHomePage extends StatefulWidget {
  const MusicHomePage({super.key});

  @override
  _MusicHomePageState createState() => _MusicHomePageState();
}

class _MusicHomePageState extends State<MusicHomePage> {
  final AudioPlayer audioPlayer = AudioPlayer();
  // നിങ്ങൾ നൽകിയ Cloudinary വിവരങ്ങൾ
  final cloudinary = CloudinaryPublic('dcsczlahu', 'ml_default', cache: false);
  final databaseRef = FirebaseDatabase.instance.ref("songs");

  // പാട്ട് അപ്‌ലോഡ് ചെയ്യാനുള്ള ഫങ്ക്ഷൻ
  Future<void> uploadSong() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
    
    if (result != null) {
      String filePath = result.files.single.path!;
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(filePath, resourceType: CloudinaryResourceType.Auto),
        );
        
        // Firebase Realtime Database-ലേക്ക് പാട്ടിന്റെ ലിങ്ക് അയക്കുന്നു
        await databaseRef.push().set({
          "name": result.files.single.name,
          "url": response.secureUrl,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Song Uploaded Successfully!")));
      } catch (e) {
        print("Upload Error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("A One Music Player")),
      floatingActionButton: FloatingActionButton(
        onPressed: uploadSong,
        child: const Icon(Icons.cloud_upload),
      ),
      body: StreamBuilder(
        stream: databaseRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData && (snapshot.data!).snapshot.value != null) {
            Map<dynamic, dynamic> map = (snapshot.data!).snapshot.value as Map;
            List songs = map.values.toList();
            return ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(songs[index]['name']),
                  leading: const Icon(Icons.play_circle_fill, color: Colors.green),
                  onTap: () async {
                    // ലിങ്കിൽ നിന്ന് നേരിട്ട് പാട്ട് പ്ലേ ചെയ്യുന്നു
                    await audioPlayer.play(UrlSource(songs[index]['url']));
                  },
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
