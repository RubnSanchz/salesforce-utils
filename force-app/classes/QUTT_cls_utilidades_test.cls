/*
 * @name: QUTT_cls_utilidades_test
 * @version: 1.0
 * @creation date: 19/02/2024
 * @author: Rubén Sánchez González
 * @description: Clase de test para QUTT_cls_utilidades
 */
@isTest
public with sharing class QUTT_cls_utilidades_test {
	final static String U_ADM = 'adm_user';
	final static String USER_COORD = 'coordinador_user';
	final static String U_AGENT = 'agente_user';
	final static String U_FAIL = 'unathorized_user';
	final static String ERROR_MESSAGE = 'No se devuelve el resultado esperado';
	final static String EXTERNAL_ID = '012987456';

	final static String HANDLED_EXCEPTION = 'Error. No todos los pedidos pueden ser marcados como urgentes.';

	/**
	 * @creation date:  20/02/2024
	 * @author: Rubén Sánchez González
	 * @description Class setup
	 */
	@TestSetup
	static void setup() {
		User soporteAdm = QUTT_cls_utiles_test.createUserTTSoporte(U_ADM);
		User coordinador = QUTT_cls_utiles_test.createUserTTCoord(USER_COORD);
		User agente = QUTT_cls_utiles_test.createUserTTGenerico(U_AGENT, null);
		User dummyUser = QUTT_cls_utiles_test.createUserWithoutPS(U_FAIL, null);

		System.runAs(soporteAdm) {
			QUTT_cls_utiles_test.createCarterizacion_test(new List<Id>{ coordinador.Id, agente.Id, soporteAdm.Id });
			QUTT_cls_utiles_test.createTareaAllLevels_test(QUTT_cls_constantes.TAREA_TYPE_ZRE, EXTERNAL_ID);
		}

	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método isCoordinadorTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testIsCoordinadorTT() {
		User coordinador = [SELECT Id FROM User WHERE LastName = :USER_COORD];

		Boolean isCoord = false;
		System.runAs(coordinador) {
			Test.startTest();
			isCoord = QUTT_cls_utilidades.isTteTerrestre(coordinador.Id);
			Test.stopTest();
		}

		System.assertEquals(true, isCoord);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método isAgenteTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testIsAgenteTT() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_AGENT];

		Boolean isAgente = false;
		System.runAs(agente) {
			Test.startTest();
			isAgente = QUTT_cls_utilidades.isAgenteTT(agente.Id);
			Test.stopTest();
		}

		System.assertEquals(true, isAgente, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método getUserRole
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetUserRole() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_AGENT];

		String role = '';
		System.runAs(agente) {
			Test.startTest();
			role = QUTT_cls_utilidades.getUserRole(agente.Id);
			Test.stopTest();
		}

		System.assertNotEquals('', role, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método getUserRole
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetUserRoleCatch() {
		User dummyUnatorized = [
			SELECT Id
			FROM User
			WHERE LastName = :U_FAIL
		];

		String role = '';
		System.runAs(dummyUnatorized) {
			Test.startTest();
			role = QUTT_cls_utilidades.getUserRole(dummyUnatorized.Id);
			Test.stopTest();
		}

		System.assert('' != role, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método getUsuariosAsignadosBuzon
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetUsuariosAsignadosBuzon() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];
		QUTT_obj_agrupadorCartera__c agrupador = [
			SELECT Id
			FROM QUTT_obj_agrupadorCartera__c
			LIMIT 1
		];

		List<User> usuarios = new List<User>();
		System.runAs(agente) {
			Test.startTest();
			usuarios = QUTT_cls_utilidades.getUsuariosAsignadosBuzon(agrupador.Id);
			Test.stopTest();
		}
		System.assertEquals(3, usuarios.size(), ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método getUsuariosAsignadosBuzon
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetUsuariosAsignadosBuzonCatch() {
		User dummyUnatorized = [
			SELECT Id
			FROM User
			WHERE LastName = :U_FAIL
		];
		QUTT_obj_agrupadorCartera__c agrupador = [
			SELECT Id
			FROM QUTT_obj_agrupadorCartera__c
			LIMIT 1
		];

		List<User> usuarios = new List<User>();
		System.runAs(dummyUnatorized) {
			Test.startTest();
			usuarios = QUTT_cls_utilidades.getUsuariosAsignadosBuzon(agrupador.Id);
			Test.stopTest();
		}
		System.assertEquals(0, usuarios.size(), ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método getFiltrosBuzonTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetFiltrosBuzonTT() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		List<QUTT_cls_utilidades.FiltroBuzonTT> filtros = new List<QUTT_cls_utilidades.FiltroBuzonTT>();
		System.runAs(agente) {
			Test.startTest();
			filtros = QUTT_cls_utilidades.getFiltrosBuzonTT(agente.Id);
			Test.stopTest();
		}
		System.assertNotEquals(10, filtros.size(), ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getFiltrosBuzonTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetFiltrosBuzonTTCatch() {
		User dummyUnnauthorized = [
			SELECT Id
			FROM User
			WHERE LastName = :U_FAIL
		];

		List<QUTT_cls_utilidades.FiltroBuzonTT> filtros = new List<QUTT_cls_utilidades.FiltroBuzonTT>();
		System.runAs(dummyUnnauthorized) {
			Test.startTest();
			filtros = QUTT_cls_utilidades.getFiltrosBuzonTT(dummyUnnauthorized.Id);
			Test.stopTest();
		}
		System.assertEquals(0, filtros.size(), ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para el método getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetBuzonesTT() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		List<QUTT_obj_agrupadorCartera__c> buzones = new List<QUTT_obj_agrupadorCartera__c>();
		System.runAs(agente) {
			Test.startTest();
			buzones = QUTT_cls_utilidades.getBuzonesTT();
			Test.stopTest();
		}

		System.assertEquals(1, buzones.size(), ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetBuzonesTTCatch() {
		User dummyUnnauthorized = [
			SELECT Id
			FROM User
			WHERE LastName = :U_FAIL
		];

		List<QUTT_obj_agrupadorCartera__c> buzones = new List<QUTT_obj_agrupadorCartera__c>();
		System.runAs(dummyUnnauthorized) {
			Test.startTest();
			buzones = QUTT_cls_utilidades.getBuzonesTT();
			Test.stopTest();
		}
		System.assertEquals(0, buzones.size(), ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testFlagUrgency() {
		final String MOTIVO = 'Bloqueo Pedido';
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		Asset posPedido = [
			SELECT Id
			FROM Asset
			WHERE RQO_fld_idExterno__c != NULL
			LIMIT 1
		];
		System.debug(
			'# posPedido desde test fuera: ' +
			[
				SELECT Id, RQO_fld_posicionPedido__c, RQO_fld_idRelacion__c
				FROM RQO_obj_posiciondeEntrega__c
				LIMIT 1
			]
		);
		Boolean result = false;
		String error = '';
		System.runAs(agente) {
			try {
				System.debug(
					'# posPedido desde test dentro: ' +
					[
						SELECT Id, RQO_fld_posicionPedido__c, RQO_fld_idRelacion__c
						FROM RQO_obj_posiciondeEntrega__c
						LIMIT 1
					]
				);

				Test.startTest();
				result = QUTT_cls_utilidades.flagUrgency(new List<Id>{ posPedido.Id }, MOTIVO, null);
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assert(error != HANDLED_EXCEPTION, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 19/02/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testIsRTCarteraSustitucion() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		Id rtIdSustitucion = Schema.SObjectType.QUSAC_obj_cartera__c.getRecordTypeInfosByDeveloperName()
			.get(QUSAC_cls_constantes.RT_CARTERA_SUSTITUCION)
			.getRecordTypeId();
		Boolean result = false;
		System.runAs(agente) {
			Test.startTest();
			result = QUTT_cls_utilidades.isRTCarteraSustitucion(rtIdSustitucion);
			Test.stopTest();
		}
		System.assert(!result, ERROR_MESSAGE);
	}

	/**
	 * @description Método que comprueba la modificación del estado de una tarea a cerrada.
	 * @author Rubén Sánchez González | 14-03-2024
	 **/
	@isTest
	public static void testSetCierreTarea() {
		QUSAC_obj_tarea__c testTask = [
			SELECT Id
			FROM QUSAC_obj_tarea__c
			LIMIT 1
		];

		Test.startTest();
		QUTT_cls_utilidades.setCierreTarea(new List<Id>{ testTask.Id }, ERROR_MESSAGE);
		Test.stopTest();

		System.assertEquals(0, [SELECT COUNT() FROM REP_obj_errorInfo__c LIMIT 10], 'Se esperaban capturar errore');
	}

	/*
	 * @creation date: 25/03/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testIsValidCarteraTerrestre() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		RQO_obj_posiciondeEntrega__c posEntrega = [
			SELECT
				Id,
				RQO_fld_posicionPedido__r.RQO_fld_centro__c,
				RQO_fld_posicionPedido__r.RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c,
				RQO_fld_idRelacion__c
			FROM RQO_obj_posiciondeEntrega__c
			WHERE RQO_fld_idExterno__c != NULL
			LIMIT 1
		];
		List<QUSAC_obj_cartera__c> carteras = [
			SELECT Id, QUTT_fld_centro__c, QUTT_fld_modoEnvio__c
			FROM QUSAC_obj_cartera__c
			LIMIT 10
		];

		Boolean result = false;
		System.runAs(agente) {
			Test.startTest();
			result = QUTT_cls_utilidades.isValidCarteraTerrestre(posEntrega.RQO_fld_posicionPedido__r, carteras);
			Test.stopTest();
		}
		System.assert(result, 'Se esperaba que cumpliera las condiciones');
	}

	/*
	 * @creation date: 06/05/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testGetCurrentMailbox() {
		User userAdmin = [
			SELECT Id
			FROM User
			WHERE LastName = :U_ADM
		];

		Asset posPedido = [
			SELECT Id
			FROM Asset
			WHERE RQO_fld_idExterno__c != NULL
			LIMIT 1
		];
		String mailbox = '';
		System.runAs(userAdmin) {
			Test.startTest();
			mailbox = QUTT_cls_utilidades.getBuzonTerrestre(posPedido.Id);
			Test.stopTest();
		}
		System.assertNotEquals('', mailbox, 'No se ha detectado el buzón de correo correctamente'); // PALET_PUERTOLLANO
	}

	/*
	 * @creation date: 36/03/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para la excepción catch de getBuzonesTT
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testExceptions() {
		final String MOTIVO = 'Bloqueo Pedido';
		User userUnauthorized = [
			SELECT Id
			FROM User
			WHERE LastName = :U_FAIL
		];

		Asset posPedido = [
			SELECT Id
			FROM Asset
			WHERE RQO_fld_idExterno__c != NULL
			LIMIT 1
		];
		QUSAC_obj_tarea__c testTask = [
			SELECT Id
			FROM QUSAC_obj_tarea__c
			LIMIT 1
		];
		String error = '';
		System.runAs(userUnauthorized) {
			try {
				Test.startTest();
				QUTT_cls_utilidades.flagUrgency(new List<Id>{ posPedido.Id }, MOTIVO, null);
				QUTT_cls_utilidades.setCierreTarea(new List<Id>{ testTask.Id }, ERROR_MESSAGE);
				QUTT_cls_utilidades.isAlbaranesMismoPedido(new List<Id>{ posPedido.Id });
				QUTT_cls_utilidades.getBuzonTerrestre(posPedido.Id);
				QUTT_cls_utilidades.getUserRole(UserInfo.getUserId());
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assertNotEquals(0, [SELECT COUNT() FROM REP_obj_errorInfo__c LIMIT 10], 'Se esperaban capturar errore');
	}

	/*
	 * @creation date: 20/05/2024
	 * @author: Rubén Sánchez González
	 * @description: Test para isAlbaranesMismoPedido
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testIsAlbaranesMismoPedido() {
		Boolean result = false;
		User userAdmin = [
			SELECT Id
			FROM User
			WHERE LastName = :U_ADM
		];
		Asset posPedido = [
			SELECT Id
			FROM Asset
			WHERE RQO_fld_idRelacion__r.RQO_fld_idExterno__c != NULL
			LIMIT 1
		];
		System.runAs(userAdmin) {
			Test.startTest();
			result = QUTT_cls_utilidades.isAlbaranesMismoPedido(new List<Id>{ posPedido.Id, posPedido.Id });
			Test.stopTest();
		}
		System.assertEquals(true, result);
	}
}