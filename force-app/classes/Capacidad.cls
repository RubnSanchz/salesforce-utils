/**
 * @class name        : Capacidad
 * @description       : Controller class to manage capacities
 * @author            : Rubén Sánchez González
 * @created on        : 15-10-2024
 * @last modified on  : 19-12-2024
 * @last modified by  : Rubén Sánchez González
 * @test class 		  : Capacidad_test
 **/
public with sharing class Capacidad {
	private final static String CLASS_NAME = 'Capacidad';

	private final static Id RT_INTERMEDIOS = Schema.SObjectType.QUFV_obj_capacidad__c.getRecordTypeInfosByDeveloperName()
		.get('QUFV_rt_capacidadIntermedios')
		.getRecordTypeId();
	private final static Id RT_POLIOLEFINAS = Schema.SObjectType.QUFV_obj_capacidad__c.getRecordTypeInfosByDeveloperName()
		.get('QUFV_rt_capacidadPoliolefinas')
		.getRecordTypeId();
	private final static Map<String, Id> MAP_LINEA_NEGOCIO = new Map<String, Id>{
		'Estireno' => RT_INTERMEDIOS,
		'Glicoles' => RT_INTERMEDIOS,
		'OP' => RT_INTERMEDIOS,
		'Polioles' => RT_INTERMEDIOS,
		'PEAD' => RT_POLIOLEFINAS,
		'PEBD' => RT_POLIOLEFINAS,
		'PEL' => RT_POLIOLEFINAS,
		'm-PEL' => RT_POLIOLEFINAS,
		'EVBA' => RT_POLIOLEFINAS,
		'PP' => RT_POLIOLEFINAS
	};
	private final static String FORMAT_NAME = '{0}-{1}-{2}';

	/**
	 * @creation date:  15/10/2024
	 * @author: Rubén Sánchez
	 * @description Get all capacities from a client
	 * @param Id clientId
	 * @return List<QUFV_obj_capacidad__c>
	 */
	@AuraEnabled
	public static List<QUFV_obj_capacidad__c> getCapacidades(Id clientId) {
		final String METHOD = 'getCapacidades';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		List<QUFV_obj_capacidad__c> capacidadList = new List<QUFV_obj_capacidad__c>();
		try {
			if (!QUFV_obj_capacidad__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_capacidad__c.sObjectType.getDescribe().getLabel()
				);
			}

			capacidadList = [
				SELECT
					Name,
					RecordTypeId,
					RecordType.name,
					QUFV_fld_year__c,
					QUFV_fld_family__c,
					QUFV_fld_country__c,
					QUFV_fld_account__r.Id,
					QUFV_fld_account__r.Name,
					QUFV_fld_account__r.QUFV_fld_codigo__c,
					QUFV_fld_account__r.RecordType.Name,
					QUFV_fld_sumi__r.Id,
					QUFV_fld_sumi__r.Name,
					QUFV_fld_sumi__r.QUFV_fld_codigo__c,
					QUFV_fld_sumi__r.RecordType.Name,
					QUFV_fld_anualConsumption__c,
					QUFV_fld_consolidatedSales__c,
					QUFV_fld_competitors__c,
					QUFV_fld_comments__c,
					QUFV_fld_cuota__c,
					QUFV_fld_lastModifiedDate__c,
					LastModifiedDate
				FROM QUFV_obj_capacidad__c
				WHERE QUFV_fld_account__c = :clientId
				ORDER BY QUFV_fld_year__c DESC, QUFV_fld_family__c, QUFV_fld_sumi__c NULLS FIRST
			];
		} catch (Exception e) {
			System.debug(
				QUFV_cls_constantes.ERROR +
					e.getLineNumber() +
					QUFV_cls_constantes.DASH_SEPARATOR_SPACE +
					e.getMessage()
			);
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
		QUFV_cls_debug.fin(CLASS_NAME, METHOD);
		return capacidadList;
	}

	/**
	 * @creation date:  21/10/2024
	 * @author: Rubén Sánchez
	 * @description Create / update a capacity record
	 * @param String jsonParams
	 * @return
	 */
	@AuraEnabled
	public static void upsertCapacidad(String jsonParams) {
		final String METHOD = 'upsertCapacidad';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		QUFV_obj_capacidad__c capacidad = null;
		try {
			if (
				!QUFV_obj_capacidad__c.sObjectType.getDescribe().isUpdateable() ||
				!QUFV_obj_capacidad__c.sObjectType.getDescribe().isCreateable()
			) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_capacidad__c.sObjectType.getDescribe().getLabel()
				);
			}
			capacidad = fillCapacidad(jsonParams);
			upsert capacidad QUFV_fld_idExterno__c;
			if (capacidad.QUFV_fld_sumi__c != null) {
				recalculateParent(capacidad);
			}
		} catch (Exception e) {
			System.debug(
				QUFV_cls_constantes.ERROR +
					e.getLineNumber() +
					QUFV_cls_constantes.DASH_SEPARATOR_SPACE +
					e.getMessage()
			);
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
		QUFV_cls_debug.fin(CLASS_NAME, METHOD, capacidad);
	}

	/**
	 * @creation date:  21/10/2024
	 * @author: Rubén Sánchez
	 * @description Create / update a capacity record
	 * @param String jsonParams
	 * @return
	 */
	@AuraEnabled
	public static void insertCapacidad(String jsonParams) {
		final String METHOD = 'insertCapacidad';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		QUFV_obj_capacidad__c capacidad = null;
		QUFV_obj_capacidad__c parentCapacidad = null;
		try {
			capacidad = fillCapacidad(jsonParams);
			upsert capacidad QUFV_fld_idExterno__c;

			if (capacidad.QUFV_fld_sumi__c != null) {
				return;
			}
			String parentName = createParentName(capacidad);
			parentCapacidad = new QUFV_obj_capacidad__c(
				RecordTypeId = capacidad.RecordTypeId,
				Name = parentName,
				QUFV_fld_idExterno__c = parentName,
				QUFV_fld_account__c = capacidad.QUFV_fld_account__c,
				QUFV_fld_year__c = capacidad.QUFV_fld_year__c,
				QUFV_fld_family__c = capacidad.QUFV_fld_family__c,
				QUFV_fld_consolidatedSales__c = QUFV_cls_ventasFacturadas.getVentasFacturadas(capacidad, true)
			);
			upsert parentCapacidad QUFV_fld_idExterno__c;
		} catch (Exception e) {
			System.debug(
				QUFV_cls_constantes.ERROR +
					e.getLineNumber() +
					QUFV_cls_constantes.DASH_SEPARATOR_SPACE +
					e.getMessage()
			);
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
		QUFV_cls_debug.fin(CLASS_NAME, METHOD, parentCapacidad);
	}

	/**
	 * @creation date:  23/10/2024
	 * @author: Rubén Sánchez
	 * @description
	 * @param String jsonParams
	 * @return QUFV_obj_capacidad__c
	 */
	public static QUFV_obj_capacidad__c fillCapacidad(String jsonParams) {
		final String METHOD = 'fillCapacidad';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		QUFV_obj_capacidad__c capacidad = (QUFV_obj_capacidad__c) JSON.deserialize(
			jsonParams,
			QUFV_obj_capacidad__c.class
		);

		if (capacidad.Name == null) {
			capacidad.RecordTypeId = MAP_LINEA_NEGOCIO.get(capacidad.QUFV_fld_family__c);
			String clienteCode = getClienteCode(capacidad.QUFV_fld_account__c);
			Id solicitante = QUFV_cls_utilidades.getSolicitanteId(capacidad.QUFV_fld_account__c);
			if (solicitante != capacidad.QUFV_fld_account__c) {
				capacidad.QUFV_fld_sumi__c = capacidad.QUFV_fld_account__c;
				capacidad.QUFV_fld_account__c = solicitante;
			}

			capacidad.Name = String.format(
				FORMAT_NAME,
				new List<Object>{
					clienteCode,
					Integer.valueOf(capacidad.QUFV_fld_year__c),
					capacidad.QUFV_fld_family__c
				}
			);
			capacidad.QUFV_fld_idExterno__c = capacidad.Name;
		}
		Boolean isSolicitante = capacidad.QUFV_fld_sumi__c == null;
		capacidad.QUFV_fld_consolidatedSales__c = QUFV_cls_ventasFacturadas.getVentasFacturadas(
			capacidad,
			isSolicitante
		);

		QUFV_cls_debug.fin(CLASS_NAME, METHOD, capacidad);
		return capacidad;
	}

	/**
	 * @creation date:  21/10/2024
	 * @author: Rubén Sánchez
	 * @description Delete a capacity record
	 * @param Id capacidadId
	 * @return
	 */
	@AuraEnabled
	public static void deleteCapacidad(Id capacidadId) {
		final String METHOD = 'deleteCapacidad';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		if (
			!QUFV_obj_capacidad__c.sObjectType.getDescribe().isUpdateable() ||
			!QUFV_obj_capacidad__c.sObjectType.getDescribe().isDeletable()
		) {
			throw new AuraHandledException(
				QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_capacidad__c.sObjectType.getDescribe().getLabel()
			);
		}
		QUFV_obj_capacidad__c capacidad = [
			SELECT Id, QUFV_fld_account__c, QUFV_fld_year__c, QUFV_fld_family__c, QUFV_fld_sumi__c
			FROM QUFV_obj_capacidad__c
			WHERE Id = :capacidadId
		];

		capacidad.OwnerId = UserInfo.getUserId();
		capacidad.QUFV_fld_anualConsumption__c = 0;
		capacidad.QUFV_fld_competitors__c = null;
		update capacidad; // make the user the owner before deleting
		recalculateParent(capacidad);
		delete capacidad;

		QUFV_cls_debug.fin(CLASS_NAME, METHOD);
	}

	/**
	 * @creation date:  21/10/2024
	 * @author: Rubén Sánchez
	 * @description Remove all capacities from a specific client, year and family
	 * @param Id capacidadId
	 * @return
	 */
	@AuraEnabled
	public static void deleteAll(Integer anno, String familia, Id clientId) {
		final String METHOD = 'deleteAll';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		if (
			!QUFV_obj_capacidad__c.sObjectType.getDescribe().isAccessible() ||
			!QUFV_obj_capacidad__c.sObjectType.getDescribe().isUpdateable()
		) {
			throw new AuraHandledException(
				QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_capacidad__c.sObjectType.getDescribe().getLabel()
			);
		}
		List<QUFV_obj_capacidad__c> capacidades2delete = new List<QUFV_obj_capacidad__c>();
		for (QUFV_obj_capacidad__c capacidad : [
			SELECT Id
			FROM QUFV_obj_capacidad__c
			WHERE QUFV_fld_year__c = :anno AND QUFV_fld_family__c = :familia AND QUFV_fld_account__c = :clientId
		]) {
			capacidad.OwnerId = UserInfo.getUserId(); // make the user the owner before deleting
			capacidades2delete.add(capacidad);
		}
		update capacidades2delete;
		delete capacidades2delete;

		QUFV_cls_debug.fin(CLASS_NAME, METHOD);
	}

	/**
	 * @creation date:  23/10/2024
	 * @author: Rubén Sánchez
	 * @description Retrieves the client code
	 * @param Id clientId
	 * @return String
	 */
	private static String getClienteCode(Id clientId) {
		final String METHOD = 'getClienteCode';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		String clientCode = null;
		if (Account.sObjectType.getDescribe().isAccessible()) {
			clientCode = [
				SELECT QUFV_fld_codigo__c
				FROM Account
				WHERE Id = :clientId
				LIMIT 1
			]
			?.QUFV_fld_codigo__c;
		}

		QUFV_cls_debug.fin(CLASS_NAME, METHOD, clientCode);
		return clientCode;
	}

	/**
	 * @creation date:  14/11/2024
	 * @author: Rubén Sánchez
	 * @description
	 * @param QUFV_obj_capacidad__c capacidad
	 * @return String
	 */
	private static String createParentName(QUFV_obj_capacidad__c capacidad) {
		final String METHOD = 'createParentName';
		String parentName = String.format(
			FORMAT_NAME,
			new List<Object>{
				getClienteCode(capacidad.QUFV_fld_account__c),
				Integer.valueOf(capacidad.QUFV_fld_year__c),
				capacidad.QUFV_fld_family__c
			}
		);
		QUFV_cls_debug.fin(CLASS_NAME, METHOD, parentName);
		return parentName;
	}

	/**
	 * @creation date:  14/11/2024
	 * @author: Rubén Sánchez
	 * @description
	 * @param QUFV_obj_capacidad__c capacidad
	 * @return void
	 */
	public static void recalculateParent(QUFV_obj_capacidad__c capacidad) {
		final String METHOD = 'recalculateParent';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);
		final String SUMA = 'suma';

		QUFV_obj_capacidad__c capacidadParent = null;
		try {
			if (
				!QUFV_obj_capacidad__c.sObjectType.getDescribe().isAccessible() ||
				!QUFV_obj_capacidad__c.sObjectType.getDescribe().isUpdateable()
			) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_capacidad__c.sObjectType.getDescribe().getLabel()
				);
			}

			capacidadParent = [
				SELECT QUFV_fld_account__c, QUFV_fld_year__c, QUFV_fld_family__c, QUFV_fld_sumi__c
				FROM QUFV_obj_capacidad__c
				WHERE QUFV_fld_idExterno__c = :createParentName(capacidad)
			];

			if (capacidadParent != null) {
				capacidadParent.QUFV_fld_consolidatedSales__c = QUFV_cls_ventasFacturadas.getVentasFacturadas(
					capacidadParent,
					true
				);
				update capacidadParent;
			}
		} catch (Exception e) {
			System.debug(
				QUFV_cls_constantes.ERROR +
					e.getLineNumber() +
					QUFV_cls_constantes.DASH_SEPARATOR_SPACE +
					e.getMessage()
			);
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
		QUFV_cls_debug.fin(CLASS_NAME, METHOD, capacidadParent);
	}
}