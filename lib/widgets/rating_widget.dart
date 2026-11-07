import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class RatingWidget extends StatelessWidget { final double rating; final int reviews; const RatingWidget({super.key,required this.rating,required this.reviews}); @override Widget build(BuildContext context)=>Row(children:[const Icon(Icons.star,color:AppColors.warning,size:17),const SizedBox(width:3),Text(rating.toStringAsFixed(1),style:const TextStyle(fontWeight:FontWeight.w700)),Text(' ($reviews)',style:const TextStyle(color:AppColors.textSecondary,fontSize:12))]); }
