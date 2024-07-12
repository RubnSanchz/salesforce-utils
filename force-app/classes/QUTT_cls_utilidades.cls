/**
 * @class name        : QUTT_cls_utilidades
 * @description       : Clase auxiliar para la gestión de componentes genéricos y utilidades comunes.
 * @author            : Rubén Sánchez González
 * @created on        : 05-02-2024
 * @last modified on  : 04-07-2024
 * @last modified by  : Rubén Sánchez González
 * @test class        : QUTT_cls_utilidades_test
 **/
public with sharing class QUTT_cls_utilidades {
	final static String CLASS_NAME = 'QUTT_cls_utilidades';

	/**
	 * @creation date:  05/02/2024
	 * @author: Rubén Sánchez
	 * @description Comprueba está dentro de la jerarquía de Transporte Terrestre
	 * @param Id userId
	 * @return Boolean
	 */
	@AuraEnabled(cacheable=true)
	public static Boolean isTteTerrestre(Id userId) {
		final String METHOD = 'isTteTerrestre';
		System.debug(CLASS_NAME + ' - ' + METHOD);
		return isCoordinadorTT(userId) || isAgenteTT(userId);
	}

	/**
	 * @creation date:  05/02/2024
	 * @author: Rubén Sánchez
	 * @description Comprueba si el usuario es Coordinador de Transporte Terrestre
	 * @param Id userId
	 * @return Boolean
	 */
	@AuraEnabled
	public static Boolean isCoordinadorTT(Id userId) {
		final String METHOD = 'isCoordinadorTT';
		System.debug(CLASS_NAME + ' - ' + METHOD);
		return getUserRole(userId) == QUTT_cls_constantes.ROLE_COORDINADOR;
	}

	/**
	 * @creation date:  05/02/2024
	 * @author: Rubén Sánchez
	 * @description Comprueba si el usuario es Agente de Transporte Terrestre
	 * @param Id userId
	 * @return Boolean
	 */
	@AuraEnabled
	public static Boolean isAgenteTT(Id userId) {
		final String METHOD = 'isAgenteTT';
		System.debug(CLASS_NAME + ' - ' + METHOD);
		return getUserRole(userId) == QUTT_cls_constantes.ROLE_AGENTE;
	}

	/**
	 * @creation date:  05/02/2024
	 * @author: Rubén Sánchez
	 * @description Recupera el rol del usuario pasado como parámetro. Por defecto el usuario conectado
	 * @param Id userId
	 * @return String
	 */
	public static String getUserRole(Id userId) {
		final String METHOD = 'getUserRole';
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		String userRole = '';
		try {
			Id userIdControl = userId != null ? userId : UserInfo.getUserId();

			if (!User.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(QUTT_cls_excepction.UNNACCESIBLE);
			}
			// Check userId role
			userRole = [
				SELECT Id, UserRole.DeveloperName
				FROM User
				WHERE Id = :userIdControl
			][0]
			.UserRole.DeveloperName;
		} catch (Exception e) {
			System.debug(QUTT_cls_constantes.ERROR_TAG + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
			throw new AuraHandledException(QUTT_cls_excepction.UNNACCESIBLE);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN ' + userRole);
		return userRole;
	}

	/**
	 * @creation date:  13/02/2024
	 * @author: Rubén Sánchez
	 * @description Recupera los usuarios asignados a un buzon
	 * @param Id userId
	 * @return List<String>
	 */
	@AuraEnabled
	public static List<User> getUsuariosAsignadosBuzon(Id buzonId) {
		final String METHOD = 'getBuzonesAsignados';
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		List<User> usuariosAsignados = new List<User>();
		try {
			if (!QUTT_obj_agrupadorPorUser__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(QUTT_cls_excepction.UNNACCESIBLE);
			}
			// Loop through the buzones assigned by buzon Name
			for (QUTT_obj_agrupadorPorUser__c buzonAsignado : [
				SELECT Id, Name, QUTT_fld_user__r.Name, QUTT_fld_user__r.Id, QUTT_fld_user__r.Email, QUTT_fld_user__c
				FROM QUTT_obj_agrupadorPorUser__c
				WHERE QUTT_fld_agrupadorCartera__c = :buzonId
			]) {
				usuariosAsignados.add(buzonAsignado.QUTT_fld_user__r);
			}
		} catch (Exception e) {
			System.debug(QUTT_cls_constantes.ERROR_TAG + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.FIN);
		return usuariosAsignados;
	}

	/**
	 * @creation date:  13/02/2024
	 * @author: Rubén Sánchez
	 * @description Recupera los buzones asignados a un usuario
	 * @param Id userId
	 * @return List<String>
	 */
	@AuraEnabled
	public static List<Id> getBuzonesAsignados(Id userId) {
		final String METHOD = 'getBuzonesAsignados';
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		List<Id> buzonesAsignados = new List<Id>();
		try {
			Id userIdControl = userId != null ? userId : UserInfo.getUserId();

			if (!QUTT_obj_agrupadorPorUser__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(QUTT_cls_excepction.UNNACCESIBLE);
			}
			// Loop through the buzones assigned to the user
			for (QUTT_obj_agrupadorPorUser__c buzonAsignado : [
				SELECT Id, name, QUTT_fld_agrupadorCartera__r.Id, QUTT_fld_agrupadorCartera__r.Name
				FROM QUTT_obj_agrupadorPorUser__c
				WHERE QUTT_fld_user__c = :userIdControl
			]) {
				buzonesAsignados.add(buzonAsignado.QUTT_fld_agrupadorCartera__r.Id);
			}
		} catch (Exception e) {
			System.debug(QUTT_cls_constantes.ERROR_TAG + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.FIN);
		return buzonesAsignados;
	}

	/**
	 * @creation date:  13/02/2024
	 * @author: Rubén Sánchez
	 * @description
	 * @param Id userId
	 * @return List<FiltroBuzonTT>
	 */
	@AuraEnabled(cacheable=true)
	public static List<FiltroBuzonTT> getFiltrosBuzonTT(Id userId) {
		final String METHOD = 'getFiltrosBuzonTT';
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		List<FiltroBuzonTT> filtros = new List<FiltroBuzonTT>();
		try {
			List<Id> buzonesAsignados = getBuzonesAsignados(userId);

			// Get the list of buzones
			if (!QUTT_obj_agrupadorCartera__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUTT_obj_agrupadorCartera__c.sObjectType.getDescribe().getName()
				);
			}
			List<QUTT_obj_agrupadorCartera__c> buzones = [
				SELECT Id, Name, QUTT_fld_email__c
				FROM QUTT_obj_agrupadorCartera__c
			];
			System.debug(CLASS_NAME + ' - ' + METHOD + ': buzones ' + buzones.size());

			Map<String, List<QUSAC_obj_cartera__c>> mapCarteras = new Map<String, List<QUSAC_obj_cartera__c>>();
			for (QUSAC_obj_cartera__c cartera : getAllCarterasTerrestre()) {
				if (!mapCarteras.containsKey(cartera.QUTT_fld_buzonTerrestre__c)) {
					mapCarteras.put(cartera.QUTT_fld_buzonTerrestre__c, new List<QUSAC_obj_cartera__c>{ cartera });
				} else {
					mapCarteras.get(cartera.QUTT_fld_buzonTerrestre__c).add(cartera);
				}
			}
			System.debug(CLASS_NAME + ' - ' + METHOD + ': mapCarteras ' + mapCarteras);
			System.debug(CLASS_NAME + ' - ' + METHOD + ': buzones ' + buzones);

			for (QUTT_obj_agrupadorCartera__c buzon : buzones) {
				Map<String, List<String>> centroModo = new Map<String, List<String>>();
				for (QUSAC_obj_cartera__c cartera : mapCarteras.get(buzon.Name)) {
					if (!centroModo.containsKey(cartera.QUTT_fld_centro__c)) {
						centroModo.put(cartera.QUTT_fld_centro__c, new List<String>{ cartera.QUTT_fld_modoEnvio__c });
					} else {
						centroModo.get(cartera.QUTT_fld_centro__c).add(cartera.QUTT_fld_modoEnvio__c);
					}
				}
				filtros.add(new FiltroBuzonTT(buzon.Name, centroModo, buzonesAsignados.contains(buzon.Id)));
			}
			System.debug(CLASS_NAME + ' - ' + METHOD + ': filtros ' + filtros.size());
		} catch (Exception e) {
			System.debug(QUTT_cls_constantes.ERROR_TAG + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.FIN);
		return filtros;
	}

	/**
	 * @creation date:  06/02/2024
	 * @author: Rubén Sánchez
	 * @description
	 * @param
	 * @return List<QUTT_obj_agrupadorCartera__c>
	 */
	@AuraEnabled(cacheable=true)
	public static List<QUTT_obj_agrupadorCartera__c> getBuzonesTT() {
		final String METHOD = 'getBuzonesTT';
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		List<QUTT_obj_agrupadorCartera__c> buzones = new List<QUTT_obj_agrupadorCartera__c>();
		try {
			if (!QUTT_obj_agrupadorCartera__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUTT_obj_agrupadorCartera__c.sObjectType.getDescribe().getName()
				);
			}
			// Get the list of buzones
			buzones = [
				SELECT Id, Name, QUTT_fld_email__c
				FROM QUTT_obj_agrupadorCartera__c
			];
		} catch (Exception e) {
			System.debug(QUTT_cls_constantes.ERROR_TAG + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.FIN);
		return buzones;
	}

	/**
	 * @creation date:  11/03/2024
	 * @author: Rubén Sánchez
	 * @description Marca como urgente los pedidos seleccionados
	 * @param List<Id> assetIds
	 * @return Boolean
	 */
	@AuraEnabled(cacheable=false) // if cacheable=true it impacts number of DML
	public static Boolean flagUrgency(List<Id> assetIds, String motivoUrgencia, Date fechaEntrega) {
		final String METHOD = 'flagUrgency';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');
		final String HANDLED_EXCEPTION = 'Error. No todos los pedidos pueden ser marcados como urgentes.';

		Boolean allFlagged = true;
		List<Asset> posPedidos = new List<Asset>();
		List<RQO_obj_posiciondeEntrega__c> posEntregasValidas = new List<RQO_obj_posiciondeEntrega__c>();
		List<RQO_obj_entrega__c> entregasToUpdate = new List<RQO_obj_entrega__c>();
		List<QUSAC_obj_tarea__c> tareasURG = new List<QUSAC_obj_tarea__c>();
		List<QUSAC_obj_cartera__c> carteras = getAllCarterasTerrestre();
		try {
			// To be defined again

			if (!QUSAC_obj_tarea__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUSAC_obj_tarea__c.sObjectType.getDescribe().getName()
				);
			}
			Integer tareas = [
				SELECT COUNT()
				FROM QUSAC_obj_tarea__c
				WHERE
					QUSAC_fld_posicionPedido__r.Id IN :assetIds
					AND QUSAC_fld_tipologia__c = :QUTT_cls_constantes.TAREA_TYPE_URG
					AND QUSAC_fld_statusTarea__c != :QUSAC_cls_constantes.TAREA_CERRADA
			];

			if (!allFlagged || tareas > 0 || posEntregasValidas.isEmpty()) {
				System.debug('Encontradas posEntregas ' + posEntregasValidas.size());
				System.debug('Encontradas tareas ' + tareas);
				allFlagged = false;
				throw new AuraHandledException(HANDLED_EXCEPTION);
			}

			if (!entregasToUpdate.isEmpty()) {
				System.debug(CLASS_NAME + ' - ' + METHOD + ': Updating ' + entregasToUpdate.size() + ' entregas');
				update entregasToUpdate;
			}

			if (!tareasURG.isEmpty()) {
				System.debug(CLASS_NAME + ' - ' + METHOD + ': Inserting ' + tareasURG.size() + ' tareas');
				insert tareasURG;
			}
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		} finally {
			System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN - allFlagged: ' + allFlagged);
		}
		return allFlagged;
	}

	/**
	 * @creation date:  22/03/2024
	 * @author: Rubén Sánchez
	 * @description
	 * @param Asset posPedido
	 * @param List<QUSAC_obj_cartera__c> carteras
	 * @return Boolean
	 */
	public static Boolean isValidCarteraTerrestre(Asset posPedido, List<QUSAC_obj_cartera__c> carteras) {
		final String METHOD = 'isValidCarteraTerrestre';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		Boolean isValid = false;
		for (QUSAC_obj_cartera__c cartera : carteras) {
			if (
				cartera.QUTT_fld_centro__c == posPedido.RQO_fld_centro__c &&
				cartera.QUTT_fld_modoEnvio__c == posPedido.RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c
			) {
				isValid = true;
				break;
			}
		}

		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN ' + posPedido.Id + '- isValid: ' + isValid);
		return isValid;
	}

	/**
	 * @creation date:  14/03/2024
	 * @author: Rubén Sánchez
	 * @description Re
	 * @param
	 * @return List<QUSAC_obj_cartera__c>
	 */
	public static List<QUSAC_obj_cartera__c> getAllCarterasTerrestre() {
		final String METHOD = 'getAllCarterasTerrestre';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		List<QUSAC_obj_cartera__c> carteras = new List<QUSAC_obj_cartera__c>();
		try {
			if (!QUSAC_obj_cartera__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUSAC_obj_cartera__c.sObjectType.getDescribe().getName()
				);
			}
			carteras = [
				SELECT Id, Name, QUTT_fld_modoEnvio__c, QUTT_fld_centro__c, QUTT_fld_buzonTerrestre__c
				FROM QUSAC_obj_cartera__c
				WHERE RecordTypeId = :QUTT_cls_constantes.RT_CARTERA_TT_ID
			];
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
		return carteras;
	}

	/**
	 * @description  Método que cierra las tareas y guarga el comentario
	 * @author: Rubén Sánchez González | 14-03-2024
	 * @param List<Id> tasksIds
	 * @param String closingComment
	 * @return List<QUSAC_obj_tarea__c>
	 **/
	@auraEnabled
	public static List<QUSAC_obj_tarea__c> setCierreTarea(List<Id> tasksIds, String closingComment) {
		final String METHOD = 'setCierreTarea';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');
		List<QUSAC_obj_tarea__c> tareas = new List<QUSAC_obj_tarea__c>();

		try {
			if (
				!QUSAC_obj_tarea__c.sObjectType.getDescribe().isAccessible() ||
				!QUSAC_obj_tarea__c.sObjectType.getDescribe().isUpdateable()
			) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUSAC_obj_tarea__c.sObjectType.getDescribe().getName()
				);
			}
			tareas = [
				SELECT Id, QUSAC_fld_statusTarea__c, QUTT_fld_solicitud__c
				FROM QUSAC_obj_tarea__c
				WHERE Id IN :tasksIds
			];
			List<Id> solicitudes = new List<Id>();
			for (QUSAC_obj_tarea__c tarea : tareas) {
				tarea.QUSAC_fld_statusTarea__c = QUSAC_cls_constantes.TAREA_CERRADA;
				tarea.QUSAC_fld_comentario__c = closingComment;
				solicitudes.add(tarea.QUTT_fld_solicitud__c);
			}
			update tareas;

			String textoMonitor = QUTT_cls_constantes.TEXTO_CIERRE_URG_MANUAL
				.replace(QUTT_cls_constantes.USER_NAME_INPUT, UserInfo.getName())
				.replace(QUTT_cls_constantes.MOTIVO_INPUT, closingComment);
			List<String> posPedidosIds = new List<String>();
			if (!QUTT_obj_agrupadorSolicitudes__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(QUTT_cls_excepction.UNNACCESIBLE);
			}
			for (QUTT_obj_agrupadorSolicitudes__c groupSolicitud : [
				SELECT Id, QUTT_fld_posicionPedido__c
				FROM QUTT_obj_agrupadorSolicitudes__c
				WHERE QUTT_fld_solicitud__c IN :solicitudes
			]) {
				posPedidosIds.add(groupSolicitud.QUTT_fld_posicionPedido__c);
			}

			QUSAC_cls_textosMonitor.addTextos(
				QUTT_cls_constantes.TEXTO_MONITOR_URGENCIA_TYPE,
				textoMonitor,
				posPedidosIds
			);
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + QUSAC_cls_constantes.COLON_SPACE + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}

		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
		return tareas;
	}

	/**
	 * @creation date:  12/03/2024
	 * @author: Rubén Sánchez
	 * @description Comprueba si el RT recibido pertenece a sustituciones de Cartera o no
	 * @param Id rtId
	 * @return Boolean
	 */
	@AuraEnabled
	public static Boolean isRTCarteraSustitucion(Id rtId) {
		final String METHOD = 'isRTCarteraSustitucion';
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		Id rtTransporteTerrestre = QUTT_cls_constantes.RT_CARTERA_TT_ID;
		Boolean notSustitucion = rtTransporteTerrestre == rtId;

		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.FIN);
		return notSustitucion;
	}

	/**
	 * @creation date:  25/04/2024
	 * @author: Rubén Sánchez
	 * @description Gets the mailbox of the current group of asset (first of them)
	 * @param Id assetId
	 * @return String
	 */
	@AuraEnabled
	public static String getBuzonTerrestre(Id assetId) {
		final String METHOD = 'getBuzonTerrestre';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		String buzon = '';
		Id recordId = null;
		try {
			if (
				!Asset.sObjectType.getDescribe().isAccessible() ||
				!QUSAC_obj_tarea__c.sObjectType.getDescribe().isAccessible()
			) {
				throw new QUTT_cls_excepction.PermissionException(QUTT_cls_excepction.UNNACCESIBLE);
			}

			if (assetId.getSObjectType() != Schema.Asset.SObjectType) {
				// The ID is from a QUSAC_obj_tarea__c
				recordId = [SELECT QUSAC_fld_posicionPedido__c FROM QUSAC_obj_tarea__c WHERE Id = :assetId LIMIT 1]
					?.get(0)
					?.QUSAC_fld_posicionPedido__c;
			} else {
				// The ID is from an Asset
				recordId = assetId;
			}

			List<Asset> assetPedido = [
				SELECT RQO_fld_centro__c, RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c
				FROM Asset
				WHERE Id = :recordId
				LIMIT 1
			];
			if (assetPedido.size() > 0) {
				String centro = assetPedido[0].RQO_fld_centro__c;
				String condicionExpedicion = assetPedido[0].RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c;
				List<QUSAC_obj_cartera__c> cartera = [
					SELECT QUTT_fld_buzonTerrestre__c
					FROM QUSAC_obj_cartera__c
					WHERE QUTT_fld_centro__c = :centro AND QUTT_fld_modoEnvio__c = :condicionExpedicion
					LIMIT 1
				];
				if (cartera.size() > 0) {
					buzon = cartera[0].QUTT_fld_buzonTerrestre__c;
				}
			}
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
		return buzon;
	}

	/**
	 * @creation date:  06/05/2024
	 * @author: Ignacio Sánchez Rodríguez
	 * @description Comprueba que los albaranes pertencen al mismo pedido
	 * @param Lista de Id de assets
	 * @return Boolean
	 */
	@AuraEnabled
	public static Boolean isAlbaranesMismoPedido(List<Id> assetIds) {
		final String METHOD = 'isAlbaranesMismoPedido';
		Boolean result = false;
		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.INICIO);

		try {
			if (!assetIds.isEmpty() && Schema.sObjectType.Asset.isAccessible()) {
				Set<String> assetsSet = new Set<String>();
				for (Asset asset : [
					SELECT Id, RQO_fld_idRelacion__r.RQO_fld_idExterno__c
					FROM Asset
					WHERE Id IN :assetIds
				]) {
					assetsSet.add(asset.RQO_fld_idRelacion__r.RQO_fld_idExterno__c);
				}
				if (assetsSet.size() == 1) {
					result = true;
				}
			}
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + QUSAC_cls_constantes.COLON_SPACE + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}

		System.debug(CLASS_NAME + ' - ' + METHOD + QUTT_cls_constantes.FIN);
		return result;
	}

	////////////////////////////////////////////// WRAPPER CLASSES //////////////////////////////////////////////
	/**
	 * @name: FiltroBuzonTT
	 * @creation date:  13/02/2024
	 * @author: Rubén Sánchez
	 * @description Wrapper para la gestión de filtros de buzones
	 * @testClass QUTT_cls_utilidades_test
	 */
	public with sharing class FiltroBuzonTT {
		@AuraEnabled
		public String name { get; set; }
		@AuraEnabled
		public List<CentroModoWrapper> filtros { get; set; }
		@AuraEnabled
		public Boolean checked { get; set; }

		/**
		 * @creation date:  13/02/2024
		 * @author: Rubén Sánchez
		 * @description Constructor de Wrapper. Recibe un par de String centro y modoEnvio
		 * @param String centro
		 * @param String modoEnvio
		 */
		public FiltroBuzonTT(String name, Map<String, List<String>> centroModoMap, Boolean checked) {
			this.name = name;
			this.checked = checked;
			this.filtros = new List<CentroModoWrapper>();
			for (String centro : centroModoMap.keySet()) {
				this.filtros.add(new CentroModoWrapper(centro, centroModoMap.get(centro)));
			}
		}
	}

	/**
	 * @name: FiltroBuzonTT
	 * @creation date:  13/02/2024
	 * @author: Rubén Sánchez
	 * @description Wrapper para la gestión de filtros de buzones
	 * @testClass QUTT_cls_utilidades_test
	 */
	public with sharing class CentroModoWrapper {
		@AuraEnabled
		public String centro { get; set; }
		@AuraEnabled
		public List<String> modosDeEnvio { get; set; }

		/**
		 * @creation date:  13/02/2024
		 * @author: Rubén Sánchez
		 * @description Constructor de Wrapper. Recibe un par de String centro y modoEnvio
		 * @param String centro
		 * @param String modoEnvio
		 */
		public CentroModoWrapper(String centro, List<String> modosDeEnvio) {
			this.centro = centro;
			this.modosDeEnvio = modosDeEnvio;
		}
	}
}