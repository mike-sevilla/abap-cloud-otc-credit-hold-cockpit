@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Order credit hold (projection)'
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity ZC_OtcCreditHold 
provider contract transactional_query
as projection on ZI_OtcCreditHold
{
    key HoldUuid,
    @Search.defaultSearchElement: true
    SalesOrder,
    @Search.defaultSearchElement: true
    @Consumption.valueHelpDefinition: [{ entity: { name: 'ZI_OtcCustomerCredit', element: 'CustomerId' } }]
    CustomerId,
    CustomerName,
    OrderNetAmount,
    CreditLimit,
    OpenReceivables,
    Currency,
    UtilizationPct,
    HoldReason,
    HeldOn,
    DaysOnHold,
    Status,
    StatusText,
    StatusCriticality,
    DecisionNote,
    DecidedBy,
    DecidedAt,
    LocalLastChangedAt,
    LastChangedAt
    
}
