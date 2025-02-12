/**
 * @class name        : QUFV_cls_alertasConfig_test
 * @description       : Test class of QUFV_cls_alertasConfig
 * @author            : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
 * @created on        : 27-01-2025
 * @last modified on  : 10-02-2025
 * @last modified by  : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
 **/
@isTest
public with sharing class QUFV_cls_alertasConfig_test {
	private final static String USERALIAS15 = '15QUATD';
	private final static String PROFILE_ESTANDAR = 'Usuario Estándar Química Repsol';
	private final static String QUFV = 'QUFV';
	private final static String PS_GESTOR_CUENTA = 'QUFV_ps_gestorCuenta';
	private static final String PS_CAPACIDADES = 'QUFV_ps_capacidadesQuimica';
	private final static Id ALERT_RT = Schema.SObjectType.QUFV_obj_alertasCliente__c.getRecordTypeInfosByDeveloperName()
		.get(QUFV_cls_constantes.RT_QUFV_ALERT_CONFIG)
		.getRecordTypeId();

	/**
	 * @description Test setup
	 * @author Rubén Sánchez González - ruben.s.gonzalez@accenture.com | 07-02-2025
	 **/
	@TestSetup
	static void setup() {
		User gestorFFVV = QUFV_cls_utiles_test.createTestGestor();
		gestorFFVV.QUFV_fld_codigoGestor__c = QUFV;
		update gestorFFVV;
		Profile perfilStandard = [SELECT Id, Name FROM Profile WHERE Name LIKE :PROFILE_ESTANDAR][0];
		//Selecciono el perfil "System Administrator" para crear los users
		Profile perfilAdm = [
			SELECT Id
			FROM Profile
			WHERE Name IN (:label.QUFV_lbl_nameAdministrator, :label.QUFV_lbl_nombreAdministrador)
		][0];
		//Selecciono el Id del rol Usuario Repsol
		UserRole rolAdm = [
			SELECT Id
			FROM UserRole
			WHERE Name LIKE :label.QUFV_lbl_nameUserRepsol
		][0];
		User tecnicoATD = QUATD_cls_utiles_test.getUser(null, perfilStandard.Id, USERALIAS15);
		User admin = QUFV_cls_utiles_test.createTestUser(rolAdm.Id, perfilAdm.Id);
		Id psGestorCuenta = [SELECT Id FROM PermissionSet WHERE Name = :PS_GESTOR_CUENTA].Id;
		Id psCapacidadId = [SELECT Id FROM PermissionSet WHERE Name = :PS_CAPACIDADES].Id;
		insert new PermissionSetAssignment(AssigneeId = gestorFFVV.Id, PermissionSetId = psGestorCuenta);
		insert new PermissionSetAssignment(AssigneeId = gestorFFVV.Id, PermissionSetId = psCapacidadId);
		System.runAs(gestorFFVV) {
			Account acc = QUFV_cls_utiles_test.createTestAccountRT();
			QUFV_obj_alertasCliente__c alerta1 = QUFV_cls_utiles_test.createAlertas(gestorFFVV, acc);
			QUFV_obj_alertasCliente__c alerta2 = QUFV_cls_utiles_test.createAlertas(gestorFFVV, acc);
			alerta2.QUFV_fld_cuenta__c = null;
			update alerta2;
		}
	}

	/**
	 * @creation date:  27/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Test method getAlertOptions
	 */
	@isTest
	public static void getAlertOptions_test() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];

		List<QUFV_cmt_alertas__mdt> alerts = null;
		System.runAs(usrAux) {
			Test.startTest();
			alerts = QUFV_cls_alertasConfig.getAlertOptions();
			Test.stopTest();
		}

		System.assertNotEquals(null, alerts);
	}

	/**
	 * @creation date:  27/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Test method getAlertUser
	 */
	@isTest
	public static void getAlertUser_test() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		Account acc = [SELECT Id FROM Account WHERE Name = :label.QUFV_lbl_accountName LIMIT 1];

		List<QUFV_obj_alertasCliente__c> alerts = null;
		System.runAs(usrAux) {
			Test.startTest();
			alerts = QUFV_cls_alertasConfig.getAlertUser(acc.Id);
			Test.stopTest();
		}

		System.assertNotEquals(null, alerts);
	}

	/**
	 * @creation date:  27/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Test method updateAlerts
	 */
	@isTest
	public static void updateAlerts_test() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		Account acc = [SELECT Id FROM Account WHERE Name = :label.QUFV_lbl_accountName LIMIT 1];
		List<QUFV_obj_alertasCliente__c> alertsChanged = new List<QUFV_obj_alertasCliente__c>();
		alertsChanged.add(
			new QUFV_obj_alertasCliente__c(
				QUFV_fld_usuario__c = usrAux.Id,
				RecordTypeId = ALERT_RT,
				QUFV_fld_categoria__c = label.QUFV_lbl_alertaCategoriaDeuda,
				QUFV_fld_tipo_alerta__c = label.QUFV_lbl_tipoDeuda30Dias,
				QUFV_fld_cuenta__c = acc.Id,
				QUFV_fld_activo__c = false
			)
		);

		Boolean result = null;
		System.runAs(usrAux) {
			Test.startTest();
			result = QUFV_cls_alertasConfig.updateAlerts(alertsChanged, acc.Id);
			Test.stopTest();
		}

		System.assertEquals(true, result, 'Fallo en la actualización de alertas 01');
	}

	/**
	 * @creation date:  27/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Test method updateAlerts for general alert
	 */
	@isTest
	public static void updateAlerts2_test() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		Account acc = [SELECT Id FROM Account WHERE Name = :label.QUFV_lbl_accountName LIMIT 1];
		List<QUFV_obj_alertasCliente__c> alertsChanged = new List<QUFV_obj_alertasCliente__c>();
		alertsChanged.add(
			new QUFV_obj_alertasCliente__c(
				QUFV_fld_usuario__c = usrAux.Id,
				RecordTypeId = ALERT_RT,
				QUFV_fld_categoria__c = label.QUFV_lbl_alertaCategoriaDeuda,
				QUFV_fld_tipo_alerta__c = label.QUFV_lbl_tipoDeuda30Dias,
				QUFV_fld_activo__c = false
			)
		);

		Boolean result = null;
		System.runAs(usrAux) {
			Test.startTest();
			result = QUFV_cls_alertasConfig.updateAlerts(alertsChanged, null);
			Test.stopTest();
		}

		System.assertEquals(true, result, 'Fallo en la actualización de alertas 02');
	}

	/**
	 * @creation date:  27/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Test method that checks the exceptions are handled correctly
	 */
	@isTest
	public static void exceptions_test() {
		User userUnauthorized = [SELECT Id FROM User WHERE Alias = :USERALIAS15 LIMIT 1];
		Account acc = [SELECT Id FROM Account WHERE Name = :label.QUFV_lbl_accountName LIMIT 1];
		List<QUFV_obj_alertasCliente__c> alertsChanged = new List<QUFV_obj_alertasCliente__c>();
		alertsChanged.add(
			new QUFV_obj_alertasCliente__c(
				QUFV_fld_usuario__c = userUnauthorized.Id,
				QUFV_fld_categoria__c = label.QUFV_lbl_alertaCategoriaDeuda,
				QUFV_fld_tipo_alerta__c = label.QUFV_lbl_tipoDeuda30Dias,
				QUFV_fld_cuenta__c = acc.Id,
				QUFV_fld_activo__c = false,
				RecordTypeId = Schema.SObjectType.QUFV_obj_alertasCliente__c.getRecordTypeInfosByDeveloperName()
					.get(QUFV_cls_constantes.RT_QUFV_ALERT_CONFIG)
					.getRecordTypeId()
			)
		);

		System.runAs(userUnauthorized) {
			Test.startTest();
			QUFV_cls_utiles_test.lanzarExcepcion = true;
			QUFV_cls_alertasConfig.getAlertOptions();
			QUFV_cls_alertasConfig.getAlertUser(acc.Id);
			QUFV_cls_alertasConfig.updateAlerts(alertsChanged, acc.Id);
			Test.stopTest();
		}

		System.assertNotEquals(
			0,
			[SELECT Id FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c = :QUFV].size(),
			'No se ha insertado el error'
		);
	}
}