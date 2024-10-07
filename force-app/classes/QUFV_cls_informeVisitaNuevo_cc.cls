/**
 * @class name        : QUFV_cls_informeVisitaNuevo_cc
 * @description       : Controller for qufv_lwc_informeVisitaNuevo
 * @author            : Rubén Sánchez González
 * @created on        : 17-09-2024
 * @last modified on  : 07-10-2024
 * @last modified by  : Rubén Sánchez González
 * @test class        : QUFV_cls_informeVisitaNuevo_test
 **/
public with sharing class QUFV_cls_informeVisitaNuevo_cc {
	private static final String CLASS_NAME = 'QUFV_cls_informeVisitaNuevo_cc';
	public static InformeData informe { get; set; } // Variable shared among methods

	/**
	 * @creation date:  17/09/2024
	 * @author: Rubén Sánchez González
	 * @description Creates a new FV_obj_informeVisita__c record or updates an existing one
	 * @param String jsonParams
	 * @return Boolean
	 */
	@AuraEnabled
	public static Id newInforme(String jsonParams) {
		final String METHOD = 'newInforme';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		Id informeId = null;
		try {
			System.debug('#### jsonParams: ' + jsonParams);
			informe = (InformeData) JSON.deserialize(jsonParams, InformeData.class);
			System.debug('#### informe: ' + informe);

			// gest SUMI-Solic relation from RQO_obj_relaciondeVentas__c
			Id solicitante = QUFV_cls_utilidades.getSolicitanteId(informe.cliente);

			if (!QUFV_obj_informeVisita__c.sObjectType.getDescribe().isCreateable() && !Test.isRunningTest()) {
				return null;
			}

			QUFV_obj_informeVisita__c informeVisita = new QUFV_obj_informeVisita__c();
			informeVisita.Id = informe.informe;
			informeVisita.RecordTypeId = informe.rtInforme;
			if (String.isBlank(informe.informe)) {
				String negocioCode = QUATD_cls_jerarquiaClientesTree_cc.getUserRoleCode() == Label.QUFV_lbl_sector0010
					? Label.QUFV_lbl_poliolefinas
					: Label.QUFV_lbl_intermedios;
				informeVisita.QUFV_fld_unidadNegocio__c = negocioCode;
				informeVisita.name = buildName();
				informeVisita.QUFV_fld_cliente__c = solicitante;
				informeVisita.QUFV_fld_destinatarioMercancias__c = (solicitante == informe.cliente)
					? null
					: informe.cliente;
				informeVisita.QUATD_fld_estado__c = QUATD_cls_constantes.QUATD_BORRADOR;
			}
			informeVisita.QUFV_fld_eventSubject__c = informe.asunto;
			informeVisita.QUFV_fld_fechaVisita__c = informe.fechaVisita;
			informeVisita.QUFV_fld_importancia__c = informe.importancia;
			informeVisita.QUFV_fld_tiporeunion__c = informe.reunion;
			informeVisita.QUATD_fld_motivo__c = informe.motivos;
			informeVisita.QUATD_fld_asistentes__c = informe.asistentes;
			informeVisita.QUATD_fld_usuarioAsociado__c = informe.colaborador;
			informeVisita.QUATD_fld_resumen__c = informe.resumen;
			informeVisita.QUATD_fld_acciones__c = informe.acciones;
			informeVisita.QUATD_fld_palabrasClave__c = informe.clave;
			informeVisita.QUATD_fld_productos__c = informe.productos;
			informeVisita.QUATD_fld_aplicacion__c = informe.aplicacion;
			informeVisita.QUFV_fld_negociation__c = informe.negociation;
			informeVisita.QUFV_fld_market__c = informe.market;
			informeVisita.QUFV_fld_recycleSustainability__c = informe.recycleSustainability;
			informeVisita.QUFV_fld_technicalAdvice__c = informe.technicalAdvice;
			informeVisita.QUFV_fld_feedback__c = informe.satisfactionComplaints;
			informeVisita.QUFV_fld_logistic__c = informe.logistics;
			informeVisita.QUFV_fld_administrative__c = informe.administrative;
			informeVisita.QUFV_fld_informeVisita__c = informe.additionalInformation;
			System.debug('#### informeVisita record: ' + informeVisita);

			upsert informeVisita;
			informeId = informeVisita.Id;

			QUFV_cls_informeVisitaSharings obj = new QUFV_cls_informeVisitaSharings(informeVisita);
			obj.grantReadAccess();
			if (
				(informeVisita.QUATD_fld_usuarioAsociado__c != null &&
				userInfo.getUserId() != informeVisita.QUATD_fld_usuarioAsociado__c &&
				QUFV_obj_informeVisita__share.sObjectType.getDescribe().isCreateable()) || Test.isRunningTest()
			) {
				delete [
					SELECT Id
					FROM QUFV_obj_informeVisita__share
					WHERE ParentId = :informeId AND RowCause = :QUFV_cls_constantes.ROWCAUSE_MANUAL
				];
				insert new QUFV_obj_informeVisita__share(
					ParentId = informeId,
					UserOrGroupId = informeVisita.QUATD_fld_usuarioAsociado__c,
					AccessLevel = QUFV_cls_constantes.ACCESSLEVEL_EDIT,
					RowCause = QUFV_cls_constantes.ROWCAUSE_MANUAL
				);
			}
		} catch (Exception e) {
			System.debug('ERROR at ' + e.getLineNumber() + ' - ' + e.getMessage());
			REP_cls_errorHandler.insertErrorNoFuture(
				label.QUFV_lbl_code,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				e.getMessage(),
				e.getStackTraceString()
			);
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
		return informeId;
	}

	/**
	 * @description Reusable method to get the product
	 * @author Rubén Sánchez González | 18-09-2024
	 * @return Map<String, String>
	 **/
	@AuraEnabled(cacheable=true)
	public static Map<String, String> getProductos() {
		return QUATD_cls_crearInformeVisita_cc.getProductos();
	}

	/**
	 * @description Reusable method to get the application
	 * @author Rubén Sánchez González | 18-09-2024
	 * @return Map<String, String>
	 **/
	@AuraEnabled(cacheable=true)
	public static Map<String, String> getAplicacion() {
		return QUATD_cls_crearInformeVisita_cc.getAplicacion();
	}

	/**
	 * @description Reusable method to get the event info
	 * @author Rubén Sánchez González | 30-09-2024
	 * @return Map<String, String>
	 **/
	@AuraEnabled(cacheable=true)
	public static Event getVisitInfo(Id visitaId) {
		if (Event.sObjectType.getDescribe().isAccessible()) {
			return [
				SELECT Id, Subject, StartDateTime, EndDateTime, AccountId
				FROM Event
				WHERE Id = :visitaId
				LIMIT 1
			];
		}
		return null;
	}

	/**
	 * @description Change informe Status to sent
	 * @author Rubén Sánchez González | 30-09-2024
	 * @return
	 **/
	@AuraEnabled(cacheable=true)
	public static void updateInformeStatus(Id informeId) {
		final String METHOD = 'updateInformeStatus';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');
		if (!QUFV_obj_informeVisita__c.sObjectType.getDescribe().isUpdateable() && !Test.isRunningTest()) {
			return;
		}
		updateInformeStatusAsync(new List<Id>{ informeId });
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
	}

	// #region aux methods
	/**
	 * @description Build the name of the informe
	 * @author Rubén Sánchez González
	 * created on 18-09-2024
	 * @return String
	 **/
	public static String buildName() {
		final String METHOD = 'buildName';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');

		String name = null;
		if (informe.isATD) {
			name = buildNameATD();
		} else if (informe.isFFVV) {
			name = buildNameFFVV();
		}

		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
		return name;
	}

	/**
	 * @description
	 * @author Rubén Sánchez González
	 * created on 18-09-2024
	 * @return String
	 **/
	private static String buildNameFFVV() {
		String name = '';

		if (
			(!Account.sObjectType.getDescribe().isAccessible() || !User.sObjectType.getDescribe().isAccessible()) &&
			!Test.isRunningTest()
		) {
			return name;
		}

		Account cuentaCliente = [SELECT QUFV_fld_codigo__c FROM Account WHERE Id = :informe.cliente LIMIT 1];

		if (String.isNotBlank(cuentaCliente.QUFV_fld_codigo__c)) {
			name = cuentaCliente.QUFV_fld_codigo__c + QUFV_cls_constantes.SLASH_SEPARATOR;
		}

		User fullUsuario = [SELECT QUFV_fld_codigoGestor__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

		name +=
			fullUsuario.QUFV_fld_codigoGestor__c +
			QUFV_cls_constantes.SLASH_SEPARATOR +
			String.valueOf(informe.fechaVisita.month()) +
			QUFV_cls_constantes.DASH_SEPARATOR +
			String.valueOf(informe.fechaVisita.year()).substring(2) +
			QUFV_cls_constantes.SLASH_SEPARATOR +
			QUFV_cls_constantes.PERCENTAGE;

		Integer countInformesPrevios = [
			SELECT COUNT()
			FROM QUFV_obj_informeVisita__c
			WHERE Name LIKE :name
		];

		// Determine the order number
		String numOrden = (countInformesPrevios + 1 < 10)
			? QUFV_cls_constantes.NUMBER_0 + String.valueOf(countInformesPrevios + 1)
			: String.valueOf(countInformesPrevios + 1);

		name = name.replace(QUFV_cls_constantes.PERCENTAGE, numOrden);

		return name;
	}

	/**
	 * @description Contructs the name
	 * @author Rubén Sánchez González
	 * created on 18-09-2024
	 * @return String
	 **/
	private static String buildNameATD() {
		String prod = '';
		if (QUATD_cmt_producto__mdt.sObjectType.getDescribe().isAccessible()) {
			for (QUATD_cmt_producto__mdt item : [
				SELECT QualifiedApiName, QUATD_fld_codigoATD__c
				FROM QUATD_cmt_producto__mdt
			]) {
				for (String p : informe?.productos?.split(',')) {
					if (p == item.QualifiedApiName) {
						prod = item.QUATD_fld_codigoATD__c;
					}
				}
			}
		}

		String name = '';
		if (prod == null || prod == '') {
			prod = '//';
		} else {
			if (prod.contains('/')) {
				name = prod + '/';
			} else {
				if (QUFV_cmt_aplicacion__mdt.sObjectType.getDescribe().isAccessible()) {
					String app = '';
					for (QUFV_cmt_aplicacion__mdt item : [
						SELECT QUFV_fld_codigo__c, QUATD_fld_codigoATD__c
						FROM QUFV_cmt_aplicacion__mdt
						WHERE QUFV_fld_codigo__c != NULL
					]) {
						if (informe.aplicacion.contains(item.QUFV_fld_codigo__c)) {
							app = item.QUATD_fld_codigoATD__c;
						}
					}
					name = prod + '/' + app + '/';
				}
			}
		}

		String anio = String.ValueOf(informe.fechaVisita.year()).subString(2, 4);
		Integer countInformes = 0;
		if (QUFV_obj_informeVisita__c.sObjectType.getDescribe().isAccessible()) {
			countInformes = [
				SELECT COUNT()
				FROM QUFV_obj_informeVisita__c
				WHERE RecordTypeId = :informe.rtInforme
			];
		}
		countInformes++;

		name = name + anio + '/' + countInformes;
		return name;
	}

	/**
	 * @description Asynchronously change informe Status to sent
	 * @author Rubén Sánchez González | 02-10-2024
	 * @param List<Id> informeIds
	 **/
	@future
	public static void updateInformeStatusAsync(List<Id> informeIds) {
		final String METHOD = 'updateInformeStatusAsync';
		System.debug(CLASS_NAME + ' - ' + METHOD + ': INICIO');
		List<QUFV_obj_informeVisita__c> informesToUpdate = new List<QUFV_obj_informeVisita__c>();
		for (Id informeId : informeIds) {
			informesToUpdate.add(
				new QUFV_obj_informeVisita__c(Id = informeId, QUATD_fld_estado__c = QUATD_cls_constantes.QUATD_ENVIADO)
			);
		}
		if (!informesToUpdate.isEmpty()) {
			update informesToUpdate;
		}
		System.debug(CLASS_NAME + ' - ' + METHOD + ': FIN');
	}

	// #endregion aux methods

	// Wrapper json de entrada

	/**
	 * @class name        : InformeData
	 * @description       : Wrapper for qufv_lwc_informeVisitaNuevo
	 * @author            : Rubén Sánchez González
	 * @created on        : 17-09-2024
	 * @last modified on  : 07-10-2024
	 * @last modified by  : Rubén Sánchez González
	 **/
	public with sharing class InformeData {
		public String informe { get; set; }
		public String rtInforme { get; set; }
		// common fields
		public String cliente { get; set; }
		public String visita { get; set; }
		public String asunto { get; set; }
		public DateTime fechaVisita { get; set; }
		public String importancia { get; set; }
		public String reunion { get; set; }
		public String motivos { get; set; }
		public String asistentes { get; set; }
		public String colaborador { get; set; }
		public String resumen { get; set; }
		public String acciones { get; set; }
		public String clave { get; set; }
		public String negociation { get; set; }
		public String market { get; set; }
		public String recycleSustainability { get; set; }
		public String technicalAdvice { get; set; }
		public String satisfactionComplaints { get; set; }
		public String logistics { get; set; }
		public String administrative { get; set; }
		public String additionalInformation { get; set; }
		// only for ATD
		public String productos { get; set; }
		public String aplicacion { get; set; }

		public Boolean isFFVV { get; set; }
		public Boolean isATD { get; set; }
	}
}