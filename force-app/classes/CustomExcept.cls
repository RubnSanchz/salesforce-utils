/**
 * @name              : CustomExcept
 * @description       : Clase de excepciones custom para el proyecto
 * @author            : Rubén Sánchez González
 * @last modified on  : 14-05-2025
 * @last modified by  : Inetum Team <ruben.sanchez-gonzalez@inetum.com>
 **/
public with sharing class CustomExcept {
    public final static String EXCEPTION_MSG = 'Ha ocurrido un error inesperado. Por favor, contacte con el administrador del sistema.';
    public final static String UNNACCESIBLE = 'Sin permiso sobre el objeto indicado: ';

    /**
    * @description Nebula Logger register
    * @author Rubén Sánchez González | 14-05-2025
    * @param Exception
    * @param String
    **/
    public static void logException(Exception cause) {
        logException(cause, '');
    }
    public static void logException(String message) {
        logException(null, message);
    }
    public static void logException(Exception cause, String message) {
        Logger.error('Exception: ' + message, cause);
        Logger.saveLog();
    }

    /**
     * @name       : IntegrationException
     * @description: Exception for integration errors
     *              It will be invoked as follows - throw new CustomExcept.IntegrationException(<<exception msg>>[, <<exception>>])
     * @created on: 14-05-2025
     * @author    : Rubén Sánchez González
     **/
    public class IntegrationException extends Exception {}

    /**
     * @name       : InvalidBlockException
     * @description: Excepcion por incorrecta configuracion de un bloqueo
     *              Se invocará de la siguiente forma - throw new CustomExcept.InvalidBlockException(<<exception msg>>)
     * @created on: 05/02/2024
     * @author    : Rubén Sánchez González
     **/
    public with sharing class InvalidBlockException extends Exception {}

    /**
     * @name       : PermissionException
     * @description: Excepcion por falta de permisos de usuario sobre un objeto o campo específico
     *              Se invocará de la siguiente forma - throw new CustomExcept.PermissionException(<<exception msg>>)
     * @created on: 05/02/2024
     * @author    : Rubén Sánchez González
     **/
    public with sharing class PermissionException extends Exception {}

    /**
     * @name       : PermissionException
     * @description: Excepciones para otros tipos no controlados - throw new CustomExcept.UnhandledException(<<exception msg>>)
     * @created on: 05/02/2024
     * @author    : Rubén Sánchez González
     **/
    public with sharing class UnhandledException extends Exception {}
}