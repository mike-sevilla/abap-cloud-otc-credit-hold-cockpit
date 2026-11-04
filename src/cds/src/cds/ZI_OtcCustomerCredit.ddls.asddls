@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Customer credit master'

define view entity ZI_OtcCustomerCredit
  as select from zotc_cust_cr

{
  key customer_id      as CustomerId,

      customer_name    as CustomerName,

      @Semantics.amount.currencyCode: 'Currency'
      credit_limit     as CreditLimit,

      @Semantics.amount.currencyCode: 'Currency'
      open_receivables as OpenReceivables,

      currency         as Currency,
      risk_class       as RiskClass
}
