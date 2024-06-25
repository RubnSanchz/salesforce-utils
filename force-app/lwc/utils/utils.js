/**
 * @class name        : lwc_utils
 * @description       : Métodos LWC comunes de utilidades varias
 * @author            : Rubén Sánchez González
 * @created on        : 17-01-2022
 * @last modified on  : 22-02-2024
 * @last modified by  : Rubén Sánchez González
**/
const filterArray = (array, filters) => {
    const filterKeys = Object.keys(filters);
    return array.filter(item => {
        // validates all filter criteria
        return filterKeys.every(key => {
            // ignores non-function predicates
            if (typeof filters[key] !== 'function') return true;
            return filters[key](item[key]);
        });
    });
}

const dynamicSort = (property) => {
    var sortOrder = 1;
    if (property[0] === "-") {
        sortOrder = -1;
        property = property.substr(1);
    }
    return function (a, b) {
        /* next line works with strings and numbers, 
         * and you may want to customize it to your needs
         */
        var result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
        return result * sortOrder;
    }
}

const sortBy = (field, reverse, primer) => {
    const key = primer
        ? function (x) {
            return primer(x[field]);
        }
        : function (x) {
            return x[field];
        };
    return function (a, b) {
        a = key(a) === undefined ? "" : key(a);
        b = key(b) === undefined ? "" : key(b);
        a = a.toString().toLowerCase();
        b = b.toString().toLowerCase();
        return reverse * ((a > b) - (b > a));
    };
}

const getRoleBranchFromRoleDevName = (rolDevName) => {
    const rolesExportacionEuropa = ['QUSAC_rol_coordGeneralEuropaExportacion', 'QUSAC_rol_coordSACEuropa', 'QUSAC_rol_agenteSACEuropa', 'QUSAC_rol_coordSACExportacion', 'QUSAC_rol_agenteSACExportacion'];
    const rolesTransporteMaritimo = ['QUSAC_rol_coordGeneralTransMaritimo', 'QUSAC_rol_agenteTransporteMaritimo', 'QUSAC_rol_coordTransporteMaritimo'];
    const rolesGestoresMaterial = ['QUSAC_rol_gestionMateriales'];
    const rolesTransporteTerrestre = ['QUTT_rol_coordGeneralTransTerrestre', 'QUTT_rol_agenteTransTerrestre'];

    if (rolesExportacionEuropa.some(rol => rol === rolDevName)) {
        return 'EuropaExportacion';
    }
    else if (rolesTransporteMaritimo.some(rol => rol === rolDevName)) {
        return 'TransporteMaritimo';
    }
    else if (rolesGestoresMaterial.some(rol => rol === rolDevName)) {
        return 'GestorMaterial';
    }
    else if (rolesTransporteTerrestre.some(rol => rol === rolDevName)) {
      return 'TransporteTerrestre';
    }
    else {
        return undefined;
    }
}

const changeIndex = (arrayToUpdate, elementToReposition, newIndex) => {
    if (newIndex > arrayToUpdate.length - 1) {
        console.log('Array index out of bounds');
        return arrayToUpdate;
    } else if (!(arrayToUpdate.includes(elementToReposition))) {
        console.log('Element not found');
        return arrayToUpdate;
    }

    arrayToUpdate.splice(arrayToUpdate.indexOf(elementToReposition), 1);
    arrayToUpdate.splice(newIndex, 0, elementToReposition);
    return arrayToUpdate;
}

const HTMLToPlainText = (html) => {
    let tempDivElement = document.createElement("div");
    tempDivElement.innerHTML = html;
    return tempDivElement.textContent || tempDivElement.innerText || "";
}

const replaceDiacritics = (str) => {
    var diacritics = [
        { char: 'A', base: /[\300-\306]/g },
        { char: 'a', base: /[\340-\346]/g },
        { char: 'E', base: /[\310-\313]/g },
        { char: 'e', base: /[\350-\353]/g },
        { char: 'I', base: /[\314-\317]/g },
        { char: 'i', base: /[\354-\357]/g },
        { char: 'O', base: /[\322-\330]/g },
        { char: 'o', base: /[\362-\370]/g },
        { char: 'U', base: /[\331-\334]/g },
        { char: 'u', base: /[\371-\374]/g },
        { char: 'N', base: /[\321]/g },
        { char: 'n', base: /[\361]/g },
        { char: 'C', base: /[\307]/g },
        { char: 'c', base: /[\347]/g }
    ]

    diacritics.forEach(function (letter) {
        str = str.replace(letter.base, letter.char);
    });

    return str;
}

