import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'CadastroPostPage.dart';
import 'DetalhesPostPage.dart'; // Importe a tela de detalhes do post
import 'package:firebase_auth/firebase_auth.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _getUserName();
  }

  Future<void> _getCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        _user = user;
      });
    }
  }

  Future<void> _getUserName() async {
    if (_user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            _userName = userDoc['name'];
          });
        } else {
          print('Documento de usuário não encontrado no Firestore');
        }
      } catch (error) {
        print('Erro ao obter dados do usuário: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Feed - Bem vindo: ${_userName.isNotEmpty ? _userName : _user.displayName ?? "Nome do Usuário"}'),
      ),
      body: _buildFeedList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => CadastroPostPage(
                    userName: _userName.isNotEmpty
                        ? _userName
                        : _user.displayName ?? '')),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildFeedList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var posts = snapshot.data!.docs;

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            var post = posts[index].data() as Map<String, dynamic>;

            String imageUrl = post['imageUrl'] ?? '';
            String corPelagem = post['corPelagem'] ?? 'Não especificada';
            bool animalDocil = post['animalDocil'] ?? false;
            String userId = post['userId'] ?? '';
            String dataString = '';

            if (post['data'] is Timestamp) {
              Timestamp timestamp = post['data'];
              DateTime dateTime = timestamp.toDate();
              dataString =
                  "${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year.toString()}";
            } else {
              dataString = post['data'] ?? '';
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalhesPostPage(
                      imageUrl: imageUrl,
                      corPelagem: corPelagem,
                      userName: _userName.isNotEmpty ? _userName : userId,
                      animalDocil: animalDocil,
                      localizacao: post['endereco'],
                      data: dataString,
                    ),
                  ),
                );
              },
              child: Card(
                margin: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      title: Text(
                          'Nome do Usuário: ${_userName.isNotEmpty ? _userName : userId}'),
                      subtitle: Text('Data: $dataString'),
                      leading: imageUrl.isNotEmpty
                          ? Image.network(imageUrl)
                          : Icon(Icons.image_not_supported, size: 50),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Cor da Pelagem: $corPelagem'),
                    ),
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child:
                          Text('Animal Dócil: ${animalDocil ? 'Sim' : 'Não'}'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}