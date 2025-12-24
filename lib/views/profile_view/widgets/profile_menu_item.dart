// Dosya: lib/views/profile_view/widgets/profile_menu_item.dart

import 'package:flutter/material.dart';
import 'package:mymovielist/app/theme.dart';

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final Color? color; // YENİ: Renk parametresi eklendi

  const ProfileMenuItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.color, // Opsiyonel
  });

  @override
  Widget build(BuildContext context) {
    // Eğer renk gönderildiyse onu kullan, yoksa Mavi (primaryBlue) kullan
    final itemColor = color ?? AppTheme.primaryBlue;

    // Eğer çıkış yap butonuysa (yani renk kırmızıysa), arka planı da hafif kırmızı yapalım
    final bgColor = color == Colors.redAccent
        ? Colors.redAccent.withOpacity(0.1)
        : AppTheme.surfaceDark;

    return Card(
      color: bgColor,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: color == Colors.redAccent
            ? const BorderSide(color: Colors.redAccent, width: 1)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Icon(icon, color: itemColor),
        title: Text(
          text,
          style: TextStyle(
            color: color == Colors.redAccent ? Colors.redAccent : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: color == Colors.redAccent ? Colors.redAccent : Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