const convierteValorMsHora = (value) => {
    if (value) {
        var seconds = Math.floor((value / 1000) % 60),
            minutes = Math.floor((value / (1000 * 60)) % 60),
            hours = Math.floor((value / (1000 * 60 * 60)) % 24);

        hours = (hours < 10) ? "0" + hours : hours;
        minutes = (minutes < 10) ? "0" + minutes : minutes;
        seconds = (seconds < 10) ? "0" + seconds : seconds;

        return hours + ":" + minutes + ":" + seconds;
    } else {
        return '';
    }
}

const formatDateSpain = (value) => {
    if (!value) return ''
    var dateField = (value == 'TODAY') ? new Date() : new Date(value);
    var dd = String(dateField.getDate()).padStart(2, '0');
    var mm = String(dateField.getMonth() + 1).padStart(2, '0');
    var yyyy = dateField.getFullYear();
    return dd + '/' + mm + '/' + yyyy;
}

const normalizeArray = (arr) => {
    arr = arr.sort();
    if (!arr[arr.length - 1]) arr.pop();
    return arr.map(function (x) { return x.toUpperCase(); });
}

const dateOptions = [{
    label: 'Ayer',
    value: 'LITERAL_YESTERDAY'
}, {
    label: 'Hoy',
    value: 'LITERAL_TODAY'
}, {
    label: 'Mañana',
    value: 'LITERAL_TOMORROW'
}, {
    label: 'Semana Pasada',
    value: 'LITERAL_LAST_WEEK'
}, {
    label: 'Semana en Curso',
    value: 'LITERAL_THIS_WEEK'
}, {
    label: 'Próxima Semana',
    value: 'LITERAL_NEXT_WEEK'
}, {
    label: 'Mes Pasado',
    value: 'LITERAL_LAST_MONTH'
}, {
    label: 'Mes en Curso',
    value: 'LITERAL_THIS_MONTH'
}, {
    label: 'Próximo Mes',
    value: 'LITERAL_NEXT_MONTH'
}, {
    label: 'Últimos 7 Días',
    value: 'LITERAL_LAST_N_DAYS:7'
}, {
    label: 'Últimos 15 Días',
    value: 'LITERAL_LAST_N_DAYS:15'
}, {
    label: 'Últimos 3 Meses',
    value: 'LITERAL_LAST_N_MONTHS:3'
}, {
    label: 'Últimos 6 Meses',
    value: 'LITERAL_LAST_N_MONTHS:6'
}, {
    label: 'Último año',
    value: 'LITERAL_LAST_N_YEARS:1'
}
];

