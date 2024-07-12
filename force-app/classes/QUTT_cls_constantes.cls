/**
 * @class name        : QUTT_cls_constantes
 * @description       : Constantes comunes de QUSAC Transporte Terrestre
 * @author            : Rubén Sánchez González
 * @created on        : 05-02-2024
 * @last modified on  : 02-07-2024
 * @last modified by  : Rubén Sánchez González
 **/
public with sharing class QUTT_cls_constantes {
	/* Reserved words */
	public final static String QUTT = 'QUTT';
	public final static String ROLE_COORDINADOR = 'QUTT_rol_coordGeneralTransTerrestre';
	public final static String ROLE_AGENTE = 'QUTT_rol_agenteTransTerrestre';
	public final static List<String> ROLES_TT = new List<String>{ ROLE_COORDINADOR, ROLE_AGENTE };
	public final static String ROLE_BRANCH_TT = 'Transporte terrestre';

	public final static String INICIO = ': INICIO';
	public final static String FIN = ': FIN';
	public final static String ERROR_TAG = 'ERROR at ';

	/* Permission sets */
	public final static String PS_GENERAL = 'QUTT_ps_tranporteTerrestreGeneral';
	public final static String PS_SOPORTE = 'QUTT_ps_soporte';
	public final static String PS_COORDINADOR = 'QUTT_ps_coordinadorGeneralQUTT';

	/* Record Types */
	public final static String RT_CARTERA_TT_DEVNAME = 'QUTT_rt_carteraTerrestre';
	public final static Id RT_CARTERA_TT_ID = Schema.SObjectType.QUSAC_obj_cartera__c.getRecordTypeInfosByDeveloperName()
		.get(RT_CARTERA_TT_DEVNAME)
		.getRecordTypeId();
	public final static String RT_ACCOUNT_TRANS_TERR = 'QUTT_rt_transportista';
	public final static Id RT_ACCOUNT_TT_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
		.get(RT_ACCOUNT_TRANS_TERR)
		.getRecordTypeId();
	public final static String RT_ACCOUNT_SOLICITANTE = 'RQO_rt_Solicitante';
	public final static Id RT_ACCOUNT_SOLICITANTE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
		.get(RT_ACCOUNT_SOLICITANTE)
		.getRecordTypeId();
	public final static String RT_POS_PEDIDO = 'RQO_rt_Posicion_de_pedido';
	public final static Id RT_POS_PEDIDO_ID = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName()
		.get(RT_POS_PEDIDO)
		.getRecordTypeId();
	public final static String RT_CONTACT = 'QUTT_rt_contactoTteTerrestre';
	public final static Id RT_CONTACT_ID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName()
		.get(RT_CONTACT)
		.getRecordTypeId();
	public final static String RT_SOLICITUD_URGENCIA = 'QUTT_rt_solicitudUrgencia';
	public final static Id RT_SOLICITUD_URGENCIA_ID = Schema.SObjectType.QUTT_obj_solicitud__c.getRecordTypeInfosByDeveloperName()
		.get(RT_SOLICITUD_URGENCIA)
		.getRecordTypeId();

	/* Albarán status (para el campo QUTT_fld_descripcionEstado__c) */
	public final static String ALBARAN_STATUS_NW = 'Oferta nueva de embarcador';
	public final static String ALBARAN_STATUS_AC = 'En proceso';
	public final static String ALBARAN_STATUS_AW = 'Aceptado por transportista con condiciones';
	public final static String ALBARAN_STATUS_RJ = 'Rechazado';
	public final static String ALBARAN_STATUS_CF = 'Confirmado por embarcador';
	public final static String ALBARAN_STATUS_EX = 'Excepción iniciada por transportista';
	public final static String ALBARAN_STATUS_CN = 'Oferta anulada';

	// TIPOLOGÍAS DE TAREAS (QUSAC_obj_tarea__c)
	public static final String TAREA_TYPE_ZRE = 'ZRE';
	public static final String TAREA_TYPE_ALB = 'ALB';
	public static final String TAREA_TYPE_REC = 'REC';
	public static final String TAREA_TYPE_URG = 'URG';
	public static final String TAREA_TYPE_EXT = 'EXT';

	/* Excepciones visualización */
	public static final List<String> INCOTERM_EXCLUDED = new List<String>{ 'FCA', 'EXW' };
	public static final List<String> TRANSPORT_EXCLUDED = new List<String>{
		'0041007991',
		'0041007992',
		'0041007993',
		'0041009999'
	};

	/* Motivos de solicitud urgencia */
	public static final String MOTIVO_QUTT_01 = 'Urgencia/Adelanto Cliente';
	public static final String MOTIVO_QUTT_02 = 'Bloqueo Pedido';
	public static final String MOTIVO_QUTT_03 = 'Retraso producto';
	public static final String MOTIVO_QUTT_04 = 'Falta Transporte';
	public static final String MOTIVO_QUTT_05 = 'Falta Franja Carga';

	/* Estados urgencia */
	public static final String STATUS_URGENCIA_00 = 'En curso';
	public static final String STATUS_URGENCIA_01 = 'Pendiente';
	public static final String STATUS_URGENCIA_02 = 'Aprobada';
	public static final String STATUS_URGENCIA_03 = 'Rechazada';
	public static final String STATUS_URGENCIA_04 = 'Aprobada salida en ruta';

	/* Tipos de textos, el orden de los elementos de las listas es importante para generar los textos automáticos*/
	public static final List<String> TIPOS_TEXTOS_SAC = new List<String>{
		'QUTT_transTerrToSAC',
		'QUTT_SACToTransTerr'
	};
	public static final List<String> TIPOS_TEXTOS_GESTION_MATERIAL = new List<String>{
		'QUTT_transTerrToGestionMaterial',
		'QUTT_gestionMaterialToTransTerr'
	};
	public final static Id RT_TEXTO_MONITOR_GENERAL = Schema.SObjectType.QUSAC_obj_textoMonitor__c.getRecordTypeInfosByDeveloperName()
		.get(QUSAC_cls_constantes.RT_TEXTO_MONITOR_GENERAL)
		.getRecordTypeId();
	public final static String TEXTO_MONITOR_URGENCIA_TYPE = 'QUTT_solicitudUrgencia';
	public final static String TEXTO_CIERRE_URG_AUTO1 = '<p>Se ha cerrado la tarea por la modificación de la fecha prevista de entregar a la siguiente fecha: {_fechaEntrega}</p>';
	public final static String TEXTO_CIERRE_URG_AUTO2 = '<p>Se ha cerrado la tarea ya que el pedido ha sido entregado​</p>';
	public final static String TEXTO_CIERRE_URG_MANUAL = '<p>Urgencia cerrada manualmente por {_userName} por el motivo:<br><i>{_motivo}</i></p>';
	public final static String USER_NAME_INPUT = '{_userName}';
	public final static String MOTIVO_INPUT = '{_motivo}';
	public final static String FECHA_ENTREGA_INPUT = '{_fechaEntrega}';
}