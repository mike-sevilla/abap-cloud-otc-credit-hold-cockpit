@AccessControl.authorizationCheck: #CHECK

@EndUserText.label: 'Order credit hold'

define root view entity ZI_OtcCreditHold
  as select from zotc_cr_hold

  association [0..1] to ZI_OtcCustomerCredit as _Customer on $projection.CustomerId = _Customer.CustomerId

{
  key hold_uuid                                 as HoldUuid,

      sales_order                               as SalesOrder,
      customer_id                               as CustomerId,
      customer_name                             as CustomerName,
      order_net_amount                          as OrderNetAmount,
      credit_limit                              as CreditLimit,
      open_receivables                          as OpenReceivables,
      currency                                  as Currency,
      utilization_pct                           as UtilizationPct,
      hold_reason                               as HoldReason,
      held_on                                   as HeldOn,
      status                                    as Status,

      cast(case when status = 'H' or status = 'E'
             then dats_days_between(held_on, $session.system_date)
             else 0 end as abap.int4
          )                                     as DaysOnHold,

      case status
      when 'H' then cast('On Hold' as abap.char(12))
      when 'R' then cast('Released' as abap.char(12))
      when 'X' then cast('Rejected' as abap.char(12))
      when 'E' then cast('Escalated' as abap.char(12))
      else cast('' as abap.char(12)) end        as StatusText,

      cast(case status when 'H' then 2
                       when 'E' then 2
                       when 'R' then 1
                       when 'X' then 0
                       else 0 end as abap.int1) as StatusCriticality,


      decision_note                             as   DecisionNote,
      decided_by                                as DecidedBy,
      decided_at                                as DecidedAt,

      @Semantics.user.createdBy: true
      local_created_by                          as LocalCreatedBy,

      @Semantics.systemDateTime.createdAt: true
      local_created_at                          as LocalCreatedAt,

      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by                     as LocalLastChangedBy,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at                     as LocalLastChangedAt,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at                           as LastChangedAt,

      _Customer
}
