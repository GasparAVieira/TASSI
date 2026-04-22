import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class ErrorPopup extends StatelessWidget {
  final VoidCallback onTryAgain;
  final VoidCallback onClose;

  const ErrorPopup({
    super.key,
    required this.onTryAgain,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = SettingsService();

    return Center(
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 360,
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              side: settings.isHighContrast 
                  ? BorderSide(color: theme.colorScheme.onSurface, width: 2.0) 
                  : BorderSide(width: 1, color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 360,
                                  child: Text(
                                    ' Something Went Wrong',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 28,
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.w500,
                                      height: 0.86,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 328,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: ' We encountered an error while trying to process your action. Please ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                            TextSpan(
                              text: 'attempt reloading the app',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                            TextSpan(
                              text: ' or ',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                            TextSpan(
                              text: 'try again later',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w700,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                            TextSpan(
                              text: '.',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w400,
                                height: 1.43,
                                letterSpacing: 0.25,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: onTryAgain,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              color: theme.colorScheme.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                                side: settings.isHighContrast ? BorderSide(color: theme.colorScheme.onSurface, width: 1) : BorderSide.none,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Try Again Now',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                  letterSpacing: 0.10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: onClose,
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: double.infinity,
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            clipBehavior: Clip.antiAlias,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  width: 1,
                                  color: theme.colorScheme.outline,
                                ),
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w500,
                                  height: 1.43,
                                  letterSpacing: 0.10,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 328,
                      child: Text(
                        'ERROR CODE: ERR_OP_503_SRV',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          height: 1.67,
                          letterSpacing: 0.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showErrorPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => ErrorPopup(
      onTryAgain: () => Navigator.of(context).pop(),
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}
