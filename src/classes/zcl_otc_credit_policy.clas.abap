CLASS zcl_otc_credit_policy DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_reason     TYPE c LENGTH 1.
    TYPES ty_risk_class TYPE c LENGTH 1.

    CONSTANTS: BEGIN OF status,
                 on_hold   TYPE zotc_hold_status VALUE 'H',
                 released  TYPE zotc_hold_status VALUE 'R',
                 rejected  TYPE zotc_hold_status VALUE 'X',
                 escalated TYPE zotc_hold_status VALUE 'E',
               END OF status.

    CONSTANTS: BEGIN OF reason,
                 none           TYPE ty_reason VALUE '',
                 limit_exceeded TYPE ty_reason VALUE 'L',
                 high_risk      TYPE ty_reason VALUE 'H',
               END OF reason.

    METHODS utilization_percent
      IMPORTING open_receivables TYPE decfloat34
                order_amount     TYPE decfloat34
                credit_limit     TYPE decfloat34
      RETURNING VALUE(result)    TYPE decfloat34.

    METHODS determine_reason
      IMPORTING utilization_percent TYPE decfloat34
                risk_class          TYPE ty_risk_class
      RETURNING VALUE(result)       TYPE ty_reason.

    METHODS assert_can_approve
      IMPORTING order_amount   TYPE decfloat34
                approver_limit TYPE decfloat34
      RAISING   zcx_otc_credit.
ENDCLASS.


CLASS zcl_otc_credit_policy IMPLEMENTATION.
  METHOD utilization_percent.
    IF credit_limit <= 0.
      result = 999.
      RETURN.
    ENDIF.

    result = nmin( val1 = round( val = ( open_receivables + order_amount ) * 100 / credit_limit
                                 dec = 1 )
                   val2 = 999 ).
  ENDMETHOD.

  METHOD determine_reason.
    result = COND #( WHEN utilization_percent > 100 THEN reason-limit_exceeded
                     WHEN risk_class = 'C'          THEN reason-high_risk
                     ELSE                                reason-none ).
  ENDMETHOD.

  METHOD assert_can_approve.
    IF order_amount > approver_limit.
      RAISE EXCEPTION NEW zcx_otc_credit( textid = zcx_otc_credit=>approval_limit_too_low
                                          msgv1  = |{ approver_limit }|
                                          msgv2  = |{ order_amount }| ).

    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS ltc_credit_policy DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_otc_credit_policy.

    METHODS setup.
    METHODS utilization_within_limit  FOR TESTING.
    METHODS utilization_above_limit   FOR TESTING.
    METHODS utilization_no_limit      FOR TESTING.
    METHODS reason_limit_exceeded     FOR TESTING.
    METHODS reason_high_risk          FOR TESTING.
    METHODS reason_none               FOR TESTING.
    METHODS approver_limit_too_low    FOR TESTING.
    METHODS approver_limit_sufficient FOR TESTING RAISING zcx_otc_credit.
ENDCLASS.


CLASS ltc_credit_policy IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD utilization_within_limit.
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 70 )
                                        act = cut->utilization_percent( open_receivables = 50000
                                                                        order_amount     = 20000
                                                                        credit_limit     = 100000 ) ).
  ENDMETHOD.

  METHOD utilization_above_limit.
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 105 )
                                        act = cut->utilization_percent( open_receivables = 60000
                                                                        order_amount     = 45000
                                                                        credit_limit     = 100000 ) ).
  ENDMETHOD.

  METHOD utilization_no_limit.
    cl_abap_unit_assert=>assert_equals( exp = CONV decfloat34( 999 )
                                        act = cut->utilization_percent( open_receivables = 0
                                                                        order_amount     = 100
                                                                        credit_limit     = 0 ) ).
  ENDMETHOD.

  METHOD reason_limit_exceeded.
    cl_abap_unit_assert=>assert_equals( exp = zcl_otc_credit_policy=>reason-limit_exceeded
                                        act = cut->determine_reason( utilization_percent = 105
                                                                     risk_class          = 'A' ) ).
  ENDMETHOD.

  METHOD reason_high_risk.
    cl_abap_unit_assert=>assert_equals( exp = zcl_otc_credit_policy=>reason-high_risk
                                        act = cut->determine_reason( utilization_percent = 40
                                                                     risk_class          = 'C' ) ).
  ENDMETHOD.

  METHOD reason_none.
    cl_abap_unit_assert=>assert_equals( exp = zcl_otc_credit_policy=>reason-none
                                        act = cut->determine_reason( utilization_percent = 80
                                                                     risk_class          = 'A' ) ).
  ENDMETHOD.

  METHOD approver_limit_too_low.
    TRY.
        cut->assert_can_approve( order_amount   = 80000
                                 approver_limit = 50000 ).
        cl_abap_unit_assert=>fail( 'Exception expected' ).
      CATCH zcx_otc_credit.
    ENDTRY.
  ENDMETHOD.

  METHOD approver_limit_sufficient.
    cut->assert_can_approve( order_amount   = 30000
                             approver_limit = 50000 ).
  ENDMETHOD.
ENDCLASS.
