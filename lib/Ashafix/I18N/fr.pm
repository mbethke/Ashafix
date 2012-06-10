package Ashafix::I18N::fr;
use utf8;
use Mojo::Base 'Ashafix::I18N';
our %Lexicon = (
YES => 'Oui',
NO => 'Non',
edit => 'Modifier',
del => 'Effacer',
exit => 'Quitter',
cancel => 'Annuler',
save => 'Enregistrer',
confirm => 'Etes vous sur de vouloir supprimer cet enregistrement\n',
confirm_domain => 'Etes-vous sur de vouloir effacer tous les enregistrements dans ce domaine ? Cette opération ne pourra pas être annulée.\n',
check_update => 'Vérifiez les mises à jour',
invalid_parameter => 'Paramètres invalides!',
pFooter_logged_as => 'Bonjour %s',
pLogin_welcome => 'Entrez votre adresse courriel pour administrer votre domaine.',
pLogin_username => 'Adresse courriel',
pLogin_password => 'Mot de passe',
pLogin_button => 'Entrer',
pLogin_failed => 'Votre email ou mot de passe est incorrect.',
pLogin_login_users => 'Utilisateurs, cliquez ici pour rejoindre votre section.',
pMenu_main => 'Menu principal',
pMenu_overview => 'Vue d\'ensemble',
pMenu_create_alias => 'Ajouter un alias',
pMenu_create_alias_domain => 'Ajouter un alias de domaine',
pMenu_create_mailbox => 'Ajouter un compte courriel',
pMenu_fetchmail => 'Récupérer le courrier',
pMenu_sendmail => 'Envoyer un courriel',
pMenu_password => 'Mot de passe',
pMenu_viewlog => 'Consulter le journal des événements',
pMenu_logout => 'Sortir',
pMain_welcome => 'Bienvenue sur Postfix Admin!',
pMain_overview => 'Visualiser vos alias et comptes courriels. (Modifier/Effacer)',
pMain_create_alias => 'Ajouter un nouvel alias à votre domaine.',
pMain_create_mailbox => 'Ajouter un nouveau compte courriel à votre domaine.',
pMain_sendmail => 'Envoyer un courriel à un de vos nouveaux comptes courriels.',
pMain_password => 'Changer votre mot de passe pour le compte administrateur.',
pMain_viewlog => 'Visualiser le fichier d\'événements.',
pMain_logout => 'Sortir du système',
pOverview_disabled => 'Désactivé',
pOverview_unlimited => 'Illimité',
pOverview_title => ':: Domaines définis',
pOverview_up_arrow => 'Remonter',
pOverview_right_arrow => 'Page suivante',
pOverview_left_arrow => 'Page précédente',
pOverview_alias_domain_title => ':: Alias Domaine',
pOverview_alias_title => ':: Alias',
pOverview_mailbox_title => ':: Comptes courriels',
pOverview_button => 'Aller',
pOverview_welcome => 'Vue d\'ensemble pour ',
pOverview_alias_domain_aliases => 'Alias Domaines',
pOverview_alias_domain_target => '%s est un alias de domaine pour:',
pOverview_alias_alias_count => 'Alias',
pOverview_alias_mailbox_count => 'Comptes courriels',
pOverview_alias_address => 'De',
pOverview_alias_goto => 'A',
pOverview_alias_modified => 'Dernière Modification',
pOverview_alias_domain_modified => 'Dernière Modification',
pOverview_alias_active => 'Activé',
pOverview_alias_domain_active => 'Activé',
pOverview_alias_edit => 'Alias',
and_x_more => '[et %s en plus...]',
pOverview_mailbox_username => 'courriel',
pOverview_mailbox_name => 'Nom',
pOverview_mailbox_quota => 'Limite (MB)',
pOverview_mailbox_modified => 'Dernière Modification',
pOverview_mailbox_active => 'Actif',
pOverview_vacation_edit => 'REPONDEUR ACTIVE',
pOverview_vacation_option => 'Configurer le répondeur',
pOverview_get_domain => 'Domaine',
pOverview_get_aliases => 'Alias',
pOverview_get_alias_domains => 'Alias Domaine',
pOverview_get_mailboxes => 'Comptes courriels',
pOverview_get_quota => 'Limite compte courriels (MB)',
pOverview_get_modified => 'Dernière Modification',
pDelete_delete_error => 'Impossible d\'effacer cette entrée ',
pDelete_delete_success => '%s supprimé.',
pDelete_postdelete_error => 'Impossible d\'effacer ce compte courriel',
pDelete_domain_error => 'Ce domaine n\'est pas le votre ',
pDelete_domain_alias_error => 'Ce domaine n\'est pas le votre ',
pDelete_alias_error => 'Impossible d\'effacer cet alias ',
pCreate_alias_domain_welcome => 'Les adresses mirroirs de l\'un de vos domaines vers un autre.',
pCreate_alias_domain_alias => 'Alias Domaine',
pCreate_alias_domain_alias_text => 'Le domaine dans lequel les courriels viennent.',
pCreate_alias_domain_target => 'Domaine Cible',
pCreate_alias_domain_target_text => 'Le domaine o� les mails doivent aller.',
pCreate_alias_domain_active => 'Activé',
pCreate_alias_domain_button => 'Ajouter un Alias de Domaine',
pCreate_alias_domain_error1 => 'Vous n\'etes pas autorisé a créer la configuration choisie.',
pCreate_alias_domain_error2 => 'La configuration choisie est invalide, merci d\'en choisir une autre!',
pCreate_alias_domain_error3 => 'Insertion dans la base de donnée échouée.',
pCreate_alias_domain_error4 => 'Tous les domaines sont déj� liés � un alias.',
pCreate_alias_domain_success => 'L\'alias de domaine est déj� pr�sent dans la table de domaine!',
pCreate_alias_welcome => 'Créer un nouvel alias pour votre domaine.',
pCreate_alias_address => 'Alias',
pCreate_alias_address_text_error1 => 'Cet ALIAS n\'est pas valide!',
pCreate_alias_address_text_error2 => 'Ce compte courriel existe déjà, choisissez un autre libellé !',
pCreate_alias_address_text_error3 => 'Vous avez atteint votre limite d\'alias créés !',
pCreate_alias_goto => 'À',
pCreate_alias_active => 'Activé',
pCreate_alias_button => 'Ajouter un alias',
pCreate_alias_goto_text => 'Destinataires des courriels.',
pCreate_alias_goto_text_error => 'le champ À contient des erreurs!',
pCreate_alias_result_error => 'Impossible d\'ajouter cet alias dans la table !',
pCreate_alias_result_success => 'L\'alias a été ajouté !',
pCreate_alias_catchall_text => 'Pour ajouter un alias global, utilisez "*". Pour un transfert de domaine à domaine, utilisez "*@domain.tld" dans le champs A.',
pEdit_alias_welcome => 'Modifier un alias dans votre domaine.<br>Une entrée par ligne.',
pEdit_alias_address => 'Alias',
pEdit_alias_address_error => 'Impossible de localiser l\'alias!',
pEdit_alias_goto => 'À',
pEdit_alias_active => 'Activé',
pEdit_alias_goto_text_error1 => 'Vous devez entrer quelques choses dans le champ À',
pEdit_alias_goto_text_error2 => 'L\'adresse courriel que vous avez entré est invalide: ',
pEdit_alias_domain_error => 'Ce domaine n\'est pas le votre: ',
pEdit_alias_domain_result_error => 'Impossible de modifier cet alias de domaine!',
pEdit_alias_forward_and_store => 'Transferer une copie.',
pEdit_alias_forward_only => 'Transferer les messages sans conserver de copie.',
pEdit_alias_button => 'Modifier cet alias',
pEdit_alias_result_error => 'Impossible de modifier cet alias!',
pCreate_mailbox_welcome => 'Ajouter un nouveau compte courriel à votre domaine.',
pCreate_mailbox_username => 'Nom d\'utilisateur',
pCreate_mailbox_username_text_error1 => 'L\'adresse courriel est invalide!',
pCreate_mailbox_username_text_error2 => 'Ce compte courriel existe deja ! Entrez une autre adresse courriel !',
pCreate_mailbox_username_text_error3 => 'Vous avez atteint le nombre maximum de compte courriel !',
pCreate_mailbox_password => 'Mot de passe',
pCreate_mailbox_password2 => 'Mot de passe (confirmation)',
pCreate_mailbox_password_text => 'Mot de passe pour compte POP3/IMAP',
pCreate_mailbox_password_text_error => 'Les mots de passe ne correspondent pas ! ou sont vide !',
pCreate_mailbox_name => 'Nom',
pCreate_mailbox_name_text => 'Nom complet',
pCreate_mailbox_quota => 'Limite',
pCreate_mailbox_quota_text => 'MB',
pCreate_mailbox_quota_text_error => 'La limite que vous avez specifie est trop haute!',
pCreate_mailbox_active => 'Actif',
pCreate_mailbox_mail => 'Envoyer le message de bienvenue',
pCreate_mailbox_button => 'Ajouter le compte courriel',
pCreate_mailbox_result_error => 'Impossible d\'ajouter un compte courriel dans la table!',
pCreate_mailbox_result_success => 'Le compte courriel a été ajouté!',
pCreate_mailbox_result_succes_nosubfolders => 'Le compte courriel a été ajouté à la table, mais un ou plusieurs dossiers prédéfinis n\'ont pu être créés !',
pEdit_mailbox_welcome => 'Modifier un compte courriel.',
pEdit_mailbox_username => 'Nom d\'utilisateur',
pEdit_mailbox_username_error => 'Impossible de localiser le compte courriel!',
pEdit_mailbox_password => 'Nouveau mot de passe',
pEdit_mailbox_password2 => 'Nouveau mot de passe (confirmation)',
pEdit_mailbox_password_text_error => 'Le mot de passe entré ne correspond pas!',
pEdit_mailbox_name => 'Nom',
pEdit_mailbox_name_text => 'Nom complet',
pEdit_mailbox_quota => 'Limite',
pEdit_mailbox_quota_text => 'MB',
pEdit_mailbox_quota_text_error => 'La limite fournit est trop haute!',
pEdit_mailbox_domain_error => 'Ce domaine n\'est pas le votre: ',
pEdit_mailbox_button => 'Modifier un compte courriel',
pEdit_mailbox_result_error => 'Impossible de modifier le compte courriel !',
pPassword_welcome => 'Changer votre mot de passe.',
pPassword_admin => 'Entrer',
pPassword_admin_text_error => 'Les informations entrées ne correspondent pas a un compte courriel!',
pPassword_password_current => 'Mot de passe actuel',
pPassword_password_current_text_error => 'Vous n\'avez pas fournit le mot de passe actuel !',
pPassword_password => 'Nouveau mot de passe',
pPassword_password2 => 'Nouveau mot de passe (confirmation)',
pPassword_password_text_error => 'Le mot de passe fournit ne correspond pas! Ou est vide!',
pPassword_button => 'Changer le mot de passe',
pPassword_result_error => 'Impossible de changer votre mot de passe!',
pPassword_result_success => 'Votre mot de passe a été change!',
pEdit_vacation_set => 'Modifier le message',
pEdit_vacation_remove => 'Effacer le message',
pVacation_result_error => 'Impossible de mettre à jour les réglages du répondeur!',
pVacation_result_removed => 'Le répondeur a été désactivé!',
pVacation_result_added => 'Le répondeur a été activé!',
pViewlog_welcome => 'Visualiser les 10 dernières action pour ',
pViewlog_timestamp => 'Date/Heure',
pViewlog_username => 'Administrateur',
pViewlog_domain => 'Domaine',
pViewlog_action => 'Action',
pViewlog_data => 'Information',
pViewlog_action_create_mailbox => 'créer un compte courriel',
pViewlog_action_delete_mailbox => 'supprimer un compte courriel',
pViewlog_action_edit_mailbox => 'éditer un compte courriel',
pViewlog_action_edit_mailbox_state => 'activer un compte courriel',
pViewlog_action_create_alias => 'créer un alias',
pViewlog_action_create_alias_domain => 'créer un alias de domaine',
pViewlog_action_delete_alias => 'supprimer un alias',
pViewlog_action_delete_alias_domain => 'supprimer un alias de domaine',
pViewlog_action_edit_alias => 'éditer un alias',
pViewlog_action_edit_alias_state => 'activer un alias',
pViewlog_action_edit_alias_domain_state => 'editer alias de domaine actif',
pViewlog_action_edit_password => 'changer le mot de passe',
pViewlog_button => 'Aller',
pViewlog_result_error => 'Impossible de trouver le journal des événements!',
pSendmail_welcome => 'Envoyer un courriel.',
pSendmail_admin => 'De',
pSendmail_to => 'À',
pSendmail_to_text_error => 'À est vide ou ce n\'est pas une adresse courriel valide!',
pSendmail_subject => 'Sujet',
pSendmail_subject_text => 'Bienvenue',
pSendmail_body => 'Message',
pSendmail_button => 'Envoyer le message',
pSendmail_result_error => 'Erreur lors de l\'envoit du message!',
pSendmail_result_success => 'Le message a été envoyé!',
pAdminMenu_list_admin => 'Liste Administrateurs',
pAdminMenu_list_domain => 'Liste Domaines',
pAdminMenu_list_virtual => 'Liste Virtuels',
pAdminMenu_viewlog => 'Visualiser événements',
pAdminMenu_backup => 'Sauvegarde',
pAdminMenu_create_domain_admins => 'Administrateurs de domaines',
pAdminMenu_create_admin => 'Nouvel administrateur',
pAdminMenu_create_domain => 'Nouveau domaine',
pAdminMenu_create_alias => 'Ajouter un Alias',
pAdminMenu_create_mailbox => 'Ajouter un compte courriel',
pAdminList_admin_domain => 'Domaine',
pAdminList_admin_username => 'Administrateur',
pAdminList_admin_count => 'Domaines',
pAdminList_admin_modified => 'Dernière modification',
pAdminList_admin_active => 'Actif',
pAdminList_domain_domain => 'Domaine',
pAdminList_domain_description => 'Description',
pAdminList_domain_aliases => 'Alias',
pAdminList_domain_mailboxes => 'Comptes courriels',
pAdminList_domain_maxquota => 'Limite maximum (MB)',
pAdminList_domain_transport => 'Transport',
pAdminList_domain_backupmx => 'MX Backup',
pAdminList_domain_modified => 'Dernière modification',
pAdminList_domain_active => 'Actif',
pAdminList_virtual_button => 'Aller',
pAdminList_virtual_welcome => 'Vue générale pour ',
pAdminList_virtual_alias_alias_count => 'Alias',
pAdminList_virtual_alias_mailbox_count => 'Comptes courriels',
pAdminList_virtual_alias_address => 'De',
pAdminList_virtual_alias_goto => 'À',
pAdminList_virtual_alias_modified => 'Dernière modification',
pAdminList_virtual_mailbox_username => 'Adresse courriel',
pAdminList_virtual_mailbox_name => 'Nom',
pAdminList_virtual_mailbox_quota => 'Limite (MB)',
pAdminList_virtual_mailbox_modified => 'Dernière modification',
pAdminList_virtual_mailbox_active => 'Actif',
pAdminCreate_domain_welcome => 'Ajouter un nouveau domaine',
pAdminCreate_domain_domain => 'Domaine',
pAdminCreate_domain_domain_text_error => 'Le domaine existe déjà!',
pAdminCreate_domain_domain_text_error2 => 'Le domaine est non valide!',
pAdminCreate_domain_description => 'Description',
pAdminCreate_domain_aliases => 'Alias',
pAdminCreate_domain_aliases_text => '-1 = désactivé | 0 = illimité',
pAdminCreate_domain_mailboxes => 'Comptes courriels',
pAdminCreate_domain_mailboxes_text => '-1 = désactivé | 0 = illimité',
pAdminCreate_domain_maxquota => 'Limite maximum',
pAdminCreate_domain_maxquota_text => 'MB  -1 = désactivé | 0 = illimité',
pAdminCreate_domain_transport => 'Transport',
pAdminCreate_domain_transport_text => 'Definir le transport',
pAdminCreate_domain_defaultaliases => 'Ajouter les alias par défaut',
pAdminCreate_domain_defaultaliases_text => '',
pAdminCreate_domain_backupmx => 'Le serveur est un "backup MX"',
pAdminCreate_domain_button => 'Ajouter un domaine',
pAdminCreate_domain_result_error => 'Impossible d\'ajouter le domaine!',
pAdminCreate_domain_result_success => 'Le domaine a été ajouté!',
pAdminDelete_domain_error => 'Impossible de supprimer le domain!',
pAdminDelete_alias_domain_error => 'Impossible de supprimé cet alias de domaine!',
pAdminEdit_domain_welcome => 'Modifier un domaine',
pAdminEdit_domain_domain => 'Domaine',
pAdminEdit_domain_description => 'Description',
pAdminEdit_domain_aliases => 'Alias',
pAdminEdit_domain_aliases_text => '-1 = désactivé | 0 = illimité',
pAdminEdit_domain_mailboxes => 'Comptes courriels',
pAdminEdit_domain_mailboxes_text => '-1 = désactivé | 0 = illimité',
pAdminEdit_domain_maxquota => 'Limite maximum',
pAdminEdit_domain_maxquota_text => 'MB  -1 = désactivé | 0 = illimité',
pAdminEdit_domain_transport => 'Transport',
pAdminEdit_domain_transport_text => 'Definir le transport',
pAdminEdit_domain_backupmx => 'Le serveur est un "backup MX"',
pAdminEdit_domain_active => 'Actif',
pAdminEdit_domain_button => 'Modifier un domaine',
pAdminEdit_domain_result_error => 'Impossible de modifier le domain!',
pAdminCreate_admin_welcome => 'Ajouter un nouvel administrateur de domaine',
pAdminCreate_admin_username => 'Administrateur',
pAdminCreate_admin_username_text => 'adresse courriel',
pAdminCreate_admin_username_text_error1 => 'Ce n\'est pas une adresse courriel administrateur valide!',
pAdminCreate_admin_username_text_error2 => 'Cet adresse courriel administrateur existe déjà ou n\'est pas valide',
pAdminCreate_admin_password => 'Mot de passe',
pAdminCreate_admin_password2 => 'Mot de passe (confirmation)',
pAdminCreate_admin_password_text_error => 'Le mot de passe fournit ne correspond pas<br> ou est vide!',
pAdminCreate_admin_button => 'Ajouter un administrateur',
pAdminCreate_admin_result_error => 'Impossible d\'ajouter un administrateur!',
pAdminCreate_admin_result_success => 'L\'administrateur a été ajouté!',
pAdminCreate_admin_address => 'Domaine',
pAdminEdit_admin_welcome => 'Modifier un domaine',
pAdminEdit_admin_username => 'Administrateur',
pAdminEdit_admin_password => 'Mot de passe',
pAdminEdit_admin_password2 => 'Mot de passe(confirmation)',
pAdminEdit_admin_password_text_error => 'Le mot de passe fournit ne correspond pas  ou est vide!',
pAdminEdit_admin_active => 'Actif',
pAdminEdit_admin_super_admin => 'Super administrateur',
pAdminEdit_admin_button => 'Modifier l\administrateur',
pAdminEdit_admin_result_error => 'Impossible de modifier l\'administrateur !',
pAdminEdit_admin_result_success => 'L\'administrateur a été ajouté!',
pUsersLogin_welcome => 'Entrer votre adresse courriel pour modifier votre mot de passe et vos transferts.',
pUsersLogin_username => 'Adresse courriel',
pUsersLogin_password => 'Mot de passe',
pUsersLogin_button => 'Entrer',
pUsersLogin_username_incorrect => 'L\'adresse courriel est invalide. Assurez-vous d\'avoir correctement saisie votre adresse courriel!',
pUsersLogin_password_incorrect => 'Votre mot de passe est invalide!',
pUsersMenu_vacation => 'Réponse Automatique',
pUsersMenu_edit_alias => 'Modifier votre transfert',
pUsersMenu_password => 'Modifier votre mot de passe',
pUsersMain_vacation => 'Configurer votre répondeur automatique.',
pUsersMain_vacationSet => 'La Réponse Automatique est activée, cliquer \'Réponse Automatique\' pour modifier/effacer',
pUsersMain_edit_alias => 'Modifier vos transferts de courriel.',
pUsersMain_password => 'Changer votre mot de passe.',
pUsersVacation_welcome => 'Répondeur Automatique.',
pUsersVacation_welcome_text => 'Votre repondeur automatique est déjà configuré!',
pUsersVacation_subject => 'Sujet',
pUsersVacation_subject_text => 'En dehors du bureau',
pUsersVacation_body => 'Message',
pUsersVacation_body_text => 'Je serai absent(e) de <date> jusqu\'au <date>.
Pour toute urgence, merci de contacter <contact person>.',
pUsersVacation_button_away => 'Absence',
pUsersVacation_button_back => 'De retour',
pUsersVacation_result_error => 'Impossible de mettre à jour vos paramètres de réponse automatique!',
pUsersVacation_result_success => 'Votre réponse automatique a été enlevée!',
pUsersVacation_activefrom => 'Active from',
pUsersVacation_activeuntil => 'Active until',
pCreate_dbLog_createmailbox => 'Création de compte',
pCreate_dbLog_createalias => 'Création d\'alias',
pDelete_dbLog_deletealias => 'Suppression d\'alias',
pDelete_dbLog_deletemailbox => 'Suppression de compte',
pEdit_dbLog_editactive => 'Changement du statut d\'activation',
pEdit_dbLog_editalias => 'Modificaton d\'alias',
pEdit_dbLog_editmailbox => 'Modification de compte',
pSearch => 'Rechercher',
pSearch_welcome => 'Recherche : ',
pReturn_to => 'Réponse à',
pBroadcast_title => 'Envoyer un message général',
pBroadcast_from => 'De',
pBroadcast_name => 'Votre nom',
pBroadcast_subject => 'Sujet',
pBroadcast_message => 'Message',
pBroadcast_send => 'Envoyer le message',
pBroadcast_success => 'Votre message général a été envoyé.',
pAdminMenu_broadcast_message => 'message général',
pBroadcast_error_empty => 'Les champs Nom, Sujet et Message ne peuvent pas être vides!',
pStatus_undeliverable => 'Non délivrable ',
pStatus_custom => 'Délivré à ',
pStatus_popimap => 'POP/IMAP ',
pPasswordTooShort => 'Mot de passe trop court. - %s caractères minimum',
pInvalidDomainRegex => 'Nom de Domaine Invalide %s, vérification regexp impossible',
pInvalidDomainDNS => 'Domaine Invalide %s, et/ou non resolvable via les DNS',
pInvalidMailRegex => 'Adresse email invalide, vérification regexp impossible',
pFetchmail_welcome => 'Récupérer le courrier pour :',
pFetchmail_new_entry => 'Nouvelle entrée',
pFetchmail_database_save_error => 'Impossible d\'enregistrer cette entrée dans la base!',
pFetchmail_database_save_success => 'Entrée enregistrée dans la base.',
pFetchmail_error_invalid_id => 'Aucune entrée trouvée avec l\'ID %s!',
pFetchmail_invalid_mailbox => 'Compte courriel incorrect!',
pFetchmail_server_missing => 'Merci d\'entrer le nom du serveur distant!',
pFetchmail_user_missing => 'Merci d\'entrer le nom de l\'utilisateur distant!',
pFetchmail_password_missing => 'Merci d\'entrer le mot de passe distant!',
pFetchmail_field_id => 'ID',
pFetchmail_field_mailbox => 'Compte courriel',
pFetchmail_field_src_server => 'Serveur',
pFetchmail_field_src_auth => 'Type Auth',
pFetchmail_field_src_user => 'Utilisateur',
pFetchmail_field_src_password => 'Mot de passe',
pFetchmail_field_src_folder => 'Dossier',
pFetchmail_field_poll_time => 'Fréquence',
pFetchmail_field_fetchall => 'Tout récupérer',
pFetchmail_field_keep => 'Conserver',
pFetchmail_field_protocol => 'Protocole',
pFetchmail_field_usessl => 'SSL activé',
pFetchmail_field_extra_options => 'Options supplémentaires',
pFetchmail_field_mda => 'MDA',
pFetchmail_field_date => 'Date',
pFetchmail_field_returned_text => 'Message retour',
pFetchmail_desc_id => 'Identifiant',
pFetchmail_desc_mailbox => 'Compte courriel local',
pFetchmail_desc_src_server => 'Serveur distant',
pFetchmail_desc_src_auth => 'Surtout \'password\'',
pFetchmail_desc_src_user => 'Utilisateur distant',
pFetchmail_desc_src_password => 'Mot de passe distant',
pFetchmail_desc_src_folder => 'Dossier distant',
pFetchmail_desc_poll_time => 'Vérifier toutes les ... minutes',
pFetchmail_desc_fetchall => 'Récupérer tous les messages, nouveaux et déjà lus',
pFetchmail_desc_keep => 'Conserver une copie des messages sur le serveur',
pFetchmail_desc_protocol => 'Protocole à utiliser',
pFetchmail_desc_usessl => 'Encryption SSL',
pFetchmail_desc_extra_options => 'Options supplémentaires de Fetchmail',
pFetchmail_desc_mda => 'Mail Delivery Agent',
pFetchmail_desc_date => 'Date dernière vérification/changement configuration',
pFetchmail_desc_returned_text => 'Message dernière vérification',
);
