/**
 * @class name        : REP_cls_listViewEnhanced
 * @description       : Clase estándar para la recuperación de datos para el componente rep_lwc_listViewEnhanced
 * @author            : Rubén Sánchez González
 * @created on        : 30-09-2022
 * @last modified on  : 05-10-2022
 * @last modified by  : Rubén Sánchez González
**/
public with sharing class REP_cls_listViewEnhanced {
    private static final String CLASS_NAME = 'REP_cls_listViewEnhanced';

    /**
    * @creation date: 30/09/2022
    * @author: Rubén Sánchez González
    * @description Recupera la configuración de campos establecida por un proyecto y objeto
    * @param String objectFrom
    * @param String projectVisibility
    * @return List<REP_cmt_listViewEnhanced__mdt>
    */
    public static Map<String,REP_cmt_listViewEnhanced__mdt> getProjectMetadata(String objectFrom, String projectVisibility) {
        final String METHOD = 'getProjectMetadata';
        System.debug(CLASS_NAME+ ' - ' + METHOD + ': INICIO');  

        Map<String,REP_cmt_listViewEnhanced__mdt> mapMetadatas = new Map<String,REP_cmt_listViewEnhanced__mdt>();

        projectVisibility = REP_cls_constantes.PORCENTAJE + projectVisibility + REP_cls_constantes.PORCENTAJE;
        for (REP_cmt_listViewEnhanced__mdt metaRecord : [SELECT Id, DeveloperName, MasterLabel, Language, NamespacePrefix, Label, QualifiedApiName, REP_fld_objectFrom__c,
                REP_fld_field__c, REP_fld_allowAsFilter__c, REP_fld_projectVisibility__c, REP_fld_linkable__c, REP_fld_linkPath__c, REP_fld_linkField__c, REP_fld_linkObject__c
            FROM REP_cmt_listViewEnhanced__mdt WHERE REP_fld_objectFrom__c=:objectFrom AND REP_fld_projectVisibility__c LIKE: projectVisibility]) {
            mapMetadatas.put(metaRecord.QualifiedApiName, metaRecord);
        }

        System.debug(CLASS_NAME+ ' - ' + METHOD + ': FIN');
        return mapMetadatas;
    }

    /**
    * @creation date: 30/09/2022
    * @author: Rubén Sánchez González
    * @description Recupera la configuración y orden de campos elegidos por un usuario
    * @param String objectFrom
    * @param String projectVisibility
    * @return List<REP_obj_userListViewConfig__c>
    */
    public static List<REP_obj_userListViewConfig__c> getUserPreferences(String objectFrom) {
        final String METHOD = 'getColumns';
        System.debug(CLASS_NAME+ ' - ' + METHOD + ': INICIO');  

        List<REP_obj_userListViewConfig__c> userSelection = new List<REP_obj_userListViewConfig__c>();

        SObjectType sObjType = ((SObject) Type.forName(objectFrom).newInstance()).getSObjectType();
        try {
            if (!sObjType.getDescribe().isAccessible()) {
                throw new PermissionException('Sin permisos sobre el objeto '+objectFrom);
            }

            userSelection = [SELECT Id, REP_fld_field__c, REP_fld_value__c, RecordType.Name
                FROM REP_obj_userListViewConfig__c WHERE REP_fld_objectFrom__c=:objectFrom AND IsDeleted=false ORDER BY REP_fld_order__c ASC];

        } catch(Exception excep) {
            System.debug('ERROR at '+excep.getLineNumber()+' - '+excep.getMessage());
            REP_cls_errorHandler.insertErrorNoFuture(REP_cls_constantes.APP_NAME, Datetime.now(), UserInfo.getName(), CLASS_NAME, METHOD, excep.getMessage(),excep.getStackTraceString());
        } 

        System.debug(CLASS_NAME+ ' - ' + METHOD + ': FIN');
        return userSelection;
    }

    /**
    * @creation date: 30/09/2022
    * @author: Rubén Sánchez González
    * @description Recupera los campos elegidos por un usuario y habilitados por cierto proyecto
    * @param String objectFrom
    * @param String projectVisibility
    * @return List<REP_cmt_listViewEnhanced__mdt>
    */
    public static List<REP_cmt_listViewEnhanced__mdt> getCommonColumns(String objectFrom, String projectVisibility) {
        final String METHOD = 'getCommonColumns';
        System.debug(CLASS_NAME+ ' - ' + METHOD + ': INICIO');  

        List<REP_cmt_listViewEnhanced__mdt> userSelectionFiltered = new List<REP_cmt_listViewEnhanced__mdt>();
        
        try {
            SObjectType sObjType = ((SObject) Type.forName(objectFrom).newInstance()).getSObjectType();
            if (!sObjType.getDescribe().isAccessible()) {
                throw new PermissionException('Sin permisos sobre el objeto '+objectFrom);
            }
            Map<String,REP_cmt_listViewEnhanced__mdt> mapMetadatas = new Map<String,REP_cmt_listViewEnhanced__mdt>();
            List<REP_obj_userListViewConfig__c> userSelection = new List<REP_obj_userListViewConfig__c>();

            mapMetadatas = getProjectMetadata(objectFrom, projectVisibility);
            userSelection = getUserPreferences(objectFrom);

            for (REP_obj_userListViewConfig__c selection :userSelection) {
                if (mapMetadatas.containsKey(selection.REP_fld_field__c)) {
                    userSelectionFiltered.add( mapMetadatas.get(selection.REP_fld_field__c) );
                }                    
            }

        } catch(Exception excep) {
            System.debug('ERROR at '+excep.getLineNumber()+' - '+excep.getMessage());
            REP_cls_errorHandler.insertErrorNoFuture(REP_cls_constantes.APP_NAME, Datetime.now(), UserInfo.getName(), CLASS_NAME, METHOD, excep.getMessage(),excep.getStackTraceString());
        } 

        System.debug(CLASS_NAME+ ' - ' + METHOD + ': FIN');
        return userSelectionFiltered;
    }


    /**
     * @description: Excepción por falta de permisos del usuario sobre el objeto indicado
     * @author: Rubén Sánchez González
     **/
    public class PermissionException extends Exception {}

}