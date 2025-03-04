/**
 * @name: QUTT_cls_urgenciasGestion_test
 * @creation date:  27/05/2024
 * @author: Rubén Sánchez González
 * @description Clase de test para la clase QUT_cls_urgenciasGestion
 * @testClass QUTT_cls_urgenciasGestion_test_test
 */
@isTest
public with sharing class QUTT_cls_urgenciasGestion_test {
	private static final String CLASS_NAME = 'QUTT_cls_urgenciasGestion_test';
	private static final String U_ADM = 'adm_user';
	private static final String USER_COORD = 'coordinador_user';
	private static final String U_AGENT = 'agente_user';
	private static final String U_FAIL = 'unathorized_user';
	private static final String ERROR_MESSAGE = 'No se devuelve el resultado esperado';
	private static final String EXTERNAL_ID = '012987456';
	private static final String PS_AGENTE_SAC = 'QUSAC_ps_agenteSAC';
	private static final List<String> ALBARANES = new List<String>{ '123456789', '987654321', '456789123' };

	private static final String HANDLED_EXCEPTION = 'Error. No todos los pedidos pueden ser marcados como urgentes.';

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
		QUTT_cls_utiles_test.assignPermisionSet(soporteAdm.Id, PS_AGENTE_SAC, false);

		System.runAs(soporteAdm) {
			QUTT_cls_utiles_test.createCarterizacion_test(new List<Id>{ coordinador.Id, agente.Id, soporteAdm.Id });
			QUTT_cls_utiles_test.createPedidoAllLevels_test(EXTERNAL_ID);
		}
	}

	/*
	 * @creation date: 27/05/2024
	 * @author: Rubén Sánchez González González
	 * @description: Test para la funcionalidad principal flagUrgency
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testFlagUrgency() {
		final String MOTIVO = 'QUTT_falloCargaTransporte';
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		String error = '';
		System.runAs(agente) {
			Asset posPedido = [
				SELECT Id
				FROM Asset
				WHERE RQO_fld_idExterno__c != NULL
				LIMIT 1
			];
			try {
				Test.startTest();
				QUTT_cls_urgenciasGestion.flagUrgency(new List<Id>{ posPedido.Id }, MOTIVO, null, CLASS_NAME);
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assert(error != HANDLED_EXCEPTION, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 27/05/2024
	 * @author: Rubén Sánchez González González
	 * @description: Test para la funcionalidad principal flagUrgency que además crea tarea
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testFlagUrgencyConSalida() {
		final String MOTIVO = 'QUTT_falloCargaTransporte';
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		String error = '';
		System.runAs(agente) {
			try {
				Asset posPedido = [
					SELECT Id, RQO_fld_idExterno__c
					FROM Asset
					WHERE RQO_fld_idExterno__c != NULL
					LIMIT 1
				];
				RQO_obj_pedido__c pedido = [
					SELECT Id
					FROM RQO_obj_pedido__c
					WHERE RQO_fld_idExterno__c != NULL
					LIMIT 1
				];
				pedido.QUSAC_fld_salidaMercancias__c = true;
				update pedido;

				Test.startTest();
				QUTT_cls_urgenciasGestion.flagUrgency(new List<Id>{ posPedido.Id }, MOTIVO, null, CLASS_NAME);
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assert(error != HANDLED_EXCEPTION, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 27/05/2024
	 * @author: Rubén Sánchez González González
	 * @description: Test para la funcionalidad principal flagUrgency que además crea tarea
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testCreateTextoUrgByStatus() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		String error = '';
		System.runAs(agente) {
			try {
				List<Asset> posPedido = [
					SELECT Id, RQO_fld_idExterno__c
					FROM Asset
					WHERE RQO_fld_idExterno__c != NULL
				];
				QUTT_obj_solicitud__c solicitud = QUTT_cls_utiles_test.createSolicitud(posPedido);

				Test.startTest();
				QUTT_cls_urgenciasGestion.createTextoUrgByStatus(new List<String>{ solicitud.Id });
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assert(error != HANDLED_EXCEPTION, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 27/05/2024
	 * @author: Rubén Sánchez González González
	 * @description: Test para la funcionalidad principal flagUrgency que además crea tarea
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testCreateTextoUrgEnCurso() {
		User agente = [SELECT Id FROM User WHERE LastName = :U_ADM];

		String error = '';
		System.runAs(agente) {
			try {
				List<Asset> posPedido = [
					SELECT Id, RQO_fld_idExterno__c
					FROM Asset
					WHERE RQO_fld_idExterno__c != NULL
				];
				QUTT_obj_solicitud__c solicitud = QUTT_cls_utiles_test.createSolicitud(posPedido);
				solicitud.QUTT_fld_estadoSolicitud__c = QUTT_cls_constantes.STATUS_URGENCIA_00;
				update solicitud;

				Test.startTest();
				QUTT_cls_urgenciasGestion.createTextoUrgByStatus(new List<String>{ solicitud.Id });
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assert(error != HANDLED_EXCEPTION, ERROR_MESSAGE);
	}

	/*
	 * @creation date: 27/05/2024
	 * @author: Rubén Sánchez González González
	 * @description: Test para comprobar que se lanzan y capturan excepciones correctamente.
	 * @return: N/A
	 * @throws: N/A
	 */
	@isTest
	static void testExcepciones() {
		final String MOTIVO = 'QUTT_falloCargaTransporte';
		User dummyUnatorized = [
			SELECT Id
			FROM User
			WHERE LastName = :U_FAIL
		];

		List<Asset> posPedidos = [
			SELECT Id, RQO_fld_idExterno__c
			FROM Asset
			WHERE RQO_fld_idExterno__c != NULL
		];
		QUTT_obj_solicitud__c solicitud = QUTT_cls_utiles_test.createSolicitud(posPedidos);

		String error = '';
		System.runAs(dummyUnatorized) {
			try {
				Test.startTest();
				QUTT_cls_urgenciasGestion.createTextoUrgByStatus(new List<String>{ solicitud.Id });
				QUTT_cls_urgenciasGestion.flagUrgency(new List<Id>{ posPedidos[0].Id }, MOTIVO, null, CLASS_NAME);
				QUTT_cls_urgenciasGestion.createTarea(solicitud, posPedidos, ALBARANES);
				QUTT_cls_urgenciasGestion.createSolicitud(
					posPedidos,
					QUTT_cls_constantes.STATUS_URGENCIA_01,
					QUTT_cls_constantes.MOTIVO_QUTT_01,
					null,
					CLASS_NAME
				);
				Test.stopTest();
			} catch (Exception e) {
				error = e.getMessage();
			}
		}
		System.assert(
			0 !=
			[
				SELECT COUNT()
				FROM REP_obj_errorInfo__c
				WHERE REP_fld_codigoAplicacion__c = :QUTT_cls_constantes.QUTT
			],
			ERROR_MESSAGE
		);
	}
}