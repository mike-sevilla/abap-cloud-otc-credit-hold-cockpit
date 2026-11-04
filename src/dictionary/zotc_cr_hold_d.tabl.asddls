@EndUserText.label : 'Draft table for entity ZI_OTCCREDITHOLD'
@AbapCatalog.enhancement.category : #EXTENSIBLE_ANY
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table zotc_cr_hold_d {

  key mandt          : mandt not null;
  key holduuid       : sysuuid_x16 not null;
  salesorder         : abap.char(10);
  customerid         : abap.char(10);
  customername       : abap.char(40);
  @Semantics.amount.currencyCode : 'zotc_cr_hold_d.currency'
  ordernetamount     : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'zotc_cr_hold_d.currency'
  creditlimit        : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'zotc_cr_hold_d.currency'
  openreceivables    : abap.curr(15,2);
  currency           : abap.cuky;
  utilizationpct     : abap.dec(5,1);
  holdreason         : abap.char(1);
  heldon             : abap.dats;
  status             : zotc_hold_status;
  daysonhold         : abap.int4;
  statustext         : abap.char(12);
  statuscriticality  : abap.int1;
  decisionnote       : abap.char(255);
  decidedby          : abap.char(12);
  decidedat          : abap.utclong;
  localcreatedby     : abp_creation_user;
  localcreatedat     : abp_creation_tstmpl;
  locallastchangedby : abp_locinst_lastchange_user;
  locallastchangedat : abp_locinst_lastchange_tstmpl;
  lastchangedat      : abp_lastchange_tstmpl;
  "%admin"           : include sych_bdl_draft_admin_inc;

}
