@EndUserText.label : 'Approval Limit per user'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zotc_appr_lim {

  key client  : abap.clnt not null;
  key user_id : abap.char(12) not null;
  @Semantics.amount.currencyCode : 'zotc_appr_lim.currency'
  max_amount  : abap.curr(15,2);
  currency    : abap.cuky;

}
