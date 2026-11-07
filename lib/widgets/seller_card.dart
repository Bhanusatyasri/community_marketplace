import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';
import 'rating_widget.dart';
class SellerCard extends StatelessWidget { final UserModel user; const SellerCard({super.key,required this.user}); @override Widget build(BuildContext context)=>Card(child:Padding(padding:const EdgeInsets.all(12),child:Row(children:[const CircleAvatar(radius:26,backgroundColor:AppColors.primaryLight,child:Icon(Icons.person,color:AppColors.primaryDark)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(user.name,style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),RatingWidget(rating:user.rating,reviews:user.reviewCount),const SizedBox(height:3),Text(user.location,style:const TextStyle(fontSize:11,color:AppColors.textSecondary))])),if(user.online) const Text('Online',style:TextStyle(fontSize:11,color:AppColors.primary,fontWeight:FontWeight.w700))]))); }
