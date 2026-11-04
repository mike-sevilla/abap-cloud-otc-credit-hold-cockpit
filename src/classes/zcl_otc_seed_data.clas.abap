CLASS zcl_otc_seed_data DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.
    METHODS seed_master_data.
    METHODS seed_holds IMPORTING !out TYPE REF TO if_oo_adt_classrun_out.
ENDCLASS.


CLASS zcl_otc_seed_data IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DELETE FROM zotc_cr_hold.
    DELETE FROM zotc_cr_hold_d.
    seed_master_data( ).
    seed_holds( out ).
  ENDMETHOD.

  METHOD seed_master_data.
    DELETE FROM zotc_cust_cr.
    DELETE FROM zotc_appr_lim.

    INSERT zotc_cust_cr FROM TABLE @( VALUE #( currency = 'USD'
                                               ( customer_id      = 'C1000'
                                                 customer_name    = 'Contoso Foods'
                                                 credit_limit     = '100000.00'
                                                 open_receivables = '60000.00'
                                                 risk_class       = 'A' )
                                               ( customer_id      = 'C2000'
                                                 customer_name    = 'Northwind Retail'
                                                 credit_limit     = '50000.00'
                                                 open_receivables = '45000.00'
                                                 risk_class       = 'B' )
                                               ( customer_id      = 'C3000'
                                                 customer_name    = 'Fabrikam Distributors'
                                                 credit_limit     = '200000.00'
                                                 open_receivables = '20000.00'
                                                 risk_class       = 'C' ) ) ).

    INSERT zotc_appr_lim FROM @( VALUE #( user_id    = cl_abap_context_info=>get_user_technical_name( )
                                          max_amount = '50000.00'
                                          currency   = 'USD' ) ).
  ENDMETHOD.

  METHOD seed_holds.
    MODIFY ENTITIES OF zi_otccredithold
           ENTITY CreditHold
           CREATE FIELDS ( SalesOrder CustomerId OrderNetAmount )
           WITH VALUE #( ( %cid = 'H1' SalesOrder = '5000001' CustomerId = 'C1000' OrderNetAmount = '45000.00' )
                         ( %cid = 'H2' SalesOrder = '5000002' CustomerId = 'C2000' OrderNetAmount = '12000.00' )
                         ( %cid = 'H3' SalesOrder = '5000003' CustomerId = 'C3000' OrderNetAmount = '30000.00' )
                         ( %cid = 'H4' SalesOrder = '5000004' CustomerId = 'C1000' OrderNetAmount = '80000.00' ) )
              " TODO: variable is assigned but never used (ABAP cleaner)
           FAILED FINAL(failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED FINAL(reported).

    COMMIT ENTITIES RESPONSE OF ZI_OtcCreditHold
           FAILED FINAL(commit_failed)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED FINAL(commit_reported).

    IF commit_failed IS INITIAL.
      out->write( 'Holds created' ).
    ELSE.
      out->write( commit_failed ).
    ENDIF.

    SELECT FROM ZI_OtcOpenHoldsByCustomer
      FIELDS CustomerId, BlockedAmount, Currency, OpenHoldCount
      INTO TABLE @FINAL(summary).

    out->write( summary ).
  ENDMETHOD.
ENDCLASS.
