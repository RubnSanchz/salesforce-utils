/**
 * @class name        : QUFV_cls_alertasConfig
 * @description       : Class to manage the alerts configuration for FFVV
 * @author            : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
 * @created on        : 20-01-2025
 * @last modified on  : 11-02-2025
 * @last modified by  : Rubén Sánchez González - ruben.s.gonzalez@accenture.com
 * @test class        : QUFV_cls_alertasConfig_test
 **/
public with sharing class QUFV_cls_alertasConfig {
	private final static String CLASS_NAME = 'QUFV_cls_alertasConfig';
	private final static Id ALERT_RT = Schema.SObjectType.QUFV_obj_alertasCliente__c.getRecordTypeInfosByDeveloperName()
		.get(QUFV_cls_constantes.RT_QUFV_ALERT_CONFIG)
		.getRecordTypeId();
	private final static String FORMAT_NAME = '{0}-{1}-{2}';

	/**
	 * @creation date:  20/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Retrieves the alert configuration. All possible options from custom metadata type
	 * @return List<QUFV_cmt_alertas__mdt>
	 */
	@AuraEnabled
	public static List<QUFV_cmt_alertas__mdt> getAlertOptions() {
		final String METHOD = 'getAlerts';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);
		list<QUFV_cmt_alertas__mdt> alertasDefault = new List<QUFV_cmt_alertas__mdt>();
		try {
			if (!QUFV_cmt_alertas__mdt.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUFV_cmt_alertas__mdt.sObjectType.getDescribe().getLabel()
				);
			}
			alertasDefault = [
				SELECT
					Id,
					DeveloperName,
					Label,
					QUFV_fld_categoria__c,
					QUFV_fld_nombreAlerta__c,
					QUFV_fld_tipo_alerta__c
				FROM QUFV_cmt_alertas__mdt
				WHERE DeveloperName != NULL
				ORDER BY QUFV_fld_categoria__c, QUFV_fld_tipo_alerta__c
			];
		} catch (Exception error) {
			REP_cls_errorHandler.insertErrorNoFuture(
				label.QUFV_lbl_code,
				Datetime.now(),
				UserInfo.getName(),
				CLASS_NAME,
				METHOD,
				error.getMessage(),
				error.getStackTraceString()
			);
		}

		QUFV_cls_debug.fin(CLASS_NAME, METHOD);
		return alertasDefault;
	}

	/**
	 * @creation date:  20/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Get the alerts active/inactive for a specific user
	 * @param Id accountId
	 * @return List<QUFV_obj_alertasCliente__c>
	 */
	@AuraEnabled
	public static List<QUFV_obj_alertasCliente__c> getAlertUser(Id accountId) {
		final String METHOD = 'getAlertUser';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD);

		String scapeChar = accountId != null ? '\'' : '';
		String accountIdScaped = accountId != null ? String.escapeSingleQuotes(accountId) : null;
		final String QUERY_BEGIN =
			'SELECT Id, QUFV_fld_activo__c, QUFV_fld_cuenta__c, QUFV_fld_tipo_alerta__c, QUFV_fld_categoria__c' +
			' FROM QUFV_obj_alertasCliente__c' +
			' WHERE QUFV_fld_usuario__c = \'' +
			UserInfo.getUserId() +
			'\' AND (QUFV_fld_cuenta__c = ' +
			scapeChar +
			accountIdScaped +
			scapeChar;
		final String QUERY_PORTFOLIO = ' OR QUFV_fld_cuenta__c = NULL';
		final String QUERY_END = ') ORDER BY QUFV_fld_categoria__c, QUFV_fld_tipo_alerta__c, QUFV_fld_cuenta__c NULLS FIRST';

		List<QUFV_obj_alertasCliente__c> alerts = new List<QUFV_obj_alertasCliente__c>();
		try {
			if (!QUFV_obj_alertasCliente__c.sObjectType.getDescribe().isAccessible()) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_alertasCliente__c.sObjectType.getDescribe().getLabel()
				);
			}
			Map<Id, List<Id>> portfolioMap = QUFV_cls_generalUtils.getClientesCartera(
				new List<Id>{ UserInfo.getUserId() },
				new List<Id>{ accountId }
			);
			Boolean isInCartera = QUFV_cls_generalUtils.isInCartera(UserInfo.getUserId(), accountId, portfolioMap);

			String query = QUERY_BEGIN + (isInCartera ? QUERY_PORTFOLIO : '') + QUERY_END;
			System.debug('### Query: ' + query);
			alerts = Database.query(query);
		} catch (Exception e) {
			System.debug(
				QUFV_cls_constantes.ERROR_AT +
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
		QUFV_cls_debug.fin(CLASS_NAME, METHOD, alerts);
		return alerts;
	}

	/**
	 * @creation date:  20/01/2025
	 * @author: Rubén Sánchez - Accenture
	 * @description Update the alerts
	 * @param List<QUFV_obj_alertasCliente__c> alertsChanged
	 * @param Id accountId
	 * @return Boolean
	 */
	@AuraEnabled
	public static Boolean updateAlerts(List<QUFV_obj_alertasCliente__c> alertsChanged, Id accountId) {
		final String METHOD = 'updateAlerts';
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD, alertsChanged);
		QUFV_cls_debug.inicio(CLASS_NAME, METHOD, accountId);

		Set<QUFV_obj_alertasCliente__c> alertsToDelete = new Set<QUFV_obj_alertasCliente__c>();
		Set<QUFV_obj_alertasCliente__c> alertsToUpsert = new Set<QUFV_obj_alertasCliente__c>();
		List<QUFV_obj_alertasCliente__c> alertsPre = new List<QUFV_obj_alertasCliente__c>();
		Savepoint sp = Database.setSavepoint();
		try {
			if (
				!QUFV_obj_alertasCliente__c.sObjectType.getDescribe().isCreateable() ||
				!QUFV_obj_alertasCliente__c.sObjectType.getDescribe().isUpdateable() ||
				!QUFV_obj_alertasCliente__c.sObjectType.getDescribe().isDeletable()
			) {
				throw new QUTT_cls_excepction.PermissionException(
					QUTT_cls_excepction.UNNACCESIBLE + QUFV_obj_alertasCliente__c.sObjectType.getDescribe().getLabel()
				);
			}
			Boolean fromClient = accountId != null;
			Map<Id, List<Id>> portfolioMap = QUFV_cls_generalUtils.getClientesCartera(
				new List<Id>{ UserInfo.getUserId() },
				new List<Id>{ accountId }
			);

			alertsPre = [
				SELECT Id, QUFV_fld_activo__c, QUFV_fld_cuenta__c, QUFV_fld_tipo_alerta__c, QUFV_fld_categoria__c
				FROM QUFV_obj_alertasCliente__c
				WHERE QUFV_fld_usuario__c = :UserInfo.getUserId()
				ORDER BY QUFV_fld_categoria__c, QUFV_fld_tipo_alerta__c, QUFV_fld_cuenta__c NULLS FIRST
			];

			for (QUFV_obj_alertasCliente__c alert : alertsChanged) {
				Boolean doInsert = true;
				alert.QUFV_fld_usuario__c = UserInfo.getUserId();
				alert.RecordTypeId = ALERT_RT;
				String alertConcat = String.format(
					FORMAT_NAME,
					new List<Object>{
						alert.QUFV_fld_categoria__c,
						alert.QUFV_fld_tipo_alerta__c,
						(String) alert.QUFV_fld_cuenta__c ?? ''
					}
				);
				for (QUFV_obj_alertasCliente__c alertPre : alertsPre) {
					String alertPreConcat = String.format(
						FORMAT_NAME,
						new List<Object>{
							alertPre.QUFV_fld_categoria__c,
							alertPre.QUFV_fld_tipo_alerta__c,
							(String) alertPre.QUFV_fld_cuenta__c ?? ''
						}
					);
					Boolean sameActive = alertPre.QUFV_fld_activo__c == alert.QUFV_fld_activo__c;
					Boolean preGeneral = alertPre.QUFV_fld_cuenta__c == null;

					System.debug('### Comparing: ' + alertConcat + ' with ' + alertPreConcat);
					// General alert
					if (!fromClient) {
						// erase other alerts from all clients of same category & type
						if (alertConcat.startsWith(alertPreConcat)) {
							// to delete by creating general alert
							System.debug('### 01 Deleting alert: ' + alertPreConcat);
							alertsToDelete.add(alertPre);
							if (!alert.QUFV_fld_activo__c) {
								doInsert = false;
							}
							continue;
						}
					}  // Client specific alert
					else {
						if (
							portfolioMap.isEmpty() ||
							!portfolioMap?.get(UserInfo.getUserId())?.contains((Id) alert.QUFV_fld_cuenta__c)
						) {
							// Alert for client not in portfolio. General alerts do not apply
							System.debug('### Not from portfilo. Add/Remove? ' + alert.QUFV_fld_activo__c);
							if (alert.QUFV_fld_activo__c) {
								alertsToUpsert.add(alert);
							} else {
								alertsToDelete.add(alert);
							}
							doInsert = false;
							break;
						}
						if (preGeneral && alertConcat.startsWith(alertPreConcat) && sameActive) {
							// to delete by matching general alert
							System.debug('### 02 Deleting alert: ' + alertPreConcat);
							alertsToDelete.add(alert);
							doInsert = false;
							break;
						}
						if (preGeneral && alertPreConcat == alertConcat) {
							// to update
							System.debug('### 01 Updating alert: ' + alertConcat);
							alertsToUpsert.add(alert);
							doInsert = false;
							break;
						}
						if (alertPreConcat == alertConcat) {
							if (alert.QUFV_fld_activo__c) {
								// to update
								System.debug('### 02 Updating alert: ' + alertConcat);
								alertsToUpsert.add(alert);
							} else {
								// to delete
								System.debug('### 03 Deleting alert: ' + alertPreConcat);
								alertsToDelete.add(alertPre);
							}
							doInsert = false;
							break;
						}
						// skipped
					}
				}
				// is an activation over a new type not identified or deactivation for a client specific alert
				if (doInsert) {
					// to insert
					System.debug('### Inserting alert: ' + alertConcat);
					alert.Id = null;
					alertsToUpsert.add(alert);
				}
			}

			// commit DB changes
			if (!alertsToDelete.isEmpty()) {
				System.debug('### Deleting alerts: ' + alertsToDelete);
				delete new List<QUFV_obj_alertasCliente__c>(alertsToDelete);
			}
			if (!alertsToUpsert.isEmpty()) {
				System.debug('### Upserting alerts: ' + alertsToUpsert);
				upsert new List<QUFV_obj_alertasCliente__c>(alertsToUpsert);
			}
		} catch (Exception e) {
			Database.rollback(sp);
			System.debug(
				QUFV_cls_constantes.ERROR_AT +
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
		return true;
	}
}