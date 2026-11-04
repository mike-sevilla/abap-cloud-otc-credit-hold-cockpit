CLASS zcx_otc_credit DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    CONSTANTS:
      BEGIN OF approval_limit_too_low,
        msgid TYPE symsgid      VALUE 'ZOTC_CREDIT',
        msgno TYPE symsgno      VALUE '004',
        attr1 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV1',
        attr2 TYPE scx_attrname VALUE 'IF_T100_DYN_MSG~MSGV2',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF approval_limit_too_low.

    METHODS constructor
      IMPORTING textid    LIKE if_t100_message=>t100key OPTIONAL
                !previous LIKE previous                 OPTIONAL
                msgv1     TYPE string                   OPTIONAL
                msgv2     TYPE string                   OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcx_otc_credit IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    CLEAR me->textid.
    if_t100_dyn_msg~msgty = 'E'.
    if_t100_dyn_msg~msgv1 = msgv1.
    if_t100_dyn_msg~msgv2 = msgv2.

    if_t100_message~t100key = COND #( WHEN textid IS INITIAL
                                      THEN if_t100_message~default_textid
                                      ELSE textid ).
  ENDMETHOD.
ENDCLASS.
