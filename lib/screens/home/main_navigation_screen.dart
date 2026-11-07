import 'package:flutter/material.dart';
import '../../widgets/app_bottom_navigation.dart';
import '../categories/categories_screen.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_screen.dart';
import '../sell/sell_item_screen.dart';
import 'home_screen.dart';
class MainNavigationScreen extends StatefulWidget{const MainNavigationScreen({super.key});@override State<MainNavigationScreen> createState()=>_MainNavigationScreenState();}
class _MainNavigationScreenState extends State<MainNavigationScreen>{int index=0;final pages=const [HomeScreen(),CategoriesScreen(),SellItemScreen(),MessagesScreen(),ProfileScreen()];@override Widget build(BuildContext context)=>Scaffold(body:IndexedStack(index:index,children:pages),bottomNavigationBar:AppBottomNavigation(index:index,onTap:(i)=>setState(()=>index=i)));}
