# O2C Credit Hold Release Cockpit (ABAP Cloud / RAP)

A Fiori Elements app built with ABAP Cloud and the ABAP RESTful Application Programming Model (RAP). It lets credit controllers **release, reject or escalate credit-blocked sales orders**, with approval limits and an audit trail.

> **Note:** The source in this repository was exported manually from ADT (Eclipse), so it is not in abapGit format. See [Setup](#setup) for how to recreate the objects.

---

## Business problem

In the Order to Cash (O2C) process, sales orders blocked by the credit check often end up in an uncontrolled queue. Credit controllers work from email and spreadsheets, so:

- nobody sees credit exposure or how long an order has been blocked
- there is no approval limit per approver
- there is no audit trail of who decided what, and when

The result is late deliveries and delayed billing.

## Solution

A transactional Fiori Elements app with a list report and an object page:

- **Credit utilization %**, hold reason and days on hold for every blocked order
- **Release**, **Reject** and **Escalate** actions, each with a decision note
- **Reject requires a note**
- **Release is blocked** when the order amount is above the user's approval limit
- Every decision is stamped with the user and the time
- Draft handling, side effects and instance-based feature control
- No delete action, so the audit trail is kept

## Business rules

| Rule | Behavior |
|---|---|
| Utilization | `(open receivables + order amount) / credit limit × 100`, rounded to 1 decimal and capped at 999. A credit limit of 0 returns 999. |
| Hold reason | Utilization above 100% = **Limit exceeded**. Risk class `C` = **High risk**. Otherwise none. |
| Release | Only allowed if the order amount is within the user's approval limit (`ZOTC_APPR_LIM`). |
| Reject | A decision note is mandatory. |
| Duplicate holds | Only one open hold (On Hold or Escalated) per sales order. |
| Statuses | `H` On Hold, `R` Released, `X` Rejected, `E` Escalated |

## Tech stack

- ABAP Cloud, strict mode and released APIs only
- CDS view entities, associations, aggregation and access control (DCL)
- RAP: managed, draft-enabled, `strict ( 2 )`
- Actions with an abstract-entity parameter, determinations, validations, side effects
- Instance authorization and instance feature control
- ABAP SQL (`FOR ALL ENTRIES`, `SELECT SINGLE`), constructor expressions, table expressions
- T100 exception class (`ZCX_OTC_CREDIT`)
- ABAP Unit
- OData V4 UI service, Fiori Elements preview

## Architecture

```
Tables (ZOTC_CR_HOLD, ZOTC_CUST_CR, ZOTC_APPR_LIM)
   -> ZI_OtcCreditHold (root view entity)   -> ZI_OtcOpenHoldsByCustomer (aggregation)
   -> RAP behavior (managed, draft)         -> ZBP_I_OTCCREDITHOLD
   -> ZC_OtcCreditHold (projection) + metadata extension (UI annotations)
   -> Service definition ZUI_OTCCREDITHOLD -> Service binding ZUI_OTCCREDITHOLD_O4 (OData V4 - UI)
```

Business rules live in the global class `ZCL_OTC_CREDIT_POLICY`. It has no dependency on RAP, so it can be tested in isolation with ABAP Unit. The behavior implementation only reads and writes through EML and calls the policy class.

## Repository structure

```
src/
  dictionary/   4 database tables
  cds/          view entities, projection, abstract entity, access control, metadata extension
  rap/          behavior definitions, service definition
  classes/      policy class, exception class, behavior class, seed data class
docs/           screenshots
```

## Objects

| Type | Name |
|---|---|
| Package | `ZOTC_CREDIT_HOLD` |
| Domain / Data element | `ZOTC_HOLD_STATUS` (CHAR 1, values H, R, X, E) |
| Tables | `ZOTC_CR_HOLD`, `ZOTC_CR_HOLD_D` (draft), `ZOTC_CUST_CR`, `ZOTC_APPR_LIM` |
| View entities | `ZI_OtcCustomerCredit`, `ZI_OtcCreditHold`, `ZI_OtcOpenHoldsByCustomer`, `ZC_OtcCreditHold` |
| Abstract entity | `ZA_OtcDecision` |
| Access control | `ZI_OtcCreditHold`, `ZC_OtcCreditHold` |
| Behavior definitions | `ZI_OtcCreditHold`, `ZC_OtcCreditHold` (projection) |
| Metadata extension | `ZME_OtcCreditHold` |
| Classes | `ZCL_OTC_CREDIT_POLICY`, `ZCX_OTC_CREDIT`, `ZBP_I_OTCCREDITHOLD`, `ZCL_OTC_SEED_DATA` |
| Message class | `ZOTC_CREDIT` |
| Service | `ZUI_OtcCreditHold` (definition), `ZUI_OTCCREDITHOLD_O4` (OData V4 - UI binding) |

### Message class `ZOTC_CREDIT`

| No. | Text |
|---|---|
| 001 | Sales order &1 already has an open credit hold |
| 002 | Customer &1 does not exist in the credit master |
| 003 | Order amount must be greater than zero |
| 004 | Your approval limit &1 is below the order amount &2 |
| 005 | A decision note is required to reject an order |

## Setup

**Requirements:** an SAP BTP ABAP environment (trial is fine) and ABAP Development Tools (ADT) in Eclipse.

1. Create the package `ZOTC_CREDIT_HOLD` in your ABAP Cloud project.
2. Create the objects in this order, copying the source from `src/`:
   1. Domain and data element `ZOTC_HOLD_STATUS`, then the tables
   2. Message class `ZOTC_CREDIT`
   3. View entities, abstract entity and access control
   4. `ZCX_OTC_CREDIT` and `ZCL_OTC_CREDIT_POLICY`, including the test class
   5. Behavior definition, using `Ctrl+1` to generate the draft table and behavior class
   6. Local types of `ZBP_I_OTCCREDITHOLD`
   7. Projection view, projection behavior and metadata extension
   8. Service definition and service binding
3. Activate all objects with `Ctrl+Shift+F3`.
4. Run `ZCL_OTC_SEED_DATA` with `F9` to create the demo customers, the approver limit and four sample holds.
5. Open the service binding `ZUI_OTCCREDITHOLD_O4`, click **Publish**, select the `CreditHold` entity set, and click **Preview**.

## Demo data and expected results

The seed class creates three customers and one approver with a limit of 50,000 USD.

| Sales order | Customer | Order amount | Utilization | Hold reason | Release by a 50,000 approver |
|---|---|---|---|---|---|
| 5000001 | C1000 | 45,000 | 105% | Limit exceeded | Allowed |
| 5000002 | C2000 | 12,000 | 114% | Limit exceeded | Allowed |
| 5000003 | C3000 | 30,000 | 25% | High risk | Allowed |
| 5000004 | C1000 | 80,000 | 140% | Limit exceeded | **Blocked** (message 004) |

Other checks:

- **Reject** without a note shows message 005.
- Creating a second hold for order `5000001` shows message 001.
- An unknown customer ID shows message 002.

## Testing

`ZCL_OTC_CREDIT_POLICY` has 8 ABAP Unit tests covering utilization, hold reason and approval-limit logic. Run them with `Ctrl+Shift+F10`.

## Screenshots

| List report | Object page |
|---|---|
| ![List report](docs/list-report.png) | ![Object page](docs/object-page.png) |

| Release blocked above approval limit | ABAP Unit results |
|---|---|
| ![Release blocked](docs/release-blocked.png) | ![ABAP Unit](docs/abap-unit.png) |

## Clean Core and design notes

- Only released APIs are used, targeting the ABAP Cloud development scope.
- Business logic is kept in a separate, testable class, not in the RAP handlers.
- The customer credit master is a custom table for the demo. In a real system, replace it with released CDS views from S/4HANA.
- There is no physical delete, so decisions stay auditable.

## Roadmap

- Replace the demo credit master with released S/4HANA CDS views
- Raise a business event when a hold is released
- Restrict read access through a `PFCG_AUTH` aspect in the access control
- Add an analytical view of blocked amount per customer to the UI

## Author

Mike Sevilla

## License

MIT. See [LICENSE](LICENSE).
