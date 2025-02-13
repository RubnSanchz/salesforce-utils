/**
 * @class name        : Capacidad_test
 * @description       : Test class for QUFV_cls_capacidad
 * @author            : Rubén Sánchez González
 * @created on        : 24-10-2024
 * @last modified on  : 19-12-2024
 * @last modified by  : Rubén Sánchez González
 **/
@isTest
public with sharing class Capacidad_test {
	private final static String CLASS_NAME = 'Capacidad_test';

	private final static String CAPACIDAD_JSON = '{"Id":null,"QUFV_fld_account__c":"%%cliente%%","QUFV_fld_year__c":"2023","QUFV_fld_family__c":"PP","QUFV_fld_anualConsumption__c":"1234","QUFV_fld_competitors__c":"Comp1","QUFV_fld_lastModifiedDate__c":"2024-01-15","QUFV_fld_comments__c":"Comm1"}';
	private final static String CAPACIDAD_JSON2 = '{"Id":null,"QUFV_fld_account__c":"%%cliente%%","QUFV_fld_year__c":"2023","QUFV_fld_family__c":"PEL","QUFV_fld_anualConsumption__c":"1234","QUFV_fld_competitors__c":"Comp1","QUFV_fld_lastModifiedDate__c":"2024-01-15","QUFV_fld_comments__c":"Comm1"}';
	private final static String PATTERN_CLI = '%%cliente%%';
	private final static String ERROR_MESSAGE = 'No se devuelve el resultado esperado';
	private final static String USERALIAS15 = '15QUATD';
	private final static String PROFILE_ESTANDAR = 'Usuario Estándar Química Repsol';
	private final static String QUFV = 'QUFV';
	private final static String NAME_CAPACIDAD = '10411-2023-PP';
	private final static String NAME_CAPACIDAD2 = '10411-2023-PEL';
	private final static String FAMILY = 'PP';
	private final static String FAMILY2 = 'PEL';
	private final static Id RT_POLIOLEFINAS = Schema.SObjectType.QUFV_obj_capacidad__c.getRecordTypeInfosByDeveloperName()
		.get('QUFV_rt_capacidadPoliolefinas')
		.getRecordTypeId();
	private static final String PS_CAPACIDADES = 'QUFV_ps_capacidadesQuimica';

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Class setup
	 */
	@TestSetup
	static void setup() {
		User gestorFFVV = QUFV_cls_utiles_test.createTestGestor();
		List<profile> perfiles = [SELECT Id, Name FROM Profile WHERE Name LIKE :PROFILE_ESTANDAR];
		Profile perfil = null;
		if (!perfiles.isEmpty()) {
			perfil = perfiles[0];
		}
		User tecnicoATD = QUATD_cls_utiles_test.getUser(null, perfil.Id, USERALIAS15);
		Id psCapacidadId = [SELECT Id FROM PermissionSet WHERE Name = :PS_CAPACIDADES].Id;
		insert new PermissionSetAssignment(AssigneeId = gestorFFVV.Id, PermissionSetId = psCapacidadId);
		System.runAs(gestorFFVV) {
			Account client = QUFV_cls_utiles_test.createTestAccount();
			QUATD_cls_utiles_test.getAccount();
			List<QUFV_obj_capacidad__c> capacidades = new List<QUFV_obj_capacidad__c>();
			capacidades.add(
				new QUFV_obj_capacidad__c(
					Name = NAME_CAPACIDAD,
					QUFV_fld_idExterno__c = NAME_CAPACIDAD,
					QUFV_fld_year__c = 2023,
					QUFV_fld_family__c = FAMILY,
					QUFV_fld_account__c = client.Id,
					RecordTypeId = RT_POLIOLEFINAS
				)
			);
			capacidades.add(
				new QUFV_obj_capacidad__c(
					Name = NAME_CAPACIDAD2,
					QUFV_fld_idExterno__c = NAME_CAPACIDAD2,
					QUFV_fld_year__c = 2023,
					QUFV_fld_family__c = FAMILY2,
					QUFV_fld_account__c = client.Id,
					RecordTypeId = RT_POLIOLEFINAS
				)
			);
			insert capacidades;

			RQO_obj_qp0Grade__c grado = new RQO_obj_qp0Grade__c(RQO_fld_jerarquiaDeProducto__c = 'R1PPPPXXXX');
			insert grado;
			RQO_obj_qp0Grade__c grado2 = new RQO_obj_qp0Grade__c(
				RQO_fld_jerarquiaDeProducto__c = 'R1PEPLXXXX',
				RQO_fld_descripcionDelGrado__c = 'METALOCENO TEST'
			);
			insert grado2;
			List<QUFV_obj_ventasFacturadas__c> ventas = new List<QUFV_obj_ventasFacturadas__c>();
			ventas.add(
				new QUFV_obj_ventasFacturadas__c(
					QUFV_fld_cantidadVenta__c = 1000,
					QUFV_fld_fechaVenta__c = Date.newInstance(2023, 2, 1),
					QUFV_fld_cliente__c = client.Id,
					QUFV_fld_grado__c = grado.Id
				)
			);
			ventas.add(
				new QUFV_obj_ventasFacturadas__c(
					QUFV_fld_cantidadVenta__c = 1000,
					QUFV_fld_fechaVenta__c = Date.newInstance(2023, 2, 1),
					QUFV_fld_cliente__c = client.Id,
					QUFV_fld_grado__c = grado2.Id
				)
			);
			insert ventas;
		}
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for getCapacidades method
	 */
	@isTest
	static void testGetCapacidades() {
		Account cuenta = [SELECT Id FROM Account LIMIT 1];
		List<QUFV_obj_capacidad__c> capacidades = new List<QUFV_obj_capacidad__c>();
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];

		System.runAs(usrAux) {
			Test.startTest();
			capacidades = QUFV_cls_capacidad.getCapacidades(cuenta.Id);
			Test.stopTest();
		}

		System.assertNotEquals(0, capacidades.size(), ERROR_MESSAGE);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for upsertCapacidad method
	 */
	@isTest
	static void testUpsertCapacidad() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		QUFV_obj_capacidad__c capacidad = [
			SELECT
				Id,
				Name,
				QUFV_fld_idExterno__c,
				QUFV_fld_account__c,
				QUFV_fld_year__c,
				QUFV_fld_family__c,
				QUFV_fld_anualConsumption__c,
				QUFV_fld_competitors__c,
				QUFV_fld_lastModifiedDate__c,
				QUFV_fld_comments__c
			FROM QUFV_obj_capacidad__c
			WHERE QUFV_fld_family__c = :FAMILY
		];

		System.runAs(usrAux) {
			Test.startTest();
			QUFV_cls_capacidad.upsertCapacidad(JSON.serialize(capacidad));
			Test.stopTest();
		}

		System.assert(
			10 > [SELECT Id FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c = :QUFV].size(),
			ERROR_MESSAGE
		);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for upsertCapacidad method
	 */
	@isTest
	static void testUpsertCapacidad2() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		QUFV_obj_capacidad__c capacidad = [
			SELECT
				Id,
				Name,
				QUFV_fld_idExterno__c,
				QUFV_fld_account__c,
				QUFV_fld_year__c,
				QUFV_fld_family__c,
				QUFV_fld_anualConsumption__c,
				QUFV_fld_competitors__c,
				QUFV_fld_lastModifiedDate__c,
				QUFV_fld_comments__c
			FROM QUFV_obj_capacidad__c
			WHERE QUFV_fld_family__c = :FAMILY2
		];

		System.runAs(usrAux) {
			Test.startTest();
			QUFV_cls_capacidad.upsertCapacidad(JSON.serialize(capacidad));
			Test.stopTest();
		}

		System.assert(
			10 > [SELECT Id FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c = :QUFV].size(),
			ERROR_MESSAGE
		);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for insertCapacidad method
	 */
	@isTest
	static void testInsertCapacidad() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		Account cuenta = [SELECT Id FROM Account LIMIT 1];
		String jsonParams = CAPACIDAD_JSON.replace(PATTERN_CLI, cuenta.Id);

		System.runAs(usrAux) {
			Test.startTest();
			QUFV_cls_capacidad.insertCapacidad(jsonParams);
			Test.stopTest();
		}

		List<QUFV_obj_capacidad__c> capacidades = [SELECT Id FROM QUFV_obj_capacidad__c];
		System.assert(1 < capacidades.size(), ERROR_MESSAGE);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for insertCapacidad method
	 */
	@isTest
	static void testInsertCapacidadPEL() {
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		Account cuenta = [SELECT Id FROM Account LIMIT 1];
		String jsonParams = CAPACIDAD_JSON2.replace(PATTERN_CLI, cuenta.Id);

		System.runAs(usrAux) {
			Test.startTest();
			QUFV_cls_capacidad.insertCapacidad(jsonParams);
			Test.stopTest();
		}

		List<QUFV_obj_capacidad__c> capacidades = [SELECT Id FROM QUFV_obj_capacidad__c];
		System.assert(1 < capacidades.size(), ERROR_MESSAGE);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for deleteCapacidad method
	 */
	@isTest
	static void testDeleteCapacidad() {
		QUFV_obj_capacidad__c capacidad = [SELECT Id FROM QUFV_obj_capacidad__c LIMIT 1];
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		System.runAs(usrAux) {
			Test.startTest();
			QUFV_cls_capacidad.deleteCapacidad(capacidad.Id);
			Test.stopTest();
		}

		List<QUFV_obj_capacidad__c> capacidades = [
			SELECT Id
			FROM QUFV_obj_capacidad__c
			WHERE Id = :capacidad.Id
			LIMIT 1
		];
		System.assertEquals(0, capacidades.size(), ERROR_MESSAGE);
	}

	/**
	 * @creation date: 28/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for deleteAll method
	 */
	@isTest
	static void testDeleteAll() {
		QUFV_obj_capacidad__c capacidad = [
			SELECT QUFV_fld_year__c, QUFV_fld_family__c, QUFV_fld_account__c
			FROM QUFV_obj_capacidad__c
			LIMIT 1
		];
		User usrAux = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];
		System.runAs(usrAux) {
			Test.startTest();
			QUFV_cls_capacidad.deleteAll(
				Integer.valueOf(capacidad.QUFV_fld_year__c),
				capacidad.QUFV_fld_family__c,
				capacidad.QUFV_fld_account__c
			);
			Test.stopTest();
		}

		List<QUFV_obj_capacidad__c> capacidades = [
			SELECT Id
			FROM QUFV_obj_capacidad__c
			WHERE Id = :capacidad.Id
			LIMIT 1
		];
		System.assertEquals(0, capacidades.size(), ERROR_MESSAGE);
	}

	/**
	 * @creation date: 12/11/2024
	 * @author: Rubén Sánchez González
	 * @description: Test for updateVentasYear method
	 */
	@isTest
	static void testUpdateVentasYear() {
		User gestorFFVV = [SELECT Id FROM User WHERE Email = :label.QUFV_lbl_email LIMIT 1];

		System.runAs(gestorFFVV) {
			Test.startTest();
			QUFV_cls_ventasFacturadas.updateVentasYear(2023);
			Test.stopTest();
		}
		System.assert(
			0 == [SELECT Id FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c = :QUFV].size(),
			ERROR_MESSAGE
		);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for check that exceptions are tracked
	 */
	@isTest
	static void testUnautorized() {
		QUFV_obj_capacidad__c capacidad = [
			SELECT Id, QUFV_fld_year__c, QUFV_fld_family__c, QUFV_fld_account__c
			FROM QUFV_obj_capacidad__c
			LIMIT 1
		];
		User userUnauthorized = [SELECT Id FROM User WHERE Alias = :USERALIAS15 LIMIT 1];
		Account cuenta = [SELECT Id FROM Account LIMIT 1];
		String jsonParams = CAPACIDAD_JSON.replace(PATTERN_CLI, cuenta.Id);
		System.runAs(userUnauthorized) {
			try {
				Test.startTest();
				QUFV_cls_ventasFacturadas.updateVentasYear(2023);
				QUFV_cls_ventasFacturadas.getVentasFacturadas(capacidad, false);
				QUFV_cls_capacidad.getCapacidades(cuenta.Id);
				QUFV_cls_capacidad.upsertCapacidad(JSON.serialize(capacidad));
				QUFV_cls_capacidad.insertCapacidad(jsonParams);
				QUFV_cls_capacidad.deleteCapacidad(capacidad.Id);
				QUFV_cls_capacidad.deleteAll(
					Integer.valueOf(capacidad.QUFV_fld_year__c),
					capacidad.QUFV_fld_family__c,
					capacidad.QUFV_fld_account__c
				);
				Test.stopTest();
			} catch (Exception e) {
				System.debug(e.getLineNumber() + QUFV_cls_constantes.DASH_SEPARATOR_SPACE + e.getMessage());
				REP_cls_errorHandler.insertErrorNoFuture(
					label.QUFV_lbl_code,
					Datetime.now(),
					UserInfo.getName(),
					CLASS_NAME,
					'',
					e.getMessage(),
					e.getStackTraceString()
				);
			}
		}

		QUFV_obj_capacidad__c updatedCapacidad = [
			SELECT QUFV_fld_anualConsumption__c
			FROM QUFV_obj_capacidad__c
			WHERE Id = :capacidad.Id
			LIMIT 1
		];
		System.assertNotEquals(
			0,
			[SELECT Id FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c = :QUFV].size(),
			ERROR_MESSAGE
		);
	}

	/**
	 * @creation date: 24/10/2024
	 * @author: Rubén Sánchez González
	 * @description Test for check that exceptions are tracked
	 */
	@isTest
	static void testUnautorized2() {
		QUFV_obj_capacidad__c capacidad = [
			SELECT Id, QUFV_fld_year__c, QUFV_fld_family__c, QUFV_fld_account__c
			FROM QUFV_obj_capacidad__c
			LIMIT 1
		];
		User userUnauthorized = [SELECT Id FROM User WHERE Alias = :USERALIAS15 LIMIT 1];
		Account cuenta = [SELECT Id FROM Account LIMIT 1];
		String jsonParams = CAPACIDAD_JSON.replace(PATTERN_CLI, cuenta.Id);
		System.runAs(userUnauthorized) {
			try {
				Test.startTest();
				QUFV_cls_capacidad.getCapacidades(cuenta.Id);
				QUFV_cls_capacidad.upsertCapacidad(JSON.serialize(capacidad));
				QUFV_cls_capacidad.insertCapacidad(jsonParams);
				QUFV_cls_capacidad.deleteCapacidad(capacidad.Id);
				QUFV_cls_capacidad.deleteAll(
					Integer.valueOf(capacidad.QUFV_fld_year__c),
					capacidad.QUFV_fld_family__c,
					capacidad.QUFV_fld_account__c
				);
				Test.stopTest();
			} catch (Exception e) {
				System.debug(e.getLineNumber() + QUFV_cls_constantes.DASH_SEPARATOR_SPACE + e.getMessage());
				REP_cls_errorHandler.insertErrorNoFuture(
					label.QUFV_lbl_code,
					Datetime.now(),
					UserInfo.getName(),
					CLASS_NAME,
					'',
					e.getMessage(),
					e.getStackTraceString()
				);
			}
		}

		QUFV_obj_capacidad__c updatedCapacidad = [
			SELECT QUFV_fld_anualConsumption__c
			FROM QUFV_obj_capacidad__c
			WHERE Id = :capacidad.Id
			LIMIT 1
		];
		System.assertNotEquals(
			0,
			[SELECT Id FROM REP_obj_errorInfo__c WHERE REP_fld_codigoAplicacion__c = :QUFV].size(),
			ERROR_MESSAGE
		);
	}
}