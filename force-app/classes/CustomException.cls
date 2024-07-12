/**
 * @name              : CustomExcepction
 * @description       : Clase de excepciones custom para el proyecto CP SVA
 * @author            : Rubén Sánchez González
 * @last modified on  : 21-03-2024
 * @last modified by  : Rubén Sánchez González
 **/
public with sharing class CustomExcepction {
    public final static String EXCEPTION_MSG = 'Ha ocurrido un error inesperado. Por favor, contacte con el administrador del sistema.';
    public final static String UNNACCESIBLE = 'Sin permiso sobre el objeto indicado: ';

    /**
     * @name       : InvalidBlockException
     * @description: Excepcion por incorrecta configuracion de un bloqueo
     *              Se invocará de la siguiente forma - throw new QUTT_cls_excepction.InvalidBlockException(<<exception msg>>)
     * @created on: 05/02/2024
     * @author    : Rubén Sánchez González
     **/
    public with sharing class InvalidBlockException extends Exception {}

    /**
     * @name       : PermissionException
     * @description: Excepcion por falta de permisos de usuario sobre un objeto o campo específico
     *              Se invocará de la siguiente forma - throw new QUTT_cls_excepction.PermissionException(<<exception msg>>)
     * @created on: 05/02/2024
     * @author    : Rubén Sánchez González
     **/
    public with sharing class PermissionException extends Exception {}

    /**
     * @name       : PermissionException
     * @description: Excepciones para otros tipos no controlados - throw new QUTT_cls_excepction.UnhandledException(<<exception msg>>)
     * @created on: 05/02/2024
     * @author    : Rubén Sánchez González
     **/
    public with sharing class UnhandledException extends Exception {}
}