import 'package:flutter/material.dart';
import '../core/validators/password_validator.dart';
import '../l10n/app_localizations.dart';

/// Şifre güç göstergesi widget'ı
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;
  
  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final strength = PasswordValidator.getStrengthLevel(password);
    final strengthValue = PasswordValidator.calculateStrength(password) / 100;
    final strengthColor = PasswordValidator.getStrengthColor(strength);
    final strengthText = PasswordValidator.getStrengthText(strength, context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Güç göstergesi bar
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: strengthValue,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: strengthColor,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Güç metni
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.passwordStrength,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              strengthText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        
        // Gereksinimler listesi
        if (showRequirements && password.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildRequirementsList(context),
        ],
      ],
    );
  }
  
  Widget _buildRequirementsList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requirements = [
      RequirementCheck(
        label: l10n.passwordMinLength('8'),
        isMet: password.length >= PasswordValidator.minLength,
      ),
      RequirementCheck(
        label: l10n.passwordRequireUppercase,
        isMet: password.contains(RegExp(r'[A-Z]')),
      ),
      RequirementCheck(
        label: l10n.passwordRequireLowercase,
        isMet: password.contains(RegExp(r'[a-z]')),
      ),
      RequirementCheck(
        label: l10n.passwordRequireNumber,
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      RequirementCheck(
        label: l10n.passwordRequireSpecial,
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
      ),
    ];
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.passwordRequirements,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...requirements.map((req) => _buildRequirementItem(req, context)),
        ],
      ),
    );
  }
  
  Widget _buildRequirementItem(RequirementCheck requirement, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            requirement.isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: requirement.isMet ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: requirement.isMet ? Colors.green[700] : Colors.red[700],
                decoration: requirement.isMet ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RequirementCheck {
  final String label;
  final bool isMet;
  
  RequirementCheck({required this.label, required this.isMet});
}
