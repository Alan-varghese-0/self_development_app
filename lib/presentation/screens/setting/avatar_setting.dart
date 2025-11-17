import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarSelectionPage extends StatelessWidget {
  const AvatarSelectionPage({super.key});

  final avatarList = const ["assets/avatars/sheep.png"];

  Future<void> _selectAvatar(BuildContext context, String avatarPath) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Update DB
    await Supabase.instance.client
        .from('profiles')
        .update({'avatar': avatarPath})
        .eq('id', user.id);

    Navigator.pop(context); // Go back to profile
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Your Avatar")),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: avatarList.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final img = avatarList[index];
          return GestureDetector(
            onTap: () => _selectAvatar(context, img),
            child: CircleAvatar(radius: 40, backgroundImage: AssetImage(img)),
          );
        },
      ),
    );
  }
}
