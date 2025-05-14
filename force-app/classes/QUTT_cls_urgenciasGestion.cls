/**
 * @name: QUTT_cls_urgenciasGestion
 * @creation date:  22/05/2024
 * @author: Rubén Sánchez González
 * @description Clase para gestionar las urgencias de los pedidos
 * @testClass QUTT_cls_urgenciasGestion_test
 */
public with sharing class QUTT_cls_urgenciasGestion {
	private static final String CLASS_NAME = 'QUTT_cls_urgenciasGestion';

	private static final String EXCEPTION_1 = 'La clase de pedido seleccionado no puede ser ZPM.';
	private static final String EXCEPTION_2 = 'Al menos uno de los pedidos seleccionados no es gestionado por el equipo de Transporte Terrestre.';
	private static final String EXCEPTION_3 = 'Los pedidos seleccionados deben tener un mismo albarán o agrupación común.';
	private static final String EXCEPTION_4 = 'Los pedidos seleccionados no son de agrupación, deben solicitarse urgencias por separado.';
	private static final String EXCEPTION_5 = 'Alguno de los pedidos seleccionados tiene un bloqueo vigente por lo que no se puede solicitar la urgencia.';
	private static final String EXCEPTION_6 = 'Alguno de los pedidos seleccionados tiene un Incoterm inválido para Transporte Terrestre: ';
	private static final String EXCEPTION_7 = 'Alguno de los pedidos seleccionados tiene un transportista inválido para Transporte Terrestre: ';
	private static final String EXCEPTION_8 = 'Alguno de los pedidos seleccionados ya ha sido entregado.';
	private static final String EXCEPTION_9 = 'Alguno de los pedidos seleccionados ya tiene una solicitud de urgencia abierta.';

	private static final String ZPM = 'ZPM';

	private static final String OVERRIDE_1 = '{_idSolicitud}';
	private static final String OVERRIDE_2 = '{_nombreSolicitud}';
	private static final String OVERRIDE_3 = '{_motivo}';
	private static final String OVERRIDE_4 = '{_comentario}';

	private static final Map<String, String> MAP_URGENCY_TYPES = new Map<String, String>{
		'QUTT_urgenciaAdelantoCliente' => 'URG_01',
		'QUTT_retrasoAdministrativo' => 'URG_02',
		'QUTT_bloqueoCredito' => 'URG_03',
		'QUTT_faltaStock' => 'URG_04',
		'QUTT_falloCargaTransporte' => 'URG_05'
	};
	private static final Map<String, String> MAP_URGENCY_LABELS_TYPES = new Map<String, String>{
		'Urgencia/Adelanto Cliente' => 'URG_01',
		'Retraso Administrativo' => 'URG_02',
		'Bloqueo Crédito' => 'URG_03',
		'Falta Stock' => 'URG_04',
		'Fallo en Carga/Transporte' => 'URG_05'
	};

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Marca como urgente los pedidos seleccionados
	 * @param List<Id> assetIds
	 * @param String motivoUrgencia
	 * @param Date fechaEntrega
	 * @param String comentario
	 * @return Id
	 */
	@AuraEnabled(cacheable=false) // if cacheable=true it impacts number of DML
	public static Id flagUrgency(List<Id> assetIds, String motivoUrgencia, Date fechaEntrega, String comentario) {
		final String METHOD = 'flagUrgency';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		List<Asset> posPedidos = new List<Asset>();
		List<RQO_obj_posiciondeEntrega__c> posEntregas = new List<RQO_obj_posiciondeEntrega__c>();
		List<QUSAC_obj_cartera__c> carteras = QUTT_cls_utilidades.getAllCarterasTerrestre();
		List<String> posPedidosIds = new List<String>();
		QUTT_obj_solicitud__c solicitud = new QUTT_obj_solicitud__c();
		List<String> albaranes = new List<String>();

		Savepoint sp = Database.setSavepoint();
		try {
			if (
				!RQO_obj_posiciondeEntrega__c.sObjectType.getDescribe().isAccessible() ||
				!Asset.sObjectType.getDescribe().isUpdateable() ||
				!QUSAC_obj_tarea__c.sObjectType.getDescribe().isCreateable()
			) {
				throw new CustomExcept.PermissionException(
					CustomExcept.UNNACCESIBLE +
						RQO_obj_posiciondeEntrega__c.sObjectType.getDescribe().getName() +
						' ' +
						Asset.sObjectType.getDescribe().getName() +
						' ' +
						QUSAC_obj_tarea__c.sObjectType.getDescribe().getName()
				);
			}

			posPedidos = [
				SELECT
					Id,
					AccountId,
					RQO_fld_centro__c,
					RQO_fld_material__c,
					QUSAC_fld_bloqueosR3__c,
					RQO_fld_idRelacion__r.QUSAC_fld_salidaMercancias__c,
					RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c,
					RQO_fld_idRelacion__r.RQO_fld_incoterm__c,
					RQO_fld_idRelacion__r.RQO_fld_tipodePedido__c,
					RQO_fld_idRelacion__r.QUFV_fld_bloqueo__c,
					QUTT_fld_solicitud__r.QUTT_fld_estadoSolicitud__c,
					RQO_fld_idRelacion__r.RQO_fld_interlocutorRE__c,
					(
						SELECT
							Id,
							RQO_fld_idRelacion__c,
							RQO_fld_idRelacion__r.RQO_fld_fechaRealdeLlegada__c,
							RQO_fld_idRelacion__r.QUTT_fld_codigoTransportista__r.RQO_fld_idExterno__c,
							RQO_fld_posicionPedido__r.RQO_fld_idRelacion__r.RQO_fld_incoterm__c,
							RQO_fld_idRelacion__r.RQO_fld_idExterno__c,
							RQO_fld_idRelacion__r.RQO_fld_numeroExternodeEntrega__c
						FROM Posiciones_de_entrega__r
						WHERE RQO_fld_isDelete__c = FALSE
					)
				FROM Asset
				WHERE Id IN :assetIds
			];

			for (Asset posPedido : posPedidos) {
				posEntregas.addAll(posPedido.Posiciones_de_entrega__r);
				posPedidosIds.add(posPedido.Id);
				for (RQO_obj_posiciondeEntrega__c posEntrega : posPedido.Posiciones_de_entrega__r) {
					albaranes.add(posEntrega.RQO_fld_idRelacion__r.RQO_fld_idExterno__c);
				}
			}

			// Check conditions for to create 'Solicitud de urgencia'
			checkZPM(posPedidos);
			checkAssignableTteTerrestre(posPedidos, carteras);
			checkAllSameAlbaran(posEntregas);
			checkNotAlbaranAndAG(posEntregas, posPedidos);
			checkBlockDelivery(posPedidos);
			checkExcludedIncoterms(posEntregas);
			checkExcludedTransport(posEntregas);
			checkNotDelivered(posEntregas);
			checkNotOpenedRequest(posPedidos);

			// If this point is reached, Solicitud can be created
			System.debug('#### ALL CONDITIONS ARE ACCOMPLISHED ####');

			Boolean tieneSalidaMercancia = posPedidos[0].RQO_fld_idRelacion__r.QUSAC_fld_salidaMercancias__c;
			String statusURG = tieneSalidaMercancia
				? QUTT_cls_constantes.STATUS_URGENCIA_04
				: QUTT_cls_constantes.STATUS_URGENCIA_01;

			// create solicitud and agrupadorSolicitudes records
			solicitud = createSolicitud(posPedidos, statusURG, motivoUrgencia, fechaEntrega, comentario);

			for (Asset posPedido : posPedidos) {
				posPedido.QUTT_fld_solicitud__c = solicitud.Id;
			}
			update posPedidos;

			createTextoMonitor(solicitud, posPedidosIds);

			if (!tieneSalidaMercancia) {
				// Notification for Stock only if they have to approve. Also notify FFVV agents if has alerts active
				createNotificacion(solicitud, posPedidos[0]);
			} else {
				// If not salidaMercancias it creates task automatically. Otherwise it has to be approved by Stock
				createTarea(solicitud, posPedidos, albaranes);
			}
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + ' - ' + e.getMessage());
			Database.rollback(sp);
			Database.releaseSavepoint(sp);
			REP_cls_errorHandler.insertErrorNoFuture(
				QUTT_cls_constantes.QUTT,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
			throw new AuraHandledException(e.getMessage());
		} finally {
			System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
		}
		return solicitud.Id;
	}

	/**
	 * @creation date:  23/05/2024
	 * @author: Rubén Sánchez González
	 * @description Comprueba si alguno de los pedidos seleccionados es de tipo ZPM
	 * @param List<Asset> posPedidos
	 * @return
	 */
	private static void checkZPM(List<Asset> posPedidos) {
		for (Asset posPedido : posPedidos) {
			if (posPedido.RQO_fld_idRelacion__r.RQO_fld_tipodePedido__c == ZPM) {
				throw new CustomExcept.UnhandledException(EXCEPTION_1);
			}
		}
		System.debug(CLASS_NAME + ' - Not ZPM');
	}

	/**
	 * @creation date:  22/03/2024
	 * @author: Rubén Sánchez González
	 * @description Comprueba si todos los pedidos marcados son asignables al equipo de Transporte Terrestre (recogido en sus buzones)
	 * @param List<Asset> posPedidos
	 * @param List<QUSAC_obj_cartera__c> carteras
	 * @return
	 */
	private static void checkAssignableTteTerrestre(List<Asset> posPedidos, List<QUSAC_obj_cartera__c> carteras) {
		Boolean isValid = false;
		for (Asset posPedido : posPedidos) {
			isValid = false;
			for (QUSAC_obj_cartera__c cartera : carteras) {
				if (
					cartera.QUSAC_fld_centro__r.REP_fld_masterRecordId__c == posPedido.RQO_fld_centro__c &&
					cartera.QUTT_fld_modoEnvio__c == posPedido.RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c
				) {
					isValid = true;
					break;
				}
			}

			if (!isValid) {
				throw new CustomExcept.UnhandledException(EXCEPTION_2);
			}
		}
		System.debug(CLASS_NAME + ' - Assignable to Tte Terrestre');
	}

	/**
	 * @creation date:  24/05/2024
	 * @author: Rubén Sánchez González
	 * @description Comprueba si todas las entregas tienen el mismo albarán o bien el mismo número de agrupación en una misma solicitud
	 * @param List<RQO_obj_posiciondeEntrega__c> posEntregas
	 * @return void
	 */
	private static void checkAllSameAlbaran(List<RQO_obj_posiciondeEntrega__c> posEntregas) {
		String albaran = null;
		String agrupacion = null;
		for (RQO_obj_posiciondeEntrega__c posEntrega : posEntregas) {
			albaran = albaran == null ? posEntrega.RQO_fld_idRelacion__r.RQO_fld_idExterno__c : albaran;
			agrupacion = agrupacion == null
				? posEntrega.RQO_fld_idRelacion__r.RQO_fld_numeroExternodeEntrega__c
				: agrupacion;
			Boolean cond1 = albaran != posEntrega.RQO_fld_idRelacion__r.RQO_fld_idExterno__c;
			Boolean cond2 = agrupacion != posEntrega.RQO_fld_idRelacion__r.RQO_fld_numeroExternodeEntrega__c;
			Boolean cond3 = agrupacion == null;

			if (cond1 && (cond2 || cond3)) {
				throw new CustomExcept.UnhandledException(EXCEPTION_3);
			}
		}
		System.debug(CLASS_NAME + ' - All same delivery number or group number');
	}

	/**
	 * @creation date:  24/05/2024
	 * @author: Rubén Sánchez González
	 * @description Comprueba que si no está albaranado, la solicitud debe ser sobre pedidos de agrupación (AG)
	 * @param List<RQO_obj_posiciondeEntrega__c> posEntregas
	 * @param List<Asset> posPedidos
	 * @return void
	 */
	private static void checkNotAlbaranAndAG(List<RQO_obj_posiciondeEntrega__c> posEntregas, List<Asset> posPedidos) {
		final String AGRUPACION_CODE = 'AG';
		if (posEntregas.isEmpty() && posPedidos.size() > 1) {
			for (Asset posPedido : posPedidos) {
				if (posPedido.RQO_fld_idRelacion__r.QUSAC_fld_condicionExpedicion__c != AGRUPACION_CODE) {
					throw new CustomExcept.UnhandledException(EXCEPTION_4);
				}
			}
		}
		System.debug(
			CLASS_NAME + ' - Valid send modes on Assets (either single asset, delivered or multiple Asset with AG mode)'
		);
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Checks if the order has any block that prevents the delivery to be generated
	 * @param List<Asset> posPedidos
	 * @return
	 */
	private static void checkBlockDelivery(List<Asset> posPedidos) {
		for (Asset posPedido : posPedidos) {
			if (posPedido.RQO_fld_idRelacion__r.QUFV_fld_bloqueo__c != null) {
				throw new CustomExcept.UnhandledException(EXCEPTION_5);
			}
		}
		System.debug(CLASS_NAME + ' - Any with block');
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Checks that the delivery has not non-valid Incoterms
	 * @param List<RQO_obj_posiciondeEntrega__c> posEntregas
	 * @return void
	 */
	private static void checkExcludedIncoterms(List<RQO_obj_posiciondeEntrega__c> posEntregas) {
		for (RQO_obj_posiciondeEntrega__c posEntrega : posEntregas) {
			String incoterm = posEntrega.RQO_fld_posicionPedido__r.RQO_fld_idRelacion__r.RQO_fld_incoterm__c;
			if (QUTT_cls_constantes.INCOTERM_EXCLUDED.contains(incoterm)) {
				throw new CustomExcept.UnhandledException(EXCEPTION_6 + incoterm);
			}
		}
		System.debug(CLASS_NAME + ' - All have valid Incoterms');
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Checks that the delivery has not non-valid transporters
	 * @param List<RQO_obj_posiciondeEntrega__c> posEntregas
	 * @return void
	 */
	private static void checkExcludedTransport(List<RQO_obj_posiciondeEntrega__c> posEntregas) {
		for (RQO_obj_posiciondeEntrega__c posEntrega : posEntregas) {
			String transportista = posEntrega.RQO_fld_idRelacion__r.QUTT_fld_codigoTransportista__r.RQO_fld_idExterno__c;
			if (QUTT_cls_constantes.TRANSPORT_EXCLUDED.contains(transportista)) {
				throw new CustomExcept.UnhandledException(EXCEPTION_7 + transportista);
			}
		}
		System.debug(CLASS_NAME + ' - All have valid Transporters');
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Comprueba que ninguna de las entegas seleccionadas haya sido ya entregada
	 * @param List<RQO_obj_posiciondeEntrega__c> posEntregas
	 * @return void
	 */
	private static void checkNotDelivered(List<RQO_obj_posiciondeEntrega__c> posEntregas) {
		for (RQO_obj_posiciondeEntrega__c posEntrega : posEntregas) {
			if (posEntrega.RQO_fld_idRelacion__r.RQO_fld_fechaRealdeLlegada__c != null) {
				throw new CustomExcept.UnhandledException(EXCEPTION_8);
			}
		}
		System.debug(CLASS_NAME + ' - Any delivered yet');
	}

	/**
	 * @creation date:  29/05/2024
	 * @author: Rubén Sánchez González
	 * @description Comprueba que ninguno de los pedidos seleccionados tenga una solicitud ya abierta (no aprobada ni rechazada)
	 * @param List<Asset> posPedidos
	 * @return void
	 */
	private static void checkNotOpenedRequest(List<Asset> posPedidos) {
		final List<String> onGoingStatus = new List<String>{
			QUTT_cls_constantes.STATUS_URGENCIA_00,
			QUTT_cls_constantes.STATUS_URGENCIA_01
		};
		for (Asset posPedido : posPedidos) {
			if (onGoingStatus.contains(posPedido.QUTT_fld_solicitud__r.QUTT_fld_estadoSolicitud__c)) {
				throw new CustomExcept.UnhandledException(EXCEPTION_9);
			}
		}
		System.debug(CLASS_NAME + ' - Not exists urgency request');
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Crea la solicitud de urgencia con los datos pasados como parámetro
	 * @param List<Asset> posPedidos
	 * @param String statusURG
	 * @param String motivoUrgencia
	 * @param Date fechaEntrega
	 * @param String comentario
	 * @return QUTT_obj_solicitud__c
	 */
	public static QUTT_obj_solicitud__c createSolicitud(
		List<Asset> posPedidos,
		String statusURG,
		String motivoUrgencia,
		Date fechaEntrega,
		String comentario
	) {
		final String METHOD = 'createSolicitud';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		QUTT_obj_solicitud__c solicitud = new QUTT_obj_solicitud__c();
		List<QUTT_obj_agrupadorSolicitudes__c> agrupadorSolicitudes = new List<QUTT_obj_agrupadorSolicitudes__c>();
		try {
			if (
				!QUTT_obj_solicitud__c.sObjectType.getDescribe().isCreateable() ||
				!QUTT_obj_solicitud__c.sObjectType.getDescribe().isAccessible() ||
				!QUTT_obj_agrupadorSolicitudes__c.sObjectType.getDescribe().isCreateable()
			) {
				throw new CustomExcept.PermissionException(
					CustomExcept.UNNACCESIBLE + QUTT_obj_solicitud__c.sObjectType.getDescribe().getName()
				);
			}

			// We link the request to the first delivery position. If more than one, it only has sense with the group request object
			Id posEntregaId = getPosEntregaId(posPedidos[0]);

			solicitud = new QUTT_obj_solicitud__c(
				QUTT_fld_estadoSolicitud__c = statusURG,
				QUTT_fld_solicitante__c = UserInfo.getUserId(),
				QUTT_fld_fechaAperturaSolicitud__c = Date.today(),
				QUTT_fld_motivo__c = motivoUrgencia,
				QUTT_fld_nuevaFechaEntrega__c = fechaEntrega,
				QUTT_fld_posicionPedido__c = posPedidos[0].Id,
				QUTT_fld_posicionEntrega__c = posEntregaId,
				QUTT_fld_comentarioSolicitante__c = comentario,
				RecordTypeId = QUTT_cls_constantes.RT_SOLICITUD_URGENCIA_ID
			);
			insert solicitud;

			solicitud = [
				SELECT Id, Name, toLabel(QUTT_fld_motivo__c)
				FROM QUTT_obj_solicitud__c
				WHERE Id = :solicitud.Id
			];

			for (Asset posPedido : posPedidos) {
				posEntregaId = getPosEntregaId(posPedido);
				agrupadorSolicitudes.add(
					new QUTT_obj_agrupadorSolicitudes__c(
						QUTT_fld_solicitud__c = solicitud.Id,
						QUTT_fld_posicionPedido__c = posPedido.Id,
						QUTT_fld_posicionEntrega__c = posEntregaId
					)
				);
			}
			insert agrupadorSolicitudes;
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				CPSVA_cls_constantes.CPSVA,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN' + solicitud);
		return solicitud;
	}

	/**
	 * @creation date:  18/06/2024
	 * @author: Rubén Sánchez González
	 * @description Get the position of delivery id if exists
	 * @param Asset posPedido
	 * @return Id
	 */
	private static Id getPosEntregaId(Asset posPedido) {
		Id posEntregaId = null;
		if (!posPedido?.Posiciones_de_entrega__r.isEmpty()) {
			posEntregaId = posPedido?.Posiciones_de_entrega__r[0]?.Id;
		}
		return posEntregaId;
	}

	/**
	 * @creation date:  23/05/2024
	 * @author: Rubén Sánchez González
	 * @description Crea el texto asociado a la solicitud de urgencia
	 * @param QUTT_obj_solicitud__c solicitud
	 * @param List<Asset> posPedidos
	 * @return
	 */
	public static void createTextoMonitor(QUTT_obj_solicitud__c solicitud, List<String> posPedidosIds) {
		final String METHOD = 'createTextoMonitor';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');
		final String TEXTO_URGENCIA = 'Se ha generado la solicitud de urgencia <b><a href="/lightning/r/QUTT_obj_solicitud__c/{_idSolicitud}/view">{_nombreSolicitud}</a></b> con el motivo <i>{_motivo}</i><br>{_comentario}';
		QUTT_obj_solicitud__c solicitudQ = null;
		if (QUTT_obj_solicitud__c.sObjectType.getDescribe().isAccessible()) {
			solicitudQ = [
				SELECT Id, Name, toLabel(QUTT_fld_motivo__c), QUTT_fld_comentarioSolicitante__c
				FROM QUTT_obj_solicitud__c
				WHERE Id = :solicitud.Id
			];
		}
		String comentario = solicitudQ != null &&
			solicitudQ.QUTT_fld_comentarioSolicitante__c != null
			? solicitudQ.QUTT_fld_comentarioSolicitante__c
			: '';
		String texto = TEXTO_URGENCIA
			.replace(OVERRIDE_1, solicitudQ.Id)
			.replace(OVERRIDE_2, solicitudQ.Name)
			.replace(OVERRIDE_3, solicitudQ.QUTT_fld_motivo__c)
			.replace(OVERRIDE_4, comentario);
		QUSAC_cls_textosMonitor.addTextos(QUTT_cls_constantes.TEXTO_MONITOR_URGENCIA_TYPE, texto, posPedidosIds);

		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
	}

	/**
	 * @creation date:  23/05/2024
	 * @author: Rubén Sánchez González
	 * @description Crea el texto asociado a la solicitud de urgencia
	 * @param QUTT_obj_solicitud__c solicitud
	 * @param List<Asset> posPedidos
	 * @return
	 */
	public static void createNotificacion(QUTT_obj_solicitud__c solicitud, Asset posPedido) {
		final String METHOD = 'createNotificacion';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		final String INPUT_CNT = 'ntDeveloperName';
		final String INPUT_RECIPIENTS = 'recipientIds';
		final String CNT_QUTT = 'QUTT_nt_urgencias';
		final String TITLE_NOTIF = 'URGENCIA: Solicitud de urgencia pendiente de tratar';
		final String TEXTO_NOTIF =
			solicitud.Name +
			' de urgencia con el motivo ' +
			solicitud.QUTT_fld_motivo__c +
			' sobre el material ' +
			posPedido.RQO_fld_material__c;
		final String ALERT_URG_TYPE = MAP_URGENCY_TYPES.get(solicitud.QUTT_fld_motivo__c) ??
			MAP_URGENCY_LABELS_TYPES.get(solicitud.QUTT_fld_motivo__c);

		Set<String> recipientIds = new Set<String>();
		Set<Id> gestoresCliente = new Set<Id>();
		List<UserRole> roles = QUSAC_cls_utilidades.getRolesSAC(
			new List<String>{ QUSAC_cls_constantes.ROL_GESTOR_MATERIAL }
		);
		if (!User.sObjectType.getDescribe().isAccessible()) {
			throw new CustomExcept.PermissionException(
				CustomExcept.UNNACCESIBLE + User.sObjectType.getDescribe().getName()
			);
		}
		for (User user : [
			SELECT id, Name, QUSAC_fld_codigoFO__c
			FROM USER
			WHERE UserRoleId IN :roles AND IsActive = TRUE
			ORDER BY Name
		]) {
			recipientIds.add(user.Id);
		}
		System.debug('### Recipients 01: ' + recipientIds);

		// Check if there are other users that are actually listening for this notifications
		Map<String, QUFV_obj_alertasCliente__c> userAlerts = QUFV_cls_generalUtils.buildAlertMap(
			null,
			new List<Id>{ posPedido.RQO_fld_idRelacion__r.RQO_fld_interlocutorRE__c },
			new List<String>{ ALERT_URG_TYPE },
			false
		);
		for (String gestorCliente : userAlerts.keySet()) {
			List<String> keys = gestorCliente.split(QUSAC_cls_constantes.DASH_SEPARATOR);
			recipientIds.add(keys[0]);
			System.debug('### Recipients 02: ' + keys[0]);
		}

		Map<String, Object> customNotificationParameters = new Map<String, Object>{
			INPUT_CNT => CNT_QUTT,
			INPUT_RECIPIENTS => recipientIds,
			QUSAC_cls_constantes.SENDER => UserInfo.getUserId(),
			QUSAC_cls_constantes.TITLE => TITLE_NOTIF,
			QUSAC_cls_constantes.BODY => TEXTO_NOTIF,
			QUSAC_cls_constantes.TARGET_ID => solicitud.Id
		};

		//create instance of Interview
		Flow.Interview.QUTT_vw_sendCustomNotification flowSendNotif = new Flow.Interview.QUTT_vw_sendCustomNotification(
			customNotificationParameters
		);
		//Invoke start method
		flowSendNotif.start();

		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
	}

	/**
	 * @creation date:  27/05/2024
	 * @author: Rubén Sánchez González
	 * @description Generates a record of QUSAC_obj_tarea__c from URG type
	 * @param QUTT_obj_solicitud__c solicitud
	 * @param List<Asset> posPedidos
	 * @return
	 */
	public static void createTarea(QUTT_obj_solicitud__c solicitud, List<Asset> posPedidos, List<String> albaranes) {
		QUSAC_obj_tarea__c tareaURG = new QUSAC_obj_tarea__c(
			QUSAC_fld_tipologia__c = QUTT_cls_constantes.TAREA_TYPE_URG,
			QUTT_fld_solicitud__c = solicitud.Id,
			QUSAC_fld_posicionPedido__c = posPedidos[0].Id,
			QUSAC_fld_posicionEntrega__c = posPedidos[0].Posiciones_de_entrega__r[0].Id,
			QUSAC_fld_creadoPor__c = UserInfo.getUserName(),
			QUSAC_fld_statusTarea__c = QUSAC_cls_constantes.TAREA_NUEVA,
			QUSAC_fld_idExteno__c = QUTT_cls_constantes.TAREA_TYPE_URG +
				QUSAC_cls_constantes.DASH_SEPARATOR +
				solicitud.Id,
			QUTT_fld_albaranesConcatenados__c = String.join(
				new List<String>(new Set<String>(albaranes)),
				QUSAC_cls_constantes.DASH_SEPARATOR
			),
			RecordTypeId = Schema.SObjectType.QUSAC_obj_tarea__c.getRecordTypeInfosByDeveloperName()
				.get(QUSAC_cls_constantes.RT_TAREA)
				.getRecordTypeId()
		);

		if (!QUSAC_obj_tarea__c.sObjectType.getDescribe().isCreateable()) {
			throw new CustomExcept.PermissionException(
				CustomExcept.UNNACCESIBLE + QUSAC_obj_tarea__c.sObjectType.getDescribe().getName()
			);
		}
		insert tareaURG;
	}

	/**
	 * @creation date:  27/05/2024
	 * @author: Rubén Sánchez González
	 * @description Crea el texto monitor de tipo urgencia la solicitud indicada
	 * @param String solicitudId
	 * @return void
	 */
	@InvocableMethod(
		label='Create texto monitor Urgencia'
		description='Crea texto monitor de tipo urgencia para el estado pasado como parámetro'
	)
	public static void createTextoUrgByStatus(List<String> solicitudId) {
		final String METHOD = 'createTextoUrgByStatus';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		final String TEXTO_DEFAULT = 'Actualización de la <b><a href="/lightning/r/QUTT_obj_solicitud__c/{_idSolicitud}/view">{_nombreSolicitud}</a></b>:<br>{_aprobador} ha marcado su solicitud de urgencia como ';
		final Map<String, String> TEXTO_BY_STATUS = new Map<String, String>{
			'Aprobada' => '<b>aprobada</b>:<br><i>{_comentario}.</i><br>Se crea tarea para el departamento de Transporte Terrestre.',
			'Rechazada' => '<b>rechazada</b>:<br><i>{_comentario}</i>',
			'En curso' => '<b>en curso</b>.<br><i>{_comentario}</i>'
		};
		final String APROBADOR = '{_aprobador}';
		final String COMENTARIO = '{_comentario}';
		final String EN_CURSO = 'En curso';

		List<Id> posPedidosIds = new List<Id>();
		try {
			String texto = TEXTO_DEFAULT;
			Boolean changeText = true;
			if (!QUTT_obj_agrupadorSolicitudes__c.sObjectType.getDescribe().isAccessible()) {
				throw new CustomExcept.PermissionException(
					CustomExcept.UNNACCESIBLE +
					QUTT_obj_agrupadorSolicitudes__c.sObjectType.getDescribe().getName()
				);
			}
			for (QUTT_obj_agrupadorSolicitudes__c agrupador : [
				SELECT
					QUTT_fld_posicionPedido__c,
					QUTT_fld_solicitud__r.Id,
					QUTT_fld_solicitud__r.Name,
					QUTT_fld_solicitud__r.QUTT_fld_estadoSolicitud__c,
					QUTT_fld_solicitud__r.QUTT_fld_aprobador__r.Name,
					QUTT_fld_solicitud__r.QUTT_fld_comentarioAprobador__c,
					QUTT_fld_solicitud__r.QUTT_fld_comentarioEnCurso__c
				FROM QUTT_obj_agrupadorSolicitudes__c
				WHERE QUTT_fld_solicitud__c = :solicitudId
			]) {
				if (changeText) {
					texto += TEXTO_BY_STATUS.get(agrupador.QUTT_fld_solicitud__r.QUTT_fld_estadoSolicitud__c);
					String comentarioT = agrupador.QUTT_fld_solicitud__r.QUTT_fld_estadoSolicitud__c == EN_CURSO
						? agrupador.QUTT_fld_solicitud__r.QUTT_fld_comentarioEnCurso__c
						: agrupador.QUTT_fld_solicitud__r.QUTT_fld_comentarioAprobador__c;
					texto = texto.replace(OVERRIDE_1, agrupador.QUTT_fld_solicitud__r.Id)
						.replace(OVERRIDE_2, agrupador.QUTT_fld_solicitud__r.Name);
					texto = texto.replace(APROBADOR, agrupador.QUTT_fld_solicitud__r.QUTT_fld_aprobador__r?.Name);
					if (comentarioT != null) {
						texto = texto.replace(COMENTARIO, comentarioT);
					}
					changeText = false;
				}
				posPedidosIds.add(agrupador.QUTT_fld_posicionPedido__c);
			}

			QUSAC_cls_textosMonitor.addTextos(QUTT_cls_constantes.TEXTO_MONITOR_URGENCIA_TYPE, texto, posPedidosIds);
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
	}
}