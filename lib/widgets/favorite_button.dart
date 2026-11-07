import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
class FavoriteButton extends StatelessWidget { final bool selected; final VoidCallback onPressed; const FavoriteButton({super.key,required this.selected,required this.onPressed}); @override Widget build(BuildContext context)=>IconButton(onPressed:onPressed,icon:Icon(selected?Icons.favorite:Icons.favorite_border,color:selected?Colors.red:AppColors.textPrimary)); }