// Dado un resultado de SObjects usando qusac_lwc_categorized-results-lookup, tipifica los resultados para mostrar una vista común. Si se incluyen otros objetos, incluir al final
const processCategorizedLookup = (res) => {
    return res.map(function (item) {
        return (item.REP_fld_clave__c)? { // Buzones y Navieras (config personalizada)
            id         : item.Id,
            sObjectType: "REP_obj_configuracionPersonalizada__c",
            title      : item.REP_fld_clave__c,
            subtitle   : (item.RecordType?.DeveloperName==='QUSAC_rt_navieras')? "Naviera - " + item.REP_fld_valor__c : "Buzón general - " + item.REP_fld_valor__c,
            icon       : (item.RecordType?.DeveloperName==='QUSAC_rt_navieras')? "custom:custom54" : "custom:custom105",
            email      : item.REP_fld_valor__c
        } : (item.QUSAC_fld_codigoFO__c || item.QUFV_fld_codigoGestor__c)? { // Usuarios
            id         : item.Id,
            sObjectType: "User",
            title      : item.Name,
            subtitle   : (item.QUSAC_fld_codigoFO__c)? item.Email + " - " +  item.QUSAC_fld_codigoFO__c : item.Email + " - " + item.QUFV_fld_codigoGestor__c,
            icon       : "standard:avatar",
            email      : item.Email
        } : (item.REP_fld_contacto__r)? { // Contactos
            id         : item.Id,
            sObjectType: "Contact",
            title      : item.REP_fld_contacto__r.Name,
            subtitle   : item.Name + " - " + item.REP_fld_cliente__r.Name + " - " + item.REP_fld_cliente__r.QUFV_fld_codigo__c,
            icon       : "standard:contact",
            email      : item.Name
        } : (item.Queue?.Email)? { // Otros buzones SAC Química
            id         : item.Id,
            sObjectType: "QueueSobject",
            title      : item.Queue.Name,
            subtitle   : item.Queue.Name + " - " + item.Queue.Email,
            icon       : "custom:custom105",
            email      : item.Queue.Email
        } : (item.RQO_fld_codigoPedido__c && item.RecordType?.DeveloperName==='RQO_rt_Posicion_de_pedido')? {
            id         : item.Id,
            sObjectType: "Asset",
            title      : item.RQO_fld_codigoPedido__c,
            subtitle   : item.RQO_fld_idRelacion__r.RQO_fld_solicitante__r.Name + " - " + item.RQO_fld_material__c,
            icon       : "standard:asset_object",
            email      : null
        } : { // Otro caso no contemplado
            id         : item.Id,
            sObjectType: "User",
            title      : item.Name,
            subtitle   : item.Email,
            icon       : "standard:avatar",
            email      : item.Email
        }
    })
}

// Dado un texto (html) marca todas las palabras coincidentes con un patrón dado
const highlight = (finding, globalText) => {
    const MARK_INI = '<span style="background-color:yellow;">';
    const MARK_END = '</span>';
    const findingLenght = finding.length;
    let notEnd = true;
    let indexSplit = 0;
    while (notEnd){
        let indexFound = globalText?.toLowerCase().indexOf(finding.toLowerCase(), indexSplit);
        let valid = true;
        for(var i=indexFound ; indexFound && i!=-1 && i<globalText.length ; i++){ // avoid highlighting inside a tag
            if (globalText[i]=='<'){ break; }
            if (globalText[i]=='>'){ valid=false; break; }
        }
        if (!valid){ indexSplit=indexFound+1; continue }; // highlight next valid word
        if (indexFound != -1 && globalText){
            indexSplit = indexFound + findingLenght + 46; // jump over inserting text
            let textInserting = MARK_INI + globalText.substring(indexFound, indexFound+findingLenght) + MARK_END;
            globalText = [globalText.slice(0,indexFound), textInserting, globalText.slice(indexFound+findingLenght)].join('');
        }
        else notEnd = false;
    }
    return globalText;
}

const isValidDate = (dateInput) => {
    return isValidDateStrict(dateInput) || isValidDateTime(dateInput)
}
    
const isValidDateStrict = (dateInput) => {
    if (!dateInput) return false
    const regexDate = /^(?:\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{3})?(?:Z|[+-]\d{4}))?$/gmi
    return regexDate.test(dateInput)
}
    
const isValidDateTime = (dateTimeInput) => {
    if (!dateTimeInput) return false
    const regexDateTime = /^\d{4}-\d{2}-\d{2}$/gmi
    return regexDateTime.test(dateTimeInput)
}

const getDiffDateToday = (date)=> {
    return Math.floor( (new Date(date) - new Date()) / (1000*3600*24) )
}
  
const getDeepValue = (obj, path)=> {
    for (var i=0, path=path.split('.'), len=path.length; i<len; i++){
        obj = Boolean(obj)? obj[path[i]] : null;
    };
    return obj;
}


export { filterArray, dynamicSort, sortBy, getRoleBranchFromRoleDevName, changeIndex, HTMLToPlainText, replaceDiacritics, convierteValorMsHora, formatDateSpain, normalizeArray, dateOptions, 
    processCategorizedLookup, highlight, isValidDate, isValidDateStrict, isValidDateTime, getDiffDateToday, getDeepValue };
