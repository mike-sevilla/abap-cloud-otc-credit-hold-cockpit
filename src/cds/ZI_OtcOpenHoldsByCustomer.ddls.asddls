@AbapCatalog.viewEnhancementCategory: [ #NONE ]

@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Open holds per customer'

@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_OtcOpenHoldsByCustomer
  as select from ZI_OtcCreditHold

{
  key CustomerId,
  key Currency,

      @Semantics.amount.currencyCode: 'Currency'
      sum(OrderNetAmount) as BlockedAmount,

      count(*)            as OpenHoldCount
}

where Status = 'H'

group by CustomerId,
         Currency
