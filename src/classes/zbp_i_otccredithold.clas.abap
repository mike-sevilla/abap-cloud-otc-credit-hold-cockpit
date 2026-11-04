CLASS zbp_i_otccredithold DEFINITION PUBLIC ABSTRACT FINAL FOR BEHAVIOR OF zi_otccredithold.
ENDCLASS.


CLASS zbp_i_otccredithold IMPLEMENTATION.
ENDCLASS.

CLASS lhc_credithold DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CONSTANTS c_msgid TYPE symsgid VALUE 'ZOTC_CREDIT'.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR CreditHold RESULT result.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR CreditHold RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR CreditHold RESULT result.

    METHODS onCreate     FOR DETERMINE ON MODIFY IMPORTING keys FOR CreditHold~onCreate.
    METHODS enrichCredit FOR DETERMINE ON MODIFY IMPORTING keys FOR CreditHold~enrichCredit.

    METHODS validateAmount      FOR VALIDATE ON SAVE IMPORTING keys FOR CreditHold~validateAmount.
    METHODS validateCustomer    FOR VALIDATE ON SAVE IMPORTING keys FOR CreditHold~validateCustomer.
    METHODS validateUniqueOrder FOR VALIDATE ON SAVE IMPORTING keys FOR CreditHold~validateUniqueOrder.

    METHODS releaseHold  FOR MODIFY IMPORTING keys FOR ACTION CreditHold~releaseHold  RESULT result.
    METHODS rejectHold   FOR MODIFY IMPORTING keys FOR ACTION CreditHold~rejectHold   RESULT result.
    METHODS escalateHold FOR MODIFY IMPORTING keys FOR ACTION CreditHold~escalateHold RESULT result.
ENDCLASS.


