import 'package:flutter/material.dart';
import 'package:mobile/src/pages/groups/list_groups.dart';

class MenuDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            child: Text('Menu'),
            decoration: BoxDecoration(
              color: Colors.blueGrey[400],
            ),
          ),
          ListTile(
            title: Text('Grupo'),
             onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListGroupsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}