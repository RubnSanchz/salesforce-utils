/**
 * @class name        : QUTT_cls_utiles_test
 * @description       : Métodos auxiliares para la creación de registros de prueba en los test unitarios
 * @author            : Rubén Sánchez González
 * @created on        : 10-01-2024
 * @last modified on  : 18-06-2024
 * @last modified by  : Rubén Sánchez González
 **/
@isTest
public with sharing class QUTT_cls_utiles_test {
	private static final String CLASS_NAME = 'QUTT_cls_utiles_test';

	public static Integer contador = 0;
	public static boolean lanzarExcepcion = false;

	private final static String USERNAME_TEST = 'user.terrestre';
	private final static String APPEND_MAIL = '@test.com';

	/**
	 * @creation date:  08/02/2024
	 * @author: Rubén Sánchez González
	 * @description
	 * @param String userName
	 * @return User
	 */
	public static User createUserTTSoporte(String userName) {
		User userSoporte = createUserTTGenerico(
			userName,
			QUTT_cls_constantes.ROLE_COORDINADOR
		);
		assignPermisionSet(
			userSoporte.Id,
			QUTT_cls_constantes.PS_SOPORTE,
			false
		);
		assignPermisionSet(
			userSoporte.Id,
			QUTT_cls_constantes.PS_COORDINADOR,
			false
		);

		return userSoporte;
	}

	/**
	 * @creation date:  08/02/2024
	 * @author: Rubén Sánchez González
	 * @description
	 * @param String userName
	 * @return User
	 */
	public static User createUserTTCoord(String userName) {
		User userCoord = createUserTTGenerico(
			userName,
			QUTT_cls_constantes.ROLE_COORDINADOR
		);
		assignPermisionSet(
			userCoord.Id,
			QUTT_cls_constantes.PS_COORDINADOR,
			false
		);

		return userCoord;
	}

	/**
	 * @creation date:  08/02/2024
	 * @author: Rubén Sánchez González
	 * @description
	 * @param String userName
	 * @return User
	 */
	public static User createUserTTGenerico(
		String userName,
		String userRoleDevName
	) {
		User userGeneral = createUserWithoutPS(userName, userRoleDevName);
		assignPermisionSet(
			userGeneral.Id,
			QUTT_cls_constantes.PS_GENERAL,
			false
		);

		return userGeneral;
	}

	/**
	 * @creation date:  08/02/2024
	 * @author: Rubén Sánchez González
	 * @description
	 * @param String userName
	 * @return User
	 */
	public static User createUserWithoutPS(
		String userName,
		String userRoleDevName
	) {
		final String PROFILE_QU = 'Usuario Estándar Química';
		String roleNameFinal = userRoleDevName != null
			? userRoleDevName
			: QUTT_cls_constantes.ROLE_AGENTE;
		String userNameFinal = userName == null
			? USERNAME_TEST + contador
			: userName;

		User userGeneral = new User(
			UserRoleId = [
				SELECT Id
				FROM UserRole
				WHERE DeveloperName = :roleNameFinal
				LIMIT 1
			]
			.Id,
			ProfileId = [
				SELECT Id
				FROM Profile
				WHERE Name = :PROFILE_QU
				LIMIT 1
			][0]
			.Id,
			Email = userNameFinal + APPEND_MAIL,
			CurrencyIsoCode = label.QUFV_lbl_currencyIsoCode,
			LocaleSidKey = label.QUFV_lbl_localeSidKey,
			EmailEncodingKey = label.QUFV_lbl_emailEncodingKey,
			TimeZoneSidKey = label.QUFV_lbl_timeZoneSidKey,
			DefaultGroupNotificationFrequency = label.QUFV_lbl_groupNotificationFrequency,
			LanguageLocaleKey = label.QUFV_lbl_languageLocaleKey,
			DigestFrequency = label.QUFV_lbl_digestFrequency,
			CommunityNickname = userNameFinal + contador,
			Alias = label.QUFV_lbl_userAlias,
			LastName = userNameFinal,
			Username = userNameFinal + APPEND_MAIL,
			IsActive = true
		);
		contador++;

		insert userGeneral;
		return userGeneral;
	}

	/**
	 * @creation date:  12/02/2024
	 * @author: Rubén Sánchez González
	 * @description Asigna un permission Set o permission Set group a un usuario específico
	 * @param User u
	 * param String permissionSetName
	 * param Boolean isPSGroup
	 * @return
	 */
	public static void assignPermisionSet(
		Id userId,
		String permissionSetName,
		Boolean isPSGroup
	) {
		Id psId = isPSGroup
			? [
					SELECT Id
					FROM PermissionSetGroup
					WHERE DeveloperName = :permissionSetName
					LIMIT 1
			  ]
			  .Id
			: [
					SELECT Id
					FROM PermissionSet
					WHERE Name = :permissionSetName
					LIMIT 1
			  ]
			  .Id;

		PermissionSetAssignment assignment = new PermissionSetAssignment(
			PermissionSetGroupId = isPSGroup ? psId : null,
			PermissionSetId = isPSGroup ? null : psId,
			AssigneeId = userId
		);
		insert assignment;
	}

	/**
	 * @creation date:  20/02/2024
	 * @author: Rubén Sánchez González
	 * @description Crea un registro de tipo agrupador carteras
	 * @param String nameBuzon
	 * @return QUTT_obj_agrupadorCartera__c
	 */
	public static QUTT_obj_agrupadorCartera__c createAgrupadorCartera_test(
		String nameBuzon
	) {
		QUTT_obj_agrupadorCartera__c agrupador = new QUTT_obj_agrupadorCartera__c(
			Name = nameBuzon,
			QUTT_fld_email__c = nameBuzon + APPEND_MAIL
		);
		insert agrupador;
		return agrupador;
	}

	/**
	 * @creation date:  20/02/2024
	 * @author: Rubén Sánchez González
	 * @description Crea una lista de carteras asignadas con un agrupador específico
	 * @param String nameBuzon
	 * @param String centro
	 * @param List<String> modosEnvio
	 * @param Id agrupadorId
	 * @return List<QUTT_obj_agrupadorCartera__c>
	 */
	public static List<QUSAC_obj_cartera__c> createCarteras_test(
		String nameBuzon,
		String centro,
		List<String> modosEnvio,
		QUTT_obj_agrupadorCartera__c agrupador
	) {
		List<QUSAC_obj_cartera__c> carteras = new List<QUSAC_obj_cartera__c>();
		for (String modoEnvio : modosEnvio) {
			carteras.add(
				new QUSAC_obj_cartera__c(
					QUTT_fld_buzonTerrestre__c = nameBuzon,
					QUTT_fld_centro__c = centro,
					QUTT_fld_modoEnvio__c = modoEnvio,
					QUTT_fld_agrupadorCartera__c = agrupador.Id,
					RecordTypeId = QUTT_cls_constantes.RT_CARTERA_TT_ID
				)
			);
		}
		insert carteras;
		return carteras;
	}

	/**
	 * @creation date:  20/02/2024
	 * @author: Rubén Sánchez González
	 * @description Asigna un agrupador a una lista de usuarios
	 * @param Id agrupadorId
	 * @param List<Id> usersId
	 * @return List<QUTT_obj_agrupadorCartera__c>
	 */
	public static List<QUTT_obj_agrupadorPorUser__c> createAgrupadorPorUser_test(
		Id agrupadorId,
		List<Id> usersId
	) {
		List<QUTT_obj_agrupadorPorUser__c> agrupadoresPorUser = new List<QUTT_obj_agrupadorPorUser__c>();
		for (Id userId : usersId) {
			agrupadoresPorUser.add(
				new QUTT_obj_agrupadorPorUser__c(
					QUTT_fld_agrupadorCartera__c = agrupadorId,
					QUTT_fld_user__c = userId
				)
			);
		}

		insert agrupadoresPorUser;
		return agrupadoresPorUser;
	}

	/**
	 * @creation date:  20/02/2024
	 * @author: Rubén Sánchez González
	 * @description Levanta el modelo de carterización para Transporte Terrestre para un conjunto de usuarios
	 * @param List<Id> usersId
	 * @return
	 */
	public static void createCarterizacion_test(List<Id> usersId) {
		final String BUZON = 'PALET_PUERTOLLANO';
		final String CENTRO = '03';
		final List<String> MODOS_ENVIO = new List<String>{
			'A2',
			'AG',
			'CX',
			'CY'
		};

		QUTT_obj_agrupadorCartera__c agrupador = createAgrupadorCartera_test(
			BUZON
		);
		List<QUSAC_obj_cartera__c> carteras = createCarteras_test(
			BUZON,
			CENTRO,
			MODOS_ENVIO,
			agrupador
		);
		createAgrupadorPorUser_test(agrupador.Id, usersId);
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Pedido con todos sus niveles inferiores
	 * @param String externalId
	 * @return RQO_obj_pedido__c
	 */
	public static RQO_obj_pedido__c createPedidoAllLevels_test(
		String externalId
	) {
		Account destinatarioMercancias = createInterlocutorWE();
		Account solicitante = createInterlocutorRE();
		RQO_obj_pedido__c pedido = createPedido(
			externalId,
			destinatarioMercancias,
			solicitante
		);
		Asset posPedido = createPosPedido(externalId, pedido.Id);
		RQO_obj_entrega__c entrega = createEntrega(externalId);
		RQO_obj_posiciondeEntrega__c posEntrega = createPosEntrega(
			externalId,
			entrega.Id,
			posPedido.Id
		);

		return pedido;
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Crea una cuenta con RT de InterlocutorWE (Destinatario de Mercancías)
	 * @return Account
	 */
	public static Account createInterlocutorWE() {
		final String NAME = 'InterlocutorWE';

		Account account = new Account(
			Name = NAME,
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
				.get(QUSAC_cls_constantes.RT_ACCOUNT_DESTINATARIO_MERCANCIAS)
				.getRecordTypeId()
		);

		insert account;
		return account;
	}

	/**
	 * @creation date:  22/05/2024
	 * @author: Rubén Sánchez González
	 * @description Crea una cuenta con RT de InterlocutorRE (Solicitante)
	 * @return Account
	 */
	public static Account createInterlocutorRE() {
		final String NAME = 'InterlocutorRE';

		Account account = new Account(
			Name = NAME,
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
				.get(QUSAC_cls_constantes.RT_ACCOUNT_SOLICITANTE)
				.getRecordTypeId()
		);

		insert account;
		return account;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Pedido
	 * @param String externalId
	 * @return RQO_obj_pedido__c
	 */
	public static RQO_obj_pedido__c createPedido(
		String externalId,
		Account destinatarioMercancias,
		Account solicitante
	) {
		final String EXTERNAL_ENTREGA = '9';
		final String CONDICION_EXP = 'AG';
		RQO_obj_pedido__c pedido = new RQO_obj_pedido__c(
			RQO_fld_idExterno__c = EXTERNAL_ENTREGA + externalId,
			QUSAC_fld_condicionExpedicion__c = CONDICION_EXP,
			RQO_fld_interlocutorWE__c = destinatarioMercancias.Id,
			RQO_fld_interlocutorRE__c = solicitante.Id
		);

		insert pedido;
		return pedido;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Entrega
	 * @param String externalId
	 * @return RQO_obj_entrega__c
	 */
	public static RQO_obj_entrega__c createEntrega(String externalId) {
		final String EXTERNAL_ENTREGA = '6';
		final Integer MATRICULA = 12345;
		Account transportista = createAccount(
			externalId,
			QUTT_cls_constantes.RT_ACCOUNT_TT_ID
		);
		RQO_obj_entrega__c entrega = new RQO_obj_entrega__c(
			RQO_fld_idExterno__c = EXTERNAL_ENTREGA + externalId,
			QUTT_fld_codigoTransportista__r = transportista,
			QUTT_fld_descripcionEstado__c = USERNAME_TEST,
			QUTT_fld_descripcionRuta__c = USERNAME_TEST,
			QUTT_fld_matriculaCisterna__c = String.valueOf(MATRICULA),
			QUTT_fld_matriculaContenedor__c = String.valueOf(MATRICULA + 1),
			QUTT_fld_matriculaTractor__c = String.valueOf(MATRICULA + 2),
			QUTT_fld_zona__c = USERNAME_TEST,
			QUTT_fld_zonaOrigen__c = USERNAME_TEST
		);

		insert entrega;
		return entrega;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Posición de Entrega
	 * @param String externalId
	 * @param Id entregaId
	 * @param Id posPedidoId
	 * @return RQO_obj_posiciondeEntrega__c
	 */
	public static RQO_obj_posiciondeEntrega__c createPosEntrega(
		String externalId,
		Id entregaId,
		Id posPedidoId
	) {
		final String EXTERNAL_ENTREGA = '7';
		RQO_obj_posiciondeEntrega__c posEntrega = new RQO_obj_posiciondeEntrega__c(
			RQO_fld_idExterno__c = EXTERNAL_ENTREGA + externalId,
			RQO_fld_idRelacion__c = entregaId,
			RQO_fld_posicionPedido__c = posPedidoId
		);

		insert posEntrega;
		return posEntrega;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Posición de Pedido
	 * @param String externalId
	 * @param Id pedido
	 * @return Asset
	 */
	public static Asset createPosPedido(String externalId, Id pedido) {
		final String EXTERNAL_ENTREGA = '8';
		final String CENTRO = '03';
		final String NOMBRE_APLICACION = 'Film';
		Account solicitante = createAccount(
			externalId,
			QUTT_cls_constantes.RT_ACCOUNT_SOLICITANTE_ID
		);
		Asset posPedido = new Asset(
			AccountId = solicitante.Id,
			RecordTypeId = QUTT_cls_constantes.RT_POS_PEDIDO_ID,
			Name = USERNAME_TEST,
			RQO_fld_idRelacion__c = pedido,
			RQO_fld_idExterno__c = EXTERNAL_ENTREGA + externalId,
			RQO_fld_centro__c = CENTRO,
			QUSAC_fld_nombreAplicacion__c = NOMBRE_APLICACION
		);

		insert posPedido;
		return posPedido;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Account
	 * @param String externalId
	 * @param Id rtId
	 * @return Account
	 */
	public static Account createAccount(String externalId, Id rtId) {
		Account cuenta = new Account(
			RecordTypeId = rtId,
			Name = USERNAME_TEST + contador,
			RQO_fld_idExterno__c = externalId + contador,
			REP_fld_pais__c = label.QUFV_lbl_languageLocaleKey,
			REP_fld_numeroFiscal__c = externalId
		);
		contador++;

		insert cuenta;
		return cuenta;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Tarea
	 * @param String externalId
	 * @return QUSAC_obj_tarea__c
	 */
	public static QUSAC_obj_tarea__c createTareaAllLevels_test(
		String tipologia,
		String externalId
	) {
		Account destinatarioMercancias = createInterlocutorWE();
		Account solicitante = createInterlocutorRE();
		RQO_obj_pedido__c pedido = createPedido(
			externalId,
			destinatarioMercancias,
			solicitante
		);
		Asset posPedido = createPosPedido(externalId, pedido.Id);
		RQO_obj_entrega__c entrega = createEntrega(externalId);
		RQO_obj_posiciondeEntrega__c posEntrega = createPosEntrega(
			externalId,
			entrega.Id,
			posPedido.Id
		);

		QUSAC_obj_tarea__c tarea = createTarea(
			tipologia,
			posPedido.Id,
			posEntrega.Id
		);
		return tarea;
	}

	/**
	 * @creation date:  13/03/2024
	 * @author: Rubén Sánchez González
	 * @description
	 * @param String externalId
	 * param Id posPedidoId
	 * param Id posEntregaId
	 * @return QUSAC_obj_tarea__c
	 */
	public static QUSAC_obj_tarea__c createTarea(
		String tipologia,
		Id posPedidoId,
		Id posEntregaId
	) {
		QUSAC_obj_tarea__c tarea = new QUSAC_obj_tarea__c(
			RecordTypeId = Schema.SObjectType.QUSAC_obj_tarea__c.getRecordTypeInfosByDeveloperName()
				.get(QUSAC_cls_constantes.RT_TAREA)
				.getRecordTypeId(),
			QUSAC_fld_tipologia__c = tipologia,
			QUSAC_fld_posicionPedido__c = posPedidoId,
			QUSAC_fld_posicionEntrega__c = posEntregaId,
			QUSAC_fld_statusTarea__c = QUSAC_cls_constantes.TAREA_NUEVA
		);

		insert tarea;
		return tarea;
	}

	/**
	 * @creation date:  10/05/2024
	 * @author: Rubén Sánchez González
	 * @description
	 * @param String contactName
	 * @param String email
	 * @return Contact
	 */
	public static Contact createContact(String contactName) {
		final String CONTRATO_GRANEL = 'QUTT_Granel';
		Contact contacto = new Contact(
			RecordTypeId = QUTT_cls_constantes.RT_CONTACT_ID,
			LastName = contactName,
			Email = USERNAME_TEST + contactName + APPEND_MAIL,
			REP_fld_tipoContrato__c = CONTRATO_GRANEL
		);

		insert contacto;
		return contacto;
	}

	/**
	 * @creation date:  27/05/2024
	 * @author: Rubén Sánchez González
	 * @description Creación de un registro de tipo Solicitud de Urgencia con sus agrupadores por debajo
	 * @param List<Asset> posPedidos
	 * @return QUTT_obj_solicitud__c
	 */
	public static QUTT_obj_solicitud__c createSolicitud(
		List<Asset> posPedidos
	) {
		final String MOTIVO = 'QUTT_falloCargaTransporte';
		QUTT_obj_solicitud__c solicitud = new QUTT_obj_solicitud__c(
			QUTT_fld_estadoSolicitud__c = QUTT_cls_constantes.STATUS_URGENCIA_01,
			QUTT_fld_solicitante__c = UserInfo.getUserId(),
			QUTT_fld_fechaAperturaSolicitud__c = Date.today(),
			QUTT_fld_motivo__c = MOTIVO,
			QUTT_fld_nuevaFechaEntrega__c = Date.today().addDays(1),
			QUTT_fld_comentarioEnCurso__c = QUTT_cls_constantes.ALBARAN_STATUS_AC,
			QUTT_fld_comentarioAprobador__c = QUTT_cls_constantes.ALBARAN_STATUS_AW,
			QUTT_fld_comentarioSolicitante__c = QUTT_cls_constantes.ALBARAN_STATUS_AW,
			QUTT_fld_aprobador__c = UserInfo.getUserId(),
			RecordTypeId = QUTT_cls_constantes.RT_SOLICITUD_URGENCIA_ID
		);
		insert solicitud;

		List<QUTT_obj_agrupadorSolicitudes__c> agrupadorSolicitudes = new List<QUTT_obj_agrupadorSolicitudes__c>();
		for (Asset posPedido : posPedidos) {
			agrupadorSolicitudes.add(
				new QUTT_obj_agrupadorSolicitudes__c(
					QUTT_fld_solicitud__c = solicitud.Id,
					QUTT_fld_posicionPedido__c = posPedido.Id
				)
			);
		}
		insert agrupadorSolicitudes;
		return solicitud;
	}
}