CLASS lhc_credithold IMPLEMENTATION.
  METHOD get_global_authorizations.
    " Anyone may create a hold; decisions are controlled per instance (approval limit).
  ENDMETHOD.

  METHOD get_instance_authorizations.
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold FIELDS ( OrderNetAmount ) WITH CORRESPONDING #( keys )
         RESULT FINAL(holds).

    FINAL(user) = cl_abap_context_info=>get_user_technical_name( ).
    SELECT SINGLE max_amount FROM zotc_appr_lim
      WHERE user_id = @user
      INTO @DATA(approver_limit).
    IF sy-subrc <> 0.
      approver_limit = 0.
    ENDIF.

    FINAL(policy) = NEW zcl_otc_credit_policy( ).
    LOOP AT holds INTO FINAL(hold).
      DATA(release_auth) = if_abap_behv=>auth-allowed.
      TRY.
          policy->assert_can_approve( order_amount   = CONV decfloat34( hold-OrderNetAmount )
                                      approver_limit = CONV decfloat34( approver_limit ) ).
        CATCH zcx_otc_credit.
          release_auth = if_abap_behv=>auth-unauthorized.
      ENDTRY.
      APPEND VALUE #( %tky                = hold-%tky
                      %action-releaseHold = release_auth ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold FIELDS ( Status ) WITH CORRESPONDING #( keys )
         RESULT FINAL(holds).

    result = VALUE #( FOR hold IN holds
                      ( %tky                 = hold-%tky
                        %update              = COND #( WHEN hold-Status = zcl_otc_credit_policy=>status-on_hold
                                                       THEN if_abap_behv=>fc-o-enabled
                                                       ELSE if_abap_behv=>fc-o-disabled )
                        %action-releaseHold  = COND #( WHEN hold-Status = zcl_otc_credit_policy=>status-on_hold
                                                         OR hold-Status = zcl_otc_credit_policy=>status-escalated
                                                       THEN if_abap_behv=>fc-o-enabled
                                                       ELSE if_abap_behv=>fc-o-disabled )
                        %action-rejectHold   = COND #( WHEN hold-Status = zcl_otc_credit_policy=>status-on_hold
                                                         OR hold-Status = zcl_otc_credit_policy=>status-escalated
                                                       THEN if_abap_behv=>fc-o-enabled
                                                       ELSE if_abap_behv=>fc-o-disabled )
                        %action-escalateHold = COND #( WHEN hold-Status = zcl_otc_credit_policy=>status-on_hold
                                                       THEN if_abap_behv=>fc-o-enabled
                                                       ELSE if_abap_behv=>fc-o-disabled ) ) ).
  ENDMETHOD.

  METHOD onCreate.
    MODIFY ENTITIES OF zi_otccredithold IN LOCAL MODE
           ENTITY CreditHold
           UPDATE FIELDS ( Status HeldOn )
           WITH VALUE #( FOR key IN keys
                         ( %tky   = key-%tky
                           Status = zcl_otc_credit_policy=>status-on_hold
                           HeldOn = cl_abap_context_info=>get_system_date( ) ) ).
  ENDMETHOD.

  METHOD enrichCredit.
    DATA updates TYPE TABLE FOR UPDATE zi_otccredithold.

    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold FIELDS ( CustomerId OrderNetAmount ) WITH CORRESPONDING #( keys )
         RESULT FINAL(holds).
    IF holds IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM zotc_cust_cr
      FIELDS customer_id, customer_name, credit_limit, open_receivables, currency, risk_class
      FOR ALL ENTRIES IN @holds
      WHERE customer_id = @holds-CustomerId
      INTO TABLE @FINAL(customers).

    FINAL(policy) = NEW zcl_otc_credit_policy( ).

    LOOP AT holds INTO FINAL(hold).
      ASSIGN customers[ customer_id = hold-CustomerId ] TO FIELD-SYMBOL(<customer>).
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      FINAL(utilization) = policy->utilization_percent(
                               open_receivables = CONV decfloat34( <customer>-open_receivables )
                               order_amount     = CONV decfloat34( hold-OrderNetAmount )
                               credit_limit     = CONV decfloat34( <customer>-credit_limit ) ).
      APPEND VALUE #( %tky            = hold-%tky
                      CustomerName    = <customer>-customer_name
                      CreditLimit     = <customer>-credit_limit
                      OpenReceivables = <customer>-open_receivables
                      Currency        = <customer>-currency
                      UtilizationPct  = utilization
                      HoldReason      = policy->determine_reason( utilization_percent = utilization
                                                                  risk_class          = <customer>-risk_class ) )
             TO updates.
    ENDLOOP.

    MODIFY ENTITIES OF zi_otccredithold IN LOCAL MODE
           ENTITY CreditHold
           UPDATE FIELDS ( CustomerName CreditLimit OpenReceivables Currency UtilizationPct HoldReason )
           WITH updates.
  ENDMETHOD.

  METHOD validateAmount.
    reported-credithold = VALUE #( FOR key IN keys
                                   ( %tky = key-%tky %state_area = 'AMOUNT' ) ).
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold FIELDS ( OrderNetAmount ) WITH CORRESPONDING #( keys )
         RESULT FINAL(holds).

    LOOP AT holds INTO FINAL(hold) WHERE OrderNetAmount <= 0.
      APPEND VALUE #( %tky = hold-%tky ) TO failed-credithold.
      APPEND VALUE #( %tky                    = hold-%tky
                      %state_area             = 'AMOUNT'
                      %msg                    = new_message( id       = c_msgid
                                                             number   = '003'
                                                             severity = if_abap_behv_message=>severity-error )
                      %element-OrderNetAmount = if_abap_behv=>mk-on ) TO reported-credithold.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateCustomer.
    reported-credithold = VALUE #( FOR key IN keys
                                   ( %tky = key-%tky %state_area = 'CUSTOMER' ) ).
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold FIELDS ( CustomerId ) WITH CORRESPONDING #( keys )
         RESULT FINAL(holds).
    IF holds IS INITIAL.
      RETURN.
    ENDIF.

    SELECT FROM zotc_cust_cr
      FIELDS customer_id
      FOR ALL ENTRIES IN @holds
      WHERE customer_id = @holds-CustomerId
      INTO TABLE @FINAL(known_customers).

    LOOP AT holds INTO FINAL(hold).
      IF line_exists( known_customers[ customer_id = hold-CustomerId ] ).
        CONTINUE.
      ENDIF.
      APPEND VALUE #( %tky = hold-%tky ) TO failed-credithold.
      APPEND VALUE #( %tky                = hold-%tky
                      %state_area         = 'CUSTOMER'
                      %msg                = new_message( id       = c_msgid
                                                         number   = '002'
                                                         severity = if_abap_behv_message=>severity-error
                                                         v1       = hold-CustomerId )
                      %element-CustomerId = if_abap_behv=>mk-on ) TO reported-credithold.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateUniqueOrder.
    reported-credithold = VALUE #( FOR key IN keys
                                   ( %tky = key-%tky %state_area = 'UNIQUE_ORDER' ) ).
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold FIELDS ( SalesOrder ) WITH CORRESPONDING #( keys )
         RESULT FINAL(holds).

    LOOP AT holds INTO FINAL(hold).
      SELECT SINGLE FROM zotc_cr_hold
        FIELDS hold_uuid
        WHERE sales_order  = @hold-SalesOrder
          AND hold_uuid   <> @hold-HoldUuid
          AND status      IN ( @zcl_otc_credit_policy=>status-on_hold,
                               @zcl_otc_credit_policy=>status-escalated )
        " TODO: variable is assigned but never used (ABAP cleaner)
        INTO @FINAL(duplicate_uuid).
      IF sy-subrc = 0.
        APPEND VALUE #( %tky = hold-%tky ) TO failed-credithold.
        APPEND VALUE #( %tky                = hold-%tky
                        %state_area         = 'UNIQUE_ORDER'
                        %msg                = new_message( id       = c_msgid
                                                           number   = '001'
                                                           severity = if_abap_behv_message=>severity-error
                                                           v1       = hold-SalesOrder )
                        %element-SalesOrder = if_abap_behv=>mk-on ) TO reported-credithold.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD releaseHold.
    MODIFY ENTITIES OF zi_otccredithold IN LOCAL MODE
           ENTITY CreditHold
           UPDATE FIELDS ( Status DecisionNote DecidedBy DecidedAt )
           WITH VALUE #( FOR key IN keys
                         ( %tky         = key-%tky
                           Status       = zcl_otc_credit_policy=>status-released
                           DecisionNote = key-%param-DecisionNote
                           DecidedBy    = cl_abap_context_info=>get_user_technical_name( )
                           DecidedAt    = utclong_current( ) ) ).
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold ALL FIELDS WITH CORRESPONDING #( keys ) RESULT FINAL(holds).
    result = VALUE #( FOR hold IN holds
                      ( %tky = hold-%tky %param = hold ) ).
  ENDMETHOD.

  METHOD rejectHold.
    LOOP AT keys INTO FINAL(key) WHERE %param-DecisionNote IS INITIAL.
      APPEND VALUE #( %tky = key-%tky ) TO failed-credithold.
      APPEND VALUE #( %tky = key-%tky
                      %msg = new_message( id       = c_msgid
                                          number   = '005'
                                          severity = if_abap_behv_message=>severity-error ) )
             TO reported-credithold.
    ENDLOOP.
    IF failed-credithold IS NOT INITIAL.
      RETURN.
    ENDIF.

    MODIFY ENTITIES OF zi_otccredithold IN LOCAL MODE
           ENTITY CreditHold
           UPDATE FIELDS ( Status DecisionNote DecidedBy DecidedAt )
           WITH VALUE #( FOR k IN keys
                         ( %tky         = k-%tky
                           Status       = zcl_otc_credit_policy=>status-rejected
                           DecisionNote = k-%param-DecisionNote
                           DecidedBy    = cl_abap_context_info=>get_user_technical_name( )
                           DecidedAt    = utclong_current( ) ) ).
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold ALL FIELDS WITH CORRESPONDING #( keys ) RESULT FINAL(holds).
    result = VALUE #( FOR hold IN holds
                      ( %tky = hold-%tky %param = hold ) ).
  ENDMETHOD.

  METHOD escalateHold.
    MODIFY ENTITIES OF zi_otccredithold IN LOCAL MODE
           ENTITY CreditHold
           UPDATE FIELDS ( Status DecisionNote )
           WITH VALUE #( FOR key IN keys
                         ( %tky         = key-%tky
                           Status       = zcl_otc_credit_policy=>status-escalated
                           DecisionNote = key-%param-DecisionNote ) ).
    READ ENTITIES OF zi_otccredithold IN LOCAL MODE
         ENTITY CreditHold ALL FIELDS WITH CORRESPONDING #( keys ) RESULT FINAL(holds).
    result = VALUE #( FOR hold IN holds
                      ( %tky = hold-%tky %param = hold ) ).
  ENDMETHOD.
ENDCLASS.
