/**
 * @class name        : categoriesInput
 * @description       : Controller. Muestra las categorías de visitas de cliente y permite introducir información adicional.
 * @author            : Rubén Sánchez González
 * @created on        : 11-09-2024
 * @last modified on  : 12-09-2024
 * @last modified by  : Rubén Sánchez González
**/
import { LightningElement, track } from 'lwc';

const PLACEHOLDERS = {
  negociation: `Precios/ Volumen  |  Rappel  |  Información competencia  |  Situación oferta/ demanda`,
  market: `Sector que atienden  |  Situación de su demanda   |  Posición competencia  |  Clientes que atienden  |  Información sobre sus competidores directos`,
  recycle_sustainability: `Interés de clientes sobre productos circulares  |  Reducción CO2  |  Mass-balance  |  Otros`,
  tecnical_advice: `Colaboraciones  técnicas  |  Nuevos desarrollos  |  Homologaciones  |  Volúmenes potenciales`,
  satisfaction_complaints: `Valoraciones sobre relación  |  servicios  |  entregas  |  Posición competencia  |  Registro de reclamaciones`,
  logistics: `Información específica sobre algún tema relacionado con la logística o el servicio que necesitan `,
  administrative: `Solicitud gestión temas administrativos (facturas, documentación, etc)`,
  additional_information: `Información adicional que no se ajuste a las categorías superiores`,
}
export default class CategoriesInput extends LightningElement {
  
  @track selectedItem = '';
  @track selectedItemLabel = '';
  @track inputValues = {};

  navigationItems = [
    { label: 'Negociación', name: 'negociation', iconName: 'utility:comments' },
    { label: 'Mercado', name: 'market', iconName: 'utility:cart' },
    { label: 'Sostenibilidad/ Circularidad/ Reciclado', name: 'recycle_sustainability', iconName: 'utility:rotate' },
    { label: 'Asesoramiento técnico/ Homologaciones', name: 'technical_advice', iconName: 'utility:service_contract' },
    { label: 'Satisfacción/ Quejas', name: 'satisfaction_complaints', iconName: 'utility:feed' },
    { label: 'Aspectos logísticos', name: 'logistics', iconName: 'utility:rules' },
    { label: 'Aspectos administrativos', name: 'administrative', iconName: 'utility:collection' }
  ];

  additionalItems = [
    { label: 'Información adicional', name: 'additional_information' }
  ];
  

  handleItemClick(event) {
    this.selectedItem = event.detail.name;
    this.selectedItemLabel = event.detail.label;
  }

  handleInputChange(event) {
    this.inputValues = { ...this.inputValues, [this.selectedItem]: event.target.value };
  }

  get selectedItemValue() {
    return this.inputValues[this.selectedItem] || '';
  }

  get selectedItemPlaceholder() {
    return PLACEHOLDERS[this.selectedItem] || 'Contenido';
  }

}