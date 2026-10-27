# Payment gateway logos

Drop the official logo files here, named as the registry
(`lib/features/builder/domain/payment_gateways.dart`) expects:

| Gateway | Logo | Optional dark-background variant |
|---------|------|-----------------------------------|
| HyperPay | `hyperpay.svg` | `hyperpay-dark.svg` |
| Paymob | `paymob.svg` | `paymob-dark.svg` |
| Amazon Payment Services (PayFort) | `aps.svg` | `aps-dark.svg` |

Use the files exactly as the brand provides them: the wizard shows them
uncropped, unstretched and not recolored, on a white tile. Until a file is
here (or if it fails to load) the tile shows the gateway's initials instead.
