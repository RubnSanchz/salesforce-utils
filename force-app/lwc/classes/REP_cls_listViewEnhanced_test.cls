/**
 * @class name        : REP_cls_listViewEnhanced_test
 * @description       : Clase test para comprobar la correcta funcionalidad de REP_cls_listViewEnhanced
 * @author            : Rubén Sánchez González
 * @created on        : 04-10-2022
 * @last modified on  : 13-10-2022
 * @last modified by  : Rubén Sánchez González
**/
@isTest
public with sharing class REP_cls_listViewEnhanced_test {
    
    final static String ROLE_NAME = 'Central España y Francia';
    final static String PROJECT = 'CPSVA';
    final static String USER1 = 'listViewEnhanced1@testorg.com';
    final static String USER2 = 'listViewEnhanced2@testorg.com';
    final static String PROFILE2 = 'Usuario Estándar';

    /**
    * @creation date:  05/10/2022
    * @author: Rubén Sánchez
    * @description Class setup
    */
    @TestSetup
    static void setup(){
        User user1 = REP_cls_dataFactoryCompo_utils.userCreation(USER1, REP_cls_constantes.USER_PROFILE_NAME, 
                ROLE_NAME, REP_cls_constantes.LOCALE, REP_cls_constantes.LOCALE_SID_KEY, REP_cls_constantes.TIME_ZONE_SID_KEY);
        User user2 = REP_cls_dataFactoryCompo_utils.userCreation(USER2, PROFILE2, 
                ROLE_NAME, REP_cls_constantes.LOCALE, REP_cls_constantes.LOCALE_SID_KEY, REP_cls_constantes.TIME_ZONE_SID_KEY);
        System.runAs(user1){
            REP_cls_dataFactoryCompo_utils.createUserListView(1);
            REP_cls_dataFactoryCompo_utils.createUserListView(2);
            
        }
    }

    /**
    * @creation date:  05/10/2022
    * @author: Rubén Sánchez
    * @description Prueba el método sendData recibiendo un listado de visitas
    */
    @isTest
    public static void getCommonColumns_test(){
        User usrAux = [SELECT Id FROM User WHERE UserName =: USER1 LIMIT 1];
        System.runAs(usrAux){
            Test.startTest();
            REP_cls_listViewEnhanced.getCommonColumns(REP_cls_constantes.ACCOUNT,PROJECT);
            Test.stopTest();
        }
        System.assertEquals(0, [SELECT count() FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c=: REP_cls_constantes.APP_NAME]);
    }

    /**
    * @creation date:  05/10/2022
    * @author: Rubén Sánchez
    * @description Prueba el método sendData recibiendo un listado de visitas
    */
    @isTest
    public static void exceptions_test(){
        User usrAux = [SELECT Id FROM User WHERE UserName =: USER2 LIMIT 1];
        System.runAs(usrAux){
            Test.startTest();
            REP_cls_listViewEnhanced.getCommonColumns(REP_cls_constantes.ACCOUNT,PROJECT);
            Test.stopTest();
        }
        System.assertNotEquals(0, [SELECT count() FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c=: REP_cls_constantes.APP_NAME]);
    }
    
    /**
    * @creation date:  05/10/2022
    * @author: Rubén Sánchez
    * @description Prueba el método sendData recibiendo un listado de visitas
    */
    @isTest
    public static void exceptions2_test(){
        User usrAux = [SELECT Id FROM User WHERE UserName =: USER2 LIMIT 1];
        System.runAs(usrAux){
            Test.startTest();
            REP_cls_listViewEnhanced.getUserPreferences(REP_cls_constantes.ACCOUNT);
            Test.stopTest();
        }
        System.assertNotEquals(0, [SELECT count() FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c=: REP_cls_constantes.APP_NAME]);
    }
    
}