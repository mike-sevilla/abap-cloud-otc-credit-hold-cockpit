@EndUserText.label : 'Order credit hold'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zotc_cr_hold {

  key client            : abap.clnt not null;
  key hold_uuid         : sysuuid_x16 not null;
  sales_order           : abap.char(10);
  customer_id           : abap.char(10);
  customer_name         : abap.char(40);
  @Semantics.amount.currencyCode : 'zotc_cr_hold.currency'
  order_net_amount      : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'zotc_cr_hold.currency'
  credit_limit          : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'zotc_cr_hold.currency'
  open_receivables      : abap.curr(15,2);
  currency              : abap.cuky;
  utilization_pct       : abap.dec(5,1);
  hold_reason           : abap.char(1);
  held_on               : abap.dats;
  status                : zotc_hold_status;
  decision_note         : abap.char(255);
  decided_by            : abap.char(12);
  decided_at            : abap.utclong;
  local_created_by      : abp_creation_user;
  local_created_at      : abp_creation_tstmpl;
  local_last_changed_by : abp_locinst_lastchange_user;
  local_last_changed_at : abp_locinst_lastchange_tstmpl;
  last_changed_at       : abp_lastchange_tstmpl;

}
