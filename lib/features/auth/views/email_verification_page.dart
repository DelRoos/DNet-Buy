import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dnet_buy/app/controllers/auth_controller.dart';
import 'package:dnet_buy/shared/constants/app_constants.dart';
import 'package:dnet_buy/shared/widgets/custom_button.dart';

class EmailVerificationPage extends GetView<AuthController> {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: controller.signOut,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding * 2),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mark_email_unread,
                  size: 80,
                  color: Colors.orange,
                ),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Text(
                  'Vérifiez votre email',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Un email de vérification a été envoyé à :',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.userEmail,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Text(
                  'Cliquez sur le lien dans l\'email pour activer votre compte.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.defaultPadding * 2),
                Obx(
                  () => CustomButton(
                    text: 'Renvoyer l\'email',
                    isLoading: controller.isLoading.value,
                    onPressed: controller.resendEmailVerification,
                  ),),
               const SizedBox(height: AppConstants.defaultPadding),
               Obx(
                 () => CustomButton(
                   text: 'J\'ai vérifié mon email',
                   isLoading: controller.isLoading.value,
                   onPressed: () async {
                     await controller.refreshUser();
                     if (controller.isEmailVerified) {
                       Get.offAllNamed('/dashboard');
                     } else {
                       Get.snackbar(
                         'Email non vérifié',
                         'Veuillez cliquer sur le lien dans votre email.',
                       );
                     }
                   },
                 ),
               ),
               const SizedBox(height: AppConstants.defaultPadding * 2),
               TextButton(
                 onPressed: controller.signOut,
                 child: const Text('Se déconnecter'),
               ),
             ],
           ),
         ),
       ),
     ),
   );
 }
}