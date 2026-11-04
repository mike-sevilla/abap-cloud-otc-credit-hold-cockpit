@EndUserText.label : 'Customer credit master'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zotc_cust_cr {

  key client       : abap.clnt not null;
  key customer_id  : abap.char(10) not null;
  customer_name    : abap.char(40);
  @Semantics.amount.currencyCode : 'zotc_cust_cr.currency'
  credit_limit     : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'zotc_cust_cr.currency'
  open_receivables : abap.curr(15,2);
  currency         : abap.cuky;
  risk_class       : abap.char(1);

}
