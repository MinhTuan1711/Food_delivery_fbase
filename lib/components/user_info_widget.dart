import 'package:flutter/material.dart';
import 'package:food_delivery_fbase/models/user.dart';
import 'package:food_delivery_fbase/services/auth/auth_service.dart';

class UserInfoWidget extends StatelessWidget {
  final bool showEmail;
  final bool showAdminBadge;
  final double avatarRadius;
  final TextStyle? nameStyle;
  final TextStyle? emailStyle;
  final VoidCallback? onTap;

  const UserInfoWidget({
    Key? key,
    this.showEmail = true,
    this.showAdminBadge = true,
    this.avatarRadius = 20,
    this.nameStyle,
    this.emailStyle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().getCurrentUserStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return Icon(
            Icons.error,
            color: Theme.of(context).colorScheme.error,
            size: avatarRadius,
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return Icon(
            Icons.person,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: avatarRadius,
          );
        }

        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Theme.of(context).colorScheme.primary,
                backgroundImage: user.profileImageUrl != null
                    ? NetworkImage(user.profileImageUrl!)
                    : null,
                child: user.profileImageUrl == null
                    ? Icon(
                        Icons.person,
                        size: avatarRadius,
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : null,
              ),
              if (showEmail || showAdminBadge) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      user.displayNameOrEmail,
                      style: nameStyle ?? Theme.of(context).textTheme.bodyMedium,
                    ),
                    // Email
                    if (showEmail)
                      Text(
                        user.email,
                        style: emailStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    // Admin Badge
                    if (showAdminBadge && user.isAdmin)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class UserGreetingWidget extends StatelessWidget {
  final String prefix;
  final TextStyle? style;

  const UserGreetingWidget({
    Key? key,
    this.prefix = "Xin chào",
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: AuthService().getCurrentUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          return Text(
            "$prefix, ${user.displayNameOrEmail}",
            style: style ?? Theme.of(context).textTheme.bodyMedium,
          );
        }
        return Text(
          prefix,
          style: style ?? Theme.of(context).textTheme.bodyMedium,
        );
      },
    );
  }
}















